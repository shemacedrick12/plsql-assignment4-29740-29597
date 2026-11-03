-- =====================================================================
-- get_letter_grade.sql
-- Converts a numeric score (0-100) to a letter grade.
-- Scale: 90+ A | 80-89 B | 70-79 C | 60-69 D | below 60 F
-- Call from SQL:   SELECT get_letter_grade(85) FROM dual;
-- Invalid input (NULL or outside 0-100) raises ORA-20030 instead of
-- returning a misleading grade.
-- =====================================================================
CREATE OR REPLACE FUNCTION get_letter_grade (
  p_score IN NUMBER
) RETURN VARCHAR2
DETERMINISTIC
AS
BEGIN
  IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
    RAISE_APPLICATION_ERROR(-20030, 'Invalid score: ' || NVL(TO_CHAR(p_score), 'NULL')
                            || '. A score must be between 0 and 100.');
  END IF;

  RETURN CASE WHEN p_score >= 90 THEN 'A'
              WHEN p_score >= 80 THEN 'B'
              WHEN p_score >= 70 THEN 'C'
              WHEN p_score >= 60 THEN 'D'
              ELSE 'F'
         END;
END get_letter_grade;
/
SHOW ERRORS
