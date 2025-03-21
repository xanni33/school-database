CREATE SCHEMA Students;
CREATE SCHEMA Academics;
CREATE SCHEMA Admins;

CREATE TABLE Admins.EmployeeInfo (
	EmployeeID INT PRIMARY KEY IDENTITY(0,1),
	FirstName VARCHAR(50) NOT NULL,
	LastName VARCHAR(50) NOT NULL,
	Salary FLOAT NOT NULL,
	PhoneNumber VARCHAR(12),
	EmailAddress VARCHAR(50),
	)

CREATE TABLE Academics.Teachers (
	TeacherID INT PRIMARY KEY IDENTITY(0,1),
	EmployeeID INT,
	FOREIGN KEY (EmployeeID) REFERENCES Admins.EmployeeInfo(EmployeeID)
	)

CREATE TABLE Academics.Subjects (
	SubjectID INT PRIMARY KEY IDENTITY(0,1),
	SubjectName	VARCHAR(50)
	)

CREATE TABLE Academics.Classes (
	ClassID INT PRIMARY KEY IDENTITY(0,1),
	ClassLevel INT CHECK (ClassLevel >= 1 AND ClassLevel <= 4) NOT NULL,
	ClassSymbol CHAR CHECK(ClassSymbol >= 'A' AND ClassSymbol <= 'Z'),
	TutorID INT NOT NULL,
	FOREIGN KEY(TutorID) REFERENCES Academics.Teachers(TeacherID)
	)

CREATE TABLE Students.StudentInfo (
	StudentID INT PRIMARY KEY IDENTITY(0,1),
	PESEL VARCHAR(11),
	FirstName VARCHAR(50) NOT NULL,
	PreferredName VARCHAR(50) NULL,
	LastName VARCHAR(50) NOT NULL,
	DateOfBirth DATE NOT NULL,
	EnrollmentDate DATE NOT NULL,
	Gender CHAR CHECK (Gender IN ('M', 'F', 'N')),
	ClassID INT,
	RegisterNumber INT,
	FOREIGN KEY(ClassID) REFERENCES Academics.Classes(ClassID),
	CONSTRAINT UNIQUE_PESEL UNIQUE (PESEL)
	)

CREATE TABLE Students.StudentGPA (
	StudentID INT PRIMARY KEY,
	GPA DECIMAL(3, 2) NOT NULL,
	FOREIGN KEY (StudentID) REFERENCES Students.StudentInfo(StudentID)
	)

CREATE TABLE Students.StudentReferrals (
	ReferralID INT PRIMARY KEY IDENTITY(0,1),
	TeacherID INT NOT NULL,
	StudentID INT NOT NULL,
	ReferralDate DATE DEFAULT GETDATE(),
	ReferralText VARCHAR(200) NOT NULL,
	ReferralType CHAR CHECK(ReferralType in ('+', '-')),
	FOREIGN KEY (TeacherID) REFERENCES Academics.Teachers(TeacherID),
	FOREIGN KEY (StudentID) REFERENCES Students.StudentInfo(StudentID)
	)


CREATE TABLE Academics.TeacherSubjects (
	TeacherID INT,
	SubjectID INT,
	FOREIGN KEY (TeacherID) REFERENCES Academics.Teachers(TeacherID),
	FOREIGN KEY (SubjectID) REFERENCES Academics.Subjects(SubjectID),
	PRIMARY KEY(TeacherID, SubjectID)
	)

CREATE TABLE Students.Grades (
	StudentID INT NOT NULL,
	TeacherID INT NOT NULL,
	SubjectID INT NOT NULL,
	GradeValue INT CHECK (GradeValue >= 1 AND GradeValue <= 6) NOT NULL,
	DateTime DATETIME NOT NULL,
	FOREIGN KEY (StudentID) REFERENCES Students.StudentInfo(StudentID),
	FOREIGN KEY (TeacherID) REFERENCES Academics.Teachers(TeacherID),
	FOREIGN KEY (SubjectID) REFERENCES Academics.Subjects(SubjectID),
	PRIMARY KEY (StudentID, TeacherID, SubjectID, DateTime)
	)

