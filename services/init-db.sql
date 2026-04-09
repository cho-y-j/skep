-- Create databases
CREATE DATABASE dispatch_db;
CREATE DATABASE inspection_db;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE dispatch_db TO postgres;
GRANT ALL PRIVILEGES ON DATABASE inspection_db TO postgres;
