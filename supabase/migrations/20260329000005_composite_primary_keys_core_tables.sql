-- Migration v14: promote core owner-scoped tables to composite PKs.
--
-- Why:
-- - Matches audit recommendation for multi-tenant scale hardening.
-- - Preserves existing numeric IDs while enforcing owner + ID identity.
-- - Keeps compatibility with existing app code by retaining unique id indexes.

alter table public.transactions drop constraint if exists transactions_pkey;
alter table public.transactions add primary key (owner_id, id);

alter table public.tasks drop constraint if exists tasks_pkey;
alter table public.tasks add primary key (owner_id, id);

alter table public.events drop constraint if exists events_pkey;
alter table public.events add primary key (owner_id, id);

alter table public.incomes drop constraint if exists incomes_pkey;
alter table public.incomes add primary key (owner_id, id);

alter table public.budgets drop constraint if exists budgets_pkey;
alter table public.budgets add primary key (owner_id, id);

alter table public.recurring_templates drop constraint if exists recurring_templates_pkey;
alter table public.recurring_templates add primary key (owner_id, id);

-- Compatibility uniqueness: keeps fast id-only lookups if any legacy code relies on it.
create unique index if not exists idx_transactions_id_unique
  on public.transactions (id);
create unique index if not exists idx_tasks_id_unique
  on public.tasks (id);
create unique index if not exists idx_events_id_unique
  on public.events (id);
create unique index if not exists idx_incomes_id_unique
  on public.incomes (id);
create unique index if not exists idx_budgets_id_unique
  on public.budgets (id);
create unique index if not exists idx_recurring_templates_id_unique
  on public.recurring_templates (id);

-- Additional owner-scoped indexes aligned with critical query paths.
create index if not exists idx_transactions_owner_date
  on public.transactions (owner_id, occurred_at desc);
create index if not exists idx_transactions_owner_category_date
  on public.transactions (owner_id, category, occurred_at desc);
create index if not exists idx_tasks_owner_status_due
  on public.tasks (owner_id, completed, due_at);
create index if not exists idx_events_owner_status_start
  on public.events (owner_id, completed, start_at);
create index if not exists idx_incomes_owner_date
  on public.incomes (owner_id, received_at desc);
create index if not exists idx_recurring_templates_owner_enabled_next
  on public.recurring_templates (owner_id, enabled, next_run_at);
