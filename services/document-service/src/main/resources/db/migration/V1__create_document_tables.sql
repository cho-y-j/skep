-- Create ENUM types
CREATE TYPE document_status AS ENUM ('PENDING', 'VERIFIED', 'FAILED', 'EXPIRED');
CREATE TYPE owner_type AS ENUM ('EQUIPMENT', 'PERSON');

-- Document Types Table
CREATE TABLE document_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    requires_ocr BOOLEAN NOT NULL DEFAULT false,
    requires_verification BOOLEAN NOT NULL DEFAULT false,
    has_expiry BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Documents Table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL,
    owner_type owner_type NOT NULL,
    document_type_id UUID NOT NULL REFERENCES document_types(id),
    file_url VARCHAR(2048) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    ocr_result JSONB,
    verified BOOLEAN NOT NULL DEFAULT false,
    verification_result JSONB,
    issue_date DATE,
    expiry_date DATE,
    status document_status NOT NULL DEFAULT 'PENDING',
    uploaded_by UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Document Type Requirements Table
CREATE TYPE entity_type AS ENUM ('EQUIPMENT', 'DRIVER', 'GUIDE');

CREATE TABLE document_type_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type entity_type NOT NULL,
    document_type_id UUID NOT NULL REFERENCES document_types(id),
    is_required BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_documents_owner ON documents(owner_id, owner_type);
CREATE INDEX idx_documents_type ON documents(document_type_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_expiry_date ON documents(expiry_date);
CREATE INDEX idx_document_type_requirements_entity ON document_type_requirements(entity_type, document_type_id);

-- Insert Document Types for Equipment
INSERT INTO document_types (name, description, requires_ocr, requires_verification, has_expiry)
VALUES
    ('자동차등록원부', '차량 등록 원부', true, true, false),
    ('자동차등록증', '차량 등록증', true, true, true),
    ('사업자등록증', '사업자 등록증', true, true, true),
    ('자동차보험', '자동차 보험증권', true, true, true),
    ('안전인증서', '장비 안전 인증서', true, true, true),
    ('장비제원표', '장비 제원표', false, false, false),
    ('비파괴검사서', '비파괴 검사 결과서', true, true, true)
ON CONFLICT (name) DO NOTHING;

-- Insert Document Types for Person/Driver
INSERT INTO document_types (name, description, requires_ocr, requires_verification, has_expiry)
VALUES
    ('운전면허증', '운전면허증', true, true, true),
    ('기초안전보건교육이수증', '기초안전보건교육 이수증', true, true, true),
    ('화물운송종사자격증', '화물운송 종사자 격증', true, true, true),
    ('조종자격수료증', '조종자격 수료증', true, true, true),
    ('특수형태근로자교육실시확인서', '특수형태근로자 교육 확인서', true, true, true),
    ('건강검진결과서', '건강검진 결과서', true, true, true)
ON CONFLICT (name) DO NOTHING;

-- Insert Document Type Requirements for Equipment
INSERT INTO document_type_requirements (entity_type, document_type_id, is_required)
SELECT 'EQUIPMENT', id, true FROM document_types WHERE name IN ('자동차등록원부', '자동차등록증', '자동차보험', '안전인증서')
ON CONFLICT DO NOTHING;

-- Insert Document Type Requirements for Driver
INSERT INTO document_type_requirements (entity_type, document_type_id, is_required)
SELECT 'DRIVER', id, true FROM document_types WHERE name IN ('운전면허증', '기초안전보건교육이수증', '건강검진결과서')
ON CONFLICT DO NOTHING;

-- Insert Document Type Requirements for Guide
INSERT INTO document_type_requirements (entity_type, document_type_id, is_required)
SELECT 'GUIDE', id, true FROM document_types WHERE name IN ('기초안전보건교육이수증')
ON CONFLICT DO NOTHING;
