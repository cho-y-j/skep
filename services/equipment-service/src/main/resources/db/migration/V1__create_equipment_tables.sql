-- Create ENUM types
CREATE TYPE equipment_status AS ENUM ('ACTIVE', 'MAINTENANCE', 'INACTIVE');
CREATE TYPE person_type_enum AS ENUM ('DRIVER', 'GUIDE', 'SAFETY_INSPECTOR');
CREATE TYPE person_status AS ENUM ('ACTIVE', 'INACTIVE');
CREATE TYPE pre_inspection_status AS ENUM ('PENDING', 'PASSED', 'FAILED');

-- Equipment Types Table
CREATE TABLE equipment_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    required_documents JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Equipment Table
CREATE TABLE equipment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL,
    equipment_type_id UUID NOT NULL REFERENCES equipment_types(id),
    vehicle_number VARCHAR(50) NOT NULL UNIQUE,
    model_name VARCHAR(255),
    manufacture_year INTEGER,
    status equipment_status NOT NULL DEFAULT 'ACTIVE',
    nfc_tag_id VARCHAR(255) UNIQUE,
    pre_inspection_status pre_inspection_status NOT NULL DEFAULT 'PENDING',
    pre_inspection_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Person Types Table
CREATE TABLE person_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name person_type_enum NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Persons Table
CREATE TABLE persons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL,
    person_type person_type_enum NOT NULL,
    user_id UUID,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    birth_date DATE,
    photo_url VARCHAR(2048),
    health_check_date DATE,
    safety_training_date DATE,
    status person_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Equipment Assignments Table
CREATE TABLE equipment_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    equipment_id UUID NOT NULL REFERENCES equipment(id),
    driver_id UUID NOT NULL REFERENCES persons(id),
    guides JSONB,
    assigned_from DATE NOT NULL,
    assigned_until DATE,
    is_current BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_equipment_supplier ON equipment(supplier_id);
CREATE INDEX idx_equipment_type ON equipment(equipment_type_id);
CREATE INDEX idx_equipment_status ON equipment(status);
CREATE INDEX idx_equipment_nfc_tag ON equipment(nfc_tag_id);
CREATE INDEX idx_persons_supplier ON persons(supplier_id);
CREATE INDEX idx_persons_type ON persons(person_type);
CREATE INDEX idx_persons_status ON persons(status);
CREATE INDEX idx_assignments_equipment ON equipment_assignments(equipment_id);
CREATE INDEX idx_assignments_driver ON equipment_assignments(driver_id);
CREATE INDEX idx_assignments_current ON equipment_assignments(is_current, equipment_id);

-- Insert Person Types
INSERT INTO person_types (name, description)
VALUES
    ('DRIVER', '운전원'),
    ('GUIDE', '안내원'),
    ('SAFETY_INSPECTOR', '안전점검원')
ON CONFLICT (name) DO NOTHING;

-- Insert Equipment Types
INSERT INTO equipment_types (name, description, required_documents)
VALUES
    ('소형 크레인', 'Small Crane', '["자동차등록증", "자동차보험", "안전인증서"]'),
    ('대형 크레인', 'Large Crane', '["자동차등록증", "자동차보험", "안전인증서", "비파괴검사서"]'),
    ('지게차', 'Forklift', '["자동차등록증", "자동차보험", "안전인증서"]'),
    ('굴삭기', 'Excavator', '["자동차등록증", "자동차보험", "안전인증서"]'),
    ('덤프트럭', 'Dump Truck', '["자동차등록원부", "자동차등록증", "자동차보험", "안전인증서"]')
ON CONFLICT (name) DO NOTHING;
