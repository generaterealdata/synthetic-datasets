# Synthetic Smart Meter Readings (15-Minute Intervals)

**500K interval readings from 100 homes and businesses with solar and EVs.**

One hundred homes and small businesses in one city, each with a smart meter read every 15 minutes for 52 days from 1 August 2026. That is 4,998 consecutive readings per meter with no gaps and no repeats: energy taken from the grid, energy exported by rooftop solar, voltage, the time-of-use rate and the cost of every interval.

| | |
|---|---|
| Tables | 3 |
| Rows | 500,000 |
| Full data | Kaggle (coming soon): CSV files and a SQLite database |
| Sample in this folder | [`sample/`](sample/), a connected slice of up to 1,000 rows per table |
| Licence | [CC BY 4.0](../LICENSE): free to use, share and adapt, with credit |
| Made with | [GenerateRealData](https://generaterealdata.com/industries/energy-utilities/), fully synthetic, no real records |

## What makes it useful

- A complete, regular time series: every meter has exactly 4,998 readings, exactly 15 minutes apart.
- Daily load shapes: homes are quiet overnight, pick up in the morning and peak from 17:00 to 21:00; small businesses use most in working hours; each meter moves between levels gradually rather than in steps.
- Realistic amounts: about 35 kWh a day for a house, 20 for an apartment and 58 for a small business; electric cars charge from 22:00 to about 02:00.
- Solar behaves like solar: only premises with panels export, only between 07:00 and 19:00, peaking around noon, and panels cut the grid power a house draws at midday by about three quarters.
- Billing is exact: the rate is 0.38 in the 17:00-21:00 peak and 0.24 otherwise, and cost = import x rate in every row.

**Good for:** Time-series analysis and forecasting practice; Testing metering, billing and energy dashboards; Load-profile clustering (home, business, EV, solar); SQL practice with window functions on timestamps.

## Tables

```mermaid
erDiagram
    premises ||--o| meters : premise_id
    meters ||--o{ readings : meter_id
```

| Table | Rows | What it holds |
|---|---:|---|
| `premises` | 100 | The 100 metered buildings. |
| `meters` | 100 | Exactly one meter per premise. |
| `readings` | 499,800 | One row per meter per 15-minute interval. |

## Rules you can rely on

20 rules were checked on the full dataset and all 20 hold. Each rule is a query that counts the rows breaking it, and every count is 0. The queries are in [`checks.sql`](checks.sql).

- premises.premise_id is unique
- meters.meter_id is unique
- meters.meter_serial is unique
- meters.premise_id is unique
- readings.reading_id is unique
- Every meters.premise_id exists in premises
- Every readings.meter_id exists in meters
- Every premise has a meter
- Tariff follows solar and EV
- Every meter has the same number of readings
- No meter has two readings for the same interval
- Readings are exactly 15 minutes apart with no gaps
- Rate is 0.38 at peak and 0.24 otherwise
- Cost = import x rate
- Import and export are within range
- Peak is exactly 17:00 to 21:00
- Homes use at least three times more in the evening peak than overnight
- Only solar premises export, and only between 07:00 and 19:00
- Businesses use more in working hours than at night
- Voltage stays between 228 and 252

## Column dictionary

The last column is measured from the data.

### `premises` (100 rows)

The 100 metered buildings.

| Column | Type | Meaning | In this dataset |
|---|---|---|---|
| `premise_id` (PK) | INTEGER | Premise number (primary key). | 1 to 100 |
| `address` | VARCHAR(120) | Street address (invented). | 100 different values, e.g. `426 Clark Fort` |
| `city` | VARCHAR(80) | Always Fort Collins. | `Fort Collins` 100% |
| `postcode` | VARCHAR(12) | One of five Fort Collins ZIP codes. | `80526` 25%, `80524` 24%, `80528` 22%, `80521` 16%, `80525` 13% |
| `premise_type` | VARCHAR(14) | house, apartment or small_business. | `house` 61%, `apartment` 30%, `small_business` 9% |
| `has_solar` | BOOLEAN | Whether the premise has rooftop solar (1 = yes). | `0` 69%, `1` 31% |
| `has_ev` | BOOLEAN | Whether the premise charges an electric vehicle (1 = yes). | `0` 73%, `1` 27% |

### `meters` (100 rows)

Exactly one meter per premise.

| Column | Type | Meaning | In this dataset |
|---|---|---|---|
| `meter_id` (PK) | INTEGER | Meter number (primary key). | 1 to 100 |
| `premise_id` → `premises.premise_id` | INTEGER | The premise the meter serves (each appears once). | 1 to 100 |
| `meter_serial` | VARCHAR(16) | Unique serial number, SM-000001 onwards. | 100 different values, e.g. `SM-000005` |
| `tariff_code` | VARCHAR(10) | TOU-SOLAR if the premise has solar, else TOU-EV if it has an EV, else TOU-STD. | `TOU-STD` 48%, `TOU-SOLAR` 31%, `TOU-EV` 21% |
| `installed_on` | DATE | Installation date. | 2019-01-20 to 2025-12-27 |

### `readings` (499,800 rows)

One row per meter per 15-minute interval.

| Column | Type | Meaning | In this dataset |
|---|---|---|---|
| `reading_id` (PK) | INTEGER | Reading number (primary key). | 1 to 499,800 |
| `meter_id` → `meters.meter_id` | INTEGER | The meter read. | 1 to 100 |
| `interval_start` | TIMESTAMP | Start of the 15-minute interval. | 2026-08-01 00:00:00 to 2026-09-22 01:15:00 |
| `import_kwh` | NUMERIC(8,3) | Energy taken from the grid in the interval, in kWh. | 0.02 to 2.2 |
| `export_kwh` | NUMERIC(8,3) | Energy sent to the grid in the interval, in kWh; above 0 only for solar premises in daylight. | 0 to 0.8 |
| `voltage_v` | NUMERIC(5,1) | Supply voltage in volts; drifts around 240. | 236 to 243.8 |
| `is_peak` | BOOLEAN | 1 from 17:00 up to 21:00, otherwise 0. | `0` 83.4%, `1` 16.6% |
| `rate_per_kwh` | NUMERIC(5,2) | Price per kWh: 0.38 at peak, 0.24 otherwise. | `0.24` 83.4%, `0.38` 16.6% |
| `cost` | NUMERIC(8,2) | import_kwh x rate_per_kwh, rounded to cents. | 0 to 0.59 |

## Questions to try

**Average load by hour of day for homes and businesses**

```sql
SELECT CAST(strftime('%H', r.interval_start) AS INTEGER) AS hour,
       ROUND(AVG(CASE WHEN p.premise_type <> 'small_business' THEN r.import_kwh END), 3) AS home_kwh,
       ROUND(AVG(CASE WHEN p.premise_type = 'small_business' THEN r.import_kwh END), 3) AS business_kwh
FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id)
GROUP BY hour ORDER BY hour;
```

**Daily energy and cost per premise type**

```sql
SELECT p.premise_type, ROUND(SUM(r.import_kwh) / COUNT(DISTINCT date(r.interval_start)) / COUNT(DISTINCT r.meter_id), 2) AS kwh_per_meter_per_day,
       ROUND(SUM(r.cost) / COUNT(DISTINCT date(r.interval_start)) / COUNT(DISTINCT r.meter_id), 2) AS cost_per_meter_per_day
FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id)
GROUP BY p.premise_type;
```

**What share of energy and of the bill falls in the peak window?**

```sql
SELECT ROUND(100.0 * SUM(CASE WHEN is_peak = 1 THEN import_kwh END) / SUM(import_kwh), 1) AS peak_share_of_kwh,
       ROUND(100.0 * SUM(CASE WHEN is_peak = 1 THEN cost END) / SUM(cost), 1) AS peak_share_of_cost
FROM readings;
```

Seven more are in [`questions.sql`](questions.sql). All ten run as written on the SQLite file.

## Good to know

- Meters of the same kind follow one shared daily pattern: small businesses in particular are near-identical, and every electric car starts charging at 22:00 every night.
- There is no weekday/weekend, weather or seasonal effect, and solar output does not depend on the day.
- The series ends at 01:15 on 22 September 2026 (4,998 intervals).
- Street addresses are invented.
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
| `sample/` | `premises.csv` 5 rows; `meters.csv` 5 rows; `readings.csv` 960 rows |

## Re-create it

The dataset is reproducible. With a GenerateRealData API key, [`scripts/recreate.py`](../scripts/recreate.py) sends `plan.json`, `schema.sql` and the seed `20261106` to the API and downloads the same data:

```bash
python scripts/recreate.py smart-meter-readings
```

To build your own version, change the row counts or rules, or start from your own schema: [generaterealdata.com/industries/energy-utilities/](https://generaterealdata.com/industries/energy-utilities/).

## How it was made

Fully synthetic: generated with [GenerateRealData](https://generaterealdata.com/industries/energy-utilities/) from a database schema and a set of rules, using a fixed seed. No real person, company or transaction is in the data, and no value was edited after generation. No field was written by AI. 

## Licence

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Use it for anything, including commercial work; please credit "Synthetic Smart Meter Readings (15-Minute Intervals), GenerateRealData" with a link to https://generaterealdata.com.
