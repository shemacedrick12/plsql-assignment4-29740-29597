-- =====================================================================
-- drop_enrollment.sql
-- Drops a student from a course: deletes any grade, marks enrollment DROPPED.
--   IN : p_student_id, p_course_id
--   OUT: p_grades_deleted (number of grade rows removed)
-- Demonstrates: implicit cursors on DELETE and UPDATE
--   (SQL%ROWCOUNT, SQL%NOTFOUND), NO_DATA_FOUND, TOO_MANY_ROWS,
--   RAISE_APPLICATION_ERROR. Does not commit.
-- Error codes: -20010 no active enrollment   -20011 update failed
--              -20012 data integrity problem  -20099 unexpected
-- =====================================================================
CREATE OR REPLACE PROCEDURE drop_enrollment (
  p_student_id     IN  students.student_id%TYPE,
  p_course_id      IN  courses.course_id%TYPE,
  p_grades_deleted OUT PLS_INTEGER
) AS
  v_enrollment_id enrollments.enrollment_id%TYPE;
BEGIN
  p_grades_deleted := 0;

  SELECT enrollment_id
  INTO   v_enrollment_id
  FROM   enrollments
  WHERE  student_id = p_student_id
  AND    course_id  = p_course_id
  AND    status     = 'ENROLLED';

  DELETE FROM grades WHERE enrollment_id = v_enrollment_id;
  p_grades_deleted := SQL%ROWCOUNT;     -- 0 if the student was never graded
  IF SQL%NOTFOUND THEN
    DBMS_OUTPUT.PUT_LINE('No grade existed for this enrollment, nothing to delete.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Grade rows deleted: ' || p_grades_deleted);
  END IF;

  UPDATE enrollments SET status = 'DROPPED' WHERE enrollment_id = v_enrollment_id;
  IF SQL%NOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20011, 'Enrollment ' || v_enrollment_id || ' could not be updated.');
  END IF;

  DBMS_OUTPUT.PUT_LINE('Student ' || p_student_id || ' dropped from course ' || p_course_id
                       || ' (rows updated: ' || SQL%ROWCOUNT || ').');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20010, 'Student ' || p_student_id
                            || ' has no active enrollment in course ' || p_course_id || '.');
  WHEN TOO_MANY_ROWS THEN
    RAISE_APPLICATION_ERROR(-20012, 'Data integrity problem: several active enrollments for student '
                            || p_student_id || ' in course ' || p_course_id || '.');
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    log_error('drop_enrollment', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in drop_enrollment: ' || SQLERRM);
END drop_enrollment;
/
SHOW ERRORS