CREATE TABLE Students.Attendance (
	AttendanceID INT PRIMARY KEY IDENTITY(0,1),
	StudentID INT NOT NULL,
	AttendanceDate DATE NOT NULL,
	Status VARCHAR(10) CHECK (Status IN ('Present', 'Absent', 'Excused', 'Late')),
	SubjectID INT NOT NULL,
	FOREIGN KEY (StudentID) REFERENCES Students.StudentInfo(StudentID),
	FOREIGN KEY (SubjectID) REFERENCES Academics.Subjects(SubjectID)
)


CREATE TABLE Students.Parents(
	ParentID INT PRIMARY KEY IDENTITY(0,1),
	FirstName VARCHAR(50) NOT NULL,
	LastName VARCHAR(50) NOT NULL,
	PhoneNumber VARCHAR(10),
	EmailAddress VARCHAR(50),
	)

CREATE TABLE Students.StudentParents(
	StudentID INT NOT NULL,
	ParentID INT NOT NULL,
	FOREIGN KEY (StudentID) REFERENCES Students.StudentInfo(StudentID),
	FOREIGN KEY (ParentID) REFERENCES Students.Parents(ParentID),
	PRIMARY KEY (StudentID, ParentID)
)

CREATE TABLE Admins.Rooms (
	RoomNumber INT PRIMARY KEY NOT NULL,
	Capacity INT NOT NULL,
	RoomType VARCHAR(12) CHECK(RoomType IN ('Classroom', 'Gym', 'Auditorium')),
)

CREATE TABLE Students.StudentCouncil (
	StudentID INT PRIMARY KEY NOT NULL,
	Role VARCHAR(30) CHECK (Role IN ('President', 'Vice President', 'Treasurer', 'Secretary')) NOT NULL,
	FOREIGN KEY (StudentID) REFERENCES Students.StudentInfo(StudentID)
	)

CREATE TABLE Students.Societies (
	SocietyID INT PRIMARY KEY IDENTITY(0,1),
	SocietyName VARCHAR(50) NOT NULL,
	TutorID INT NOT NULL,
	FOREIGN KEY(TutorID) REFERENCES Academics.Teachers(TeacherID)
	)

CREATE TABLE Students.StudentSocieties
(
	SocietyID INT NOT NULL,
	StudentID INT NOT NULL,
	PRIMARY KEY (SocietyID, StudentID),
	FOREIGN KEY (SocietyID) REFERENCES Students.Societies(SocietyID),
	FOREIGN KEY (StudentID) REFERENCES Students.StudentInfo(StudentID)
);

CREATE TABLE Academics.ClassSchedule (
	ClassOneID INT NOT NULL,
	ClassTwoID INT NULL,
	SubjectID INT,
	TeacherID INT,
	Day DATE,
	StartTime TIME,
	EndTime TIME,
	RoomNumber INT,
	FOREIGN KEY (ClassOneID) REFERENCES Academics.Classes(ClassID),
	FOREIGN KEY (ClassTwoID) REFERENCES Academics.Classes(ClassID),
	FOREIGN KEY (SubjectID) REFERENCES Academics.Subjects(SubjectID),
	FOREIGN KEY(TeacherID) REFERENCES Academics.Teachers(TeacherID),
	PRIMARY KEY (Day, StartTime, EndTime, RoomNumber)
	)

CREATE TABLE Academics.LuckyRegisterNumber (
	Day DATE PRIMARY KEY NOT NULL,
	RegisterNumber INT NOT NULL
)

CREATE TABLE Admins.CurrentSchoolYear (
	SchoolYearID INT PRIMARY KEY,
	StartDate DATE,
	EndDate DATE
);

CREATE TABLE Students.BehaviorGrade(
	StudentID INT PRIMARY KEY,
	BehaviorGrade VARCHAR(20) DEFAULT 'Good' CHECK (BehaviorGrade IN ('Inadequate', 'Good', 'Outstanding'))
	FOREIGN KEY (StudentID) REFERENCES Students.StudentInfo(StudentID)
);
