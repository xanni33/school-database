CREATE PROCEDURE Students.AddNewStudent
	@FirstName VARCHAR(50),
	@LastName VARCHAR(50),
	@PESEL VARCHAR(11),
	@DateOfBirth DATE,
	@Gender CHAR
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1 FROM Students.StudentInfo WHERE PESEL = @PESEL)
	BEGIN

    	RAISERROR('Student with the provided PESEL already exists in the database.', 16, 1);
   	   	 
    	RETURN;
	END

	INSERT INTO Students.StudentInfo
	(PESEL, FirstName, PreferredName, LastName, DateOfBirth, EnrollmentDate, Gender, ClassID, RegisterNumber)
	VALUES (@PESEL, @FirstName, NULL, @LastName, @DateOfBirth, GETDATE(), @Gender, NULL, NULL);

END;

CREATE PROCEDURE Students.AddStudentToClass
	@StudentID INT,
	@ClassID INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Students.StudentInfo WHERE StudentID = @StudentID)
	BEGIN
    	RAISERROR('Student does not exist.', 16, 1);
        	RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM Academics.Classes WHERE ClassID = @ClassID)
	BEGIN
    	RAISERROR('Class does not exist.', 16, 1);
    	RETURN;
	END;

	IF EXISTS (SELECT 1 FROM Students.StudentInfo WHERE ClassID = @ClassID AND StudentID = @StudentID)
	BEGIN
    	RAISERROR('Student already in this class', 16, 1);
    	RETURN;
	END;

	DECLARE @RegisterNumber INT;
	SET @RegisterNumber = Students.GetNextRegisterNumber(@ClassID);

	UPDATE Students.StudentInfo
	SET ClassID = @ClassID, RegisterNumber = @RegisterNumber
	WHERE StudentID = @StudentID;

END;

CREATE PROCEDURE Students.AddStudentGrade
	@StudentID INT,
	@TeacherID INT,
	@GradeValue INT,
	@SubjectID INT
AS
BEGIN
	SET NOCOUNT ON;

	
	IF NOT EXISTS (SELECT 1 FROM Academics.Subjects WHERE SubjectID = @SubjectID)
	BEGIN
    	RAISERROR('Subject does not exist', 16, 1);
        	RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM Students.StudentInfo WHERE StudentID = @StudentID)
	BEGIN
    	RAISERROR('Student does not exist', 16, 1);
        	RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM Academics.Teachers WHERE TeacherID = @TeacherID)
	BEGIN
    	RAISERROR('Teacher does not exist', 16, 1);
        	RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM Academics.TeacherSubjects WHERE TeacherID = @TeacherID AND SubjectID = @SubjectID)
	BEGIN
    	RAISERROR('Teacher does not teach the subject', 16, 1);
    	RETURN;
	END;

	INSERT INTO Students.Grades (StudentID, TeacherID, SubjectID, GradeValue, DateTime)
	VALUES (@StudentID, @TeacherID, @SubjectID, @GradeValue, GETDATE());

END;

CREATE PROCEDURE Students.AddStudentReferral
	@StudentID INT,
	@TeacherID INT,
	@ReferralText VARCHAR(500),
	@ReferralType CHAR
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Students.StudentInfo WHERE StudentID = @StudentID)
	BEGIN
    	RAISERROR('Student does not exist', 16, 1);
    	RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM Academics.Teachers WHERE TeacherID = @TeacherID)
	BEGIN
    	RAISERROR('Teacher does not exist', 16, 1);
        	RETURN;
	END;

	INSERT INTO Students.StudentReferrals (TeacherID, StudentID, ReferralDate, ReferralText, ReferralType)
	VALUES (@TeacherID, @StudentID, GETDATE(), @ReferralText, @ReferralType);

END;


CREATE PROCEDURE Students.RemoveStudentFromClass
	@StudentID INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ClassID INT, @RegisterNumber INT;

	BEGIN TRANSACTION;

	IF NOT EXISTS (SELECT 1 FROM Students.StudentInfo WHERE StudentID = @StudentID)
	BEGIN
    	RAISERROR('Student does not exist', 16, 1);
    	ROLLBACK TRANSACTION;
    	RETURN;
	END;

	SELECT @ClassID = ClassID, @RegisterNumber = RegisterNumber
	FROM Students.StudentInfo
	WHERE StudentID = @StudentID;

	IF @ClassID IS NULL
	BEGIN
    	RAISERROR('Student is not assigned to any class.', 16, 1);
    	ROLLBACK TRANSACTION;
    	RETURN;
	END;

	UPDATE Students.StudentInfo
	SET ClassID = NULL, RegisterNumber = NULL
	WHERE StudentID = @StudentID;

	UPDATE Students.StudentInfo
	SET RegisterNumber = RegisterNumber - 1
	WHERE ClassID = @ClassID AND RegisterNumber > @RegisterNumber;

	COMMIT TRANSACTION;

