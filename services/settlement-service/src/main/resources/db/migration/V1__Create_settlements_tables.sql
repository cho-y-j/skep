CREATE TABLE settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_plan_id UUID NOT NULL,
  supplier_id UUID NOT NULL,
  bp_company_id UUID NOT NULL,
  year_month VARCHAR(7),
  total_daily_amount DECIMAL(15,2) DEFAULT 0,
  total_overtime_amount DECIMAL(15,2) DEFAULT 0,
  total_early_morning_amount DECIMAL(15,2) DEFAULT 0,
  total_night_amount DECIMAL(15,2) DEFAULT 0,
  total_overnight_amount DECIMAL(15,2) DEFAULT 0,
  supply_amount DECIMAL(15,2) DEFAULT 0,
  tax_amount DECIMAL(15,2) DEFAULT 0,
  total_amount DECIMAL(15,2) DEFAULT 0,
  status VARCHAR(20) DEFAULT 'DRAFT',
  sent_at TIMESTAMP,
  paid_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE settlement_daily_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  settlement_id UUID REFERENCES settlements(id) ON DELETE CASCADE,
  work_date DATE NOT NULL,
  is_daily_work BOOLEAN DEFAULT FALSE,
  daily_amount DECIMAL(12,2) DEFAULT 0,
  overtime_hours DECIMAL(4,2) DEFAULT 0,
  overtime_amount DECIMAL(12,2) DEFAULT 0,
  early_morning_count INT DEFAULT 0,
  early_morning_amount DECIMAL(12,2) DEFAULT 0,
  night_hours DECIMAL(4,2) DEFAULT 0,
  night_amount DECIMAL(12,2) DEFAULT 0,
  is_overnight BOOLEAN DEFAULT FALSE,
  overnight_amount DECIMAL(12,2) DEFAULT 0,
  day_total DECIMAL(12,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_settlements_supplier ON settlements(supplier_id);
CREATE INDEX idx_settlements_bp_company ON settlements(bp_company_id);
CREATE INDEX idx_settlements_year_month ON settlements(year_month);
CREATE INDEX idx_settlements_status ON settlements(status);
CREATE INDEX idx_settlement_daily_details_settlement ON settlement_daily_details(settlement_id);
CREATE INDEX idx_settlement_daily_details_work_date ON settlement_daily_details(work_date);
