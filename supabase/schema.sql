create table if not exists public.transactions (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  category text not null,
  amount double precision not null,
  occurred_at timestamptz not null default now(),
  source text not null default 'manual',
  source_hash text
);

create index if not exists idx_transactions_owner_occurred_at
  on public.transactions (owner_id, occurred_at desc);
create index if not exists idx_transactions_owner_category
  on public.transactions (owner_id, category);
create unique index if not exists idx_transactions_owner_source_hash
  on public.transactions (owner_id, source_hash)
  where source_hash is not null;

create table if not exists public.tasks (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  completed boolean not null default false,
  due_at timestamptz,
  priority text not null default 'medium'
);

alter table public.tasks
  add column if not exists description text;

create index if not exists idx_tasks_owner_completed
  on public.tasks (owner_id, completed);
create index if not exists idx_tasks_owner_due
  on public.tasks (owner_id, due_at);

create table if not exists public.events (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  start_at timestamptz not null,
  end_at timestamptz,
  note text,
  completed boolean not null default false,
  priority text not null default 'medium',
  event_type text not null default 'general'
);

alter table public.events
  add column if not exists completed boolean not null default false;

alter table public.events
  add column if not exists priority text not null default 'medium';

alter table public.events
  add column if not exists event_type text not null default 'general';

create index if not exists idx_events_owner_start
  on public.events (owner_id, start_at);

create table if not exists public.incomes (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  amount double precision not null,
  received_at timestamptz not null default now(),
  source text not null default 'manual'
);

create index if not exists idx_incomes_owner_received
  on public.incomes (owner_id, received_at desc);

create table if not exists public.budgets (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  monthly_limit double precision not null
);

create unique index if not exists idx_budgets_owner_category
  on public.budgets (owner_id, lower(category));

create table if not exists public.recurring_templates (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,
  title text not null,
  description text,
  category text,
  amount double precision,
  priority text,
  cadence text not null,
  next_run_at timestamptz not null,
  enabled boolean not null default true
);

create index if not exists idx_recurring_owner_next
  on public.recurring_templates (owner_id, next_run_at);

create table if not exists public.user_profile (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  phone text not null,
  member_since_label text not null,
  verified boolean not null default false,
  avatar_url text
);

alter table public.user_profile
  add column if not exists avatar_url text;

