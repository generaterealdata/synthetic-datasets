-- Screen Time, Sleep and Mental Health
-- Schema used to generate this dataset with GenerateRealData (https://www.generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE people (
    person_id            INTEGER      PRIMARY KEY,
    age                  INTEGER      NOT NULL,
    gender               VARCHAR(12)  NOT NULL,
    country              VARCHAR(20)  NOT NULL,
    occupation           VARCHAR(24)  NOT NULL,
    chronotype           VARCHAR(14)  NOT NULL,
    has_children         BOOLEAN      NOT NULL,
    fitness_level        VARCHAR(8)   NOT NULL,
    typical_screen_hours NUMERIC(4,1) NOT NULL,
    diagnosed_anxiety    BOOLEAN      NOT NULL
);

CREATE TABLE daily_logs (
    log_id                    INTEGER      PRIMARY KEY,
    person_id                 INTEGER      NOT NULL REFERENCES people(person_id),
    log_date                  DATE         NOT NULL,
    day_of_week               VARCHAR(10)  NOT NULL,
    is_weekend                BOOLEAN      NOT NULL,
    age                       INTEGER      NOT NULL,
    gender                    VARCHAR(12)  NOT NULL,
    occupation                VARCHAR(24)  NOT NULL,
    chronotype                VARCHAR(14)  NOT NULL,
    has_children              BOOLEAN      NOT NULL,
    fitness_level             VARCHAR(8)   NOT NULL,
    diagnosed_anxiety         BOOLEAN      NOT NULL,
    work_hours                NUMERIC(4,1) NOT NULL,
    screen_time_hours         NUMERIC(4,1) NOT NULL,
    social_media_minutes      INTEGER      NOT NULL,
    screen_after_10pm_minutes INTEGER      NOT NULL,
    caffeine_mg               INTEGER      NOT NULL,
    alcohol_units             INTEGER      NOT NULL,
    exercise_minutes          INTEGER      NOT NULL,
    steps                     INTEGER      NOT NULL,
    outdoor_minutes           INTEGER      NOT NULL,
    bedtime_hour              NUMERIC(4,2) NOT NULL,
    sleep_hours               NUMERIC(3,1) NOT NULL,
    sleep_quality             INTEGER      NOT NULL,
    mood_score                INTEGER      NOT NULL,
    stress_level              INTEGER      NOT NULL,
    productivity_score        INTEGER      NOT NULL
);
