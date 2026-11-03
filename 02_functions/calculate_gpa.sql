-- =====================================================================
-- calculate_gpa.sql
-- Credit-weighted GPA of a student: SUM(grade_points * credits) / SUM(credits)
-- over the courses that already have a grade (DROPPED courses ignored).
-- Returns NULL when the student has no graded course yet (NOT 0, because
-- 0.00 would wrongly look like a real GPA).
-- Demonstrates: user-defined record, nested-table collection of records,
--   BULK COLLECT, predefined exception handling, RAISE_APPLICATION_ERROR.
-- Call from SQL:   SELECT calculate_gpa(1001) FROM dual;
-- Error codes: -20001 student missing   -20099 unexpected
-- =====================================================================
CREATE OR REPLACE FUNCTION calculate_gpa (
  p_student_id IN students.student_id%TYPE
) RETURN NUMBER
AS
  TYPE t_grade_rec IS RECORD (
    credits      courses.credits%TYPE,
    grade_points grades.grade_points%TYPE
  );
  TYPE t_grade_tab IS TABLE OF t_grade_rec;      -- nested table of records

  v_grades  t_grade_tab;
  v_exists  NUMBER;
  v_points  NUMBER := 0;
  v_credits NUMBER := 0;
BEGIN
  SELECT COUNT(*) INTO v_exists FROM students WHERE student_id = p_student_id;
  IF v_exists = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Student ' || p_student_id || ' does not exist.');
  END IF;

  SELECT c.credits, g.grade_points
  BULK COLLECT INTO v_grades
  FROM   enrollments e
  JOIN   courses c ON c.course_id     = e.course_id
  JOIN   grades  g ON g.enrollment_id = e.enrollment_id
  WHERE  e.student_id = p_student_id
  AND    e.status    <> 'DROPPED';

  IF v_grades.COUNT = 0 THEN
    RETURN NULL;                                  -- nothing graded yet
  END IF;

  FOR i IN 1 .. v_grades.COUNT LOOP
    v_points  := v_points  + v_grades(i).grade_points * v_grades(i).credits;
    v_credits := v_credits + v_grades(i).credits;
  END LOOP;

  RETURN ROUND(v_points / v_credits, 2);
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    log_error('calculate_gpa', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in calculate_gpa: ' || SQLERRM);
END calculate_gpa;
/
SHOW ERRORS
