-- 현장
CREATE TABLE IF NOT EXISTS sites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  address VARCHAR(500),
  bp_company_id UUID NOT NULL,
  created_by UUID,
  boundary_type VARCHAR(20) DEFAULT 'POLYGON',
  boundary_coordinates TEXT,
  center_lat DECIMAL(10,8),
  center_lng DECIMAL(11,8),
  radius_meters INTEGER,
  status VARCHAR(20) DEFAULT 'ACTIVE',
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sites_bp_company ON sites(bp_company_id);
CREATE INDEX IF NOT EXISTS idx_sites_status ON sites(status);

-- 견적 요청
CREATE TABLE IF NOT EXISTS quotation_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL REFERENCES sites(id),
  bp_company_id UUID NOT NULL,
  requested_by UUID,
  title VARCHAR(200),
  description TEXT,
  desired_start_date DATE,
  desired_end_date DATE,
  status VARCHAR(20) DEFAULT 'PENDING',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_qr_site ON quotation_requests(site_id);
CREATE INDEX IF NOT EXISTS idx_qr_bp_company ON quotation_requests(bp_company_id);
CREATE INDEX IF NOT EXISTS idx_qr_status ON quotation_requests(status);

-- 견적서
CREATE TABLE IF NOT EXISTS quotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES quotation_requests(id),
  supplier_id UUID NOT NULL,
  created_by UUID,
  total_amount DECIMAL(15,2) DEFAULT 0,
  notes TEXT,
  status VARCHAR(20) DEFAULT 'DRAFT',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_quotations_request ON quotations(request_id);
CREATE INDEX IF NOT EXISTS idx_quotations_supplier ON quotations(supplier_id);
CREATE INDEX IF NOT EXISTS idx_quotations_status ON quotations(status);

-- 견적 항목
CREATE TABLE IF NOT EXISTS quotation_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id UUID NOT NULL REFERENCES quotations(id) ON DELETE CASCADE,
  equipment_type_name VARCHAR(100),
  equipment_type_id UUID,
  quantity INTEGER DEFAULT 1,
  rate_daily DECIMAL(12,2),
  rate_overtime DECIMAL(12,2),
  rate_night DECIMAL(12,2),
  rate_monthly DECIMAL(12,2),
  labor_included BOOLEAN DEFAULT TRUE,
  labor_cost_daily DECIMAL(12,2),
  guide_cost_daily DECIMAL(12,2),
  notes TEXT
);

-- 투입 체크리스트
CREATE TABLE IF NOT EXISTS deployment_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_plan_id UUID NOT NULL REFERENCES deployment_plans(id),
  quotation_confirmed BOOLEAN DEFAULT FALSE,
  documents_verified BOOLEAN DEFAULT FALSE,
  license_verified BOOLEAN DEFAULT FALSE,
  safety_inspection_passed BOOLEAN DEFAULT FALSE,
  health_check_completed BOOLEAN DEFAULT FALSE,
  personnel_assigned BOOLEAN DEFAULT FALSE,
  equipment_assigned BOOLEAN DEFAULT FALSE,
  overall_status VARCHAR(20) DEFAULT 'PENDING',
  overridden_by UUID,
  overridden_at TIMESTAMP,
  override_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_checklist_plan ON deployment_checklists(deployment_plan_id);
CREATE INDEX IF NOT EXISTS idx_checklist_status ON deployment_checklists(overall_status);
