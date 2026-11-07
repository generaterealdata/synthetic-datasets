# Student Performance and Lifestyle

**102K high-school students: study, sleep, screen time, family and exam scores.**

> **Made with [GenerateRealData](https://www.generaterealdata.com?ref=github).** You can create your own realistic datasets like this one in minutes, from a single table to a full database with many linked tables. Just describe what you need in plain English, or upload your SQL schema. IDs match across tables, totals add up, and your business rules hold on every row. With 232 data types and 222 built-in generators, it has one of the largest libraries of any test data generator. **Try it free at [www.generaterealdata.com](https://www.generaterealdata.com?ref=github)**, or write to support@generaterealdata.com.

102,000 high-school students in grades 9 to 12, one row each. For every student the dataset records the school (type, location, teacher quality), the family (parents' education, income, internet at home, distance to school), daily life (study hours, attendance, a part-time job, screen time, social media, sleep, exercise, activities, tutoring), how they feel (motivation, stress, peer influence, learning disability) and the results: last year's score, this year's exam score, the letter grade and whether they passed.

| | |
|---|---|
| Tables | 1 |
| Rows | 102,000 |
| Full data | [Kaggle](https://www.kaggle.com/datasets/generaterealdata/student-performance-and-lifestyle): CSV files and a SQLite database |
| Sample in this folder | [`sample/`](sample/), a connected slice of up to 1,000 rows per table |
| Licence | [CC BY 4.0](../LICENSE): free to use, share and adapt, with credit |
| Made with | [GenerateRealData](https://www.generaterealdata.com/industries/education/?ref=github), a relational synthetic data generator with 232 data types and 222 built-in generators, one of the largest libraries of any test data generator; fully synthetic, no real records |

## What makes it useful

- 28 columns in one table, every one documented, with no missing values: ready for a first regression or classification project.
- An exam score you can learn: it builds on last year's score and moves with study time, attendance, sleep, tutoring, teachers, peers and motivation; heavy social media, stress, a learning disability and no internet pull it down; about +-8 points are left to chance. A gradient-boosting model reaches R-squared 0.87 on held-out students.
- Clear, measured gaps: highly motivated students average 78.6 against 62.1 for the least motivated, and students who sleep 9 hours average 73.7 against 66.0 for those who sleep 5.
- Inputs that hang together like real life: motivated students study 17 hours a week and unmotivated ones 7; part-time jobs are mostly in grades 11-12 and come with lower attendance and more stress; more screen time means less sleep; parents' education goes with family income and with last year's score.
- Grades A to F follow the exam score, and 80% pass (60 or more). 11 rules are checked with SQL and all hold.

**Good for:** Regression: predict the exam score; Classification: predict who passes; Exploratory analysis and teaching statistics; SQL practice with group by, bands and window functions; Feature importance, and why correlation is not causation.

## Tables

```mermaid
erDiagram
```

| Table | Rows | What it holds |
|---|---:|---|
| `students` | 102,000 | One row per student: the only table. |

## Rules you can rely on

11 rules were checked on the full dataset and all 11 hold. Each rule is a query that counts the rows breaking it, and every count is 0. The queries are in [`checks.sql`](checks.sql).

- students.student_id is unique
- Age is grade + 5 or grade + 6
- Distance to school fits the location
- Attendance is 50-100%
- Social media time is part of screen time
- Sleep is 4-10 hours
- Stress is 1-10
- Scores are 0-100
- The final grade follows the exam score (A 90+, B 80+, C 70+, D 60+, F below)
- Passed exactly when the exam score is 60 or more
- Study time is 0-40 hours a week

## Column dictionary

The last column is measured from the data.

### `students` (102,000 rows)

One row per student: the only table.

| Column | Type | Meaning | In this dataset |
|---|---|---|---|
| `student_id` (PK) | VARCHAR(10) | Student id, STU-000001 onwards (primary key). | STU-000001 to STU-102000 |
| `grade_level` | INTEGER | School grade, 9 to 12. | `12` 25.2%, `11` 25.1%, `10` 24.9%, `9` 24.7% |
| `age` | INTEGER | Age in years: grade + 5, or one year older for about 30% of students. | `17` 25.2%, `16` 25.2%, `15` 24.9%, `14` 17.2%, `18` 7.5% |
| `gender` | VARCHAR(12) | Female, Male or Non-binary. | `Female` 49.2%, `Male` 48.7%, `Non-binary` 2.1% |
| `school_type` | VARCHAR(10) | Public, Private or Charter. | `Public` 77.7%, `Private` 16.3%, `Charter` 6% |
| `school_location` | VARCHAR(10) | Urban, Suburban or Rural. | `Urban` 44.8%, `Suburban` 38.2%, `Rural` 17% |
| `parental_education` | VARCHAR(16) | Highest education of the parents: High school, Some college, Bachelor's, Master's or Doctorate. | `Bachelor's` 30%, `High school` 27.9%, `Some college` 22%, `Master's` 14.9%, `Doctorate` 5.1% |
| `family_income` | VARCHAR(8) | Low, Middle or High; higher when the parents have more education. | `Middle` 48.5%, `Low` 27.3%, `High` 24.2% |
| `internet_access` | BOOLEAN | 1 if the student has internet at home; less common in rural areas and low-income families. | `1` 92.4%, `0` 7.6% |
| `distance_to_school_km` | NUMERIC(5,1) | Distance from home to school in km: shortest in cities, up to 35 km in rural areas. | 0.3 to 35 |
| `motivation_level` | VARCHAR(8) | Low, Medium or High. | `Medium` 49.7%, `High` 25.2%, `Low` 25.1% |
| `study_hours_per_week` | NUMERIC(4,1) | Hours of study outside class per week; about 7 for low and 17 for high motivation. | 0 to 38.4 |
| `attendance_pct` | NUMERIC(4,1) | Share of school days attended, in percent; lower with a part-time job, low motivation or a long way to school. | 66.1 to 99 |
| `part_time_job` | BOOLEAN | 1 if the student has a part-time job; much more common in grades 11-12. | `0` 81.4%, `1` 18.6% |
| `screen_time_hours_per_day` | NUMERIC(4,1) | Hours of recreational screen time per day. | 0.5 to 12 |
| `social_media_hours_per_day` | NUMERIC(4,1) | The part of the screen time spent on social media, in hours per day. | 0.1 to 8.9 |
| `sleep_hours_per_night` | NUMERIC(3,1) | Hours of sleep per night; less with more screen time or a part-time job. | 4.8 to 9.7 |
| `physical_activity_hours_per_week` | NUMERIC(4,1) | Hours of exercise or sport per week. | 0 to 15 |
| `extracurricular_activities` | INTEGER | Number of clubs or activities, 0-4. | `1` 33.9%, `0` 30.1%, `2` 21.9%, `3` 10.1%, `4` 4% |
| `tutoring_sessions_per_month` | INTEGER | Private tutoring sessions per month, 0-8; more common at private schools. | `0` 62.6%, `2` 10.3%, `4` 9.9%, `1` 8.3%, `6` 5.1%, `8` 3.8% |
| `teacher_quality` | VARCHAR(8) | Low, Medium or High, as rated for the student's classes; higher on average at private schools. | `Medium` 54.9%, `High` 30%, `Low` 15.1% |
| `peer_influence` | VARCHAR(10) | Negative, Neutral or Positive influence of the student's friends on school work. | `Neutral` 50.2%, `Positive` 30%, `Negative` 19.8% |
| `learning_disability` | BOOLEAN | 1 if the student has a diagnosed learning disability. | `0` 93%, `1` 7% |
| `stress_level` | INTEGER | Self-reported stress, 1-10; higher with more study hours, a job and less sleep. | `4` 21.9%, `5` 20.1%, `3` 18.6%, `6` 13.2%, `2` 11.6%, `7` 6.4%, `1` 5.2%, `8` 2.3% and 2 more |
| `previous_score` | INTEGER | Score on last year's final exam, 0-100. | 36 to 100 |
| `exam_score` | INTEGER | Score on this year's final exam, 0-100. The column to predict. | 22 to 100 |
| `final_grade` | CHAR(1) | Letter grade from exam_score: A (90+), B (80+), C (70+), D (60+) or F. | `C` 27.7%, `D` 25.8%, `F` 20.1%, `B` 18.5%, `A` 8% |
| `passed` | BOOLEAN | 1 if exam_score is 60 or more. | `1` 79.9%, `0` 20.1% |

## Questions to try

**Average exam score and pass rate by grade level**

```sql
SELECT grade_level, COUNT(*) AS students, ROUND(AVG(exam_score), 1) AS avg_score, ROUND(100.0 * AVG(passed), 1) AS pass_rate_pct
FROM students GROUP BY grade_level ORDER BY grade_level;
```

**Does sleep matter? Exam score by hours of sleep**

```sql
SELECT CAST(sleep_hours_per_night AS INTEGER) AS sleep_hours, COUNT(*) AS students, ROUND(AVG(exam_score), 1) AS avg_score
FROM students GROUP BY sleep_hours ORDER BY sleep_hours;
```

**Exam score by weekly study hours, in bands of five**

```sql
SELECT (CAST(study_hours_per_week AS INTEGER) / 5) * 5 AS study_hours_from, COUNT(*) AS students, ROUND(AVG(exam_score), 1) AS avg_score
FROM students GROUP BY study_hours_from ORDER BY study_hours_from;
```

Seven more are in [`questions.sql`](questions.sql). All ten run as written on the SQLite file.

## Good to know

- The exam score is built from the factors listed above plus chance, so a model learns exactly those; use the dataset to practise, not as evidence about real students.
- final_grade and passed are calculated from exam_score, so they give it away: drop both when predicting the score.
- last year's score (previous_score) depends only on parents' education, family income and chance.
- Screen time affects the exam only through sleep and social media; gender, school type and school location have no direct effect, so any gap you find there comes from the other columns.
- There is one exam per student and no school or class identifier, so students cannot be grouped by school.
- Yes/no columns hold 1 and 0. Empty cells in the CSV files mean no value (NULL in the database files).
- The CSV files are UTF-8. Dates are `YYYY-MM-DD` and timestamps `YYYY-MM-DD HH:MM:SS`.

## Files

| File | What it is |
|---|---|
| `schema.sql` | The `CREATE TABLE` statements (PostgreSQL syntax) the data was generated from |
| `generation.json` | Settings of the run: seed, rows per table, options |
| `plan.json` | The full generation plan: one rule set per column |
| `checks.sql` | One query per rule above; each returns 0 on the full dataset |
| `questions.sql` | Ten practice questions with their queries |
| `sample/` | `students.csv` 1,000 rows |

## Re-create it

The dataset is reproducible. With a GenerateRealData API key, [`scripts/recreate.py`](../scripts/recreate.py) sends `plan.json`, `schema.sql` and the seed `20261414` to the API and downloads the same data:

```bash
python scripts/recreate.py student-performance
```

To build your own version, change the row counts or rules, or start from your own schema: [www.generaterealdata.com/industries/education/](https://www.generaterealdata.com/industries/education/?ref=github).

## How it was made

Fully synthetic: generated with [GenerateRealData](https://www.generaterealdata.com/industries/education/?ref=github) from a database schema and a set of rules, using a fixed seed. No real person, company or transaction is in the data, and no value was edited after generation. No field was written by AI. 

## Licence

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Use it for anything, including commercial work; please credit "Student Performance and Lifestyle, GenerateRealData" with a link to https://www.generaterealdata.com.
