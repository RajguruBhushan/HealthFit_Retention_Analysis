-- ============================================================
-- FILE 01: SCHEMA.sql
-- PROJECT: DARK PATTERN UX PROJECT
-- DESCRIPTION: Schema creation and data addition
-- ============================================================

CREATE DATABASE IF NOT EXISTS UX_PROJECT;

USE UX_PROJECT;

-- =============================CREATE TABLES===============================

-- ============================================================
-- TABLE 1: USERS
-- ============================================================

CREATE TABLE users (
    user_id            INT AUTO_INCREMENT PRIMARY KEY,
    signup_date        DATE        NOT NULL,
    device_type        VARCHAR(10) NOT NULL,   -- Android / iOS / Web
    acquisition_channel VARCHAR(20) NOT NULL,  -- Google Ads / YouTube / Instagram / Organic
    city_tier          VARCHAR(10) NOT NULL,   -- Tier-1 / Tier-2 / Tier-3
    age_group          VARCHAR(10) NOT NULL    -- 18-24 / 25-34 / 35-44 / 45+
);

-- ============================================================
-- TABLE 2: SESSIONS
-- ============================================================

CREATE TABLE sessions (
    session_id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id             INT NOT NULL,
    session_date        DATE        NOT NULL,
    screen_name         VARCHAR(30) NOT NULL,  -- Home / Pricing Page / Plan Selection / Payment / Confirmation
    funnel_stage        INT         NOT NULL,  -- 1 to 5
    time_spent_seconds  INT         NOT NULL,
    action_taken        VARCHAR(15) NOT NULL,  -- viewed / clicked / dropped / converted
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ============================================================
-- TABLE 3: SUBSCRIPTIONS
-- ============================================================

CREATE TABLE subscriptions (
    subscription_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id            INT NOT NULL,
    plan_type          VARCHAR(25) NOT NULL,   -- Monthly ₹499 / Quarterly ₹1299 / Annual ₹3999
    start_date         DATE        NOT NULL,
    end_date           DATE,                   -- NULL = still active
    cancellation_reason VARCHAR(50),           -- available only if churned
    churn_flag         TINYINT     NOT NULL DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ============================================================
-- TABLE 4: AB_TEST
-- ============================================================

CREATE TABLE ab_test (
    ab_id               INT AUTO_INCREMENT PRIMARY KEY,
    user_id             INT NOT NULL,
    variant             CHAR(1)     NOT NULL,  -- A = old page, B = new page
    converted           TINYINT     NOT NULL DEFAULT 0,
    time_on_page_seconds INT        NOT NULL,
    assigned_date       DATE        NOT NULL,  -- always >= Mar 15 2024
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);


-- ===========================================================================================


-- =============================INSERT DATA===============================

-- ============================================================
-- 1. Insert Users
-- ============================================================

DELIMITER //
CREATE PROCEDURE insert_users(IN n INT)
BEGIN
  DECLARE i       INT DEFAULT 1;
  DECLARE v_roll  FLOAT;
  DECLARE v_dev   VARCHAR(10);
  DECLARE v_chan  VARCHAR(20);
  DECLARE v_city  VARCHAR(10);
  DECLARE v_age   VARCHAR(10);

  WHILE i <= n DO
    -- device
    SET v_roll = RAND();
    SET v_dev  = CASE
                   WHEN v_roll < 0.40 THEN 'Android'
                   WHEN v_roll < 0.75 THEN 'iOS'
                   ELSE 'Web'
                 END;

    -- acquisition channel
    SET v_roll = RAND();
    SET v_chan = CASE
                  WHEN v_roll < 0.30 THEN 'Google Ads'
                  WHEN v_roll < 0.55 THEN 'YouTube'
                  WHEN v_roll < 0.80 THEN 'Instagram'
                  ELSE 'Organic'
                END;

    -- city tier
    SET v_city = ELT(FLOOR(1 + RAND()*3), 'Tier-1', 'Tier-2', 'Tier-3');

    -- age group
    SET v_roll = RAND();
    SET v_age  = CASE
                   WHEN v_roll < 0.30 THEN '18-24'
                   WHEN v_roll < 0.60 THEN '25-34'
                   WHEN v_roll < 0.80 THEN '35-44'
                   ELSE '45+'
                 END;

    INSERT INTO users (signup_date, device_type, acquisition_channel, city_tier, age_group)
    VALUES (
      DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND()*181) DAY),  -- Jan 1 to Jun 30
      v_dev,
      v_chan,
      v_city,
      v_age
    );

    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

