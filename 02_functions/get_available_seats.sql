-- =====================================================================
-- get_available_seats.sql
-- Seats still free in a course = max_capacity - students with status ENROLLED.
-- Call from SQL:
--   SELECT course_code, get_available_seats(course_id) AS seats_left FROM courses;
-- Error codes: -20002 course missing   -20099 unexpected
-- =====================================================================
CREATE OR REPLACE FUNCTION get_available_seats (
  p_course_id IN courses.course_id%TYPE
) RETURN NUMBER
AS
  v_capacity courses.max_capacity%TYPE;
  v_taken    NUMBER;
BEGIN
  SELECT max_capacity INTO v_capacity FROM courses WHERE course_id = p_course_id;

  SELECT COUNT(*) INTO v_taken
  FROM   enrollments
  WHERE  course_id = p_course_id
  AND    status    = 'ENROLLED';

  RETURN v_capacity - v_taken;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'Course ' || p_course_id || ' does not exist.');
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    log_error('get_available_seats', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in get_available_seats: ' || SQLERRM);
END get_available_seats;
/
SHOW ERRORS
