-- 안전점검 항목 마스터
CREATE TABLE inspection_item_masters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_type_id UUID NOT NULL,
  item_number INT NOT NULL,
  item_name VARCHAR(200) NOT NULL,
  inspection_method TEXT NOT NULL,
  requires_photo BOOLEAN DEFAULT TRUE,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_inspection_item_masters_equipment_type ON inspection_item_masters(equipment_type_id);
CREATE UNIQUE INDEX idx_inspection_items_unique ON inspection_item_masters(equipment_type_id, item_number);

-- 안전점검 세션
CREATE TABLE safety_inspections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_id UUID NOT NULL,
  inspector_id UUID NOT NULL,
  inspection_date DATE NOT NULL,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  inspector_gps_lat DECIMAL(10,8),
  inspector_gps_lng DECIMAL(11,8),
  equipment_gps_lat DECIMAL(10,8),
  equipment_gps_lng DECIMAL(11,8),
  distance_meters DECIMAL(8,2),
  status VARCHAR(20) DEFAULT 'IN_PROGRESS',
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_safety_inspections_equipment ON safety_inspections(equipment_id);
CREATE INDEX idx_safety_inspections_inspector ON safety_inspections(inspector_id);
CREATE INDEX idx_safety_inspections_date ON safety_inspections(inspection_date);
CREATE INDEX idx_safety_inspections_status ON safety_inspections(status);

-- 안전점검 항목별 결과
CREATE TABLE inspection_item_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id UUID REFERENCES safety_inspections(id),
  item_master_id UUID REFERENCES inspection_item_masters(id),
  item_number INT NOT NULL,
  result VARCHAR(10),
  photo_url VARCHAR(500),
  notes TEXT,
  recorded_at TIMESTAMP DEFAULT NOW(),
  sequence_number INT
);

CREATE INDEX idx_inspection_item_results_inspection ON inspection_item_results(inspection_id);
CREATE INDEX idx_inspection_item_results_master ON inspection_item_results(item_master_id);
CREATE UNIQUE INDEX idx_inspection_results_unique ON inspection_item_results(inspection_id, item_number);

-- 운전원 정비점검표
CREATE TABLE maintenance_inspections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_id UUID NOT NULL,
  driver_id UUID NOT NULL,
  inspection_date DATE NOT NULL,
  mileage INT,
  engine_oil VARCHAR(20),
  hydraulic_oil VARCHAR(20),
  coolant VARCHAR(20),
  fuel_level INT,
  notes TEXT,
  recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_maintenance_inspections_equipment ON maintenance_inspections(equipment_id);
CREATE INDEX idx_maintenance_inspections_driver ON maintenance_inspections(driver_id);
CREATE INDEX idx_maintenance_inspections_date ON maintenance_inspections(inspection_date);
