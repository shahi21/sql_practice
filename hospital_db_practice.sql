--Assignment Description
--In this assignment, you will create a Hospital Management System using PostgreSQL. 
    --The system will manage patients, doctors, appointments, and prescriptions.
    --You will also implement triggers to log appointment changes in a separate table.

-- CREATING TABLES

-- Patients Table
CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    age INT CHECK (age > 0),
    gender VARCHAR(10) CHECK (gender IN ('Male', 'Female')),
    contact VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL
);

-- Doctors Table
CREATE TABLE doctors (
    doctor_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    specialization VARCHAR(50) NOT NULL UNIQUE,
    contact VARCHAR(15) UNIQUE NOT NULL
);

-- Appointments Table
CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id) ON DELETE CASCADE,
    doctor_id INT REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    appointment_date TIMESTAMP NOT NULL,
    status VARCHAR(20) CHECK (status IN ('Scheduled', 'Completed', 'Cancelled'))
);

-- Prescriptions Table
CREATE TABLE prescriptions (
    prescription_id SERIAL PRIMARY KEY,
    appointment_id INT REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    medicine VARCHAR(50) NOT NULL,
    dosage VARCHAR(25) NOT NULL,
    instructions TEXT
);

-- Appointment Log Table (For Trigger)
CREATE TABLE appointment_log (
    log_id SERIAL PRIMARY KEY,
    operation VARCHAR(10) NOT NULL,
    appointment_id INT,
    old_data JSONB,
    new_data JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);


--INSERTING DATA INTO TABLES

-- Insert Patients
INSERT INTO patients (name, age, gender, contact, email) VALUES
('Alice Johnson', 28, 'Female', '9876543210', 'alice@gmail.com'),
('Bob Smith', 35, 'Male', '9876543211', 'bob@gmail.com'),
('Charlie Brown', 22, 'Male', '9876543212', 'charlie@gmail.com'),
('Diana Prince', 30, 'Female', '9876543213', 'diana@gmail.com');

SELECT * FROM PATIENTS;

-- Insert Doctors
INSERT INTO doctors (name, specialization, contact) VALUES
('Dr. Emily White', 'Cardiologist', '9123456789'),
('Dr. Robert Green', 'Dermatologist', '9123456790'),
('Dr. Sophia Black', 'Neurologist', '9123456791');

SELECT * FROM DOCTORS;

-- Insert Appointments
INSERT INTO appointments (patient_id, doctor_id, appointment_date, status) VALUES
(1, 1, '2025-03-15 10:30:00', 'Scheduled'),
(2, 2, '2025-03-16 11:00:00', 'Scheduled'),
(3, 1, '2025-03-17 09:00:00', 'Completed'),
(4, 3, '2025-03-18 14:30:00', 'Cancelled');

SELECT * FROM APPOINTMENTS;

-- Insert Prescriptions
INSERT INTO prescriptions (appointment_id, medicine, dosage, instructions) VALUES
(1, 'Paracetamol', '500mg', 'Take twice daily after meals'),
(2, 'Cough Syrup', '10ml', 'Take once daily before bedtime');

SELECT * FROM PRESCRIPTIONS;


-- Function for Trigger
CREATE OR REPLACE FUNCTION log_appointment_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO appointment_log (operation, appointment_id, new_data, timestamp)
        VALUES ('INSERT', NEW.appointment_id, row_to_json(NEW)::jsonb, NOW());

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO appointment_log (operation, appointment_id, old_data, new_data, timestamp)
        VALUES ('UPDATE', OLD.appointment_id, row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb, NOW());

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO appointment_log (operation, appointment_id, old_data, timestamp)
        VALUES ('DELETE', OLD.appointment_id, row_to_json(OLD)::jsonb, NOW());
        
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creating Trigger
CREATE TRIGGER appointment_changes_trigger
AFTER INSERT OR UPDATE OR DELETE
ON appointments
FOR EACH ROW
EXECUTE FUNCTION log_appointment_changes();


-- Testing the trigger
-- inserting
INSERT INTO appointments (patient_id, doctor_id, appointment_date, status)
VALUES (2, 1, '2025-03-20 10:00:00', 'Scheduled');

select * from appointment_log;

-- updating
UPDATE appointments
SET status = 'Completed'
WHERE appointment_id = 1;


-- deleting
delete from appointments where appointment_id=1;


-- QUERIES

-- 1. Basic JOIN to View Appointments with Patient & Doctor Details
select * from appointments;
select * from patients;
select * from doctors;

select a.appointment_id, p.name as patient_name, d.name as doctor_name, a.status
from appointments a
join patients p on a.patient_id=p.patient_id
join doctors d on a.doctor_id=d.doctor_id;


-- 2.  Find the Total Number of Appointments Per Doctor
select d.name as doctor_name , count(a.doctor_id) as total_appointments
from appointments a
join doctors d on a.doctor_id=d.doctor_id
group by d.name;


-- 3. Find Patients Who Have More Than One Appointment
select p.name as patient_name, count(a.appointment_id) as patient_appointments
from appointments a 
join patients p on a.patient_id=p.patient_id
group by p.name
having count(a.appointment_id) >1;

-- 4. Subquery Example: Find Patients Who Have Never Had an Appointment
select name from patients
where patient_id not in (select  patient_id from appointments);

-- 5. Check Which Patients Were Prescribed Medicine
select * from prescriptions;

select p.name as patient_name, pr.medicine
from prescriptions pr
join appointments a on a.appointment_id=pr.appointment_id
join patients p on a.patient_id=p.patient_id;

-- 6. find details of doctors who are cardiologist and neurologist
SELECT * FROM doctors WHERE specialization IN ('Cardiologist', 'Neurologist');

-- 7. Using LIKE for Pattern Matching
select * from patients where name like 'A%';

select * from patients where email like '%gmail.com';

-- 8.select maximum and minimum aged patients
select * from patients 
where age=(select max(age) from patients) or age=(select min(age) from patients);

-- 9. Group By Example: Count Patients by Gender
select gender, count(*) 
from patients
group by gender;

-- 10.Find Doctors with No Appointments
select name from doctors
where doctor_id not in (select doctor_id from appointments);

-- 11.categorize patients by age
SELECT name, age, 
    CASE 
        WHEN age < 18 THEN 'Minor'
        WHEN age BETWEEN 18 AND 40 THEN 'Adult'
        ELSE 'Senior'
    END AS age_group
FROM patients;

-- 12.rank appointments by date
select appointment_id,patient_id,doctor_id,appointment_date,
rank() over(order by appointment_date asc) as rank
from appointments;


-- 13.Find Patients with the Most Appointments
select p.name as patient_name, count(a.appointment_id) as total_appointments
from appointments a
join patients p on a.patient_id=p.patient_id
group by p.name
order by total_appointments desc
limit 1;

-- 14.Find the Most Popular Doctor
select d.name as doctor_name, count(a.doctor_id) as total_appointments
from appointments a
join doctors d on a.doctor_id=d.doctor_id
group by d.name
order by total_appointments desc
limit 1;


