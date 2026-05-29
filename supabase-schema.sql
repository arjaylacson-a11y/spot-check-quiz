-- Run in Supabase SQL Editor (Dashboard → SQL → New query)

create table if not exists quiz_results (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  quiz_name text not null default 'Spot Check Quiz',
  score integer not null,
  total_questions integer not null,
  percent_correct integer not null,
  passed boolean not null,
  missed_count integer not null default 0,
  results_json jsonb,
  created_at timestamptz not null default now()
);

create index if not exists quiz_results_email_idx on quiz_results (email);
create index if not exists quiz_results_created_at_idx on quiz_results (created_at desc);

-- One submission per rep (emails stored lowercase from the app)
create unique index if not exists quiz_results_email_unique on quiz_results (lower(email));

alter table quiz_results enable row level security;

-- Allow the public anon key to insert scores only (no reads/updates/deletes)
drop policy if exists "Allow anonymous insert" on quiz_results;
create policy "Allow anonymous insert"
  on quiz_results
  for insert
  to anon
  with check (true);

-- Check if a rep already completed the quiz (no table data exposed)
create or replace function quiz_already_taken(check_email text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1 from quiz_results where lower(email) = lower(trim(check_email))
  );
$$;

grant execute on function quiz_already_taken(text) to anon;
