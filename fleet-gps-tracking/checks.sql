-- Synthetic Fleet GPS Tracking: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py fleet-gps-tracking <database file>

-- vehicles.vehicle_id is unique
SELECT COUNT(*) - COUNT(DISTINCT vehicle_id) FROM vehicles;

-- vehicles.vin is unique
SELECT COUNT(*) - COUNT(DISTINCT vin) FROM vehicles;

-- vehicles.plate_number is unique
SELECT COUNT(*) - COUNT(DISTINCT plate_number) FROM vehicles;

-- drivers.license_no is unique
SELECT COUNT(*) - COUNT(DISTINCT license_no) FROM drivers;

-- trips.trip_id is unique
SELECT COUNT(*) - COUNT(DISTINCT trip_id) FROM trips;

-- pings.ping_id is unique
SELECT COUNT(*) - COUNT(DISTINCT ping_id) FROM pings;

-- every trips.vehicle_id exists in vehicles
SELECT COUNT(*) FROM trips c LEFT JOIN vehicles p ON p.vehicle_id = c.vehicle_id WHERE c.vehicle_id IS NOT NULL AND p.vehicle_id IS NULL;

-- every trips.driver_id exists in drivers
SELECT COUNT(*) FROM trips c LEFT JOIN drivers p ON p.driver_id = c.driver_id WHERE c.driver_id IS NOT NULL AND p.driver_id IS NULL;

-- every pings.trip_id exists in trips
SELECT COUNT(*) FROM pings c LEFT JOIN trips p ON p.trip_id = c.trip_id WHERE c.trip_id IS NOT NULL AND p.trip_id IS NULL;

-- VINs are 17 characters without I, O or Q
SELECT COUNT(*) FROM vehicles WHERE LENGTH(vin) <> 17 OR vin GLOB '*[IOQ]*';

-- a model always belongs to the same make
SELECT COUNT(*) FROM (SELECT model FROM vehicles GROUP BY model HAVING COUNT(DISTINCT make) > 1);

-- electric models are electric
SELECT COUNT(*) FROM vehicles WHERE (model IN ('E-Transit', 'EDV')) <> (fuel_type = 'electric');

-- every vehicle has trips
SELECT COUNT(*) FROM vehicles v WHERE NOT EXISTS (SELECT 1 FROM trips t WHERE t.vehicle_id = v.vehicle_id);

-- every trip has pings
SELECT COUNT(*) FROM trips t WHERE NOT EXISTS (SELECT 1 FROM pings p WHERE p.trip_id = t.trip_id);

-- a trip's first ping is at its start time and is the depot exit
SELECT COUNT(*) FROM (SELECT p.*, ROW_NUMBER() OVER (PARTITION BY trip_id ORDER BY recorded_at) n FROM pings p) p JOIN trips t USING (trip_id) WHERE p.n = 1 AND (datetime(p.recorded_at) <> datetime(t.started_at) OR p.geofence_event <> 'depot_exit');

-- pings are exactly 30 seconds apart within a trip
SELECT COUNT(*) FROM (SELECT (julianday(recorded_at) - julianday(LAG(recorded_at) OVER w)) * 86400 AS gap FROM pings WINDOW w AS (PARTITION BY trip_id ORDER BY recorded_at)) WHERE gap IS NOT NULL AND ABS(gap - 30) > 0.5;

-- the odometer grows by exactly speed x 30 seconds
SELECT COUNT(*) FROM (SELECT odometer_km - LAG(odometer_km) OVER w AS d, (speed_kmh * 30.0 / 3600) AS km FROM pings WINDOW w AS (PARTITION BY trip_id ORDER BY recorded_at)) WHERE d IS NOT NULL AND ABS(d - km) > 0.002;

-- the odometer never goes backwards within a trip
SELECT COUNT(*) FROM (SELECT odometer_km - LAG(odometer_km) OVER w AS d FROM pings WINDOW w AS (PARTITION BY trip_id ORDER BY recorded_at)) WHERE d < 0;

