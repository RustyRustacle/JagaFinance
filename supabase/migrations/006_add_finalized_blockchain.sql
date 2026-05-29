-- Add FINALIZED to receipt_status enum
ALTER TYPE "public"."receipt_status" ADD VALUE IF NOT EXISTS 'FINALIZED' AFTER 'COMPLETED';

-- Add blockchain columns to receipts table
ALTER TABLE "public"."receipts"
  ADD COLUMN IF NOT EXISTS "blockchain_tx_hash" VARCHAR(100),
  ADD COLUMN IF NOT EXISTS "blockchain_status" VARCHAR(20) DEFAULT 'PENDING',
  ADD COLUMN IF NOT EXISTS "blockchain_network" VARCHAR(50) DEFAULT 'base_sepolia',
  ADD COLUMN IF NOT EXISTS "blockchain_submitted_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "blockchain_confirmed_at" TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_receipts_blockchain_tx_hash ON "public"."receipts"("blockchain_tx_hash");
