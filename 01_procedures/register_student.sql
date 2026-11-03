-- =====================================================================
-- register_student.sql
-- Registers a student in a course.
--   IN : p_student_id, p_course_id
--   OUT: p_enrollment_id  (id of the new or re-activated enrollment)
-- Demonstrates: %ROWTYPE records, implicit cursor attributes
--   (SQL%FOUND / SQL%NOTFOUND / SQL%ROWCOUNT) on UPDATE and INSERT,
--   predefined exceptions (NO_DATA_FOUND, DUP_VAL_ON_INDEX),
--   user-defined exceptions and RAISE_APPLICATION_ERROR.
-- The procedure does NOT commit; the caller decides COMMIT / ROLLBACK.
-- Error codes: -20001 student missing   -20002 course missing
--              -20003 student not ACTIVE -20004 already enrolled
--              -20005 course full        -20099 unexpected
-- =====================================================================
CREATE OR REPLACE PROCEDURE register_student (
  p_student_id    IN  students.student_id%TYPE,
  p_course_id     IN  courses.course_id%TYPE,
  p_enrollment_id OUT enrollments.enrollment_id%TYPE
) AS
  v_student  students%ROWTYPE;          -- record shaped like a students row
  v_course   courses%ROWTYPE;           -- record shaped like a courses row
  v_count    NUMBER;
  v_rows     PLS_INTEGER;

  e_student_not_active EXCEPTION;       -- user-defined exceptions
  e_already_enrolled   EXCEPTION;
  e_course_full        EXCEPTION;
BEGIN
  p_enrollment_id := NULL;

  -- 1) Student must exist (predefined exception NO_DATA_FOUND)
  BEGIN
    SELECT * INTO v_student FROM students WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Student ' || p_student_id || ' does not exist.');
  END;

  -- 2) Course must exist. FOR UPDATE locks the course row so two people
  --    cannot take the last seat at the same time.
  BEGIN
    SELECT * INTO v_course FROM courses WHERE course_id = p_course_id FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'Course ' || p_course_id || ' does not exist.');
  END;

  -- 3) Business rules
  IF v_student.status <> 'ACTIVE' THEN
    RAISE e_student_not_active;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM   enrollments
  WHERE  student_id = p_student_id
  AND    course_id  = p_course_id
  AND    status IN ('ENROLLED', 'COMPLETED');
  IF v_count > 0 THEN
    RAISE e_already_enrolled;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM   enrollments
  WHERE  course_id = p_course_id
  AND    status = 'ENROLLED';
  IF v_count >= v_course.max_capacity THEN
    RAISE e_course_full;
  END IF;

  -- 4) If the student earlier DROPPED this course, re-activate that row
  --    (implicit cursor UPDATE). Otherwise insert a new row.
  UPDATE enrollments
     SET status = 'ENROLLED', enroll_date = SYSDATE
   WHERE student_id = p_student_id
     AND course_id  = p_course_id
     AND status     = 'DROPPED'
  RETURNING enrollment_id INTO p_enrollment_id;

  IF SQL%NOTFOUND THEN                  -- nothing to re-activate
    INSERT INTO enrollments (student_id, course_id)
    VALUES (p_student_id, p_course_id)
    RETURNING enrollment_id INTO p_enrollment_id;
    v_rows := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('New enrollment created (rows inserted: ' || v_rows || ').');
  ELSE
    v_rows := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Dropped enrollment re-activated (rows updated: ' || v_rows || ').');
  END IF;

  DBMS_OUTPUT.PUT_LINE('Student ' || p_student_id || ' (' || v_student.first_name || ' '
                       || v_student.last_name || ') registered in ' || v_course.course_code
                       || '. Enrollment id = ' || p_enrollment_id);
EXCEPTION
  WHEN e_student_not_active THEN
    RAISE_APPLICATION_ERROR(-20003, 'Student ' || p_student_id
                            || ' cannot register: status is ' || v_student.status || '.');
  WHEN e_already_enrolled THEN
    RAISE_APPLICATION_ERROR(-20004, 'Student ' || p_student_id
                            || ' is already enrolled in course ' || p_course_id || '.');
  WHEN e_course_full THEN
    RAISE_APPLICATION_ERROR(-20005, 'Course ' || v_course.course_code
                            || ' is full (capacity ' || v_course.max_capacity || ').');
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20004, 'Duplicate enrollment for student ' || p_student_id
                            || ' and course ' || p_course_id || '.');
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;                             -- our own messages from above: pass through unchanged
    END IF;
    log_error('register_student', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in register_student: ' || SQLERRM);
END register_student;
/
SHOW ERRORS
