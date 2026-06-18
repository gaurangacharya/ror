-- Runs only on first MySQL container initialization (empty volume).
-- Creates additional databases needed by Rails tasks.

CREATE DATABASE IF NOT EXISTS ownoutdoors_test
  CHARACTER SET utf8 COLLATE utf8_unicode_ci;

GRANT ALL PRIVILEGES ON ownoutdoors_test.* TO 'rdeveloper'@'%';

FLUSH PRIVILEGES;

