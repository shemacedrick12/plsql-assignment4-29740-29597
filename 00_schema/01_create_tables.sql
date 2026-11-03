-- =====================================================================
-- 01_create_tables.sql
-- Student Registration and Grading System
-- Course: INSY 8311 - Group Assignment IV (Group C)
-- Run as the schema owner in Oracle SQL Developer (Run Script: F5)
-- Requires Oracle 12c or later (identity columns).
-- =====================================================================

SET SERVEROUTPUT ON;

-- ---------------------------------------------------------------------
-- Re-runnable cleanup: drop objects if they already exist
-- (ORA-00942 = table does not exist, ORA-02289 = sequence does not exist)
-- ---------------------------------------------------------------------
BEGIN
  FOR t IN (SELECT column_value AS tname
            FROM TABLE(sys.odcivarchar2list('ERROR_LOG','GRADES','ENROLLMENTS','COURSES','STUDENTS')))
  LOOP
    BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE ' || t.tname || ' CASCADE CONSTRAINTS PURGE';
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;   -- ignore only "table does not exist"
    END;
  END LOOP;
END;
/

-- ---------------------------------------------------------------------
-- STUDENTS
-- ---------------------------------------------------------------------
CREATE TABLE students (
  student_id     NUMBER(6)      CONSTRAINT pk_students PRIMARY KEY,
  first_name     VARCHAR2(50)   NOT NULL,
  last_name      VARCHAR2(50)   NOT NULL,
  email          VARCHAR2(100)  NOT NULL,
  date_of_birth  DATE,
  status         VARCHAR2(10)   DEFAULT 'ACTIVE' NOT NULL,
  created_at     TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
  CONSTRAINT uq_students_email  UNIQUE (email),
  CONSTRAINT ck_students_status CHECK (status IN ('ACTIVE','SUSPENDED','GRADUATED'))
);

-- ---------------------------------------------------------------------
-- COURSES
-- ---------------------------------------------------------------------
CREATE TABLE courses (
  course_id      NUMBER(4)      CONSTRAINT pk_courses PRIMARY KEY,
  course_code    VARCHAR2(10)   NOT NULL,
  course_name    VARCHAR2(100)  NOT NULL,
  credits        NUMBER(1)      NOT NULL,
  max_capacity   NUMBER(3)      NOT NULL,
  CONSTRAINT uq_courses_code   UNIQUE (course_code),
  CONSTRAINT ck_courses_credit CHECK (credits BETWEEN 1 AND 6),
  CONSTRAINT ck_courses_cap    CHECK (max_capacity > 0)
);

-- ---------------------------------------------------------------------
-- ENROLLMENTS  (a student registers for a course; one row per pair)
-- ---------------------------------------------------------------------
CREATE TABLE enrollments (
  enrollment_id  NUMBER GENERATED ALWAYS AS IDENTITY
                 CONSTRAINT pk_enrollments PRIMARY KEY,
  student_id     NUMBER(6)  NOT NULL,
  course_id      NUMBER(4)  NOT NULL,
  enroll_date    DATE       DEFAULT SYSDATE NOT NULL,
  status         VARCHAR2(10) DEFAULT 'ENROLLED' NOT NULL,
  CONSTRAINT fk_enr_student FOREIGN KEY (student_id) REFERENCES students (student_id),
  CONSTRAINT fk_enr_course  FOREIGN KEY (course_id)  REFERENCES courses (course_id),
  CONSTRAINT uq_enr_student_course UNIQUE (student_id, course_id),
  CONSTRAINT ck_enr_status CHECK (status IN ('ENROLLED','DROPPED','COMPLETED'))
);

CREATE INDEX idx_enr_course ON enrollments (course_id);

-- ---------------------------------------------------------------------
-- GRADES  (at most one grade per enrollment)
-- ---------------------------------------------------------------------
CREATE TABLE grades (
  grade_id       NUMBER GENERATED ALWAYS AS IDENTITY
                 CONSTRAINT pk_grades PRIMARY KEY,
  enrollment_id  NUMBER        NOT NULL,
  score          NUMBER(5,2)   NOT NULL,
  letter_grade   VARCHAR2(2)   NOT NULL,
  grade_points   NUMBER(2,1)   NOT NULL,
  graded_on      DATE          DEFAULT SYSDATE NOT NULL,
  CONSTRAINT fk_grades_enr   FOREIGN KEY (enrollment_id) REFERENCES enrollments (enrollment_id),
  CONSTRAINT uq_grades_enr   UNIQUE (enrollment_id),
  CONSTRAINT ck_grades_score CHECK (score BETWEEN 0 AND 100),
  CONSTRAINT ck_grades_letter CHECK (letter_grade IN ('A','B','C','D','F')),
  CONSTRAINT ck_grades_points CHECK (grade_points BETWEEN 0 AND 4)
);

-- ---------------------------------------------------------------------
-- ERROR_LOG  (procedures write unexpected errors here, then re-raise)
-- ---------------------------------------------------------------------
CREATE TABLE error_log (
  log_id        NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_error_log PRIMARY KEY,
  logged_at     TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
  module_name   VARCHAR2(60)   NOT NULL,
  error_code    NUMBER,
  error_message VARCHAR2(4000)
);

PROMPT Tables created successfully.
