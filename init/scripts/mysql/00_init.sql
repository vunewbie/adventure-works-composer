CREATE DATABASE IF NOT EXISTS person
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS human_resources
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON person.* TO 'adventureworks'@'%';
GRANT ALL PRIVILEGES ON human_resources.* TO 'adventureworks'@'%';
FLUSH PRIVILEGES;
