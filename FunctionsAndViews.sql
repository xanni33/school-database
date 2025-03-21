CREATE VIEW Students.RankingGPA AS (
	SELECT ROW_NUMBER() OVER (ORDER BY G.GPA DESC) AS Rank, S.FirstName, S.LastName, G.GPA
	FROM Students.StudentInfo S
	JOIN Students.StudentGPA G ON G.StudentID = S.StudentID
)

CREATE FUNCTION Students.GetClassStudents (@ClassID INT)
RETURNS TABLE
AS
RETURN
(
	SELECT ROW_NUMBER() OVER (ORDER BY S.RegisterNumber ASC) AS RegisterNumber, 
	S.FirstName, S.LastName, S.PESEL, S.DateOfBirth, S.Gender, 
	P1.PhoneNumber AS 'Parent Contact 1', P2.PhoneNumber AS 'Parent Contact 2'
	FROM Students.StudentInfo S
	LEFT JOIN Students.StudentParents SP ON S.StudentID = SP.StudentID
	LEFT JOIN Students.Parents P1 ON SP.ParentID = P1.ParentID
	LEFT JOIN Students.Parents P2 ON SP.ParentID = P2.ParentID
	WHERE S.ClassID = @ClassID
    
);

CREATE FUNCTION Students.GetStudentGradesForSubjectAndYear (
	@StudentID INT,
	@SubjectID INT,
	@SchoolYear INT
)
RETURNS TABLE
AS
RETURN
(
	SELECT
    	G.StudentID,
    	G.SubjectID,
    	G.GradeValue,
    	G.DateTime
	FROM
    	Students.Grades G
	JOIN
    	Academics.Subjects S ON G.SubjectID = S.SubjectID
	JOIN
    	Admins.SchoolYearDates SY ON SY.SchoolYear = @SchoolYear
	WHERE
    	G.StudentID = @StudentID
    	AND G.SubjectID = @SubjectID
    	AND (G.DateTime BETWEEN SY.StartDate AND SY.EndDate)
);

CREATE FUNCTION Students.GetStudentFinalGradesForYear (
	@StudentID INT,
	@SchoolYear INT
)
RETURNS TABLE
AS
RETURN
(
	SELECT
    	F.StudentID,
    	F.SubjectID,
    	F.FinalGrade
	FROM
    	Students.FinalGrades F
	WHERE
    	F.StudentID = @StudentID
    	AND F.SchoolYear = @SchoolYear
);

CREATE VIEW Students.AttendanceRanking AS
SELECT 
	s.StudentID,
	s.FirstName,
	s.LastName,
	c.ClassLevel,
	c.ClassSymbol,
	COUNT(a.AttendanceID) AS TotalAbsences
FROM Students.StudentInfo s
JOIN Academics.Classes c ON s.ClassID = c.ClassID
LEFT JOIN Students.Attendance a ON s.StudentID = a.StudentID AND a.Status = 'Absent'
	WHERE EXISTS (
SELECT 1 
		FROM Admins.CurrentSchoolYear sy
		WHERE a.AttendanceDate BETWEEN sy.StartDate AND sy.EndDate
	)
	
	GROUP BY s.StudentID, s.FirstName, s.LastName, c.ClassLevel, c.ClassSymbol
	ORDER BY TotalAbsences ASC; --najmniej nieobecnoœci na górze


CREATE VIEW StudentsWithFinalGrade1 AS
SELECT DISTINCT
	S.StudentID,
	S.FirstName,
	S.LastName
FROM
	Students.StudentInfo S
JOIN
	Students.FinalGrades F ON S.StudentID = F.StudentID
WHERE
	F.FinalGrade = 1 AND F.SchoolYear = Admins.GetCurrentSchoolYear();


CREATE FUNCTION Students.GetStudentSchedule (@StudentID INT)
RETURNS TABLE
AS
	RETURN
	(
    	SELECT si.StudentID,
    	si.FirstName, si.LastName, cs.Day, cs.StartTime, cs.EndTime, s.SubjectName, 
		e.FirstName + ' ' + e.LastName AS TeacherName, cs.RoomNumber
    	FROM Academics.ClassSchedule cs
    	JOIN Academics.Subjects s ON cs.SubjectID = s.SubjectID
    	JOIN Academics.Teachers t ON cs.TeacherID = t.TeacherID
    	JOIN Admins.EmployeeInfo e ON t.EmployeeID = e.EmployeeID
    	JOIN Students.StudentInfo si ON cs.ClassOneID = si.ClassID OR si.ClassID = cs.ClassTwoID
    	WHERE si.StudentID = @StudentID
	);

CREATE FUNCTION Students.GetNextRegisterNumber (@ClassID INT)
RETURNS INT
AS
BEGIN
	DECLARE @NextRegisterNumber INT;

	IF NOT EXISTS (SELECT 1 FROM Academics.Classes WHERE ClassID = @ClassID)
    	BEGIN
        	/* THIS CLASS DOES NOT EXIST */
    	RETURN NULL;
    	END

	SELECT TOP 1 @NextRegisterNumber = RegisterNumber FROM (
    	VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), 
		(16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28), (29), (30)
    	)
	AS AvailableNumbers (RegisterNumber)
	WHERE RegisterNumber NOT IN (
    	SELECT RegisterNumber FROM Students.StudentInfo WHERE ClassID = @ClassID AND RegisterNumber IS NOT NULL
	)
    
	ORDER BY RegisterNumber ASC;
	RETURN @NextRegisterNumber;

END;

CREATE VIEW Academics.ClassesAndTutors AS (
	SELECT DISTINCT CONVERT(VARCHAR(1), C.ClassLevel) + ' ' +  C.ClassSymbol AS 'Class', 
	E.FirstName + ' ' + E.LastName AS 'Tutor', E.PhoneNumber AS 'Tutor Contact', 
	COUNT(S.StudentID) AS 'Number Of Students'
	FROM Academics.Classes C
	JOIN Academics.Teachers T ON C.TutorID = T.TeacherID
	JOIN Admins.EmployeeInfo E ON E.EmployeeID = T.EmployeeID
	JOIN Students.StudentInfo S ON C.ClassID = S.ClassID
	GROUP BY C.ClassID, C.ClassLevel, C.ClassSymbol, E.FirstName, E.LastName, E.PhoneNumber
)


CREATE VIEW TeachersNotTutors AS
SELECT T.TeacherID, E.FirstName, E.LastName, E.PhoneNumber, E.EmailAddress
FROM
	Academics.Teachers T
	JOIN Admins.EmployeeInfo E ON T.EmployeeID = E.EmployeeID
	LEFT JOIN
	Academics.Classes C ON T.TeacherID = C.TutorID
WHERE
	C.ClassID IS NULL;

CREATE FUNCTION Admins.GetCurrentSchoolYear()
RETURNS INT
AS
BEGIN
	DECLARE @CurrentSchoolYear INT;
	SELECT @CurrentSchoolYear = MAX(SchoolYear)
	FROM SchoolYearDates;
    
	RETURN @CurrentSchoolYear;
END;
