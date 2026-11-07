-- Student Performance and Lifestyle
-- Schema used to generate this dataset with GenerateRealData (https://www.generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE students (
    student_id                 VARCHAR(10)  PRIMARY KEY,
    grade_level                INTEGER      NOT NULL,
    age                        INTEGER      NOT NULL,
    gender                     VARCHAR(12)  NOT NULL,
    school_type                VARCHAR(10)  NOT NULL,
    school_location            VARCHAR(10)  NOT NULL,
    parental_education         VARCHAR(16)  NOT NULL,
    family_income              VARCHAR(8)   NOT NULL,
    internet_access            BOOLEAN      NOT NULL,
    distance_to_school_km      NUMERIC(5,1) NOT NULL,
    motivation_level           VARCHAR(8)   NOT NULL,
    study_hours_per_week       NUMERIC(4,1) NOT NULL,
    attendance_pct             NUMERIC(4,1) NOT NULL,
    part_time_job              BOOLEAN      NOT NULL,
    screen_time_hours_per_day  NUMERIC(4,1) NOT NULL,
    social_media_hours_per_day NUMERIC(4,1) NOT NULL,
    sleep_hours_per_night      NUMERIC(3,1) NOT NULL,
    physical_activity_hours_per_week NUMERIC(4,1) NOT NULL,
    extracurricular_activities INTEGER      NOT NULL,
    tutoring_sessions_per_month INTEGER     NOT NULL,
    teacher_quality            VARCHAR(8)   NOT NULL,
    peer_influence             VARCHAR(10)  NOT NULL,
    learning_disability        BOOLEAN      NOT NULL,
    stress_level               INTEGER      NOT NULL,
    previous_score             INTEGER      NOT NULL,
    exam_score                 INTEGER      NOT NULL,
    final_grade                CHAR(1)      NOT NULL,
    passed                     BOOLEAN      NOT NULL
);
