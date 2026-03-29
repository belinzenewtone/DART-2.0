alter table public.tasks
  add column if not exists reminder_enabled boolean not null default true;

alter table public.tasks
  add column if not exists reminder_minutes_before integer not null default 30;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'tasks_reminder_minutes_non_negative'
  ) then
    alter table public.tasks
      add constraint tasks_reminder_minutes_non_negative
      check (reminder_minutes_before >= 0) not valid;
  end if;
end
$$;

alter table public.tasks
  validate constraint tasks_reminder_minutes_non_negative;

alter table public.events
  add column if not exists reminder_enabled boolean not null default true;

alter table public.events
  add column if not exists reminder_minutes_before integer not null default 15;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'events_reminder_minutes_non_negative'
  ) then
    alter table public.events
      add constraint events_reminder_minutes_non_negative
      check (reminder_minutes_before >= 0) not valid;
  end if;
end
$$;

alter table public.events
  validate constraint events_reminder_minutes_non_negative;