create table if not exists public.assistant_messages (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  text text not null,
  is_user boolean not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_assistant_messages_owner_created
  on public.assistant_messages (owner_id, created_at, id);

create table if not exists public.app_updates (
  id bigserial primary key,
  active boolean not null default true,
  latest_version text not null,
  min_supported_version text not null,
  force_update boolean not null default false,
  title text not null default 'Update Available',
  message text not null default 'A newer version of the app is available. Please update now.',
  notes text[] not null default '{}',
  apk_url text,
  website_url text,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_app_updates_active_updated
  on public.app_updates (active, updated_at desc);

create table if not exists public.feature_flags (
  id bigserial primary key,
  flag_key text not null unique,
  enabled boolean not null default true,
  active boolean not null default true,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.sms_import_queue (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  raw_message text not null,
  source_hash text not null,
  semantic_hash text not null,
  status text not null default 'pending',
  route text not null default 'directLedger',
  confidence double precision not null default 0,
  attempt integer not null default 0,
  next_retry_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_sms_import_queue_owner_source_hash
  on public.sms_import_queue (owner_id, source_hash);
create index if not exists idx_sms_import_queue_owner_status
  on public.sms_import_queue (owner_id, status, next_retry_at);

create table if not exists public.sms_import_audit (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  source_hash text not null,
  semantic_hash text not null,
  route text not null,
  confidence double precision not null,
  decision text not null,
  status text not null,
  payload jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_sms_import_audit_owner_created
  on public.sms_import_audit (owner_id, created_at desc);
create index if not exists idx_sms_import_audit_owner_semantic
  on public.sms_import_audit (owner_id, semantic_hash);

create table if not exists public.sms_review_queue (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  source_hash text not null,
  semantic_hash text not null,
  title text not null,
  category text not null,
  amount double precision not null,
  occurred_at timestamptz not null,
  raw_message text not null,
  confidence double precision not null,
  status text not null default 'pending',
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create unique index if not exists idx_sms_review_owner_source_hash
  on public.sms_review_queue (owner_id, source_hash);
create index if not exists idx_sms_review_owner_status
  on public.sms_review_queue (owner_id, status, created_at desc);

create table if not exists public.sms_quarantine (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  source_hash text not null,
  semantic_hash text not null,
  raw_message text not null,
  reason text not null,
  confidence double precision not null,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create unique index if not exists idx_sms_quarantine_owner_source_hash
  on public.sms_quarantine (owner_id, source_hash);
create index if not exists idx_sms_quarantine_owner_status
  on public.sms_quarantine (owner_id, status, created_at desc);

create table if not exists public.paybill_registry (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  paybill text not null,
  display_name text not null,
  last_seen_at timestamptz not null default now(),
  usage_count integer not null default 1
);

create unique index if not exists idx_paybill_owner_value
  on public.paybill_registry (owner_id, paybill);

create table if not exists public.fuliza_lifecycle_events (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  mpesa_code text not null,
  event_kind text not null,
  amount double precision not null,
  occurred_at timestamptz not null,
  raw_message text not null,
  source_hash text,
  created_at timestamptz not null default now()
);

create unique index if not exists idx_fuliza_owner_code_kind
  on public.fuliza_lifecycle_events (owner_id, mpesa_code, event_kind);

alter table public.transactions enable row level security;
alter table public.tasks enable row level security;
alter table public.events enable row level security;
alter table public.user_profile enable row level security;
alter table public.assistant_messages enable row level security;
alter table public.app_updates enable row level security;
alter table public.incomes enable row level security;
alter table public.budgets enable row level security;
alter table public.recurring_templates enable row level security;
alter table public.feature_flags enable row level security;
alter table public.sms_import_queue enable row level security;
alter table public.sms_import_audit enable row level security;
alter table public.sms_review_queue enable row level security;
alter table public.sms_quarantine enable row level security;
alter table public.paybill_registry enable row level security;
alter table public.fuliza_lifecycle_events enable row level security;

drop policy if exists "transactions_owner_rw" on public.transactions;
create policy "transactions_owner_rw"
  on public.transactions
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "tasks_owner_rw" on public.tasks;
create policy "tasks_owner_rw"
  on public.tasks
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "events_owner_rw" on public.events;
create policy "events_owner_rw"
  on public.events
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "assistant_messages_owner_rw" on public.assistant_messages;
create policy "assistant_messages_owner_rw"
  on public.assistant_messages
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "user_profile_owner_rw" on public.user_profile;
create policy "user_profile_owner_rw"
  on public.user_profile
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "incomes_owner_rw" on public.incomes;
create policy "incomes_owner_rw"
  on public.incomes
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "budgets_owner_rw" on public.budgets;
create policy "budgets_owner_rw"
  on public.budgets
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "recurring_templates_owner_rw" on public.recurring_templates;
create policy "recurring_templates_owner_rw"
  on public.recurring_templates
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "app_updates_public_read" on public.app_updates;
create policy "app_updates_public_read"
  on public.app_updates
  for select
  to anon, authenticated
  using (active = true);

drop policy if exists "feature_flags_public_read" on public.feature_flags;
create policy "feature_flags_public_read"
  on public.feature_flags
  for select
  to anon, authenticated
  using (active = true);

drop policy if exists "sms_import_queue_owner_rw" on public.sms_import_queue;
create policy "sms_import_queue_owner_rw"
  on public.sms_import_queue
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "sms_import_audit_owner_rw" on public.sms_import_audit;
create policy "sms_import_audit_owner_rw"
  on public.sms_import_audit
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "sms_review_queue_owner_rw" on public.sms_review_queue;
create policy "sms_review_queue_owner_rw"
  on public.sms_review_queue
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "sms_quarantine_owner_rw" on public.sms_quarantine;
create policy "sms_quarantine_owner_rw"
  on public.sms_quarantine
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "paybill_registry_owner_rw" on public.paybill_registry;
create policy "paybill_registry_owner_rw"
  on public.paybill_registry
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "fuliza_lifecycle_owner_rw" on public.fuliza_lifecycle_events;
create policy "fuliza_lifecycle_owner_rw"
  on public.fuliza_lifecycle_events
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update
  set public = excluded.public;

drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read"
  on storage.objects
  for select
  using (bucket_id = 'avatars');

drop policy if exists "avatars_owner_write" on storage.objects;
create policy "avatars_owner_write"
  on storage.objects
  for all
  to authenticated
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
