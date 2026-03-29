-- Migration v15: index parity + query hardening for high-row workloads.
--
-- Goal:
-- - Keep index coverage aligned across migrated and fresh-schema environments.
-- - Harden common owner-scoped filter/sort query paths before 50k+ row growth.

create index if not exists idx_transactions_owner_type
  on public.transactions (owner_id, transaction_type, occurred_at desc);

create index if not exists idx_transactions_owner_title_occurred
  on public.transactions (owner_id, lower(title), occurred_at desc);

create index if not exists idx_transactions_owner_title_amount
  on public.transactions (owner_id, lower(title), amount);

create index if not exists idx_transactions_owner_category_date
  on public.transactions (owner_id, category, occurred_at desc);

create index if not exists idx_transactions_owner_source_date
  on public.transactions (owner_id, source, occurred_at desc);

create index if not exists idx_tasks_owner_priority_due
  on public.tasks (owner_id, priority, due_at);

create index if not exists idx_tasks_owner_status_due
  on public.tasks (owner_id, completed, due_at);

create index if not exists idx_events_owner_status_start
  on public.events (owner_id, completed, start_at);

create index if not exists idx_events_owner_type_start
  on public.events (owner_id, event_type, start_at);

create index if not exists idx_events_owner_priority_start
  on public.events (owner_id, priority, start_at);

create index if not exists idx_incomes_owner_source_date
  on public.incomes (owner_id, source, received_at desc);

create index if not exists idx_recurring_templates_owner_enabled_next
  on public.recurring_templates (owner_id, enabled, next_run_at);

create index if not exists idx_recurring_owner_kind_enabled_next
  on public.recurring_templates (owner_id, kind, enabled, next_run_at);

create index if not exists idx_sms_import_queue_owner_route_status
  on public.sms_import_queue (owner_id, route, status, next_retry_at);

create index if not exists idx_sms_review_owner_created
  on public.sms_review_queue (owner_id, created_at desc);

create index if not exists idx_sms_quarantine_owner_created
  on public.sms_quarantine (owner_id, created_at desc);

create index if not exists idx_paybill_owner_last_seen
  on public.paybill_registry (owner_id, last_seen_at desc);

create index if not exists idx_fuliza_owner_occurred
  on public.fuliza_lifecycle_events (owner_id, occurred_at desc);
