-- =====================================================================
-- 02_insert_sample_data.sql
-- Run AFTER 01_create_tables.sql
-- Grading scale used everywhere: 90-100 A (4.0) | 80-89 B (3.0)
--                                70-79 C (2.0)  | 60-69 D (1.0) | <60 F (0.0)
-- =====================================================================

-- STUDENTS ------------------------------------------------------------
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1001,'Aline','Uwase','aline.uwase@auca.ac.rw',DATE '2003-02-14');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1002,'Eric','Mugisha','eric.mugisha@auca.ac.rw',DATE '2002-07-30');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1003,'Grace','Ingabire','grace.ingabire@auca.ac.rw',DATE '2003-11-05');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1004,'Jean','Habimana','jean.habimana@auca.ac.rw',DATE '2002-04-21');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1005,'Diane','Mukamana','diane.mukamana@auca.ac.rw',DATE '2003-09-09');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1006,'Patrick','Niyonzima','patrick.niyonzima@auca.ac.rw',DATE '2002-12-12');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1007,'Sandrine','Uwimana','sandrine.uwimana@auca.ac.rw',DATE '2003-05-18');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1008,'David','Nshimiyimana','david.nshimiyimana@auca.ac.rw',DATE '2002-01-25');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1009,'Claudine','Mutesi','claudine.mutesi@auca.ac.rw',DATE '2003-03-03');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1010,'Olivier','Bizimana','olivier.bizimana@auca.ac.rw',DATE '2002-08-16');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth) VALUES (1011,'Beata','Kamanzi','beata.kamanzi@auca.ac.rw',DATE '2003-06-27');
INSERT INTO students (student_id, first_name, last_name, email, date_of_birth, status) VALUES (1012,'Samuel','Rurangwa','samuel.rurangwa@auca.ac.rw',DATE '2001-10-10','SUSPENDED');

-- COURSES (CSC201 has capacity 3 on purpose, so we can test "course full") ---
INSERT INTO courses (course_id, course_code, course_name, credits, max_capacity) VALUES (101,'INSY8311','Database Development with PL/SQL',3,30);
INSERT INTO courses (course_id, course_code, course_name, credits, max_capacity) VALUES (102,'INSY8312','Web Application Development',3,30);
INSERT INTO courses (course_id, course_code, course_name, credits, max_capacity) VALUES (103,'INSY8313','Computer Networks',4,25);
INSERT INTO courses (course_id, course_code, course_name, credits, max_capacity) VALUES (104,'MATH101','Discrete Mathematics',3,40);
INSERT INTO courses (course_id, course_code, course_name, credits, max_capacity) VALUES (105,'CSC201','Data Structures',3,3);
INSERT INTO courses (course_id, course_code, course_name, credits, max_capacity) VALUES (106,'ENG101','Technical Writing',2,30);

-- ENROLLMENTS (enrollment_id is an identity column, generated automatically) --
-- INSY8311
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1001,101,DATE '2026-09-01');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1002,101,DATE '2026-09-01');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1003,101,DATE '2026-09-02');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1004,101,DATE '2026-09-02');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1005,101,DATE '2026-09-03');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1006,101,DATE '2026-09-03');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1007,101,DATE '2026-09-03');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1008,101,DATE '2026-09-04');
-- INSY8312
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1001,102,DATE '2026-09-01');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1002,102,DATE '2026-09-01');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1009,102,DATE '2026-09-04');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1010,102,DATE '2026-09-04');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1011,102,DATE '2026-09-05');
-- INSY8313
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1003,103,DATE '2026-09-02');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1004,103,DATE '2026-09-02');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1005,103,DATE '2026-09-03');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1012,103,DATE '2026-09-05');
-- MATH101
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1006,104,DATE '2026-09-03');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1007,104,DATE '2026-09-03');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1008,104,DATE '2026-09-04');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1009,104,DATE '2026-09-04');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1010,104,DATE '2026-09-04');
-- CSC201 (capacity 3 -> now FULL)
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1001,105,DATE '2026-09-01');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1002,105,DATE '2026-09-01');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1003,105,DATE '2026-09-02');
-- ENG101
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1004,106,DATE '2026-09-02');
INSERT INTO enrollments (student_id, course_id, enroll_date) VALUES (1011,106,DATE '2026-09-05');
INSERT INTO enrollments (student_id, course_id, enroll_date, status) VALUES (1012,106,DATE '2026-09-05','DROPPED');

-- GRADES (only some enrollments are graded; the rest are used by the bulk upload tests) --
INSERT INTO grades (enrollment_id, score, letter_grade, grade_points, graded_on)
  SELECT enrollment_id, 92,'A',4.0,DATE '2026-10-20' FROM enrollments WHERE student_id=1001 AND course_id=101;
INSERT INTO grades (enrollment_id, score, letter_grade, grade_points, graded_on)
  SELECT enrollment_id, 85,'B',3.0,DATE '2026-10-20' FROM enrollments WHERE student_id=1002 AND course_id=101;
INSERT INTO grades (enrollment_id, score, letter_grade, grade_points, graded_on)
  SELECT enrollment_id, 74,'C',2.0,DATE '2026-10-20' FROM enrollments WHERE student_id=1003 AND course_id=101;
INSERT INTO grades (enrollment_id, score, letter_grade, grade_points, graded_on)
  SELECT enrollment_id, 66,'D',1.0,DATE '2026-10-20' FROM enrollments WHERE student_id=1004 AND course_id=101;
INSERT INTO grades (enrollment_id, score, letter_grade, grade_points, graded_on)
  SELECT enrollment_id, 58,'F',0.0,DATE '2026-10-20' FROM enrollments WHERE student_id=1005 AND course_id=101;
INSERT INTO grades (enrollment_id, score, letter_grade, grade_points, graded_on)
  SELECT enrollment_id, 88,'B',3.0,DATE '2026-10-21' FROM enrollments WHERE student_id=1001 AND course_id=102;
INSERT INTO grades (enrollment_id, score, letter_grade, grade_points, graded_on)
  SELECT enrollment_id, 91,'A',4.0,DATE '2026-10-21' FROM enrollments WHERE student_id=1002 AND course_id=102;
INSERT INTO grades (enrollment_id, score, letter_grade, grade_points, graded_on)
  SELECT enrollment_id, 81,'B',3.0,DATE '2026-10-22' FROM enrollments WHERE student_id=1006 AND course_id=104;
INSERT INTO grades (enrollment_id, score, letter_grade, grade_points, graded_on)
  SELECT enrollment_id, 95,'A',4.0,DATE '2026-10-22' FROM enrollments WHERE student_id=1007 AND course_id=104;

COMMIT;

-- Quick sanity check (expected: 12 students, 6 courses, 28 enrollments, 9 grades)
SELECT (SELECT COUNT(*) FROM students)    AS students,
       (SELECT COUNT(*) FROM courses)     AS courses,
       (SELECT COUNT(*) FROM enrollments) AS enrollments,
       (SELECT COUNT(*) FROM grades)      AS grades
FROM dual;
