# Implementation notes

## 1. Design choices

**Transaction control.** The procedures never `COMMIT` or `ROLLBACK`. The caller decides, so several calls can be combined in one transaction. The test scripts end with `ROLLBACK`, which restores the sample data. The only exception is `log_error`, which uses `PRAGMA AUTONOMOUS_TRANSACTION` so that an error record survives even when the caller rolls back.

**Concurrency.** `register_student` reads the course row with `SELECT ... FOR UPDATE`. Two sessions registering for the last seat are serialized, so the capacity check cannot be passed by both.

**Error handling pattern.** Each procedure and function follows the same structure:

1. Expected problems (missing student, full course, bad input) are detected with a predefined exception (`NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX`) or a user-defined one, and turned into `RAISE_APPLICATION_ERROR(-20xxx, message)` with a message that names the offending value.
2. A final `WHEN OTHERS` handler first re-raises any `-20000` to `-20999` error unchanged. Anything else is an unexpected error: it is written to `error_log` through `log_error` and re-raised as `-20099` with the original Oracle message. Nothing is swallowed.
3. `print_transcript` closes its explicit cursor in the handler if it is still open.

**Functions do not hide problems.** `calculate_gpa` returns `NULL` (not 0) for a student with no graded course, because 0.00 would look like a real GPA. `get_letter_grade` raises an error for a NULL or out-of-range score instead of returning a grade.

**Same grading scale in two places.** `bulk_upload_grades` computes the letter and the points with an inline `CASE`, and `get_letter_grade` has the same scale. We kept the procedure independent of the functions so that procedures compile before functions, as in the required "How to run" order. If the scale changes, both places must be updated.

## 2. Records and collections

| Construct | Used for |
|---|---|
| `students%ROWTYPE`, `courses%ROWTYPE` | Hold a whole table row fetched with `SELECT *` (`register_student`, `print_transcript`) |
| User-defined `RECORD` | One transcript line (`print_transcript`); one grade ready to insert (`bulk_upload_grades`); credits plus points (`calculate_gpa`) |
| Associative array `INDEX BY PLS_INTEGER` | Map student id to enrollment id for fast lookups; dense array of grade records for `FORALL` (`bulk_upload_grades`) |
| Nested table | Targets of `BULK COLLECT` (`bulk_upload_grades`, `calculate_gpa`) |
| `SYS.ODCINUMBERLIST` (VARRAY of NUMBER) | IN parameters for student ids and scores in `bulk_upload_grades`. It is a built-in type, so no extra schema object is needed. |

## 3. Cursors

- **Implicit cursors** are used for single DML statements. `register_student` tries `UPDATE` (re-activate a dropped enrollment) and checks `SQL%NOTFOUND`; if nothing was updated it runs `INSERT` and reads `SQL%ROWCOUNT`. `drop_enrollment` runs `DELETE` on the grade and `UPDATE` on the enrollment, using `SQL%ROWCOUNT` and `SQL%NOTFOUND`.
- **Explicit cursor**: `print_transcript` declares a cursor with a parameter, then `OPEN`, `FETCH` in a loop with `EXIT WHEN %NOTFOUND`, and `CLOSE`. It is used here because each row is formatted and added to a running total, and the number of rows is not known in advance.

## 4. Bulk processing and performance

`bulk_upload_grades` uploads many grades in these steps:

1. **One `BULK COLLECT` query** loads all active enrollments of the course into collections, and an associative array maps student id to enrollment id. The alternative is one `SELECT` per uploaded row.
2. The input rows are validated in memory and the valid ones are stored in a collection of records.
3. **One `FORALL ... INSERT`** sends the whole collection to the SQL engine in a single call.
4. `SAVE EXCEPTIONS` lets the database keep going when a row fails. Oracle raises `ORA-24381` at the end, and the handler reads `SQL%BULK_EXCEPTIONS` (`ERROR_INDEX`, `ERROR_CODE`) to report which student was rejected and why. The successful rows stay in the transaction.

**Why this is faster than row-by-row.** A PL/SQL loop that executes an `INSERT` for each row switches between the PL/SQL engine and the SQL engine once per row (a context switch). For N rows that is N switches. `BULK COLLECT` and `FORALL` reduce this to one switch per statement, so the cost is much less for large N. Fewer round trips between the engines also means less parsing and call overhead. We did not run a timing benchmark on this small sample data set (28 enrollments), so we do not quote numbers. The benefit shows with thousands of rows.

**Limits and trade-offs.**
- A collection holds all rows in memory (PGA). For very large loads, `BULK COLLECT ... LIMIT n` in a loop would be used so memory stays bounded. Our upload batches are small, so we did not need it.
- `SAVE EXCEPTIONS` means a partial result: some rows are inserted and some rejected. The OUT parameters `p_inserted` and `p_rejected` and the printed messages make that visible to the caller, who decides whether to commit or roll back.
- Rows rejected before the `FORALL` (student not enrolled, invalid score) are counted in `p_rejected` and reported with `DBMS_OUTPUT`.

## 5. Testing

`03_tests/test_success_cases.sql` has 7 tests (S1 to S7) and `03_tests/test_error_cases.sql` has 11 tests (E1 to E11). Each test prints its expected result above the actual result. The error tests catch each exception in an anonymous block and print `Caught -> ...`; a line starting with `UNEXPECTED` would mean an error was not raised. We ran both scripts in Oracle SQL Developer and kept the output as screenshots in `screenshots/`.

## 6. Assumptions and limitations

- Capacity counts only enrollments with status `ENROLLED`.
- A dropped enrollment is kept (status `DROPPED`) and re-activated on re-registration, because of the unique (`student_id`, `course_id`) constraint.
- `bulk_upload_grades` inserts new grades only; it does not update an existing grade (the unique constraint makes a second grade fail as a bulk error). A grade correction would need a separate update procedure.
- `SYS.ODCINUMBERLIST` holds at most 32,767 elements, which is more than a class needs.
- Tested manually; there is no automated test framework.
