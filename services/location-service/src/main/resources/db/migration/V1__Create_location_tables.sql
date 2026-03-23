CREATE TABLE location_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id UUID NOT NULL,
  equipment_id UUID,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  accuracy DECIMAL(6,2),
  recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE current_locations (
  worker_id UUID PRIMARY KEY,
  equipment_id UUID,
  site_id UUID,
  worker_name VARCHAR(100),
  equipment_name VARCHAR(200),
  vehicle_number VARCHAR(50),
  site_name VARCHAR(200),
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  last_updated TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_location_records_worker ON location_records(worker_id);
CREATE INDEX idx_location_records_equipment ON location_records(equipment_id);
CREATE INDEX idx_location_records_recorded ON location_records(recorded_at);
CREATE INDEX idx_current_locations_equipment ON current_locations(equipment_id);
