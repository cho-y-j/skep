-- 투입 계획
CREATE TABLE deployment_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id UUID NOT NULL,
  bp_company_id UUID NOT NULL,
  site_name VARCHAR(200) NOT NULL,
  equipment_id UUID NOT NULL,
  start_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_date DATE NOT NULL,
  end_time TIME NOT NULL,
  rate_daily DECIMAL(12,2),
  rate_overtime DECIMAL(12,2),
  rate_early_morning DECIMAL(12,2),
  rate_night DECIMAL(12,2),
  rate_overnight DECIMAL(12,2),
  rate_monthly DECIMAL(12,2),
  status VARCHAR(20) DEFAULT 'ACTIVE',
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_deployment_plans_supplier ON deployment_plans(supplier_id);
CREATE INDEX idx_deployment_plans_equipment ON deployment_plans(equipment_id);
CREATE INDEX idx_deployment_plans_status ON deployment_plans(status);

-- 일일 작업자 명단
CREATE TABLE daily_rosters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_plan_id UUID REFERENCES deployment_plans(id),
  work_date DATE NOT NULL,
  driver_id UUID NOT NULL,
  guide_ids JSONB,
  submitted_by UUID,
  submitted_at TIMESTAMP,
  approved_by UUID,
  approved_at TIMESTAMP,
  status VARCHAR(20) DEFAULT 'PENDING',
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_daily_rosters_plan ON daily_rosters(deployment_plan_id);
CREATE INDEX idx_daily_rosters_date ON daily_rosters(work_date);
CREATE INDEX idx_daily_rosters_status ON daily_rosters(status);

-- 작업 기록 (출근/시작/종료)
CREATE TABLE work_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  daily_roster_id UUID REFERENCES daily_rosters(id),
  worker_id UUID NOT NULL,
  worker_type VARCHAR(20),
  clock_in_at TIMESTAMP,
  clock_in_location POINT,
  clock_in_verified BOOLEAN DEFAULT FALSE,
  work_start_at TIMESTAMP,
  work_end_at TIMESTAMP,
  work_type VARCHAR(20),
  work_content TEXT,
  work_location VARCHAR(200),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_work_records_roster ON work_records(daily_roster_id);
CREATE INDEX idx_work_records_worker ON work_records(worker_id);
CREATE INDEX idx_work_records_created ON work_records(created_at);

-- 작업확인서 TYPE A (월간, BP사 수령용)
CREATE TABLE monthly_work_confirmations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_plan_id UUID REFERENCES deployment_plans(id),
  year_month VARCHAR(7),
  total_daily_hours DECIMAL(6,2),
  total_overtime_hours DECIMAL(6,2),
  total_early_morning_count INT,
  total_night_hours DECIMAL(6,2),
  total_overnight_count INT,
  total_amount DECIMAL(15,2),
  bp_signed_by UUID,
  bp_signed_at TIMESTAMP,
  site_owner_sent_at TIMESTAMP,
  status VARCHAR(20) DEFAULT 'DRAFT',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_monthly_confirmations_plan ON monthly_work_confirmations(deployment_plan_id);
CREATE INDEX idx_monthly_confirmations_period ON monthly_work_confirmations(year_month);

-- 작업확인서 TYPE B (일일, 공급사 수령용)
CREATE TABLE daily_work_confirmations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_record_id UUID REFERENCES work_records(id),
  site_name VARCHAR(200),
  company_name VARCHAR(200),
  vehicle_number VARCHAR(50),
  driver_name VARCHAR(100),
  equipment_name VARCHAR(200),
  work_content TEXT,
  work_location VARCHAR(200),
  specification VARCHAR(100),
  work_type VARCHAR(20),
  work_start_time TIME,
  work_end_time TIME,
  overtime_hours DECIMAL(4,2),
  overnight_hours DECIMAL(4,2),
  extension_notes TEXT,
  bp_signed_by UUID,
  bp_signed_at TIMESTAMP,
  status VARCHAR(20) DEFAULT 'PENDING_SIGNATURE',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_daily_confirmations_record ON daily_work_confirmations(work_record_id);
CREATE INDEX idx_daily_confirmations_status ON daily_work_confirmations(status);
