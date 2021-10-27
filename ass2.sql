-- Answer to the 2nd Database Assignment 2019/20
--
-- CANDIDATE NUMBER 184510
-- Please insert your candidate number in the line above.
-- Do NOT remove ANY lines of this template.


-- In each section below put your answer in a new line 
-- BELOW the corresponding comment.
-- Use ONE SQL statement ONLY per question.
-- If you don’t answer a question just leave 
-- the corresponding space blank. 
-- Anything that does not run in SQL you MUST put in comments.
-- Your code should never throw a syntax error.
-- Questions with syntax errors will receive zero marks.

-- DO NOT REMOVE ANY LINE FROM THIS FILE.

-- START OF ASSIGNMENT CODE

DROP TABLE IF EXISTS Hospital_MedicalRecord;
DROP FUNCTION IF EXISTS usage_theatre;

-- @@01

CREATE TABLE Hospital_MedicalRecord(
-- smallint will allow maximum of 65,535 records
recNO 		SMALLINT, 
enteredON	TIMESTAMP 	DEFAULT CURRENT_TIMESTAMP NOT NULL,
-- mediumtext will allow maximum of 2^24 bytes of text to be stored in that column
diagnosis 	MEDIUMTEXT 	NOT NULL,
treatment	VARCHAR(1000),
patient		CHAR(9),
doctor 		CHAR(9),
PRIMARY KEY (recNO, patient),
-- table constraingts
CONSTRAINT FK_patient FOREIGN KEY (patient) REFERENCES Hospital_Patient(NINumber)
	-- on update no action will make sure that once patient has a record the nin cannot be changed
	-- on delete cascade will make sure that once patient is delete from the databases all their records are deleted with him
	ON UPDATE NO ACTION 	ON DELETE CASCADE,
CONSTRAINT FK_doctor FOREIGN KEY (doctor) REFERENCES Hospital_Doctor(NINumber)
	-- on update no action will make sure that once doctor created a record the nin cannot be changed
	ON UPDATE NO ACTION
);
 
-- @@02

ALTER TABLE Hospital_MedicalRecord
	-- adds new column to the medical record table called duration
	ADD duration TIME;

-- @@03

UPDATE Hospital_Doctor
	-- takes the salary that is saved inside of the field and calculates 90% out of it
	SET salary = salary*9/10
	-- makes sure that is only happening if the doctor expertise in ear category
	WHERE expertise LIKE '%ear%';

-- @@04

SELECT fname, lname, YEAR(dateOfBirth) AS born FROM Hospital_Patient
	-- makes sure only patients that live in cities with word right in it's name are picked and displayed
	WHERE city LIKE '%right%'
	-- sorts them alphabetically
	ORDER BY fname;

-- @@05

SELECT NINumber, fname, lname, (weight/(height/100)) AS BMI FROM Hospital_Patient -- body mass is being calcualted by the weight/(height/100)
	-- makes sure that the peope returned and displayed are the only ones that haven't had their 30th birthday yet
	WHERE TIMESTAMPDIFF(YEAR, dateOfBirth, CURDATE()) < 30;

-- @@06

SELECT COUNT(*) AS 'number' FROM Hospital_Doctor;

-- @@07

SELECT NINumber, lname, COUNT(*) AS operations FROM Hospital_Doctor,Hospital_CarriesOut -- accesses two different tables as we carries out table does not have information about the last name of the doctor
	-- makes sure that only doctors that have been performing operations current year are being displayed
	WHERE doctor = NINumber AND YEAR(startDateTime) = YEAR(CURDATE())
	-- this will make sure that the doctor with most operations will apear at the top of the table and all the doctors will be displayed with correct order
	GROUP BY NINumber;

-- @@08

SELECT a.NINumber, UPPER(SUBSTRING(a.fname, 1, 1)) AS init, a.lname FROM Hospital_Doctor a, Hospital_Doctor b -- creates two lots of the same table and makes sure only the first letter of for name is displayed
	-- checks that the doctor is not mentored by anyone
	WHERE a.mentored_by IS NULL AND 
	-- checks that the doctor mentors some other doctor
	a.NINumber = b.mentored_by AND
	-- checks that the first letter of forname is always a capital letter
	ASCII(a.fname) BETWEEN 65 AND 80;

-- @@09

SELECT a.theatreNo AS theatre, a.startDateTime AS startTime1, TIME(b.startDateTime) AS startTime2 FROM Hospital_Operation a, Hospital_Operation b
-- makes sure that the operation is happening in the same theatre
WHERE a.theatreNo = b.theatreNo AND
-- checks that the start date tie of the second lot of data is after the first one so no duplicates are displayed
b.startDateTime > a.startDateTime AND
-- check that the start date after the duration have passed is bigger then the start date time of the second set
a.startDateTime + a.duration > b.startDateTime;

