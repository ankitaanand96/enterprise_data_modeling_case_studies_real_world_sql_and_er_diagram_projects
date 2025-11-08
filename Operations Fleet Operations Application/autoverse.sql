-- AutoVerse — Vehicle-Sharing & Fleet Ops

CREATE SCHEMA IF NOT EXISTS autoverse;
SET search_path TO autoverse, public;

-- 1) Users
CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  email VARCHAR(150) UNIQUE NOT NULL,
  full_name VARCHAR(120),
  phone VARCHAR(20),
  country_code CHAR(2),
  created_at TIMESTAMPTZ DEFAULT now(),
  status VARCHAR(16) DEFAULT 'active'
);

-- 2) Drivers
CREATE TABLE drivers (
  driver_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  license_no VARCHAR(40) UNIQUE NOT NULL,
  onboarded_at TIMESTAMPTZ DEFAULT now(),
  status VARCHAR(16) DEFAULT 'active',
  rating NUMERIC(3,2)
);

-- 3) DriverDocuments
CREATE TABLE driver_documents (
  doc_id SERIAL PRIMARY KEY,
  driver_id INT NOT NULL REFERENCES drivers(driver_id),
  doc_type VARCHAR(30),
  doc_number VARCHAR(60),
  issued_at DATE,
  expires_at DATE,
  verified BOOLEAN DEFAULT FALSE,
  uploaded_at TIMESTAMPTZ DEFAULT now()
);

-- 4) VehicleTypes
CREATE TABLE vehicle_types (
  vtype_id SERIAL PRIMARY KEY,
  name VARCHAR(40) NOT NULL,
  energy VARCHAR(10) NOT NULL,   -- ev|hybrid|ice
  seats INT DEFAULT 4
);

-- 5) Vehicles
CREATE TABLE vehicles (
  vehicle_id SERIAL PRIMARY KEY,
  vtype_id INT NOT NULL REFERENCES vehicle_types(vtype_id),
  registration_no VARCHAR(20) UNIQUE NOT NULL,
  make VARCHAR(60),
  model VARCHAR(60),
  make_year INT,
  color VARCHAR(30),
  current_mileage INT,
  city VARCHAR(60),
  status VARCHAR(20) DEFAULT 'available'  -- available|in_service|maintenance|retired
);

-- 6) VehicleInsurance
CREATE TABLE vehicle_insurance (
  policy_id SERIAL PRIMARY KEY,
  vehicle_id INT NOT NULL REFERENCES vehicles(vehicle_id),
  insurer_name VARCHAR(120),
  policy_no VARCHAR(60) UNIQUE,
  start_date DATE,
  end_date DATE,
  coverage_desc TEXT
);

-- 7) Bookings
CREATE TABLE bookings (
  booking_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  requested_at TIMESTAMPTZ DEFAULT now(),
  scheduled_at TIMESTAMPTZ,
  pickup_lat NUMERIC(10,6),
  pickup_lng NUMERIC(10,6),
  drop_lat NUMERIC(10,6),
  drop_lng NUMERIC(10,6),
  status VARCHAR(20) DEFAULT 'requested', -- requested|accepted|enroute|ongoing|completed|cancelled
  fare_estimate NUMERIC(10,2),
  surge_multiplier NUMERIC(5,2) DEFAULT 1.00
);

-- 8) Trips
CREATE TABLE trips (
  trip_id SERIAL PRIMARY KEY,
  booking_id INT NOT NULL REFERENCES bookings(booking_id),
  driver_id INT NOT NULL REFERENCES drivers(driver_id),
  vehicle_id INT NOT NULL REFERENCES vehicles(vehicle_id),
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  distance_km NUMERIC(8,2),
  duration_min NUMERIC(8,2),
  base_fare NUMERIC(10,2),
  time_fare NUMERIC(10,2),
  distance_fare NUMERIC(10,2),
  surge_fee NUMERIC(10,2),
  tax_amount NUMERIC(10,2),
  total_fare NUMERIC(10,2),
  payment_status VARCHAR(16) DEFAULT 'unpaid' -- unpaid|paid|refunded
);

-- 9) TelemetryEvents
CREATE TABLE telemetry_events (
  telemetry_id BIGSERIAL PRIMARY KEY,
  trip_id INT NOT NULL REFERENCES trips(trip_id),
  recorded_at TIMESTAMPTZ DEFAULT now(),
  lat NUMERIC(10,6),
  lng NUMERIC(10,6),
  speed_kmph NUMERIC(6,2),
  battery_pct INT,               -- nullable for ICE
  event_type VARCHAR(20)         -- gps|hard_brake|overspeed|idle
);

