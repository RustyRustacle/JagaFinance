-- ============================================================
-- VAULTLEDGER SUPABASE MIGRATION 005
-- Export Storage Bucket
-- ============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'exports',
  'exports',
  false,
  52428800,
  ARRAY['text/csv', 'application/pdf', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'text/tab-separated-values']
) ON CONFLICT (id) DO NOTHING;

CREATE POLICY "exports_upload_tenant" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'exports'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN (
      SELECT tm.tenant_id::TEXT
      FROM public.tenant_members tm
      WHERE tm.user_id = auth.uid() AND tm.status = 'ACCEPTED'
    )
  );

CREATE POLICY "exports_view_owner" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'exports'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN (
      SELECT tm.tenant_id::TEXT
      FROM public.tenant_members tm
      WHERE tm.user_id = auth.uid() AND tm.status = 'ACCEPTED'
    )
  );

CREATE POLICY "exports_delete_owner" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'exports'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN (
      SELECT tm.tenant_id::TEXT
      FROM public.tenant_members tm
      WHERE tm.user_id = auth.uid() AND tm.role = 'ADMIN' AND tm.status = 'ACCEPTED'
    )
  );