-- ============================================================
-- 2. Insert sessions
-- ============================================================

DELIMITER //
CREATE PROCEDURE insert_sessions(IN n INT)
BEGIN
  DECLARE i            INT DEFAULT 1;
  DECLARE v_uid        INT;
  DECLARE v_date       DATE;
  DECLARE v_screen     VARCHAR(30);
  DECLARE v_stage      INT;
  DECLARE v_time       INT;
  DECLARE v_action     VARCHAR(15);
  DECLARE v_roll       FLOAT;
  DECLARE v_post       TINYINT;   -- 1 = post Mar 15
  DECLARE v_user_count INT;
  DECLARE v_offset     INT;

  SELECT COUNT(*) INTO v_user_count FROM users;

  WHILE i <= n DO
    -- pick a random user
    SET v_offset = FLOOR(RAND() * v_user_count);
    SELECT user_id INTO v_uid FROM users LIMIT 1 OFFSET v_offset;

    -- session date Jan–Jun 2024
    SET v_date  = DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND()*181) DAY);
    SET v_post  = IF(v_date >= '2024-03-15', 1, 0);

    -- funnel screen
    SET v_roll  = RAND();
    IF v_roll < 0.20 THEN
      SET v_screen = 'Home';           SET v_stage = 1;
    ELSEIF v_roll < 0.50 THEN
      SET v_screen = 'Pricing Page';   SET v_stage = 2;
    ELSEIF v_roll < 0.72 THEN
      SET v_screen = 'Plan Selection'; SET v_stage = 3;
    ELSEIF v_roll < 0.88 THEN
      SET v_screen = 'Payment';        SET v_stage = 4;
    ELSE
      SET v_screen = 'Confirmation';   SET v_stage = 5;
    END IF;

    -- time_spent
    IF v_screen = 'Pricing Page' AND v_post = 1 THEN
      SET v_time = 38 + FLOOR(RAND() * 30);
    ELSEIF v_screen = 'Pricing Page' THEN
      SET v_time = 30 + FLOOR(RAND() * 30);
    ELSE
      SET v_time = 10 + FLOOR(RAND() * 200);
    END IF;

    -- action_taken
    IF v_screen = 'Pricing Page' THEN
      SET v_roll = RAND();
      IF v_post = 1 THEN
        SET v_action = CASE
                         WHEN v_roll < 0.60 THEN 'dropped'
                         WHEN v_roll < 0.85 THEN 'clicked'
                         ELSE 'viewed'
                       END;
      ELSE
        SET v_action = CASE
                         WHEN v_roll < 0.40 THEN 'dropped'
                         WHEN v_roll < 0.75 THEN 'clicked'
                         ELSE 'viewed'
                       END;
      END IF;
    ELSEIF v_screen = 'Confirmation' THEN
      -- Confirmation
      SET v_action = 'converted';
    ELSE
      SET v_roll   = RAND();
      SET v_action = CASE
                       WHEN v_roll < 0.25 THEN 'dropped'
                       WHEN v_roll < 0.60 THEN 'clicked'
                       ELSE 'viewed'
                     END;
    END IF;

    INSERT INTO sessions (user_id, session_date, screen_name, funnel_stage, time_spent_seconds, action_taken)
    VALUES (v_uid, v_date, v_screen, v_stage, v_time, v_action);

    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

-- ============================================================
-- 3. Insert subscriptions
-- ============================================================

