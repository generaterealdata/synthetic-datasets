-- Synthetic Fleet GPS Tracking
-- Schema used to generate this dataset with GenerateRealData (https://www.generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE vehicles (
    vehicle_id   INTEGER PRIMARY KEY,
    plate_number VARCHAR(10) NOT NULL UNIQUE,
    vin          CHAR(17)    NOT NULL UNIQUE,
    make         VARCHAR(30) NOT NULL,
    model        VARCHAR(30) NOT NULL,
    model_year   INTEGER     NOT NULL,
    fuel_type    VARCHAR(10) NOT NULL CHECK (fuel_type IN ('diesel', 'petrol', 'electric', 'hybrid')),
    depot        VARCHAR(30) NOT NULL
);

CREATE TABLE drivers (
    driver_id  INTEGER PRIMARY KEY,
    full_name  VARCHAR(120) NOT NULL,
    license_no VARCHAR(20)  NOT NULL UNIQUE,
    hired_on   DATE         NOT NULL,
    rating     NUMERIC(2,1) NOT NULL CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE trips (
    trip_id      INTEGER PRIMARY KEY,
    vehicle_id   INTEGER      NOT NULL REFERENCES vehicles(vehicle_id),
    driver_id    INTEGER      NOT NULL REFERENCES drivers(driver_id),
    started_at   TIMESTAMP    NOT NULL,
    ping_count   INTEGER      NOT NULL,
    duration_min NUMERIC(6,1) NOT NULL,
    distance_km  NUMERIC(7,2) NOT NULL,
    stops        INTEGER      NOT NULL
);

CREATE TABLE pings (
    ping_id        INTEGER PRIMARY KEY,
    trip_id        INTEGER       NOT NULL REFERENCES trips(trip_id),
    recorded_at    TIMESTAMP     NOT NULL,
    latitude       NUMERIC(9,6)  NOT NULL,
    longitude      NUMERIC(9,6)  NOT NULL,
    speed_kmh      NUMERIC(5,1)  NOT NULL CHECK (speed_kmh >= 0),
    heading        CHAR(1)       NOT NULL CHECK (heading IN ('N', 'E', 'S', 'W')),
    heading_deg    INTEGER       NOT NULL CHECK (heading_deg IN (0, 90, 180, 270)),
    odometer_km    NUMERIC(10,3) NOT NULL,
    geofence_event VARCHAR(14)   NOT NULL CHECK (geofence_event IN ('none', 'depot_exit', 'customer_stop', 'school_zone', 'depot_enter'))
);
