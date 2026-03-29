alter table public.feature_flags
  add column if not exists rollout_percentage integer not null default 100;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'feature_flags_rollout_percentage_range'
  ) then
    alter table public.feature_flags
      add constraint feature_flags_rollout_percentage_range
      check (rollout_percentage >= 0 and rollout_percentage <= 100) not valid;
  end if;
end
$$;

alter table public.feature_flags
  validate constraint feature_flags_rollout_percentage_range;
