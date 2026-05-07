-- ============================================================
-- VAULTLEDGER SUPABASE MIGRATION 002
-- Receipts, OCR Data, Expenses, Categories, Budgets
-- ============================================================

-- ======================
-- ENUMS
-- ======================

CREATE TYPE "public"."receipt_status" AS ENUM ('UPLOADED', 'PROCESSING', 'COMPLETED', 'FAILED', 'REJECTED');
CREATE TYPE "public"."expense_status" AS ENUM ('DRAFT', 'CONFIRMED', 'RECONCILED', 'VOID');
CREATE TYPE "public"."budget_period" AS ENUM ('MONTHLY', 'QUARTERLY', 'YEARLY');
CREATE TYPE "public"."alert_channel" AS ENUM ('EMAIL', 'WEBHOOK', 'IN_APP');

-- ======================
-- RECEIPTS
-- ======================

CREATE TABLE "public"."receipts" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "uploaded_by" UUID NOT NULL REFERENCES "public"."users"("id"),
  "file_url" TEXT NOT NULL,
  "file_name" VARCHAR(500) NOT NULL,
  "file_type" VARCHAR(50) NOT NULL,
  "file_size" INTEGER NOT NULL,
  "status" "public"."receipt_status" NOT NULL DEFAULT 'UPLOADED',
  "ocr_provider" VARCHAR(50) DEFAULT 'google_vision',
  "ocr_confidence" DECIMAL(5,2),
  "ocr_raw_response" JSONB,
  "error_message" TEXT,
  "processed_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_receipts_tenant ON "public"."receipts"("tenant_id");
CREATE INDEX idx_receipts_status ON "public"."receipts"("tenant_id", "status");
CREATE INDEX idx_receipts_date ON "public"."receipts"("tenant_id", "created_at" DESC);

-- ======================
-- RECEIPT DATA (OCR Extracted)
-- ======================

CREATE TABLE "public"."receipt_data" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "receipt_id" UUID UNIQUE NOT NULL REFERENCES "public"."receipts"("id") ON DELETE CASCADE,

  "merchant_name" VARCHAR(255),
  "merchant_address" TEXT,
  "merchant_phone" VARCHAR(20),
  "tax_id" VARCHAR(50),

  "receipt_number" VARCHAR(100),
  "transaction_date" TIMESTAMPTZ,
  "subtotal" DECIMAL(15,2),
  "tax_amount" DECIMAL(15,2),
  "tax_rate" DECIMAL(5,2),
  "discount_amount" DECIMAL(15,2),
  "total_amount" DECIMAL(15,2) NOT NULL,
  "currency" VARCHAR(3) NOT NULL DEFAULT 'IDR',
  "payment_method" VARCHAR(50),

  "line_items" JSONB,

  "is_verified" BOOLEAN NOT NULL DEFAULT false,
  "verified_by" UUID REFERENCES "public"."users"("id"),
  "verification_notes" TEXT,

  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_receipt_data_receipt ON "public"."receipt_data"("receipt_id");

-- ======================
-- EXPENSE CATEGORIES
-- ======================

CREATE TABLE "public"."expense_categories" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "name" VARCHAR(100) NOT NULL,
  "name_en" VARCHAR(100),
  "color" VARCHAR(7) NOT NULL DEFAULT '#6B7280',
  "icon" VARCHAR(50),
  "parent_id" UUID REFERENCES "public"."expense_categories"("id"),
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "sort_order" INTEGER NOT NULL DEFAULT 0,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE("tenant_id", "name")
);

CREATE INDEX idx_categories_tenant ON "public"."expense_categories"("tenant_id");

-- ======================
-- EXPENSES
-- ======================

