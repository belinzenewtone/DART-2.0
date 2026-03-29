-- Migration v13: merchant category learning + dedupe/index hardening

create table if not exists public.merchant_categories (
  id bigserial primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  merchant_key text not null,
  category text not null,
  usage_count integer not null default 1,
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_merchant_categories_owner_key
  on public.merchant_categories (owner_id, merchant_key);

create index if not exists idx_merchant_categories_owner_updated
  on public.merchant_categories (owner_id, updated_at desc);

alter table public.merchant_categories enable row level security;

drop policy if exists "merchant_categories_owner_rw" on public.merchant_categories;
create policy "merchant_categories_owner_rw"
  on public.merchant_categories
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create index if not exists idx_transactions_owner_title_occurred
  on public.transactions (owner_id, lower(title), occurred_at);

create index if not exists idx_transactions_owner_title_amount
  on public.transactions (owner_id, lower(title), amount);
