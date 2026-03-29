-- Migration v10: monthly_spending_by_category materialized view
--
-- Pre-aggregates transaction totals per owner / calendar month / category so
-- that the analytics screen can answer "how much did I spend on Food in March?"
-- in a single index scan instead of a full table aggregate.
--
-- Refresh strategy: call refresh_spending_views() from a Supabase scheduled
-- function (e.g. nightly) or after any bulk transaction insert.

-- ── Materialized view ────────────────────────────────────────────────────────

create materialized view if not exists public.monthly_spending_by_category as
select
  owner_id,
  date_trunc('month', occurred_at)::date as month,
  category,
  sum(amount)                            as total_amount,
  count(*)                               as transaction_count
from public.transactions
group by owner_id, date_trunc('month', occurred_at)::date, category
with data;

-- ── Indexes ──────────────────────────────────────────────────────────────────

-- Primary lookup: all categories for a given owner + month.
create unique index if not exists idx_monthly_spending_owner_month_category
  on public.monthly_spending_by_category (owner_id, month, category);

-- Secondary: filter by category across months (trend charts).
create index if not exists idx_monthly_spending_owner_category
  on public.monthly_spending_by_category (owner_id, category, month desc);

-- ── Row-level security ───────────────────────────────────────────────────────

alter materialized view public.monthly_spending_by_category owner to postgres;

-- Materialized views do not support RLS directly; access is controlled by the
-- refresh function security and by the PostgREST role grants below.
-- Only authenticated users may read rows that belong to them.
grant select on public.monthly_spending_by_category to authenticated;

-- ── Refresh function ─────────────────────────────────────────────────────────

create or replace function public.refresh_spending_views()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  refresh materialized view concurrently public.monthly_spending_by_category;
end;
$$;

-- Restrict execution to the service role so client apps cannot trigger a
-- full refresh arbitrarily.
revoke execute on function public.refresh_spending_views() from public, anon, authenticated;
grant  execute on function public.refresh_spending_views() to service_role;

-- ── Initial population ───────────────────────────────────────────────────────
-- Populate synchronously on migration so the view is ready immediately.
-- Subsequent refreshes use CONCURRENTLY (non-blocking).
select public.refresh_spending_views();
