-- =====================================================================
-- log_error.sql   (COMPILE THIS ONE FIRST - other procedures call it)
-- Writes an unexpected error into ERROR_LOG.
-- AUTONOMOUS_TRANSACTION: the log row is committed on its own, so it
-- survives even when the caller rolls back its main transaction.
-- =====================================================================
CREATE OR REPLACE PROCEDURE log_error (
  p_module  IN VARCHAR2,
  p_code    IN NUMBER,
  p_message IN VARCHAR2
) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO error_log (module_name, error_code, error_message)
  VALUES (SUBSTR(p_module, 1, 60), p_code, SUBSTR(p_message, 1, 4000));
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    -- A failure while logging must not hide the ORIGINAL error that the
    -- caller is about to re-raise, so we only undo our own insert.
    ROLLBACK;
END log_error;
/
SHOW ERRORS
