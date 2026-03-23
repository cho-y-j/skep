-- ==========================================
-- SKEP Database Initialization Script
-- Run once at DB startup to enable extensions
-- Flyway migrations handle table creation per service
-- ==========================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- PostGIS for GPS/location features (available with postgis/postgis image)
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ==========================================
-- Audit trigger function
-- ==========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ==========================================
-- Grant permissions to app user
-- ==========================================
-- (Postgres creates the DB for POSTGRES_USER automatically)
-- Additional grants can be added here if using a separate app user

SELECT 'SKEP Database initialized successfully' AS status;
