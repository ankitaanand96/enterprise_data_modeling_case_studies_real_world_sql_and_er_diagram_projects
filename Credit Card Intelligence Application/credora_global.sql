-- Credora Global — Scalable Credit Card Intelligence Platform

CREATE SCHEMA IF NOT EXISTS credora_global;
SET search_path TO credora_global, public;

-- 1) Customer
CREATE TABLE customer (
  customer_id SERIAL PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name  VARCHAR(50) NOT NULL,
  email      VARCHAR(100) UNIQUE NOT NULL,
  phone      VARCHAR(20),
  dob        DATE,
  country    VARCHAR(50),
  kyc_status BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2) CardType
CREATE TABLE card_type (
  card_type_id SERIAL PRIMARY KEY,
  name               VARCHAR(50) NOT NULL,
  annual_fee         NUMERIC(10,2) DEFAULT 0,
  cashback_percent   NUMERIC(5,2)  DEFAULT 0,
  rewards_multiplier NUMERIC(5,2)  DEFAULT 1
);

-- 3) CreditCard
CREATE TABLE credit_card (
  card_id      SERIAL PRIMARY KEY,
  customer_id  INT REFERENCES customer(customer_id),
  card_type_id INT REFERENCES card_type(card_type_id),
  credit_limit NUMERIC(15,2) NOT NULL,
  issued_date  DATE NOT NULL,
  expiry_date  DATE NOT NULL,
  status       VARCHAR(20) DEFAULT 'Active',
  currency     VARCHAR(10) DEFAULT 'INR'
);

-- 4) Merchant
CREATE TABLE merchant (
  merchant_id  SERIAL PRIMARY KEY,
  name         VARCHAR(100) NOT NULL,
  category     VARCHAR(50),
  country      VARCHAR(50),
  city         VARCHAR(50),
  contact_email VARCHAR(100)
);

-- 5) TransactionCategory
CREATE TABLE transaction_category (
  category_id SERIAL PRIMARY KEY,
  name        VARCHAR(50) NOT NULL,
  description TEXT
);

-- 6) Transaction
CREATE TABLE card_transaction (
  transaction_id  SERIAL PRIMARY KEY,
  card_id         INT REFERENCES credit_card(card_id),
  merchant_id     INT REFERENCES merchant(merchant_id),
  category_id     INT REFERENCES transaction_category(category_id),
  amount          NUMERIC(15,2) NOT NULL,
  currency        VARCHAR(10) DEFAULT 'INR',
  transaction_date TIMESTAMPTZ DEFAULT now(),
  transaction_type VARCHAR(20) DEFAULT 'POS',
  status           VARCHAR(20) DEFAULT 'Completed'
);

-- 7) Rewards
CREATE TABLE rewards (
  reward_id      SERIAL PRIMARY KEY,
  card_id        INT REFERENCES credit_card(card_id),
  points_earned  NUMERIC(10,2) DEFAULT 0,
  points_redeemed NUMERIC(10,2) DEFAULT 0,
  last_updated   TIMESTAMPTZ DEFAULT now()
);

-- 8) Redemption
CREATE TABLE redemption (
  redemption_id  SERIAL PRIMARY KEY,
  reward_id      INT REFERENCES rewards(reward_id),
  redeemed_amount NUMERIC(10,2),
  redeemed_date   TIMESTAMPTZ DEFAULT now(),
  redemption_type VARCHAR(50)
);

-- 9) Statement
CREATE TABLE statement (
  statement_id  SERIAL PRIMARY KEY,
  card_id       INT REFERENCES credit_card(card_id),
  period_start  DATE NOT NULL,
  period_end    DATE NOT NULL,
  total_due     NUMERIC(15,2) DEFAULT 0,
  min_due       NUMERIC(15,2) DEFAULT 0,
  generated_date TIMESTAMPTZ DEFAULT now(),
  paid_status   BOOLEAN DEFAULT FALSE
);

