-- =====================================================================
-- find_student_id.sql
-- Finds ONE student id from the beginning of the last name (case-insensitive).
--   find_student_id('Habimana') -> 1004   (exactly one match)
--   find_student_id('Uw')       -> error  (Uwase and Uwimana: too many matches)
--   find_student_id('Zzz')      -> error  (no match)
-- Demonstrates the predefined exceptions NO_DATA_FOUND and TOO_MANY_ROWS.
-- Error codes: -20031 not found  -20032 ambiguous  -20033 empty input  -20099 unexpected
-- =====================================================================
CREATE OR REPLACE FUNCTION find_student_id (
  p_last_name_prefix IN VARCHAR2
) RETURN students.student_id%TYPE
AS
  v_student_id students.student_id%TYPE;
BEGIN
  IF p_last_name_prefix IS NULL OR TRIM(p_last_name_prefix) IS NULL THEN
    RAISE_APPLICATION_ERROR(-20033, 'Please give at least the first letters of the last name.');
  END IF;

  SELECT student_id
  INTO   v_student_id
  FROM   students
  WHERE  UPPER(last_name) LIKE UPPER(TRIM(p_last_name_prefix)) || '%';

  RETURN v_student_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20031, 'No student has a last name starting with "'
                            || p_last_name_prefix || '".');
  WHEN TOO_MANY_ROWS THEN
    RAISE_APPLICATION_ERROR(-20032, 'More than one student has a last name starting with "'
                            || p_last_name_prefix || '". Please be more specific.');
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    log_error('find_student_id', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099, 'Unexpected error in find_student_id: ' || SQLERRM);
END find_student_id;
/
SHOW ERRORS
