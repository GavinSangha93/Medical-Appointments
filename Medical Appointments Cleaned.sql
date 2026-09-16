SELECT * FROM medicalappointments
LIMIT 10;

ALTER TABLE medicalappointments
	CHANGE COLUMN Hipertension hypertension	INT, 
	CHANGE COLUMN Handcap disability_count INT, 
    CHANGE COLUMN `No-show` no_show VARCHAR(3);
    
SELECT 
	disability_count,
    COUNT(*)  
FROM medicalappointments
GROUP BY disability_count;

SELECT 
	ScheduledDay,
    AppointmentDay 
FROM medicalappointments
LIMIT 10;

ALTER TABLE medicalappointments
	MODIFY COLUMN ScheduledDay DATETIME,
    MODIFY COLUMN AppointmentDay DATE; 

ALTER TABLE medicalappointments
	ADD COLUMN ScheduledDay_clean DATETIME,
    ADD COLUMN AppointmentDay_clean DATE;

UPDATE medicalappointments
SET ScheduledDay_clean = str_to_date(REPLACE(REPLACE(ScheduledDay, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s'),
	AppointmentDay_clean = str_to_date(REPLACE(REPLACE(AppointmentDay, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s');
    
ALTER TABLE medicalappointments
	DROP COLUMN ScheduledDay,
    DROP COLUMN AppointmentDay;
    
ALTER TABLE medicalappointments
	CHANGE COLUMN ScheduledDay_clean ScheduledDay DATETIME,
	CHANGE COLUMN AppointmentDay_clean AppointmentDay DATE; 
    
SELECT 
	ScheduledDay,
    AppointmentDay 
FROM medicalappointments
LIMIT 10;


SELECT
	MIN(AGE),
    MAX(AGE)
FROM medicalappointments;

DELETE FROM medicalappointments
WHERE AGE = -1; 


ALTER TABLE medicalappointments ADD COLUMN lead_time_days INT;

UPDATE medicalappointments 
SET lead_time_days = datediff(AppointmentDay, DATE(ScheduledDay));

SELECT 
	MIN(lead_time_days),
    MAX(lead_time_days)
FROM medicalappointments;

SELECT * FROM medicalappointments 
WHERE lead_time_days < 0; 

DELETE FROM medicalappointments
WHERE lead_time_days < 0; 

-- Date Exploration
-- 1: What's our overall no-show rate?

SELECT 
	no_show, 
    COUNT(*) as total_appointments,
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM medicalappointments), 2) as pct_of_total
FROM medicalappointments
GROUP BY no_show;

-- 2: Does the day of the week matter for no-shows?

SELECT
	dayname(AppointmentDay) as appt_day,
    COUNT(*) as total_appts,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) as no_shows, 
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) as rate_of_no_shows
FROM medicalappointments
GROUP BY dayname(AppointmentDay)
ORDER BY rate_of_no_shows desc; 

-- 3: Does lead time matter for no-shows?

-- same day
-- 1=3 days
-- within a week (4-7 days)
-- long lead (8+ days)

SELECT
	CASE 
		WHEN lead_time_days = 0 THEN 'Same Day' 
        WHEN lead_time_days BETWEEN 1 AND 3 THEN 'Short (1-3 Days)' 
        WHEN lead_time_days BETWEEN 4 AND 7 THEN 'Within a Week'
        ELSE 'Long Lead (8+ days)' 
        END AS lead_time_bucket,
	COUNT(*) as total_appts,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 /COUNT(*), 2) as no_show_rate 
FROM medicalappointments
GROUP BY lead_time_bucket
ORDER BY no_show_rate desc;

-- 4: Age Groups effect on no-shows

-- Child (0-12)
-- Teen (13-19)
-- young adult (20-39)
-- Adult (40-59)

SELECT
	CASE
		WHEN Age BETWEEN 0 AND 12 THEN 'Child'
        WHEN Age BETWEEN 13 AND 19 THEN 'Teen'
        WHEN Age BETWEEN 20 AND 39 THEN 'Young Adult'
        WHEN Age BETWEEN 40 AND 59 THEN 'Adult'
        ELSE 'Senior'
	END AS age_group,
    COUNT(*) as total_appts,
	ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 /COUNT(*), 2) as no_show_rate 
FROM medicalappointments
GROUP BY age_group
ORDER BY no_show_rate desc;


-- 5: Do SMS reminders help patients avoid no-shows

SELECT 
	CASE WHEN SMS_received = 1 THEN 'Received SMS' ELSE 'No SMS'
    END AS sms_status,
    COUNT(*) as total_appts,
	ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 /COUNT(*), 2) as no_show_rate 
FROM medicalappointments
GROUP BY sms_status;

-- 6: Which neighborhoods have the highest risk of no-shows?

SELECT 
	Neighbourhood,
    COUNT(*) as total_appts,
	ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 /COUNT(*), 2) as no_show_rate,
    RANK() OVER(ORDER BY ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100 /COUNT(*), 2) DESC) as risk_rank
FROM medicalappointments
GROUP BY Neighbourhood
HAVING COUNT(*) >= 100
ORDER BY no_show_rate DESC	
LIMIT 15; 

-- Patient-level risk scoring

SELECT 
	patientid,
    appointmentid,
    appointmentday,
    no_show,
    COUNT(*) OVER (
		PARTITION BY PatientID
        ORDER BY AppointmentDay
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as prior_appts, 
	SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) OVER 
		(PARTITION BY PatientID
        ORDER BY AppointmentDay
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as prior_no_shows
	FROM medicalappointments
    ORDER BY patientid, appointmentday; 
    
    
CREATE VIEW v_appointment_risk AS
WITH patient_history AS (
	SELECT 
		PatientID,
        AppointmentID, 
        AppointmentDay,
        Neighbourhood,
        lead_time_days,
        sms_received, 
        Scholarship,
        no_show,
        COUNT(*) OVER(
			PARTITION BY PatientID
            ORDER BY AppointmentDay
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_appts,
        SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) OVER (
			PARTITION BY PatientId
            ORDER BY AppointmentDay
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_no_shows
	FROM medicalappointments
)
SELECT 
	PatientID,
	AppointmentID, 
	AppointmentDay,
	Neighbourhood,
	lead_time_days,
    prior_appts,
    prior_no_shows,
    ROUND(prior_no_shows / NULLIF(prior_appts, 0), 2) AS prior_no_show_rate,
    CASE
		WHEN prior_appts = 0 THEN 'New Patient - Monitor' 
        WHEN (prior_no_shows / NULLIF(prior_appts, 0))  >= 0.5 OR lead_time_days >=8 THEN 'High Risk' 
        WHEN (prior_no_shows / NULLIF(prior_appts, 0))  >= 0.2 OR lead_time_days BETWEEN 4 AND 7 THEN 'Medium Risk' 
        ELSE 'Low Risk'
	END AS risk_tier
FROM patient_history;

SELECT * FROM v_appointment_risk
WHERE risk_tier = 'High Risk' 
ORDER BY AppointmentDay
LIMIT 50;

Select * FROM medicalappointments;

SELECT * FROM v_appointment_risk
        