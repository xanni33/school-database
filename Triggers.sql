
CREATE TRIGGER Students.TrackGPA ON Students.FinalGrades
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @StudentID INT;
	DECLARE @CurrentSchoolYear INT;
	DECLARE @UpdatedGPA DECIMAL (3,2);

	SET @CurrentSchoolYear = Admins.GetCurrentSchoolYear();

	IF EXISTS (SELECT 1 FROM inserted)
    	BEGIN
        	SELECT @StudentID = StudentID FROM inserted;
    	END

	ELSE IF EXISTS (SELECT 1 FROM deleted)
    	BEGIN
        	SELECT @StudentID = StudentID FROM deleted;
    	END

	SELECT @UpdatedGPA = AVG(CAST(FinalGrade AS DECIMAL (3,2))) FROM Students.FinalGrades
	WHERE StudentID = @StudentID AND SchoolYear = @CurrentSchoolYear;

	IF EXISTS (SELECT 1 FROM Students.StudentGPA WHERE StudentID = @StudentID)
	BEGIN
    	UPDATE Students.StudentGPA SET GPA = @UpdatedGPA WHERE StudentID = @StudentID
    	RETURN;
	END

	INSERT INTO Students.StudentGPA (StudentID, GPA) VALUES (@StudentID, @UpdatedGPA)

END;


CREATE TRIGGER Students.MaxStudentsInClass ON Students.StudentInfo
AFTER UPDATE
AS
BEGIN
	DECLARE @StudentCount INT;
	DECLARE @ClassID INT;
	
	SELECT @ClassID = ClassID FROM inserted;

	IF @ClassID IS NOT NULL
    	BEGIN
        	SELECT @StudentCount = COUNT(*) FROM Students.StudentInfo WHERE ClassID = @ClassID;

        	IF @StudentCount >= 15
            	BEGIN
                	RAISERROR('Class already full. Cannot add more students to this class.', 16, 1);
                	ROLLBACK;
            	END
    	END
END;


CREATE TRIGGER PreventClassDeletionWithStudents ON Academics.Classes
FOR DELETE
AS
BEGIN
	DECLARE @ClassID INT;
	SELECT @ClassID = ClassID FROM DELETED;

	IF EXISTS (SELECT 1 FROM Students.StudentInfo WHERE ClassID = @ClassID)
	BEGIN
    	RAISERROR('Deleting classes with students enrolled is not allowed.', 16, 1);
    	ROLLBACK;
	END
END;


CREATE TRIGGER Students.PreventFutureAttendance
ON Students.Attendance
AFTER INSERT
AS
BEGIN
	IF EXISTS (SELECT 1 FROM inserted WHERE AttendanceDate > GETDATE())
	BEGIN
    	RAISERROR('Adding attendance from the future is not allowed', 16, 1);
    	ROLLBACK;
    	RETURN;
	END;
END;


CREATE TRIGGER Students.trg_UpdateBehaviorGrade_Referrals
ON Students.StudentReferrals
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @StudentID INT;

	DECLARE cur CURSOR FOR
	SELECT DISTINCT StudentID FROM inserted 
	UNION
	SELECT DISTINCT StudentID FROM deleted;

	OPEN cur;
	FETCH NEXT FROM cur INTO @StudentID; 
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC Students.UpdateBehaviorGrade @StudentID;
		FETCH NEXT FROM cur INTO @StudentID;
	END;

	CLOSE cur;
	DEALLOCATE cur;
END;
GO


CREATE TRIGGER Students.trg_UpdateBehaviorGrade_Grades
ON Students.Grades
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @StudentID INT;

	DECLARE cur CURSOR FOR
	SELECT DISTINCT StudentID FROM inserted 
	UNION
	SELECT DISTINCT StudentID FROM deleted;

	OPEN cur;
	FETCH NEXT FROM cur INTO @StudentID; 
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC Students.UpdateBehaviorGrade @StudentID;
		FETCH NEXT FROM cur INTO @StudentID;
	END;

	CLOSE cur;
	DEALLOCATE cur;
END;
GO


CREATE TRIGGER Students.trg_UpdateBehaviorGrade_Attendance
ON Students.Attendance
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @StudentID INT;

	DECLARE cur CURSOR FOR
	SELECT DISTINCT StudentID FROM inserted 
	UNION
	SELECT DISTINCT StudentID FROM deleted;

	OPEN cur;
	FETCH NEXT FROM cur INTO @StudentID; 
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC Students.UpdateBehaviorGrade @StudentID;
		FETCH NEXT FROM cur INTO @StudentID;
	END;

	CLOSE cur;
	DEALLOCATE cur;
END;
GO