-- @@10

SELECT theatreNo, DAY(startDateTime) AS dom, DATE_FORMAT(startDateTime, '%M') AS 'month', YEAR(startDateTime) AS 'year', COUNT(*) numOps FROM Hospital_Operation
	GROUP BY theatreNo, startDateTime 
	HAVING(theatreNo, numOps) 
	IN(SELECT theatreNo, MAX(numOps) 
		FROM (SELECT theatreNo, COUNT(*) numOps FROM Hospital_Operation GROUP BY theatreNo)AS t 
	GROUP BY theatreNo);

-- @@11

-- Checks current date and takes away one from it to check last year date and then sums up all the operations that happened that year
SELECT theatreNo, SUM(YEAR(startDateTime) = YEAR(CURDATE()) - 1) AS lastMay, 
-- Checks current date and sums up all the operations that happened this year
SUM(YEAR(startDateTime) = YEAR(CURDATE())) AS thisMay, 
-- Calculates the difference between the amount of operations done this year to last year and specifies an increase that happened during that time
SUM(YEAR(startDateTime) = YEAR(CURDATE())) - SUM(YEAR(startDateTime) = YEAR(CURDATE()) - 1) AS increase FROM Hospital_Operation
-- Only gets the operations that happened during may of each year
WHERE MONTH(startDateTime) = 05
-- groups it by theatre number
GROUP BY theatreNo
-- this will make sure that only if there was an increase in operations from last to current year then it will display a resultHospital_Operation
HAVING SUM(YEAR(startDateTime) = YEAR(CURDATE())) > SUM(YEAR(startDateTime) = YEAR(CURDATE()) - 1)
-- orders the table so the results are shown from the biggest increase to the smallest
ORDER BY increase DESC;

-- @@12
delimiter $$

-- begins function, gives it a name and the variables that will be provided, it also specifies the datatype and lenght of the return
CREATE FUNCTION usage_theatre(theatreNumberProvided TINYINT, yearProvided INT) RETURNS VARCHAR(150)
-- begis the function
BEGIN
-- declares all the variables used
DECLARE days INT;
DECLARE hours INT;
DECLARE minutes INT;
DECLARE totalAmountSeconds INT;
DECLARE outputMessage VARCHAR(150);
-- saves the total time that the operation took in seconds and saves it into a variable
SELECT SUM(TIME_TO_SEC(duration)) INTO totalAmountSeconds FROM Hospital_Operation
-- takes the year and theatre number that is provided and tells database for which records it needs to look for
WHERE YEAR(startDateTime) = yearProvided AND theatreNo = theatreNumberProvided;
-- sets number of days by taking the number of total seconds and calculating how many days are within that time
SET days = FLOOR(totalAmountSeconds / 3600 / 24);
-- takes the remaining time and checks how many hours are within the left over seconds
SET hours = FLOOR(totalAmountSeconds / 3600 % 24);
-- takes the remianing time in seconds and checks how many minutes it creates
SET minutes = FLOOR(totalAmountSeconds / 60 % 60);

-- takes the calculated data and creates and the message that will be outputted 
SELECT CONCAT (days,'days ',hours ,'hrs ', minutes, 'mins ') INTO outputMessage;

-- checks that the year provided into the function has all ready happened and it is not in a future
IF yearProvided > YEAR(CURDATE()) THEN
	SET outputMessage = "The year is in the future";
END IF;

-- checks that the theatre provided actually exists and if not it will display a message that the provided theatre number does not exist
IF yearProvided <= YEAR(CURDATE()) AND theatreNumberProvided NOT IN (SELECT theatreNo FROM Hospital_Operation) THEN
	SET outputMessage = CONCAT("There is no operating theatre ", theatreNumberProvided);
END IF;

-- if there have not been any operations during the combination provided then appropriate message will be displayed
IF yearProvided <= YEAR(CURDATE()) AND theatreNumberProvided IN (SELECT theatreNo FROM Hospital_Operation) AND (SELECT COUNT(*) FROM Hospital_Operation WHERE YEAR(startDateTime) = yearProvided AND theatreNo = theatreNumberProvided) = 0 THEN
	SET outputMessage = CONCAT("Operating theatre ", theatreNumberProvided, " had no operations in ", yearProvided);
END IF;

-- returns the a specific message depending on the theatre number and year provided
RETURN outputMessage;
-- ends the function
END $$

-- runs the function and provides the variables
SELECT usage_theatre(2, 2018);	
	
-- END OF ASSIGNMENT CODE
