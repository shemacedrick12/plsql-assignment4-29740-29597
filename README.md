# plsql-assignment4-29740-29597

**Group Assignment IV: Advanced Oracle PL/SQL Programming**
Records, Collections, Cursors, Bulk Processing, Stored Procedures, Functions and Exception Handling
Course: Database Development with PL/SQL (INSY 8311) | Class group: **C** (Wednesday)

## Group members

| Full name | Student ID |
|---|---|
| *[SHEMA Mfizi cedrick]* | 29740 |
| *[Iradukunda Emmanuel]* | 29597 |

## Application: Student Registration and Grading System

A small university system that lets the registrar:

- register students in courses (with capacity and status rules),
- drop students from courses,
- upload many grades for a course in one batch,
- print a student transcript with a credit-weighted GPA.

### Requirements

1. A student can register in a course only if the student exists, has status `ACTIVE`, is not already enrolled, and the course still has free seats.
2. A student who dropped a course can register again; the old enrollment row is re-activated instead of duplicated.
3. Dropping a course deletes its grade (if any) and marks the enrollment `DROPPED`.
4. Grades are uploaded in bulk for one course. Each row is validated (student enrolled, score between 0 and 100). A row that the database rejects (for example, a student who already has a grade) must not stop the other rows.
5. Letter grade and grade points follow one scale: 90-100 A (4.0), 80-89 B (3.0), 70-79 C (2.0), 60-69 D (1.0), below 60 F (0.0).
6. GPA = sum(grade points x credits) / sum(credits) over graded, non-dropped courses. A student with no grade has no GPA (NULL, not 0).
7. Unexpected errors are written to `ERROR_LOG` and re-raised with a clear message; expected errors use `RAISE_APPLICATION_ERROR` codes.

### Database schema (`00_schema/01_create_tables.sql`)

| Table | Purpose | Key constraints |
|---|---|---|
| `students` | Student records | PK `student_id`; unique `email`; status check (`ACTIVE`, `SUSPENDED`, `GRADUATED`) |
| `courses` | Course catalogue | PK `course_id`; unique `course_code`; credits 1-6; `max_capacity` > 0 |
| `enrollments` | Student registers in a course | PK identity `enrollment_id`; FK to `students` and `courses`; unique (`student_id`, `course_id`); status check (`ENROLLED`, `DROPPED`, `COMPLETED`) |
| `grades` | One grade per enrollment | PK identity `grade_id`; FK to `enrollments`; unique `enrollment_id`; score 0-100; letter A-F; points 0-4 |
| `error_log` | Unexpected errors | PK identity `log_id` |

Relationships: `students` 1 - N `enrollments` N - 1 `courses`; `enrollments` 1 - 0..1 `grades`.

Sample data (`00_schema/02_insert_sample_data.sql`): 12 students (one `SUSPENDED`), 6 courses (`CSC201` has capacity 3 and is full), 28 enrollments (one `DROPPED`), 9 grades.

## Repository structure

```
plsql-assignment4-29740-29597/
├── README.md
├── .gitignore
├── 00_schema/        01_create_tables.sql, 02_insert_sample_data.sql
├── 01_procedures/    log_error, register_student, drop_enrollment, bulk_upload_grades, print_transcript
├── 02_functions/     get_letter_grade, calculate_gpa, get_available_seats, find_student_id
├── 03_tests/         test_success_cases.sql, test_error_cases.sql
├── screenshots/      output of every test (see table below)
└── docs/             IMPLEMENTATION_NOTES.md
```

## How to run (Oracle 12c or later, tested with Oracle SQL Developer)

Run every file with **Run Script (F5)**.

1. `00_schema/01_create_tables.sql` (it drops and re-creates the tables, so it can be re-run)
2. `00_schema/02_insert_sample_data.sql` (the last query should show 12, 6, 28, 9)
3. Procedures in `01_procedures/`, **`log_error.sql` first** because the others call it, then `register_student`, `drop_enrollment`, `bulk_upload_grades`, `print_transcript`
4. Functions in `02_functions/`: `get_letter_grade`, `calculate_gpa`, `get_available_seats`, `find_student_id`
5. `03_tests/test_success_cases.sql`, then `03_tests/test_error_cases.sql`. Both end with `ROLLBACK`, so the sample data is restored and the tests can be repeated.
6. Compare the output with the `Expected:` line printed above each test.