CREATE TABLE "public"."expenses" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "receipt_id" UUID UNIQUE REFERENCES "public"."receipts"("id") ON DELETE SET NULL,
  "category_id" UUID NOT NULL REFERENCES "public"."expense_categories"("id"),
  "created_by" UUID NOT NULL REFERENCES "public"."users"("id"),

  "title" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "amount" DECIMAL(15,2) NOT NULL,
  "currency" VARCHAR(3) NOT NULL DEFAULT 'IDR',
  "expense_date" TIMESTAMPTZ NOT NULL,
  "payment_method" VARCHAR(50),
  "status" "public"."expense_status" NOT NULL DEFAULT 'DRAFT',

  "journal_entry_id" VARCHAR(100),
  "cost_center" VARCHAR(100),
  "project_code" VARCHAR(100),
  "tax_deductible" BOOLEAN NOT NULL DEFAULT false,

  "tags" VARCHAR(50)[],
  "metadata" JSONB NOT NULL DEFAULT '{}',

  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_expenses_tenant ON "public"."expenses"("tenant_id");
CREATE INDEX idx_expenses_category ON "public"."expenses"("tenant_id", "category_id");
CREATE INDEX idx_expenses_date ON "public"."expenses"("tenant_id", "expense_date" DESC);
CREATE INDEX idx_expenses_status ON "public"."expenses"("tenant_id", "status");

-- ======================
-- BUDGETS
-- ======================

CREATE TABLE "public"."budgets" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "category_id" UUID NOT NULL REFERENCES "public"."expense_categories"("id"),

  "amount" DECIMAL(15,2) NOT NULL,
  "currency" VARCHAR(3) NOT NULL DEFAULT 'IDR',
  "period" "public"."budget_period" NOT NULL DEFAULT 'MONTHLY',
  "start_date" TIMESTAMPTZ NOT NULL,
  "end_date" TIMESTAMPTZ NOT NULL,

  "alert_threshold" DECIMAL(5,2) NOT NULL DEFAULT 80.00,
  "is_active" BOOLEAN NOT NULL DEFAULT true,

  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE("tenant_id", "category_id", "start_date", "end_date", "period")
);

CREATE INDEX idx_budgets_tenant ON "public"."budgets"("tenant_id");
CREATE INDEX idx_budgets_category ON "public"."budgets"("tenant_id", "category_id");

-- ======================
-- BUDGET ALERTS
-- ======================

CREATE TABLE "public"."budget_alerts" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "budget_id" UUID NOT NULL REFERENCES "public"."budgets"("id") ON DELETE CASCADE,

  "triggered_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "current_amount" DECIMAL(15,2) NOT NULL,
  "budget_amount" DECIMAL(15,2) NOT NULL,
  "percentage_used" DECIMAL(5,2) NOT NULL,
  "channel" "public"."alert_channel" NOT NULL DEFAULT 'EMAIL',
  "recipient_email" VARCHAR(255) NOT NULL,
  "status" VARCHAR(20) NOT NULL DEFAULT 'SENT',
  "error_message" TEXT,

  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_budget_alerts_budget ON "public"."budget_alerts"("budget_id");

-- ======================
-- ROW-LEVEL SECURITY
-- ======================

ALTER TABLE "public"."receipts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."receipt_data" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."expense_categories" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."expenses" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."budgets" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."budget_alerts" ENABLE ROW LEVEL SECURITY;

-- Receipts
CREATE POLICY "receipts_view" ON "public"."receipts"
  FOR SELECT USING (tenant_id IN (SELECT get_user_tenant_ids()));

CREATE POLICY "receipts_finance_create" ON "public"."receipts"
  FOR INSERT WITH CHECK (has_tenant_role_any(tenant_id, ARRAY['ADMIN', 'FINANCE']));

CREATE POLICY "receipts_finance_update" ON "public"."receipts"
  FOR UPDATE USING (has_tenant_role_any(tenant_id, ARRAY['ADMIN', 'FINANCE']));

CREATE POLICY "receipts_admin_delete" ON "public"."receipts"
  FOR DELETE USING (has_tenant_role(tenant_id, 'ADMIN'));

-- Receipt Data
CREATE POLICY "receipt_data_view" ON "public"."receipt_data"
  FOR SELECT USING (
    receipt_id IN (
      SELECT r.id FROM "public"."receipts" r
      WHERE r.tenant_id IN (SELECT get_user_tenant_ids())
    )
  );

