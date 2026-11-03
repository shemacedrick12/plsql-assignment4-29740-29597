-- =====================================================================
-- test_success_cases.sql
-- Runs every procedure and function on valid input.
-- Run with F5 (Run Script) in SQL Developer, AFTER the schema, sample data,
-- procedures and functions are installed.
-- The script changes data inside ONE transaction and ends with ROLLBACK,
-- so the sample data is back to normal afterwards and you can re-run it.
-- Take one screenshot per test (names suggested in each header).
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200

PROMPT
PROMPT ===== TEST S1: functions called from SQL  [screenshot: functions_from_sql_output.png]
PROMPT Expected: B | 3.5 | 1004 | seats left 22,25,21,35,0,28
SELECT get_letter_grade(85)       AS letter_for_85,
       calculate_gpa(1001)        AS gpa_student_1001,
       find_student_id('Habimana') AS id_habimana
FROM   dual;

SELECT course_code, max_capacity, get_available_seats(course_id) AS seats_left
FROM   courses
ORDER  BY course_id;

PROMPT
PROMPT ===== TEST S2: register_student, new enrollment  [screenshot: register_student_success_output.png]
PROMPT Expected: new enrollment created, then seats in INSY8311 drop from 22 to 21
DECLARE
  v_enrollment_id NUMBER;
BEGIN
  register_student(1009, 101, v_enrollment_id);
  DBMS_OUTPUT.PUT_LINE('OUT parameter p_enrollment_id = ' || v_enrollment_id);
  DBMS_OUTPUT.PUT_LINE('Seats left in INSY8311 = ' || get_available_seats(101));
END;
/

PROMPT
PROMPT ===== TEST S3: drop_enrollment without and with a grade  [screenshot: drop_enrollment_success_output.png]
PROMPT Expected: 0 grades deleted for 1002/CSC201, 1 grade deleted for 1001/INSY8311, GPA of 1001 becomes 3
DECLARE
  v_deleted PLS_INTEGER;
BEGIN
  drop_enrollment(1002, 105, v_deleted);
  DBMS_OUTPUT.PUT_LINE('Grades deleted (1002, CSC201): ' || v_deleted);
  DBMS_OUTPUT.PUT_LINE('---');
  drop_enrollment(1001, 101, v_deleted);
  DBMS_OUTPUT.PUT_LINE('Grades deleted (1001, INSY8311): ' || v_deleted);
  DBMS_OUTPUT.PUT_LINE('GPA of 1001 after losing the INSY8311 grade: ' || calculate_gpa(1001));
END;
/

PROMPT
PROMPT ===== TEST S4: register_student re-activates a dropped enrollment  [screenshot: register_student_reactivate_output.png]
PROMPT Expected: "Dropped enrollment re-activated (rows updated: 1)"
DECLARE
  v_enrollment_id NUMBER;
BEGIN
  register_student(1002, 105, v_enrollment_id);
  DBMS_OUTPUT.PUT_LINE('OUT parameter p_enrollment_id = ' || v_enrollment_id);
END;
/

PROMPT
PROMPT ===== TEST S5: bulk_upload_grades, all rows valid  [screenshot: bulk_upload_grades_success_output.png]
PROMPT Expected: inserted = 3, rejected = 0
DECLARE
  v_inserted PLS_INTEGER;
  v_rejected PLS_INTEGER;
BEGIN
  bulk_upload_grades(101,
                     SYS.ODCINUMBERLIST(1006, 1007, 1008),
                     SYS.ODCINUMBERLIST(81, 95, 59),
                     v_inserted, v_rejected);
  DBMS_OUTPUT.PUT_LINE('OUT parameters -> inserted: ' || v_inserted || ', rejected: ' || v_rejected);
END;
/

SELECT s.student_id, s.last_name, g.score, g.letter_grade, g.grade_points
FROM   grades g
JOIN   enrollments e ON e.enrollment_id = g.enrollment_id
JOIN   students s    ON s.student_id    = e.student_id
WHERE  e.course_id = 101
ORDER  BY s.student_id;

PROMPT
PROMPT ===== TEST S6: print_transcript (explicit cursor + records)  [screenshot: print_transcript_success_output.png]
PROMPT Expected: INSY8311 B, INSY8312 A, CSC201 not graded, GPA 3.5 over 6 credits
DECLARE
  v_gpa     NUMBER;
  v_credits NUMBER;
BEGIN
  print_transcript(1002, v_gpa, v_credits);
  DBMS_OUTPUT.PUT_LINE('OUT parameters -> gpa: ' || v_gpa || ', graded credits: ' || v_credits);
END;
/

PROMPT
PROMPT ===== TEST S7: log_error writes to ERROR_LOG  [screenshot: log_error_success_output.png]
BEGIN
  log_error('manual_test', -99999, 'This is a test entry written by test_success_cases.sql');
END;
/
SELECT log_id, module_name, error_code, error_message FROM error_log ORDER BY log_id;

PROMPT
PROMPT ===== Undoing all changes made by this script (sample data restored)
ROLLBACK;
