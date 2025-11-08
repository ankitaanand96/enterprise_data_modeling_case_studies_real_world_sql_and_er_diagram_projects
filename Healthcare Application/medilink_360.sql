-- MediLink 360 — Tele-Health & Insurance Ecosystem

CREATE SCHEMA IF NOT EXISTS medilink360;
SET search_path TO medilink360, public;

-- 1) Patients
CREATE TABLE patients (
  patient_id   SERIAL PRIMARY KEY,
  full_name    VARCHAR(160) NOT NULL,
  email        VARCHAR(150) UNIQUE,
  phone        VARCHAR(20),
  dob          DATE,
  gender       VARCHAR(16),
  country_code CHAR(2),
  created_at   TIMESTAMPTZ DEFAULT now(),
  kyc_status   VARCHAR(16) DEFAULT 'pending'
);

-- 5) Hospitals
CREATE TABLE hospitals (
  hospital_id   SERIAL PRIMARY KEY,
  name          VARCHAR(180) NOT NULL,
  accreditation VARCHAR(80),
  country_code  CHAR(2),
  city          VARCHAR(100),
  contact_email VARCHAR(150),
  onboarded_at  TIMESTAMPTZ DEFAULT now()
);

-- 2) Doctors  (FK: hospital_id -> hospitals.hospital_id)
CREATE TABLE doctors (
  doctor_id         SERIAL PRIMARY KEY,
  full_name         VARCHAR(160) NOT NULL,
  license_no        VARCHAR(60) UNIQUE NOT NULL,
  primary_specialty VARCHAR(80),
  contact_email     VARCHAR(150),
  rating            NUMERIC(3,2),
  hospital_id       INT REFERENCES hospitals(hospital_id),
  active            BOOLEAN DEFAULT TRUE
);

-- 3) Specialties
CREATE TABLE specialties (
  spec_id SERIAL PRIMARY KEY,
  name    VARCHAR(120) UNIQUE NOT NULL
);

-- 4) DoctorSpecialties (composite PK)
CREATE TABLE doctor_specialties (
  doctor_id INT NOT NULL REFERENCES doctors(doctor_id),
  spec_id   INT NOT NULL REFERENCES specialties(spec_id),
  added_at  TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (doctor_id, spec_id)
);

-- 6) Appointments
CREATE TABLE appointments (
  appointment_id SERIAL PRIMARY KEY,
  patient_id     INT NOT NULL REFERENCES patients(patient_id),
  doctor_id      INT NOT NULL REFERENCES doctors(doctor_id),
  scheduled_at   TIMESTAMPTZ NOT NULL,
  mode           VARCHAR(16)  DEFAULT 'tele',       -- tele|inperson
  status         VARCHAR(20)  DEFAULT 'booked',     -- booked|completed|cancelled|no_show
  notes          VARCHAR(300),
  hospital_id    INT REFERENCES hospitals(hospital_id)
);

-- 7) Consultations
CREATE TABLE consultations (
  consult_id     SERIAL PRIMARY KEY,
  appointment_id INT NOT NULL REFERENCES appointments(appointment_id),
  doctor_id      INT NOT NULL REFERENCES doctors(doctor_id),
  patient_id     INT NOT NULL REFERENCES patients(patient_id),
  consult_time   TIMESTAMPTZ DEFAULT now(),
  diagnosis_codes TEXT,
  summary_text    TEXT
);

-- 9) Medications
CREATE TABLE medications (
  med_id        SERIAL PRIMARY KEY,
  generic_name  VARCHAR(160) NOT NULL,
  brand_name    VARCHAR(160),
  strength      VARCHAR(60),
  form          VARCHAR(40)         -- tablet|syrup|capsule|inj
);

-- 8) Prescriptions
CREATE TABLE prescriptions (
  presc_id   SERIAL PRIMARY KEY,
  consult_id INT NOT NULL REFERENCES consultations(consult_id),
  doctor_id  INT NOT NULL REFERENCES doctors(doctor_id),
  patient_id INT NOT NULL REFERENCES patients(patient_id),
  issued_at  TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ,
  status     VARCHAR(16) DEFAULT 'active' -- active|expired|cancelled
);

-- 10) PrescriptionItems
CREATE TABLE prescription_items (
  presc_item_id SERIAL PRIMARY KEY,
  presc_id      INT NOT NULL REFERENCES prescriptions(presc_id),
  med_id        INT NOT NULL REFERENCES medications(med_id),
  dosage        VARCHAR(80),      -- e.g., 1-0-1
  duration_days INT,
  instructions  VARCHAR(200)
);

-- 11) Labs
CREATE TABLE labs (
  lab_id        SERIAL PRIMARY KEY,
  name          VARCHAR(180) NOT NULL,
  country_code  CHAR(2),
  city          VARCHAR(100),
  contact_email VARCHAR(150),
  onboarded_at  TIMESTAMPTZ DEFAULT now()
);