## What is implemented and where

| Requirement | Where |
|---|---|
| Records, `%ROWTYPE` | `register_student` (`v_student`, `v_course`), `print_transcript` (`v_student`) |
| Records, user-defined | `bulk_upload_grades` (`t_grade_rec`), `print_transcript` (`t_line`), `calculate_gpa` (`t_grade_rec`) |
| Collections | associative arrays in `bulk_upload_grades` (`t_grade_tab`, `t_enr_map`); nested tables in `bulk_upload_grades` (`t_num_tab`) and `calculate_gpa`; VARRAY parameters (`SYS.ODCINUMBERLIST`) in `bulk_upload_grades` |
| Implicit cursors | `register_student` (UPDATE and INSERT), `drop_enrollment` (DELETE and UPDATE), with `SQL%FOUND`, `SQL%NOTFOUND`, `SQL%ROWCOUNT` |
| Explicit cursor | `print_transcript` (cursor with parameter, `OPEN`, `FETCH`, `CLOSE`, `%NOTFOUND`, `%ISOPEN`) |
| `BULK COLLECT` | `bulk_upload_grades`, `calculate_gpa` |
| `FORALL` + bulk errors | `bulk_upload_grades` (`SAVE EXCEPTIONS`, `SQL%BULK_EXCEPTIONS`, `ORA-24381` via `PRAGMA EXCEPTION_INIT`) |
| Predefined exceptions | `NO_DATA_FOUND` (register_student, drop_enrollment, print_transcript, get_available_seats, find_student_id), `TOO_MANY_ROWS` (drop_enrollment, find_student_id), `DUP_VAL_ON_INDEX` (register_student) |
| User-defined exceptions + `RAISE_APPLICATION_ERROR` | `e_student_not_active`, `e_already_enrolled`, `e_course_full` in `register_student`; error codes below |
| Procedures with IN/OUT parameters | all five procedures |
| Functions callable from SQL and PL/SQL | `03_tests/test_success_cases.sql` (S1) and `test_error_cases.sql` (E11) |

### Error codes

| Code | Meaning |
|---|---|
| -20001 | Student does not exist |
| -20002 | Course does not exist |
| -20003 | Student is not `ACTIVE` |
| -20004 | Student already enrolled |
| -20005 | Course is full |
| -20010 | No active enrollment to drop |
| -20011 | Enrollment could not be updated |
| -20012 | Data integrity problem (several active enrollments) |
| -20020 | Bad input lists for bulk upload |
| -20030 | Invalid score |
| -20031 / -20032 / -20033 | Student name search: none / several / empty input |
| -20099 | Unexpected error (also written to `error_log`) |

## Screenshots (`screenshots/`)

| File | Shows |
|---|---|
| `schema_create_tables_output.png` | Tables created |
| `schema_sample_data_output.png` | Sample data counts 12, 6, 28, 9 |
| `compile_log_error_output.png` | Each procedure and function compiled with no errors |
| `functions_check_query_output.png` | Quick check of the four functions |
| `test_success_cases_part1_output.png` | Tests S1 to S3 |
| `test_success_cases_part2_output.png` | Tests S4 to S6 |
| `test_success_cases_part3_output.png` | Test S7 |
| `test_error_cases_part1_output.png` | Tests E1 to E3 |
| `test_error_cases_part2_output.png` | Tests E4 to E7 |
| `test_error_cases_part3_output.png` | Tests E8 to E11 |

## Contributions

*[SHEMA MFIZI CEDRICK DID 02_FUNCTIONS AND 03_TESTS WHILE IRADUKUNDA EMMANUEL DID 00_SCHEMA AND 01_PROCEDURES ]*

## Use of AI

We used an AI assistant (Claude, by Anthropic) during this assignment. It was used to propose the scenario and the schema, to draft the SQL and PL/SQL code and the test scripts, to help debug compile errors, and to draft the README and implementation notes. We ran every script in Oracle SQL Developer ourselves, checked the output against the expected results, and reviewed the code. Both members are responsible for understanding and explaining all submitted code.
