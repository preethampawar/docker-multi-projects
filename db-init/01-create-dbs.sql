-- ==============================================
-- mysql initialization script
-- Creates three databases and user accounts
-- for your CakePHP and Laravel projects.
-- ==============================================

-- Create databases
CREATE DATABASE IF NOT EXISTS sprphysio_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS liq_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS liq_db_v1 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS news_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create users and set passwords
CREATE USER IF NOT EXISTS 'spr_user'@'%' IDENTIFIED BY 'spr_pass';
CREATE USER IF NOT EXISTS 'liq_user'@'%' IDENTIFIED BY 'liq_pass';
CREATE USER IF NOT EXISTS 'news_user'@'%' IDENTIFIED BY 'news_pass';

-- Grant privileges for each application
GRANT ALL PRIVILEGES ON sprphysio_db.* TO 'spr_user'@'%';
GRANT ALL PRIVILEGES ON liq_db.* TO 'liq_user'@'%';
GRANT ALL PRIVILEGES ON liq_db_v1.* TO 'liq_user'@'%';
GRANT ALL PRIVILEGES ON news_db.* TO 'news_user'@'%';

-- Apply privileges
FLUSH PRIVILEGES;

-- Optional: Verify databases and users (for debugging)
-- SHOW DATABASES;
-- SELECT user, host FROM mysql.user;


