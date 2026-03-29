-- Migration v16: preserve device SMS receive timestamp in import queue.
--
-- Why:
-- - Parser currently falls back to DateTime.now() when message text has no
--   explicit date/time.
-- - Device SMS rows include a trustworthy receive timestamp.
-- - Storing source_timestamp lets queue processing use that timestamp and
--   avoid "now()" drift during historical imports.

alter table public.sms_import_queue
  add column if not exists source_timestamp timestamptz;

create index if not exists idx_sms_import_queue_owner_source_timestamp
  on public.sms_import_queue (owner_id, source_timestamp desc);