END;


CREATE PROCEDURE Academics.GetLuckyRegisterNumber
AS
BEGIN
	DECLARE @LuckyRegisterNumber INT;

	IF NOT EXISTS (SELECT 1 FROM Academics.LuckyRegisterNumber WHERE CAST(Day AS DATE) = CAST(GETDATE() AS DATE))
    	BEGIN
        	SET @LuckyRegisterNumber = FLOOR(RAND() * 30) + 1;
        	INSERT INTO Academics.LuckyRegisterNumber (Day, RegisterNumber) VALUES (GETDATE(), @LuckyRegisterNumber);
    	END;

	SELECT RegisterNumber AS 'The Lucky Register Number for today'
	FROM Academics.LuckyRegisterNumber
	WHERE CAST(Day AS DATE) = CAST(GETDATE() AS DATE);

END;


CREATE PROCEDURE Students.RemoveStudent
	@StudentID INT
AS
BEGIN

	IF NOT EXISTS (SELECT 1 FROM Students.StudentInfo WHERE StudentID = @StudentID)
	BEGIN
    	RAISERROR('Student does not exist', 16, 1);
    	RETURN;
	END

	BEGIN TRANSACTION;

	BEGIN TRY
 
    	DELETE FROM Students.StudentCouncil WHERE StudentID = @StudentID;
    	DELETE FROM Students.StudentSocieties WHERE StudentID = @StudentID;
    	DELETE FROM Students.Grades WHERE StudentID = @StudentID;
    	DELETE FROM Students.BehaviorGrade WHERE StudentID = @StudentID;
    	DELETE FROM Students.StudentReferrals WHERE StudentID = @StudentID;
    	DELETE FROM Students.Attendance WHERE StudentID = @StudentID;

    	DECLARE @ParentID INT;
    	SELECT @ParentID = ParentID FROM Students.StudentParents WHERE StudentID = @StudentID;

    	DELETE FROM Students.StudentParents WHERE StudentID = @StudentID;

    	IF NOT EXISTS (SELECT 1 FROM Students.StudentParents WHERE ParentID = @ParentID)
    	BEGIN
        	DELETE FROM Students.Parents WHERE ParentID = @ParentID;
    	END

    	DELETE FROM Students.StudentInfo WHERE StudentID = @StudentID;

    	COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
    	ROLLBACK TRANSACTION;
	END CATCH
END;


CREATE PROCEDURE Students.GenerateStudentTranscript
	@StudentID INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM Students.StudentInfo WHERE StudentID = @StudentID)
	BEGIN
		RAISERROR('Student does not exist', 16, 1);
		RETURN;
	END;

	DECLARE @PESEL VARCHAR(11), @FirstName VARCHAR(50), LastName VARCHAR(50);

SELECT @FirstName = FirstName,
	@LastName = LastName,
	@PESEL = PESEL
FROM Students.StudentInfo
WHERE StudentID = @StudentID;

	SELECT 
		s.SubjectName AS 'Subject',
		t.FirstName + ' ' + t.LastName AS 'Teacher',
		g.GradeValue AS 'Grade',
		g.DateTime AS 'Date'
	FROM Students.Grades g
	JOIN Academics.Subjects s ON g.SubjectID = s.SubjectID
	JOIN Academics.Teachers t ON g.TeacherID = t.TeacherID
	WHERE g.StudentID = @StudentID
	ORDER BY s.SubjectName, g.DateTime;

SELECT 
	s.SubjectName AS 'Subject',
	ROUND(AVG(CAST(g.GradeValue AS FLOAT)), 2) AS 'Average grade'
FROM Students.Grades g 
JOIN Academics.Subjects s ON g.SubjectID = s.SubjectID
WHERE g.StudentID = @StudentID
GROUP BY s.SubjectName;

END;


CREATE PROCEDURE Students.CalculateFinalGrades
	@StudentID INT,
	@SchoolYear INT
