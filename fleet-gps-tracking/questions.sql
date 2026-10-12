-- Synthetic Fleet GPS Tracking: ten practice questions.
-- Written for SQLite (fleet_gps_tracking.sqlite); most run unchanged on PostgreSQL.

-- 1. Trips, distance and driving time per depot
SELECT v.depot, COUNT(*) AS trips, ROUND(SUM(t.distance_km), 1) AS km, ROUND(SUM(t.duration_min) / 60, 1) AS hours
FROM trips t JOIN vehicles v USING (vehicle_id) GROUP BY v.depot ORDER BY km DESC;

-- 2. Average speed by hour of day
SELECT CAST(strftime('%H', recorded_at) AS INTEGER) AS hour, ROUND(AVG(speed_kmh), 1) AS avg_speed_kmh, COUNT(*) AS pings
FROM pings GROUP BY hour ORDER BY hour;

-- 3. The ten longest trips
SELECT t.trip_id, v.model, d.full_name AS driver, t.duration_min, t.distance_km, t.stops
FROM trips t JOIN vehicles v USING (vehicle_id) JOIN drivers d USING (driver_id)
ORDER BY t.distance_km DESC LIMIT 10;

-- 4. Rebuild trip distance from the pings and compare with the trip table
SELECT t.trip_id, t.distance_km, ROUND(SUM(p.speed_kmh * 30.0 / 3600), 2) AS from_pings
FROM trips t JOIN pings p USING (trip_id) GROUP BY t.trip_id ORDER BY t.trip_id LIMIT 10;

-- 5. Distance between consecutive pings from coordinates (window function)
SELECT ping_id, recorded_at, speed_kmh,
       ROUND(111.0 * ABS(latitude - LAG(latitude) OVER w) + 82.9 * ABS(longitude - LAG(longitude) OVER w), 3) AS km_moved,
       ROUND(speed_kmh * 30.0 / 3600, 3) AS km_expected
FROM pings WHERE trip_id = 1
WINDOW w AS (ORDER BY recorded_at) ORDER BY recorded_at LIMIT 12;

-- 6. Speeding: share of pings above 70 km/h per driver
SELECT d.driver_id, d.full_name, COUNT(*) AS pings, ROUND(100.0 * SUM(p.speed_kmh > 70) / COUNT(*), 2) AS pct_over_70
FROM pings p JOIN trips t USING (trip_id) JOIN drivers d USING (driver_id)
GROUP BY d.driver_id ORDER BY pct_over_70 DESC LIMIT 10;

-- 7. School-zone compliance
SELECT COUNT(*) AS school_zone_pings, ROUND(AVG(speed_kmh), 1) AS avg_speed, MAX(speed_kmh) AS max_speed
FROM pings WHERE geofence_event = 'school_zone';

-- 8. Fleet use: trips and kilometres per vehicle
SELECT v.vehicle_id, v.make || ' ' || v.model AS van, v.fuel_type, COUNT(*) AS trips, ROUND(SUM(t.distance_km), 1) AS km
FROM trips t JOIN vehicles v USING (vehicle_id) GROUP BY v.vehicle_id ORDER BY km DESC LIMIT 10;

-- 9. How far from its depot does each trip get?
SELECT t.trip_id, ROUND(MAX(111.0 * ABS(p.latitude - f.latitude) + 82.9 * ABS(p.longitude - f.longitude)), 2) AS max_grid_km_from_start
FROM trips t JOIN pings p USING (trip_id)
JOIN (SELECT trip_id, latitude, longitude FROM pings WHERE geofence_event = 'depot_exit') f USING (trip_id)
GROUP BY t.trip_id ORDER BY max_grid_km_from_start DESC LIMIT 10;

-- 10. Kilometres by fuel type
SELECT v.fuel_type, COUNT(DISTINCT v.vehicle_id) AS vehicles, ROUND(SUM(t.distance_km), 1) AS km,
       ROUND(SUM(t.distance_km) / COUNT(DISTINCT v.vehicle_id), 1) AS km_per_vehicle
FROM trips t JOIN vehicles v USING (vehicle_id) GROUP BY v.fuel_type;
