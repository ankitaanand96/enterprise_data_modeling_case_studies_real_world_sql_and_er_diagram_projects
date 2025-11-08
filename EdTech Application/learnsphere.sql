-- LearnSphere — Unified Learning & Knowledge Ecosystem

CREATE SCHEMA IF NOT EXISTS learnsphere;
SET search_path TO learnsphere, public;

-- 1) Users
CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  email VARCHAR(150) UNIQUE NOT NULL,
  full_name VARCHAR(120),
  role VARCHAR(20) DEFAULT 'learner',
  country_code CHAR(2),
  created_at TIMESTAMPTZ DEFAULT now(),
  status VARCHAR(16) DEFAULT 'active'
);

-- 2) UserProfiles
CREATE TABLE user_profiles (
  user_id INT PRIMARY KEY REFERENCES users(user_id),
  headline VARCHAR(160),
  experience_years INT,
  goals VARCHAR(200),
  language_pref VARCHAR(10),
  timezone VARCHAR(40),
  avatar_url VARCHAR(300)
);

-- 3) Institutions
CREATE TABLE institutions (
  inst_id SERIAL PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  inst_type VARCHAR(20),
  country_code CHAR(2),
  admin_email VARCHAR(150),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4) UserInstitutions
CREATE TABLE user_institutions (
  ui_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  inst_id INT NOT NULL REFERENCES institutions(inst_id),
  role VARCHAR(20),
  start_at TIMESTAMPTZ DEFAULT now(),
  end_at TIMESTAMPTZ,
  UNIQUE (user_id, inst_id)
);

-- 5) Courses
CREATE TABLE courses (
  course_id SERIAL PRIMARY KEY,
  title VARCHAR(180) NOT NULL,
  category VARCHAR(80),
  level VARCHAR(20),
  lang VARCHAR(10),
  price NUMERIC(10,2),
  currency CHAR(3) DEFAULT 'INR',
  status VARCHAR(16) DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 6) CourseInstructors
CREATE TABLE course_instructors (
  ci_id SERIAL PRIMARY KEY,
  course_id INT NOT NULL REFERENCES courses(course_id),
  user_id INT NOT NULL REFERENCES users(user_id),
  role VARCHAR(10),
  rev_share_pct NUMERIC(6,2),
  UNIQUE (course_id, user_id)
);

-- 7) Programs
CREATE TABLE programs (
  program_id SERIAL PRIMARY KEY,
  title VARCHAR(180) NOT NULL,
  description TEXT,
  status VARCHAR(16) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 8) ProgramCourses
CREATE TABLE program_courses (
  pc_id SERIAL PRIMARY KEY,
  program_id INT NOT NULL REFERENCES programs(program_id),
  course_id INT NOT NULL REFERENCES courses(course_id),
  order_idx INT,
  UNIQUE (program_id, course_id)
);

-- 9) Modules
CREATE TABLE modules (
  module_id SERIAL PRIMARY KEY,
  course_id INT NOT NULL REFERENCES courses(course_id),
  title VARCHAR(180) NOT NULL,
  order_idx INT NOT NULL
);

-- 10) Lessons
CREATE TABLE lessons (
  lesson_id SERIAL PRIMARY KEY,
  module_id INT NOT NULL REFERENCES modules(module_id),
  title VARCHAR(180) NOT NULL,
  duration_sec INT,
  content_type VARCHAR(16),
  order_idx INT NOT NULL,
  video_url VARCHAR(300)
);

-- 11) LessonAssets
CREATE TABLE lesson_assets (
  asset_id SERIAL PRIMARY KEY,
  lesson_id INT NOT NULL REFERENCES lessons(lesson_id),
  asset_type VARCHAR(20),
  url VARCHAR(300),
  lang VARCHAR(10)
);

-- 12) Enrollments
CREATE TABLE enrollments (
  enr_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  course_id INT NOT NULL REFERENCES courses(course_id),
  source VARCHAR(16),
  enrolled_at TIMESTAMPTZ DEFAULT now(),
  status VARCHAR(16) DEFAULT 'active',
  progress_pct NUMERIC(5,2) DEFAULT 0,
  UNIQUE (user_id, course_id)
);

-- 13) LearningEvents
CREATE TABLE learning_events (
  le_id BIGSERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  lesson_id INT NOT NULL REFERENCES lessons(lesson_id),
  event VARCHAR(16),
  at_time TIMESTAMPTZ DEFAULT now(),
  device_id VARCHAR(80),
  ip INET,
  geo_country CHAR(2)
);

-- 14) Quizzes
CREATE TABLE quizzes (
  quiz_id SERIAL PRIMARY KEY,
  course_id INT NOT NULL REFERENCES courses(course_id),
  lesson_id INT REFERENCES lessons(lesson_id),
  title VARCHAR(180),
  max_score INT,
  randomized BOOLEAN DEFAULT FALSE
);

-- 15) Questions
CREATE TABLE questions (
  q_id SERIAL PRIMARY KEY,
  quiz_id INT NOT NULL REFERENCES quizzes(quiz_id),
  body TEXT NOT NULL,
  q_type VARCHAR(10),
  order_idx INT NOT NULL,
  points INT DEFAULT 1
);

-- 16) QuestionOptions
CREATE TABLE question_options (
  opt_id SERIAL PRIMARY KEY,
  q_id INT NOT NULL REFERENCES questions(q_id),
  label TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT FALSE
);

-- 17) Submissions
CREATE TABLE submissions (
  sub_id SERIAL PRIMARY KEY,
  quiz_id INT NOT NULL REFERENCES quizzes(quiz_id),
  user_id INT NOT NULL REFERENCES users(user_id),
  submitted_at TIMESTAMPTZ DEFAULT now(),
  score NUMERIC(6,2),
  status VARCHAR(16),
  attempt_no INT DEFAULT 1
);

-- 18) SubmissionAnswers
CREATE TABLE submission_answers (
  sa_id SERIAL PRIMARY KEY,
  sub_id INT NOT NULL REFERENCES submissions(sub_id),
  q_id INT NOT NULL REFERENCES questions(q_id),
  selected_option_ids TEXT,
  text_answer TEXT,
  code_url VARCHAR(300)
);

-- 19) Orders
CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  currency CHAR(3) DEFAULT 'INR',
  total_amount NUMERIC(12,2) NOT NULL,
  discount_amount NUMERIC(12,2) DEFAULT 0,
  status VARCHAR(16) DEFAULT 'created',
  created_at TIMESTAMPTZ DEFAULT now(),
  channel VARCHAR(16)
);

-- 20) OrderItems
CREATE TABLE order_items (
  item_id SERIAL PRIMARY KEY,
  order_id INT NOT NULL REFERENCES orders(order_id),
  item_type VARCHAR(16),           -- course|program|subscription
  item_ref_id INT NOT NULL,        -- FK depends on item_type
  quantity INT DEFAULT 1,
  unit_price NUMERIC(12,2) NOT NULL,
  net_amount NUMERIC(12,2) NOT NULL
);

-- 21) Payments
CREATE TABLE payments (
  payment_id SERIAL PRIMARY KEY,
  order_id INT NOT NULL REFERENCES orders(order_id),
  method VARCHAR(16),              -- upi|card|netbanking|wallet
  amount NUMERIC(12,2) NOT NULL,
  status VARCHAR(16) DEFAULT 'paid',
  paid_at TIMESTAMPTZ DEFAULT now(),
  provider_txn_ref VARCHAR(80)
);