-- 10) Payment
CREATE TABLE payment (
  payment_id   SERIAL PRIMARY KEY,
  statement_id INT REFERENCES statement(statement_id),
  amount       NUMERIC(15,2) NOT NULL,
  payment_date TIMESTAMPTZ DEFAULT now(),
  payment_method VARCHAR(50),
  status         VARCHAR(20) DEFAULT 'Completed'
);

-- 11) Branch
CREATE TABLE branch (
  branch_id     SERIAL PRIMARY KEY,
  country       VARCHAR(50),
  city          VARCHAR(50),
  manager_name  VARCHAR(100),
  contact_number VARCHAR(20)
);

-- 12) CountryRegulation
CREATE TABLE country_regulation (
  regulation_id SERIAL PRIMARY KEY,
  country       VARCHAR(50),
  description   TEXT,
  last_updated  TIMESTAMPTZ DEFAULT now()
);

-- 13) CreditScore
CREATE TABLE credit_score (
  score_id    SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customer(customer_id),
  score_value INT,
  score_date  DATE DEFAULT CURRENT_DATE,
  provider    VARCHAR(50)
);

-- 14) FraudAlert
CREATE TABLE fraud_alert (
  alert_id      SERIAL PRIMARY KEY,
  transaction_id INT REFERENCES card_transaction(transaction_id),
  alert_type    VARCHAR(50),
  alert_date    TIMESTAMPTZ DEFAULT now(),
  status        VARCHAR(20) DEFAULT 'Open',
  resolution_notes TEXT
);

-- 15) CustomerSupportTicket
CREATE TABLE customer_support_ticket (
  ticket_id   SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customer(customer_id),
  card_id     INT REFERENCES credit_card(card_id),
  category    VARCHAR(50),
  opened_at   TIMESTAMPTZ DEFAULT now(),
  resolved_at TIMESTAMPTZ,
  status      VARCHAR(20) DEFAULT 'Open',
  notes       TEXT
);

-- 16) CardLimitChange
CREATE TABLE card_limit_change (
  change_id     SERIAL PRIMARY KEY,
  card_id       INT REFERENCES credit_card(card_id),
  previous_limit NUMERIC(15,2),
  new_limit      NUMERIC(15,2),
  change_date    TIMESTAMPTZ DEFAULT now(),
  requested_by   VARCHAR(50)
);

-- 17) Offer
CREATE TABLE offer (
  offer_id     SERIAL PRIMARY KEY,
  card_type_id INT REFERENCES card_type(card_type_id),
  description  TEXT,
  start_date   DATE,
  end_date     DATE,
  eligible_categories TEXT
);

-- 18) AccountLock
CREATE TABLE account_lock (
  lock_id     SERIAL PRIMARY KEY,
  card_id     INT REFERENCES credit_card(card_id),
  reason      TEXT,
  locked_at   TIMESTAMPTZ DEFAULT now(),
  unlocked_at TIMESTAMPTZ,
  status      VARCHAR(20) DEFAULT 'Locked'
);

-- 19) CardUpgrade
CREATE TABLE card_upgrade (
  upgrade_id   SERIAL PRIMARY KEY,
  card_id      INT REFERENCES credit_card(card_id),
  old_card_type INT REFERENCES card_type(card_type_id),
  new_card_type INT REFERENCES card_type(card_type_id),
  upgrade_date TIMESTAMPTZ DEFAULT now(),
  approved_by  VARCHAR(50)
);

-- 20) ATMTransaction
CREATE TABLE atm_transaction (
  atm_txn_id SERIAL PRIMARY KEY,
  card_id    INT REFERENCES credit_card(card_id),
  atm_id     VARCHAR(50),
  amount     NUMERIC(15,2),
  currency   VARCHAR(10) DEFAULT 'INR',
  txn_date   TIMESTAMPTZ DEFAULT now(),
  status     VARCHAR(20) DEFAULT 'Completed'
);