-- 10) Payments
CREATE TABLE payments (
  payment_id SERIAL PRIMARY KEY,
  trip_id INT NOT NULL REFERENCES trips(trip_id),
  user_id INT NOT NULL REFERENCES users(user_id),
  amount NUMERIC(10,2) NOT NULL,
  currency CHAR(3) DEFAULT 'INR',
  method VARCHAR(16),            -- card|wallet|upi|netbanking
  status VARCHAR(16) DEFAULT 'paid', -- paid|failed|refunded
  paid_at TIMESTAMPTZ DEFAULT now(),
  provider_txn_ref VARCHAR(80)
);

-- 11) Refunds
CREATE TABLE refunds (
  refund_id SERIAL PRIMARY KEY,
  payment_id INT NOT NULL REFERENCES payments(payment_id),
  amount NUMERIC(10,2) NOT NULL,
  reason VARCHAR(120),
  status VARCHAR(16) DEFAULT 'processed', -- processed|pending|failed
  processed_at TIMESTAMPTZ DEFAULT now()
);

-- 12) DriverPayouts
CREATE TABLE driver_payouts (
  payout_id SERIAL PRIMARY KEY,
  driver_id INT NOT NULL REFERENCES drivers(driver_id),
  period_start DATE,
  period_end DATE,
  gross_amount NUMERIC(12,2),
  commission_deduction NUMERIC(12,2),
  adjustments NUMERIC(12,2),
  net_amount NUMERIC(12,2),
  status VARCHAR(16) DEFAULT 'pending', -- pending|paid|failed
  paid_at TIMESTAMPTZ,
  reference_no VARCHAR(80)
);

-- 13) MaintenanceRecords
CREATE TABLE maintenance_records (
  maint_id SERIAL PRIMARY KEY,
  vehicle_id INT NOT NULL REFERENCES vehicles(vehicle_id),
  service_date DATE,
  service_type VARCHAR(40),      -- periodic|repair|tyres|battery
  odometer_km INT,
  cost NUMERIC(10,2),
  vendor VARCHAR(120),
  notes VARCHAR(300)
);

-- 14) Incidents
CREATE TABLE incidents (
  incident_id SERIAL PRIMARY KEY,
  trip_id INT REFERENCES trips(trip_id),
  reported_by_user_id INT REFERENCES users(user_id),
  reported_by_driver_id INT REFERENCES drivers(driver_id),
  incident_type VARCHAR(20),     -- accident|complaint|lost_item|safety
  description TEXT,
  reported_at TIMESTAMPTZ DEFAULT now(),
  status VARCHAR(16) DEFAULT 'open',  -- open|investigating|resolved|closed
  resolution_notes TEXT
);

-- 15) SupportTickets
CREATE TABLE support_tickets (
  ticket_id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(user_id),
  trip_id INT REFERENCES trips(trip_id),
  category VARCHAR(20),          -- billing|tech|safety|general
  opened_at TIMESTAMPTZ DEFAULT now(),
  resolved_at TIMESTAMPTZ,
  status VARCHAR(16) DEFAULT 'open',
  notes TEXT
);

-- 16) Ratings
CREATE TABLE ratings (
  rating_id SERIAL PRIMARY KEY,
  trip_id INT NOT NULL REFERENCES trips(trip_id),
  rater_user_id INT NOT NULL REFERENCES users(user_id),
  target_type VARCHAR(10),       -- driver|vehicle|overall
  score INT,                     -- 1..5
  comment VARCHAR(300),
  rated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (trip_id, rater_user_id, target_type)
);

-- 17) ChargingStations
CREATE TABLE charging_stations (
  station_id SERIAL PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  operator VARCHAR(120),
  city VARCHAR(60),
  lat NUMERIC(10,6),
  lng NUMERIC(10,6),
  connectors VARCHAR(80)         -- ccs2|chademo|type2
);

-- 18) ChargingSessions
CREATE TABLE charging_sessions (
  session_id SERIAL PRIMARY KEY,
  vehicle_id INT NOT NULL REFERENCES vehicles(vehicle_id),
  station_id INT NOT NULL REFERENCES charging_stations(station_id),
  start_at TIMESTAMPTZ DEFAULT now(),
  end_at TIMESTAMPTZ,
  kwh_consumed NUMERIC(10,3),
  cost_amount NUMERIC(10,2),
  cost_currency CHAR(3) DEFAULT 'INR',
  energy_source VARCHAR(10)      -- grid|green
);

-- 19) Plans
CREATE TABLE plans (
  plan_id SERIAL PRIMARY KEY,
  name VARCHAR(60) NOT NULL,
  monthly_fee NUMERIC(10,2) NOT NULL,
  currency CHAR(3) DEFAULT 'INR',
  perks TEXT,
  active BOOLEAN DEFAULT TRUE
);

-- 20) Subscriptions
CREATE TABLE subscriptions (
  sub_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  plan_id INT NOT NULL REFERENCES plans(plan_id),
  start_date DATE NOT NULL,
  end_date DATE,
  auto_renew BOOLEAN DEFAULT TRUE,
  status VARCHAR(16) DEFAULT 'active', -- active|cancelled|expired|paused
  last_renewal_at TIMESTAMPTZ
);