AS
BEGIN
	SET NOCOUNT ON;
    
	DECLARE @AverageGrade DECIMAL(3, 2);
	DECLARE @FinalGrade INT;
	DECLARE @StartDate DATE;
	DECLARE @EndDate DATE;
	DECLARE @SubjectID INT;

	IF NOT EXISTS (SELECT 1 FROM Students.StudentInfo WHERE StudentID = @StudentID)
	BEGIN
    	RAISERROR('Student does not exist', 16, 1);
    	RETURN;
	END

	SELECT @StartDate = StartDate, @EndDate = EndDate
	FROM Admins.SchoolYearDates
	WHERE SchoolYear = @SchoolYear;

	IF @StartDate IS NULL OR @EndDate IS NULL
	BEGIN
    	RETURN;
	END

	BEGIN TRANSACTION;

	DECLARE SubjectCursor CURSOR FOR
    	SELECT SubjectID
    	FROM Students.Grades
    	WHERE StudentID = @StudentID;

	OPEN SubjectCursor;
	FETCH NEXT FROM SubjectCursor INTO @SubjectID;

	WHILE @@FETCH_STATUS = 0
	BEGIN

    	SELECT @AverageGrade = AVG(GradeValue)
    	FROM Students.Grades
    	WHERE StudentID = @StudentID
        	AND SubjectID = @SubjectID
        	AND DateTime BETWEEN @StartDate AND @EndDate;

    	IF @AverageGrade IS NULL
    	BEGIN

        	FETCH NEXT FROM SubjectCursor INTO @SubjectID;
        	CONTINUE;
    	END

    	SET @FinalGrade = CASE
        	WHEN @AverageGrade < 1.5 THEN 1
        	WHEN @AverageGrade < 2.5 THEN 2
        	WHEN @AverageGrade < 3.5 THEN 3
        	WHEN @AverageGrade < 4.5 THEN 4
        	WHEN @AverageGrade < 5.5 THEN 5
        	WHEN @AverageGrade >= 5.5 THEN 6
        	ELSE NULL
    	END;

    	IF EXISTS (SELECT 1 FROM Students.FinalGrades WHERE StudentID = @StudentID AND SchoolYear = @SchoolYear)
    	BEGIN
        	UPDATE Students.FinalGrades
        	SET FinalGrade = @FinalGrade
        	WHERE StudentID = @StudentID AND SchoolYear = @SchoolYear AND SubjectID = @SubjectID;
    	END
    	ELSE
    	BEGIN
        	INSERT INTO Students.FinalGrades (StudentID, SchoolYear, SubjectID, FinalGrade)
        	VALUES (@StudentID, @SchoolYear, @SubjectID, @FinalGrade);
    	END

    	FETCH NEXT FROM SubjectCursor INTO @SubjectID;
	END

	CLOSE SubjectCursor;
	DEALLOCATE SubjectCursor;
	COMMIT TRANSACTION;

END;


CREATE PROCEDURE Students.UpdateBehaviorGrade
	@StudentID INT
AS
BEGIN
	DECLARE @GPA DECIMAL(3,2);
	DECLARE @PositiveReferrals INT;
	DECLARE @NegativeReferrals INT;
	DECLARE @Absences INT;
	DECLARE @NewBehaviorGrade VARCHAR(20) = 'Good';

	SELECT @GPA = GPA 
FROM Students.StudentGPA
WHERE StudentID = @StudentID;

SELECT @PositiveReferrals = COUNT(*)
FROM Students.StudentReferrals
WHERE StudentID = @StudentID AND ReferralType = '+';

SELECT @NegativeReferrals = COUNT(*)
FROM Students.StudentReferrals
WHERE StudentID = @StudentID AND ReferralType = '-';

SELECT @Absences = COUNT(*)
FROM Students.Attendance
WHERE StudentID = @StudentID AND AttendanceStatus = 'Absent';

--logika do zmiany oceny - gpa>4.0 pozytywne uwagi >= 3 nieobecnoœci < 10
--gpa < 3.0 negatywne uwagi >= 3 nieobecnoœci >= 30
IF @GPA IS NOT NULL AND @GPA > 4.0 AND @PositiveReferrals >= 3 AND @Absences < 10
	SET @NewBehaviorGrade = 'Outstanding';
ELSE IF @GPA IS NOT NULL AND @GPA < 3.0 AND @NegativeReferrals >= 3 AND @Absences > 30
	SET @NewBehaviorGrade = 'Inadequate';

UPDATE Students.BehaviorGrade
SET BehaviorGrade = @NewBehaviorGrade
WHERE StudentID = @StudentID;

END;


CREATE PROCEDURE Admins.AddTeacher
	@FirstName VARCHAR(50),
	@LastName VARCHAR(50),
	@Salary FLOAT,
	@PhoneNumber VARCHAR(12) = NULL,
	@EmailAddress VARCHAR(50) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @NewEmployeeID INT;

	BEGIN TRANSACTION;
	
	BEGIN TRY
		INSERT INTO Admins.EmployeeInfo (FirstName, LastName, Salary, PhoneNumber, EmailAddress) 
		VALUES (@FirstName, @LastName, @Salary, @PhoneNumber, @EmailAddress);
	
		SET @NewEmployeeID = SCOPE_IDENTITY();
		
		INSERT INTO Academics.Teachers(EmployeeID)
		VALUES (@NewEmployeeID);

		COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION;
		RAISERROR('Error occurred while adding a new teacher', 16, 1);
	END CATCH;
END;

