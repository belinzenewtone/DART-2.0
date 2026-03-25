-- Schedule nightly refresh of monthly_spending_by_category at 02:00 UTC.
-- Requires pg_cron extension (available on Pro plan and above).
-- On Free plan, call refresh_spending_views() manually or via an Edge Function.

create extension if not exists pg_cron schema extensions;

select cron.schedule(
  'nightly-spending-refresh',
  '0 2 * * *',
  'select public.refresh_spending_views();'
);
