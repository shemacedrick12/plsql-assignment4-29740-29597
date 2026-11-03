-- =====================================================================
-- bulk_upload_grades.sql
-- Uploads many scores for ONE course in a single batch.
--   IN : p_course_id
--        p_student_ids  (VARRAY of student ids)   } same length, same order:
--        p_scores       (VARRAY of scores 0-100)  } p_scores(i) belongs to p_student_ids(i)
--   OUT: p_inserted  number of grades saved
--        p_rejected  number of rows refused (bad input or database error)
-- Demonstrates: VARRAY parameters (SYS.ODCINUMBERLIST), associative arrays,
--   a collection of user-defined RECORDs, BULK COLLECT, FORALL with
--   SAVE EXCEPTIONS and SQL%BULK_EXCEPTIONS, predefined + user-defined errors.
-- Does not commit. Good rows stay in the transaction even if some rows fail.
-- Error codes: -20002 course missing   -20020 bad input lists   -20099 unexpected
-- =====================================================================
CREATE OR REPLACE PROCEDURE bulk_upload_grades (
  p_course_id   IN  courses.course_id%TYPE,
  p_student_ids IN  SYS.ODCINUMBERLIST,
  p_scores      IN  SYS.ODCINUMBERLIST,
  p_inserted    OUT PLS_INTEGER,
  p_rejected    OUT PLS_INTEGER
) AS
  -- user-defined record: one grade ready to insert
  TYPE t_grade_rec IS RECORD (
    student_id    NUMBER,
    enrollment_id enrollments.enrollment_id%TYPE,
    score         grades.score%TYPE,
    letter_grade  grades.letter_grade%TYPE,
    grade_points  grades.grade_points%TYPE
  );
  -- collection of records (associative array, dense 1..n)
  TYPE t_grade_tab IS TABLE OF t_grade_rec INDEX BY PLS_INTEGER;
  -- associative array: student_id -> enrollment_id
  TYPE t_enr_map  IS TABLE OF enrollments.enrollment_id%TYPE INDEX BY PLS_INTEGER;
  -- nested tables filled by BULK COLLECT
  TYPE t_num_tab  IS TABLE OF NUMBER;

  v_rows       t_grade_tab;
  v_enr_map    t_enr_map;
  v_stu_ids    t_num_tab;
  v_enr_ids    t_num_tab;
  v_n          PLS_INTEGER := 0;
  v_count      NUMBER;
  v_student_id NUMBER;
  v_score      NUMBER;

  e_bulk_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);   -- raised by FORALL ... SAVE EXCEPTIONS
BEGIN
  p_inserted := 0;
  p_rejected := 0;

  -- 1) Validate the inputs
  IF p_student_ids IS NULL OR p_scores IS NULL
     OR p_student_ids.COUNT = 0
     OR p_student_ids.COUNT <> p_scores.COUNT THEN
    RAISE_APPLICATION_ERROR(-20020, 'Student id list and score list must be non-empty and the same length.');
  END IF;

  SELECT COUNT(*) INTO v_count FROM courses WHERE course_id = p_course_id;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Course ' || p_course_id || ' does not exist.');
  END IF;

  -- 2) ONE query loads every active enrollment of the course (BULK COLLECT)
  SELECT student_id, enrollment_id
  BULK COLLECT INTO v_stu_ids, v_enr_ids
  FROM   enrollments
  WHERE  course_id = p_course_id
  AND    status    = 'ENROLLED';

  FOR i IN 1 .. v_stu_ids.COUNT LOOP
    v_enr_map(v_stu_ids(i)) := v_enr_ids(i);
  END LOOP;

  -- 3) Build the batch in memory, skipping rows that are clearly wrong
  FOR i IN 1 .. p_student_ids.COUNT LOOP
    v_student_id := p_student_ids(i);
    v_score      := p_scores(i);

    IF v_student_id IS NULL OR NOT v_enr_map.EXISTS(v_student_id) THEN
      DBMS_OUTPUT.PUT_LINE('Skipped student ' || NVL(TO_CHAR(v_student_id), 'NULL')
                           || ': not actively enrolled in course ' || p_course_id);
      p_rejected := p_rejected + 1;
    ELSIF v_score IS NULL OR v_score < 0 OR v_score > 100 THEN
      DBMS_OUTPUT.PUT_LINE('Skipped student ' || v_student_id || ': invalid score '
                           || NVL(TO_CHAR(v_score), 'NULL'));
      p_rejected := p_rejected + 1;
    ELSE
      v_n := v_n + 1;
      v_rows(v_n).student_id    := v_student_id;
      v_rows(v_n).enrollment_id := v_enr_map(v_student_id);
      v_rows(v_n).score         := v_score;
      v_rows(v_n).letter_grade  := CASE WHEN v_score >= 90 THEN 'A'
                                        WHEN v_score >= 80 THEN 'B'
                                        WHEN v_score >= 70 THEN 'C'
                                        WHEN v_score >= 60 THEN 'D'
                                        ELSE 'F' END;
      v_rows(v_n).grade_points  := CASE WHEN v_score >= 90 THEN 4
                                        WHEN v_score >= 80 THEN 3
                                        WHEN v_score >= 70 THEN 2
                                        WHEN v_score >= 60 THEN 1
                                        ELSE 0 END;
    END IF;
  END LOOP;

  -- 4) ONE round trip to the SQL engine inserts the whole batch (FORALL).
  --    SAVE EXCEPTIONS: a failing row (e.g. already graded) does not stop the rest.
  IF v_n > 0 THEN
    BEGIN
      FORALL i IN 1 .. v_n SAVE EXCEPTIONS
        INSERT INTO grades (enrollment_id, score, letter_grade, grade_points)
        VALUES (v_rows(i).enrollment_id, v_rows(i).score,
                v_rows(i).letter_grade,  v_rows(i).grade_points);
      p_inserted := SQL%ROWCOUNT;
    EXCEPTION
      WHEN e_bulk_errors THEN
        p_inserted := SQL%ROWCOUNT;      -- rows that DID succeed
        FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
          DBMS_OUTPUT.PUT_LINE('Rejected student '
              || v_rows(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX).student_id
              || ': ' || SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
          p_rejected := p_rejected + 1;
        END LOOP;
    END;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Bulk upload finished for course ' || p_course_id
                       || ': inserted = ' || p_inserted || ', rejected = ' || p_rejected);
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    log_error('bulk_upload_grades', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in bulk_upload_grades: ' || SQLERRM);
END bulk_upload_grades;
/
SHOW ERRORS
