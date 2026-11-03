-- =====================================================================
-- print_transcript.sql
-- Prints a student's transcript and returns the GPA.
--   IN : p_student_id
--   OUT: p_gpa            credit-weighted GPA (NULL if nothing graded yet)
--        p_graded_credits credits that have a grade
-- Demonstrates: explicit cursor with a parameter (OPEN / FETCH / CLOSE),
--   user-defined record, %ROWTYPE record, NO_DATA_FOUND,
--   RAISE_APPLICATION_ERROR, cursor cleanup on error.
-- Error codes: -20001 student missing   -20099 unexpected
-- =====================================================================
CREATE OR REPLACE PROCEDURE print_transcript (
  p_student_id     IN  students.student_id%TYPE,
  p_gpa            OUT NUMBER,
  p_graded_credits OUT NUMBER
) AS
  CURSOR c_transcript (cp_student_id NUMBER) IS
    SELECT c.course_code, c.course_name, c.credits,
           g.score, g.letter_grade, g.grade_points
    FROM   enrollments e
    JOIN   courses c      ON c.course_id     = e.course_id
    LEFT JOIN grades g    ON g.enrollment_id = e.enrollment_id
    WHERE  e.student_id = cp_student_id
    AND    e.status    <> 'DROPPED'
    ORDER BY c.course_code;

  -- user-defined record that receives one transcript line
  TYPE t_line IS RECORD (
    course_code  courses.course_code%TYPE,
    course_name  courses.course_name%TYPE,
    credits      courses.credits%TYPE,
    score        grades.score%TYPE,
    letter_grade grades.letter_grade%TYPE,
    grade_points grades.grade_points%TYPE
  );
  v_line    t_line;
  v_student students%ROWTYPE;            -- %ROWTYPE record
  v_points  NUMBER := 0;
  v_lines   PLS_INTEGER := 0;
BEGIN
  p_gpa            := NULL;
  p_graded_credits := 0;

  BEGIN
    SELECT * INTO v_student FROM students WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Student ' || p_student_id || ' does not exist.');
  END;

  DBMS_OUTPUT.PUT_LINE('==== TRANSCRIPT: ' || v_student.first_name || ' ' || v_student.last_name
                       || ' (ID ' || v_student.student_id || ', ' || v_student.status || ') ====');
  DBMS_OUTPUT.PUT_LINE(RPAD('CODE', 10) || RPAD('COURSE', 36) || RPAD('CR', 4)
                       || RPAD('SCORE', 7) || 'GRADE');

  OPEN c_transcript(p_student_id);
  LOOP
    FETCH c_transcript INTO v_line;
    EXIT WHEN c_transcript%NOTFOUND;

    v_lines := v_lines + 1;
    DBMS_OUTPUT.PUT_LINE(RPAD(v_line.course_code, 10) || RPAD(v_line.course_name, 36)
                         || RPAD(v_line.credits, 4)
                         || RPAD(NVL(TO_CHAR(v_line.score), '-'), 7)
                         || NVL(v_line.letter_grade, 'not graded'));

    IF v_line.grade_points IS NOT NULL THEN
      v_points         := v_points + v_line.grade_points * v_line.credits;
      p_graded_credits := p_graded_credits + v_line.credits;
    END IF;
  END LOOP;
  CLOSE c_transcript;

  IF v_lines = 0 THEN
    DBMS_OUTPUT.PUT_LINE('(no registered courses)');
  END IF;

  IF p_graded_credits > 0 THEN
    p_gpa := ROUND(v_points / p_graded_credits, 2);
    DBMS_OUTPUT.PUT_LINE('GPA: ' || TO_CHAR(p_gpa, 'FM0.00') || ' over '
                         || p_graded_credits || ' graded credits');
  ELSE
    DBMS_OUTPUT.PUT_LINE('GPA: not available (no graded courses yet)');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    IF c_transcript%ISOPEN THEN
      CLOSE c_transcript;                -- never leave a cursor open after an error
    END IF;
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    log_error('print_transcript', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in print_transcript: ' || SQLERRM);
END print_transcript;
/
SHOW ERRORS
