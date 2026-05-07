-- ============================================================
-- VAULTLEDGER SUPABASE MIGRATION 003
-- Audit Logs, API Keys, Webhooks, Export Jobs
-- ============================================================

-- ======================
-- ENUMS
-- ======================

CREATE TYPE "public"."webhook_event" AS ENUM ('RECEIPT_UPLOADED', 'RECEIPT_PROCESSED', 'BUDGET_EXCEEDED', 'EXPENSE_CREATED');
CREATE TYPE "public"."audit_action" AS ENUM ('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'INVITE_SEND', 'INVITE_ACCEPT', 'EXPORT');

-- ======================
-- API KEYS
-- ======================

CREATE TABLE "public"."api_keys" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "name" VARCHAR(100) NOT NULL,
  "key_hash" VARCHAR(255) NOT NULL,
  "key_prefix" VARCHAR(10) NOT NULL,
  "permissions" VARCHAR(50)[] NOT NULL DEFAULT '{}',
  "last_used_at" TIMESTAMPTZ,
  "expires_at" TIMESTAMPTZ,
  "revoked_at" TIMESTAMPTZ,
  "revoked_by" UUID REFERENCES "public"."users"("id"),
  "created_by" UUID NOT NULL REFERENCES "public"."users"("id"),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_api_keys_tenant ON "public"."api_keys"("tenant_id");

-- ======================
-- WEBHOOKS
-- ======================

CREATE TABLE "public"."webhooks" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "url" TEXT NOT NULL,
  "secret" VARCHAR(255) NOT NULL,
  "events" "public"."webhook_event"[] NOT NULL DEFAULT '{}',
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_by" UUID NOT NULL REFERENCES "public"."users"("id"),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE "public"."webhook_deliveries" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "webhook_id" UUID NOT NULL REFERENCES "public"."webhooks"("id") ON DELETE CASCADE,
  "event_type" "public"."webhook_event" NOT NULL,
  "payload" JSONB NOT NULL,
  "status" VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "response_code" INTEGER,
  "response_body" TEXT,
  "attempt" INTEGER NOT NULL DEFAULT 1,
  "max_attempts" INTEGER NOT NULL DEFAULT 3,
  "next_retry_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_webhooks_tenant ON "public"."webhooks"("tenant_id");

-- ======================
-- AUDIT LOGS
-- ======================

CREATE TABLE "public"."audit_logs" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "user_id" UUID REFERENCES "public"."users"("id") ON DELETE SET NULL,
  "action" "public"."audit_action" NOT NULL,
  "entity_type" VARCHAR(50) NOT NULL,
  "entity_id" UUID,
  "changes" JSONB,
  "ip_address" VARCHAR(45),
  "user_agent" TEXT,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_logs_tenant ON "public"."audit_logs"("tenant_id");
CREATE INDEX idx_audit_logs_date ON "public"."audit_logs"("tenant_id", "created_at" DESC);

-- ======================
-- EXPORT JOBS
-- ======================

CREATE TABLE "public"."export_jobs" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "requested_by" UUID NOT NULL REFERENCES "public"."users"("id"),
  "format" VARCHAR(10) NOT NULL,
  "export_type" VARCHAR(50) NOT NULL,
  "filters" JSONB NOT NULL DEFAULT '{}',
  "file_url" TEXT,
  "status" VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  "error_message" TEXT,
  "expires_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "completed_at" TIMESTAMPTZ
);

CREATE INDEX idx_export_jobs_tenant ON "public"."export_jobs"("tenant_id");

-- ======================
-- ROW-LEVEL SECURITY
-- ======================

ALTER TABLE "public"."api_keys" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."webhooks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."webhook_deliveries" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."export_jobs" ENABLE ROW LEVEL SECURITY;

-- API Keys
CREATE POLICY "api_keys_view" ON "public"."api_keys"
  FOR SELECT USING (has_tenant_role_any(tenant_id, ARRAY['ADMIN', 'FINANCE']));

CREATE POLICY "api_keys_admin_manage" ON "public"."api_keys"
  FOR ALL USING (has_tenant_role(tenant_id, 'ADMIN'));

-- Webhooks
CREATE POLICY "webhooks_view" ON "public"."webhooks"
  FOR SELECT USING (has_tenant_role_any(tenant_id, ARRAY['ADMIN', 'FINANCE']));

CREATE POLICY "webhooks_admin_manage" ON "public"."webhooks"
  FOR ALL USING (has_tenant_role(tenant_id, 'ADMIN'));

-- Webhook Deliveries
CREATE POLICY "webhook_deliveries_view" ON "public"."webhook_deliveries"
  FOR SELECT USING (
    webhook_id IN (
      SELECT w.id FROM "public"."webhooks" w
      WHERE has_tenant_role_any(w.tenant_id, ARRAY['ADMIN', 'FINANCE'])
    )
  );

-- Audit Logs (Admin only)
CREATE POLICY "audit_logs_admin_view" ON "public"."audit_logs"
  FOR SELECT USING (has_tenant_role(tenant_id, 'ADMIN'));

-- Export Jobs
CREATE POLICY "export_jobs_view" ON "public"."export_jobs"
  FOR SELECT USING (tenant_id IN (SELECT get_user_tenant_ids()));

CREATE POLICY "export_jobs_manage" ON "public"."export_jobs"
  FOR ALL USING (tenant_id IN (SELECT get_user_tenant_ids()));

-- ======================
-- TRIGGERS
-- ======================

CREATE TRIGGER trg_api_keys_updated_at BEFORE UPDATE ON "public"."api_keys"
  FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();

CREATE TRIGGER trg_webhooks_updated_at BEFORE UPDATE ON "public"."webhooks"
  FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();