DELIMITER //
CREATE PROCEDURE insert_subscriptions(IN n INT)
BEGIN
  DECLARE i            INT DEFAULT 1;
  DECLARE v_uid        INT;
  DECLARE v_plan       VARCHAR(25);
  DECLARE v_start      DATE;
  DECLARE v_end        DATE;
  DECLARE v_reason     VARCHAR(50);
  DECLARE v_churn      TINYINT;
  DECLARE v_roll       FLOAT;
  DECLARE v_post       TINYINT;
  DECLARE v_channel    VARCHAR(20);
  DECLARE v_device     VARCHAR(10);
  DECLARE v_churn_prob FLOAT;
  DECLARE v_user_count INT;
  DECLARE v_offset     INT;

  SELECT COUNT(*) INTO v_user_count FROM users;

  WHILE i <= n DO
    -- pick random user with their channel & device
    SET v_offset = FLOOR(RAND() * v_user_count);
    SELECT u.user_id, u.acquisition_channel, u.device_type
    INTO v_uid, v_channel, v_device
    FROM users u
    LIMIT 1 OFFSET v_offset;

    -- start_date Jan–Jun 2024
    SET v_start = DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND()*181) DAY);
    SET v_post  = IF(v_start >= '2024-03-15', 1, 0);

    -- plan type
    SET v_roll  = RAND();
    SET v_plan  = CASE
                    WHEN v_roll < 0.60 THEN 'Monthly ₹499'
                    WHEN v_roll < 0.85 THEN 'Quarterly ₹1299'
                    ELSE 'Annual ₹3999'
                  END;

    -- churn probability by channel
    SET v_churn_prob = CASE v_channel
                         WHEN 'YouTube'    THEN 0.22
                         WHEN 'Google Ads' THEN 0.35
                         WHEN 'Organic'    THEN 0.30
                         WHEN 'Instagram'  THEN 0.55
                         ELSE 0.35
                       END;

    -- device penalty
    SET v_churn_prob = v_churn_prob + CASE v_device
                                        WHEN 'Web'     THEN 0.12
                                        WHEN 'Android' THEN 0.05
                                        WHEN 'iOS'     THEN 0.00
                                        ELSE 0
                                      END;

    -- post-update penalty
    SET v_churn_prob = v_churn_prob + IF(v_post = 1, 0.08, 0);
    SET v_churn_prob = LEAST(v_churn_prob, 0.90);

    SET v_churn = IF(RAND() < v_churn_prob, 1, 0);

    IF v_churn = 1 THEN
      SET v_end = DATE_ADD(v_start, INTERVAL (10 + FLOOR(RAND()*80)) DAY);

      -- cancellation reason
      SET v_roll = RAND();
      IF v_post = 1 THEN
        -- post-Mar15: "Hard to Cancel" ~50%
        SET v_reason = CASE
                         WHEN v_roll < 0.50 THEN 'Hard to Cancel'
                         WHEN v_roll < 0.70 THEN 'Too Expensive'
                         WHEN v_roll < 0.85 THEN 'Not Using App'
                         ELSE 'Found Better App'
                       END;
      ELSE
        -- pre-Mar15:
        SET v_reason = CASE
                         WHEN v_roll < 0.15 THEN 'Hard to Cancel'
                         WHEN v_roll < 0.50 THEN 'Too Expensive'
                         WHEN v_roll < 0.78 THEN 'Not Using App'
                         ELSE 'Found Better App'
                       END;
      END IF;
    ELSE
      SET v_end    = NULL;
      SET v_reason = NULL;
    END IF;

    INSERT INTO subscriptions (user_id, plan_type, start_date, end_date, cancellation_reason, churn_flag)
    VALUES (v_uid, v_plan, v_start, v_end, v_reason, v_churn);

    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

-- ============================================================
-- 4. Insert ab_test
-- ============================================================

DELIMITER //
CREATE PROCEDURE insert_ab_test(IN n INT)
BEGIN
  DECLARE i            INT DEFAULT 1;
  DECLARE v_uid        INT;
  DECLARE v_variant    CHAR(1);
  DECLARE v_converted  TINYINT;
  DECLARE v_time       INT;
  DECLARE v_date       DATE;
  DECLARE v_roll       FLOAT;
  DECLARE v_user_count INT;
  DECLARE v_offset     INT;

  SELECT COUNT(*) INTO v_user_count FROM users;

  WHILE i <= n DO
    SET v_offset = FLOOR(RAND() * v_user_count);
    SELECT user_id INTO v_uid FROM users LIMIT 1 OFFSET v_offset;

    -- assigned_date Mar 15 – Jun 30 2024
    SET v_date    = DATE_ADD('2024-03-15', INTERVAL FLOOR(RAND()*107) DAY);

    -- 50-50 variant split
    SET v_variant = IF(RAND() < 0.50, 'A', 'B');

    -- conversion rate:
    IF v_variant = 'A' THEN
      SET v_converted = IF(RAND() < 0.18, 1, 0);
      SET v_time      = 35 + FLOOR(RAND() * 30);
    ELSE
      SET v_converted = IF(RAND() < 0.11, 1, 0);
      SET v_time      = 43 + FLOOR(RAND() * 30);
    END IF;

    INSERT INTO ab_test (user_id, variant, converted, time_on_page_seconds, assigned_date)
    VALUES (v_uid, v_variant, v_converted, v_time, v_date);

    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

-- ============================================================
-- Call all procedures to insert data
-- ============================================================

CALL insert_users(3000);
CALL insert_sessions(15000);
CALL insert_subscriptions(1800);
CALL insert_ab_test(2000);

COMMIT;

-- ===========================================================================================