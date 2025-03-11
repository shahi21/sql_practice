-- CREATING TABLES
create table Students(
student_id serial primary key,
name varchar(50) not null,
email varchar(50) not null,
date_of_birth date not null,
created_at timestamp default current_timestamp
);
select * from students;

create table teachers(
teacher_id serial primary key,
name varchar(50) not null,
email varchar(50) not null,
subject varchar(50) not null,
created_at timestamp default current_timestamp
);
select * from teachers;

create table courses(
course_id serial primary key,
name varchar(50) not null,
teacher_id int references teachers(teacher_id) on delete set null,
created_at timestamp default current_timestamp
);
select * from courses;

create table enrollments(
enrollment_id serial primary key,
student_id int references students(student_id) on delete set null,
course_id int references courses(course_id) on delete set null,
enrollment_date timestamp default current_timestamp
);
select * from enrollments;


create table Grades(
grade_id serial primary key,
student_id int references students(student_id) on delete set null,
course_id int references courses(course_id) on delete set null,
grade char(2) check (grade in ('A','B','C','D','F')),
created_at timestamp default current_timestamp
);

select * from grades;


-- table to add triggers
create table audit_grades(
audit_id serial primary key,
student_id int,
course_id int,
old_grade char(2),
new_grade char(2),
changed_at timestamp default current_timestamp
);

select * from audit_grades;

-- INSERTING DATA INTO TABLES

insert into students(name,email,date_of_birth) values
('Alice Johnson','alicej@gmail.com','2005-04-12'),
('Bob Smith', 'bob@gmail.com', '2004-06-23'),
('Charlie Brown', 'charlie@gmail.com', '2005-09-10'),
('David White', 'david@gmail.com', '2006-02-15'),
('Emma Wilson', 'emma@gmail.com', '2005-12-01');
select * from students;

insert into teachers(name,email,subject) values
('Dr. Emily Carter', 'emily@gmail.com', 'Mathematics'),
('Mr. John Doe', 'john@gmail.com', 'Physics'),
('Ms. Sarah Lee', 'sarah@gmail.com', 'History'),
('Mrs. Laura Green', 'laura@gmail.com', 'Chemistry'),
('Mr. Tom Adams', 'tom@gmail.com', 'Biology');
select * from teachers;

insert into courses(name,teacher_id) values
('Algebra 101', 1),
('Physics Basics', 2),
('World History', 3),
('Organic Chemistry', 4),
('Cell Biology', 5),
('Trigonometry', 1),
('Modern Physics', 2);
select * from courses;

insert into enrollments(student_id,course_id) values
(1, 1), 
(1, 2), 
(2, 3),
(2, 5),
(3, 1),
(3, 4),
(4, 6), 
(4, 7),
(5, 2),
(5, 3);
select * from enrollments;


insert into grades(student_id,course_id,grade) values
(1, 1,'A'), 
(1, 2,'B'), 
(2, 3,'C'),
(2, 5,'B'),
(3, 1,'A'),
(3, 4,'C'),
(4, 6,'B'), 
(4, 7,'C'),
(5, 2,'A'),
(5, 3,'A');
select * from grades;


-- QUERIES

--list all courses with their teachers

select c.name as course_name,t.name as teacher_name
from courses c
join teachers t on c.teacher_id=t.teacher_id;

--find all courses a specific student is enrolled in
select s.name as student_name, c.name as course_name
from enrollments e
join students s on e.student_id=s.student_id
join courses c on e.course_id=c.course_id
where s.name='Alice Johnson';

--count the number of students in each course
select c.name as course_name, count(e.student_id) as student_count
from courses c
join enrollments e on c.course_id=e.course_id
group by c.name;

--find the top performing student in each course
select c.name as course_name,s.name as student_name, g.grade
from grades g
join students s on g.student_id=s.student_id
join courses c on g.course_id=c.course_id
where g.grade='A';


-- IMPLEMENTING A TRIGGER TO TRACK GRADE UPDATES

select * from audit_grades;

create or replace function log_grade_changes()
returns trigger as $$
begin
	insert into audit_grades(student_id,course_id,old_grade,new_grade,changed_at) values
	(old.student_id,old.course_id,old.grade,new.grade,current_timestamp);
	return new;
end;
$$ language plpgsql;

create trigger track_grade_changes
before update on grades
for each row
when(old.grade is distinct from new.grade)
execute function log_grade_changes();

-- updating grade to test the trigger
update grades set grade='A' where student_id=2 and course_id=3;

select * from audit_grades;






-- QUERIES

--find average grade for each course
SELECT 
    c.name, 
   round( AVG(CASE 
                WHEN g.grade = 'A' THEN 4.0
                WHEN g.grade = 'B' THEN 3.0
                WHEN g.grade = 'C' THEN 2.0
                WHEN g.grade = 'D' THEN 1.0
                ELSE 0.0
              END),2)AS average_gpa
FROM courses c
JOIN grades g ON c.course_id = g.course_id
GROUP BY c.name
ORDER BY average_gpa DESC;

--most popular course based on enrollment

select c.name, count(student_id) as student_count
from enrollments e
join courses c on e.course_id=c.course_id
group by c.name
order by student_count desc
limit 1;

--list students who have taken more than 3 courses
select s.name, count(e.course_id) as course_count
from students s
join enrollments e on s.student_id=e.student_id
group by s.name
having count(e.course_id) > 3
order by course_count desc;

--Find Students Who Got an "A" in at Least One Course
select s.name ,g.grade
from students s
join grades g on s.student_id=g.student_id
where g.grade='A';


--
