-- ============================================================
-- VAULTLEDGER SUPABASE MIGRATION 004
-- Storage Buckets + RLS Policies
-- ============================================================

-- ======================
-- STORAGE BUCKET
-- ======================

-- Create the receipts bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'receipts',
  'receipts',
  false,
  10485760,  -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- ======================
-- STORAGE RLS POLICIES
-- ======================

-- Allow authenticated users to upload receipts
CREATE POLICY "receipts_upload_auth" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'receipts'
    AND auth.role() = 'authenticated'
  );

-- Allow users to view receipts from their tenant
CREATE POLICY "receipts_view_auth" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'receipts'
    AND auth.role() = 'authenticated'
  );

-- Allow users to delete their own receipts
CREATE POLICY "receipts_delete_auth" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'receipts'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN (
      SELECT tm.tenant_id::TEXT
      FROM public.tenant_members tm
      WHERE tm.user_id = auth.uid()
        AND tm.role = 'ADMIN'
        AND tm.status = 'ACCEPTED'
    )
  );