CREATE POLICY "receipt_data_finance_manage" ON "public"."receipt_data"
  FOR ALL USING (
    receipt_id IN (
      SELECT r.id FROM "public"."receipts" r
      WHERE has_tenant_role_any(r.tenant_id, ARRAY['ADMIN', 'FINANCE'])
    )
  );

-- Categories
CREATE POLICY "categories_view" ON "public"."expense_categories"
  FOR SELECT USING (tenant_id IN (SELECT get_user_tenant_ids()));

CREATE POLICY "categories_finance_manage" ON "public"."expense_categories"
  FOR ALL USING (has_tenant_role_any(tenant_id, ARRAY['ADMIN', 'FINANCE']));

-- Expenses
CREATE POLICY "expenses_view" ON "public"."expenses"
  FOR SELECT USING (tenant_id IN (SELECT get_user_tenant_ids()));

CREATE POLICY "expenses_finance_create" ON "public"."expenses"
  FOR INSERT WITH CHECK (has_tenant_role_any(tenant_id, ARRAY['ADMIN', 'FINANCE']));

CREATE POLICY "expenses_finance_update" ON "public"."expenses"
  FOR UPDATE USING (has_tenant_role_any(tenant_id, ARRAY['ADMIN', 'FINANCE']));

CREATE POLICY "expenses_admin_delete" ON "public"."expenses"
  FOR DELETE USING (has_tenant_role(tenant_id, 'ADMIN'));

-- Budgets
CREATE POLICY "budgets_view" ON "public"."budgets"
  FOR SELECT USING (tenant_id IN (SELECT get_user_tenant_ids()));

CREATE POLICY "budgets_finance_manage" ON "public"."budgets"
  FOR ALL USING (has_tenant_role_any(tenant_id, ARRAY['ADMIN', 'FINANCE']));

-- Budget Alerts (read-only)
CREATE POLICY "budget_alerts_view" ON "public"."budget_alerts"
  FOR SELECT USING (tenant_id IN (SELECT get_user_tenant_ids()));

-- ======================
-- TRIGGERS
-- ======================

CREATE TRIGGER trg_receipts_updated_at BEFORE UPDATE ON "public"."receipts"
  FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();

CREATE TRIGGER trg_receipt_data_updated_at BEFORE UPDATE ON "public"."receipt_data"
  FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();

CREATE TRIGGER trg_expenses_updated_at BEFORE UPDATE ON "public"."expenses"
  FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();

CREATE TRIGGER trg_categories_updated_at BEFORE UPDATE ON "public"."expense_categories"
  FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();

CREATE TRIGGER trg_budgets_updated_at BEFORE UPDATE ON "public"."budgets"
  FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();

-- ======================
-- SEED: Default Categories
-- ======================

CREATE OR REPLACE FUNCTION "public"."seed_default_categories"(p_tenant_id UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO "public"."expense_categories" (tenant_id, name, name_en, color, icon, sort_order) VALUES
    (p_tenant_id, 'Transportasi', 'Transportation', '#3B82F6', 'car', 1),
    (p_tenant_id, 'Makanan & Minuman', 'Food & Beverages', '#F59E0B', 'utensils', 2),
    (p_tenant_id, 'Perlengkapan Kantor', 'Office Supplies', '#10B981', 'box', 3),
    (p_tenant_id, 'Utilitas', 'Utilities', '#8B5CF6', 'bolt', 4),
    (p_tenant_id, 'Marketing & Iklan', 'Marketing & Ads', '#EC4899', 'megaphone', 5),
    (p_tenant_id, 'Gaji & Upah', 'Payroll', '#EF4444', 'wallet', 6),
    (p_tenant_id, 'Sewa', 'Rent', '#6B7280', 'home', 7),
    (p_tenant_id, 'Perawatan & Servis', 'Maintenance', '#06B6D4', 'wrench', 8),
    (p_tenant_id, 'Perjalanan Dinas', 'Business Travel', '#84CC16', 'plane', 9),
    (p_tenant_id, 'Lainnya', 'Others', '#64748B', 'ellipsis', 10);
END;
$$ LANGUAGE plpgsql;
