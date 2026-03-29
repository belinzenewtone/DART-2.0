-- Migration v12: scale hardening + parser parity fields
--
-- Keeps existing IDs and PKs intact (non-destructive) while adding:
-- 1) transaction_type + balance_after on transactions
-- 2) owner-scoped composite uniqueness/index patterns inspired by audit findings
-- 3) extra hot-path indexes for 50k+ row filtering/sorting workloads

alter table public.transactions
  add column if not exists transaction_type text not null default 'expense';

alter table public.transactions
  add column if not exists balance_after double precision;

create index if not exists idx_transactions_owner_type
  on public.transactions (owner_id, transaction_type, occurred_at desc);

create index if not exists idx_tasks_owner_priority_due
  on public.tasks (owner_id, priority, due_at);

create index if not exists idx_events_owner_completed_start
  on public.events (owner_id, completed, start_at);

create unique index if not exists idx_transactions_owner_id_unique
  on public.transactions (owner_id, id);

create unique index if not exists idx_tasks_owner_id_unique
  on public.tasks (owner_id, id);

create unique index if not exists idx_events_owner_id_unique
  on public.events (owner_id, id);

create unique index if not exists idx_incomes_owner_id_unique
  on public.incomes (owner_id, id);

create unique index if not exists idx_budgets_owner_id_unique
  on public.budgets (owner_id, id);
