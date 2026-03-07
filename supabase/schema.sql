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
  completed boolean not null default false,
  due_at timestamptz,
  priority text not null default 'medium'
);

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
  note text
);

create index if not exists idx_events_owner_start
  on public.events (owner_id, start_at);

create table if not exists public.user_profile (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  phone text not null,
  member_since_label text not null,
  verified boolean not null default false
);

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

alter table public.transactions enable row level security;
alter table public.tasks enable row level security;
alter table public.events enable row level security;
alter table public.user_profile enable row level security;
alter table public.assistant_messages enable row level security;
alter table public.app_updates enable row level security;

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

drop policy if exists "app_updates_public_read" on public.app_updates;
create policy "app_updates_public_read"
  on public.app_updates
  for select
  to anon, authenticated
  using (active = true);
