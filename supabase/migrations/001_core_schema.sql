-- ============================================================
-- VAULTLEDGER SUPABASE MIGRATION 001
-- Core Schema: Tenants, Users, RBAC, Invites
-- ============================================================

-- ======================
-- ENUM TYPES
-- ======================

CREATE TYPE "public"."app_role" AS ENUM ('ADMIN', 'FINANCE', 'VIEWER');
CREATE TYPE "public"."invite_status" AS ENUM ('PENDING', 'ACCEPTED', 'EXPIRED', 'DECLINED');

-- ======================
-- TENANTS
-- ======================

CREATE TABLE "public"."tenants" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "name" VARCHAR(255) NOT NULL,
  "slug" VARCHAR(50) UNIQUE NOT NULL,
  "industry" VARCHAR(100),
  "currency" VARCHAR(3) NOT NULL DEFAULT 'IDR',
  "fiscal_year_start" VARCHAR(5) NOT NULL DEFAULT '01-01',
  "timezone" VARCHAR(50) NOT NULL DEFAULT 'Asia/Jakarta',
  "language" VARCHAR(5) NOT NULL DEFAULT 'id',
  "plan" VARCHAR(20) NOT NULL DEFAULT 'FREE',
  "settings" JSONB NOT NULL DEFAULT '{}',
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ======================
-- USERS PROFILE
-- ======================

CREATE TABLE "public"."users" (
  "id" UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  "email" VARCHAR(255) NOT NULL,
  "name" VARCHAR(255),
  "avatar_url" TEXT,
  "phone" VARCHAR(20),
  "locale" VARCHAR(5) NOT NULL DEFAULT 'id',
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ======================
-- TENANT MEMBERS (RBAC)
-- ======================

CREATE TABLE "public"."tenant_members" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "user_id" UUID NOT NULL REFERENCES "public"."users"("id") ON DELETE CASCADE,
  "role" "public"."app_role" NOT NULL DEFAULT 'VIEWER',
  "status" "public"."invite_status" NOT NULL DEFAULT 'PENDING',
  "invited_by" UUID REFERENCES "public"."users"("id"),
  "invited_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "accepted_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE("tenant_id", "user_id")
);

CREATE INDEX idx_tenant_members_tenant ON "public"."tenant_members"("tenant_id");
CREATE INDEX idx_tenant_members_user ON "public"."tenant_members"("user_id");
CREATE INDEX idx_tenant_members_role ON "public"."tenant_members"("tenant_id", "role");

-- ======================
-- INVITES
-- ======================

CREATE TABLE "public"."invites" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "public"."tenants"("id") ON DELETE CASCADE,
  "email" VARCHAR(255) NOT NULL,
  "role" "public"."app_role" NOT NULL DEFAULT 'VIEWER',
  "token" VARCHAR(255) UNIQUE NOT NULL,
  "status" "public"."invite_status" NOT NULL DEFAULT 'PENDING',
  "expires_at" TIMESTAMPTZ NOT NULL,
  "created_by" UUID REFERENCES "public"."users"("id"),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "accepted_at" TIMESTAMPTZ
);

-- ======================
-- ROW-LEVEL SECURITY
-- ======================

ALTER TABLE "public"."tenants" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."tenant_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."invites" ENABLE ROW LEVEL SECURITY;

-- Helper function to get current user's tenant IDs
CREATE OR REPLACE FUNCTION "public"."get_user_tenant_ids"()
RETURNS TABLE(tenant_id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT tm.tenant_id
  FROM "public"."tenant_members" tm
  WHERE tm.user_id = auth.uid() AND tm.status = 'ACCEPTED';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user has role in tenant
CREATE OR REPLACE FUNCTION "public"."has_tenant_role"(p_tenant_id UUID, p_role "public"."app_role")
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM "public"."tenant_members"
    WHERE tenant_id = p_tenant_id
      AND user_id = auth.uid()
      AND role = p_role
      AND status = 'ACCEPTED'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user has any of the roles
CREATE OR REPLACE FUNCTION "public"."has_tenant_role_any"(p_tenant_id UUID, p_roles "public"."app_role"[])
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM "public"."tenant_members"
    WHERE tenant_id = p_tenant_id
      AND user_id = auth.uid()
      AND role = ANY(p_roles)
      AND status = 'ACCEPTED'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies

-- Users can view their own profile
CREATE POLICY "users_view_own" ON "public"."users"
  FOR SELECT USING (id = auth.uid());

-- Users can update their own profile
CREATE POLICY "users_update_own" ON "public"."users"
  FOR UPDATE USING (id = auth.uid());

-- Tenants: visible to members
CREATE POLICY "tenants_view_members" ON "public"."tenants"
  FOR SELECT USING (id IN (SELECT get_user_tenant_ids()));

-- Tenant members: view all members of own tenants
CREATE POLICY "members_view" ON "public"."tenant_members"
  FOR SELECT USING (tenant_id IN (SELECT get_user_tenant_ids()));

-- Admin can manage members
CREATE POLICY "members_admin_manage" ON "public"."tenant_members"
  FOR ALL USING (has_tenant_role(tenant_id, 'ADMIN'));

-- Invites: members can view
CREATE POLICY "invites_view" ON "public"."invites"
  FOR SELECT USING (tenant_id IN (SELECT get_user_tenant_ids()));

-- Finance+ can manage invites
CREATE POLICY "invites_manage" ON "public"."invites"
  FOR ALL USING (has_tenant_role_any(tenant_id, ARRAY['ADMIN', 'FINANCE']));

-- Anyone can accept an invite (no auth required for accept endpoint)
CREATE POLICY "invites_accept" ON "public"."invites"
  FOR UPDATE USING (true) WITH CHECK (true);

-- ======================
-- TRIGGERS
-- ======================

CREATE OR REPLACE FUNCTION "public"."update_updated_at"()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_updated_at BEFORE UPDATE ON "public"."tenants"
  FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON "public"."users"
  FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();

CREATE TRIGGER trg_tenant_members_updated_at BEFORE UPDATE ON "public"."tenant_members"
  FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION "public"."handle_new_user"()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO "public"."users" ("id", "email", "name")
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_user"();