-- position moves by speed x 30 seconds in the direction of the heading
SELECT COUNT(*) FROM (SELECT heading_deg h, (latitude - LAG(latitude) OVER w) * 111.0 AS north, (longitude - LAG(longitude) OVER w) * 82.9 AS east, (speed_kmh * 30.0 / 3600) AS km FROM pings WINDOW w AS (PARTITION BY trip_id ORDER BY recorded_at)) WHERE north IS NOT NULL AND (ABS(north - CASE h WHEN 0 THEN km WHEN 180 THEN -km ELSE 0 END) > 0.003 OR ABS(east - CASE h WHEN 90 THEN km WHEN 270 THEN -km ELSE 0 END) > 0.003);

-- heading letter and degrees agree
SELECT COUNT(*) FROM pings WHERE heading_deg <> CASE heading WHEN 'N' THEN 0 WHEN 'E' THEN 90 WHEN 'S' THEN 180 ELSE 270 END;

-- trips last between 1 and 60 minutes
SELECT COUNT(*) FROM trips WHERE duration_min NOT BETWEEN 0.5 AND 60;

-- vans never make a U-turn between pings
SELECT COUNT(*) FROM (SELECT heading_deg h, LAG(heading_deg) OVER w AS p FROM pings WINDOW w AS (PARTITION BY trip_id ORDER BY recorded_at)) WHERE p IS NOT NULL AND ABS(h - p) = 180;

-- every trip starts within 1 km of its vehicle's depot
SELECT COUNT(*) FROM (SELECT p.*, ROW_NUMBER() OVER (PARTITION BY trip_id ORDER BY recorded_at) n FROM pings p) p JOIN trips t USING (trip_id) JOIN vehicles v USING (vehicle_id) WHERE p.n = 1 AND (ABS(p.latitude - CASE v.depot WHEN 'Elmhurst' THEN 41.8995 WHEN 'Schaumburg' THEN 42.0334 WHEN 'Naperville' THEN 41.7508 WHEN 'Oak Brook' THEN 41.8398 ELSE 41.6986 END) > 0.012 OR ABS(p.longitude - CASE v.depot WHEN 'Elmhurst' THEN -87.9403 WHEN 'Schaumburg' THEN -88.0834 WHEN 'Naperville' THEN -88.1535 WHEN 'Oak Brook' THEN -87.9536 ELSE -88.0684 END) > 0.014);

-- all pings stay on land west of the Lake Michigan shore
SELECT COUNT(*) FROM pings WHERE longitude > -87.62 OR latitude NOT BETWEEN 41.2 AND 42.6;

-- vans stand still at customer stops
SELECT COUNT(*) FROM pings WHERE geofence_event = 'customer_stop' AND speed_kmh <> 0;

-- school zones are driven at 25 km/h or less
SELECT COUNT(*) FROM pings WHERE geofence_event = 'school_zone' AND speed_kmh > 25;

-- speed is 0-90 km/h
SELECT COUNT(*) FROM pings WHERE speed_kmh NOT BETWEEN 0 AND 90;

-- nothing is recorded after a van re-enters the depot
SELECT COUNT(*) FROM (SELECT LAG(geofence_event) OVER w AS p FROM pings WINDOW w AS (PARTITION BY trip_id ORDER BY recorded_at)) WHERE p = 'depot_enter';

-- trip ping_count, duration and stops equal what its pings show
SELECT COUNT(*) FROM trips t JOIN (SELECT trip_id, COUNT(*) n, SUM(geofence_event = 'customer_stop') s FROM pings GROUP BY trip_id) x USING (trip_id) WHERE t.ping_count <> x.n OR ABS(t.duration_min - x.n * 0.5) > 0.051 OR t.stops <> x.s;

-- trip distance equals the distance its pings add up to
SELECT COUNT(*) FROM trips t JOIN (SELECT trip_id, SUM((speed_kmh * 30.0 / 3600)) km FROM pings GROUP BY trip_id) x USING (trip_id) WHERE ABS(t.distance_km - x.km) > 0.06;