-- 12) LabRequests
CREATE TABLE lab_requests (
  labreq_id      SERIAL PRIMARY KEY,
  consult_id     INT NOT NULL REFERENCES consultations(consult_id),
  patient_id     INT NOT NULL REFERENCES patients(patient_id),
  lab_id         INT NOT NULL REFERENCES labs(lab_id),
  requested_tests TEXT,
  requested_at   TIMESTAMPTZ DEFAULT now(),
  status         VARCHAR(20) DEFAULT 'requested'  -- requested|sample_collected|reported|cancelled
);

-- 13) LabResults
CREATE TABLE lab_results (
  result_id    SERIAL PRIMARY KEY,
  labreq_id    INT NOT NULL REFERENCES lab_requests(labreq_id),
  test_name    VARCHAR(160),
  result_value VARCHAR(80),
  units        VARCHAR(40),
  normal_range VARCHAR(80),
  reported_at  TIMESTAMPTZ,
  report_url   VARCHAR(300)
);

-- 14) Pharmacies
CREATE TABLE pharmacies (
  pharmacy_id   SERIAL PRIMARY KEY,
  name          VARCHAR(180) NOT NULL,
  country_code  CHAR(2),
  city          VARCHAR(100),
  contact_email VARCHAR(150),
  onboarded_at  TIMESTAMPTZ DEFAULT now()
);

-- 15) PharmacyOrders
CREATE TABLE pharmacy_orders (
  order_id            SERIAL PRIMARY KEY,
  patient_id          INT NOT NULL REFERENCES patients(patient_id),
  presc_id            INT REFERENCES prescriptions(presc_id),
  pharmacy_id         INT NOT NULL REFERENCES pharmacies(pharmacy_id),
  order_status        VARCHAR(20) DEFAULT 'placed',  -- placed|packed|shipped|delivered|cancelled
  placed_at           TIMESTAMPTZ DEFAULT now(),
  delivered_at        TIMESTAMPTZ,
  courier_tracking_id VARCHAR(80)
);

-- 16) Insurers
CREATE TABLE insurers (
  insurer_id    SERIAL PRIMARY KEY,
  name          VARCHAR(180) NOT NULL,
  country_code  CHAR(2),
  support_email VARCHAR(150),
  policy_prefix VARCHAR(20),
  onboarded_at  TIMESTAMPTZ DEFAULT now()
);

-- 17) Policies
CREATE TABLE policies (
  policy_id    SERIAL PRIMARY KEY,
  insurer_id   INT NOT NULL REFERENCES insurers(insurer_id),
  plan_name    VARCHAR(160) NOT NULL,
  coverage_desc TEXT,
  region_scope VARCHAR(60),      -- IN|SG|AE|GLOBAL
  active       BOOLEAN DEFAULT TRUE
);

-- 18) PolicyMembers
CREATE TABLE policy_members (
  membership_id SERIAL PRIMARY KEY,
  policy_id     INT NOT NULL REFERENCES policies(policy_id),
  patient_id    INT NOT NULL REFERENCES patients(patient_id),
  member_type   VARCHAR(20) DEFAULT 'primary',  -- primary|spouse|child|parent
  start_date    DATE NOT NULL,
  end_date      DATE,
  UNIQUE (policy_id, patient_id)
);

-- 19) Claims
CREATE TABLE claims (
  claim_id     SERIAL PRIMARY KEY,
  policy_id    INT NOT NULL REFERENCES policies(policy_id),
  patient_id   INT NOT NULL REFERENCES patients(patient_id),
  consult_id   INT REFERENCES consultations(consult_id),
  claim_amount NUMERIC(12,2) NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT now(),
  status       VARCHAR(20) DEFAULT 'submitted', -- submitted|review|approved|rejected|paid
  decision_notes TEXT
);

-- 20) ClaimItems
CREATE TABLE claim_items (
  claim_item_id SERIAL PRIMARY KEY,
  claim_id      INT NOT NULL REFERENCES claims(claim_id),
  item_type     VARCHAR(20),   -- consult|lab|pharmacy|hospital
  ref_id        INT,           -- reference id in respective table (e.g., lab_results.result_id)
  amount        NUMERIC(12,2) NOT NULL,
  description   VARCHAR(200)
);

-- 21) Payments
CREATE TABLE payments (
  payment_id  SERIAL PRIMARY KEY,
  claim_id    INT NOT NULL REFERENCES claims(claim_id),
  insurer_id  INT NOT NULL REFERENCES insurers(insurer_id),
  amount_paid NUMERIC(12,2) NOT NULL,
  paid_at     TIMESTAMPTZ DEFAULT now(),
  method      VARCHAR(20),     -- neft|ach|rtgs|card
  reference_no VARCHAR(80)
);
