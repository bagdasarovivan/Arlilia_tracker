-- Новый раздел "Упражнения": таблица отметок "сделано сегодня" по
-- каждому упражнению. Выполнить ОДИН РАЗ в Supabase -> SQL Editor ->
-- New query -> Run. Безопасно выполнять повторно.

create table if not exists exercise_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  exercise_id text not null,
  done_date date not null,
  created_at timestamptz not null default now()
);

alter table exercise_log add column if not exists user_id uuid references auth.users(id);

alter table exercise_log drop constraint if exists exercise_log_user_exercise_date_key;
alter table exercise_log add constraint exercise_log_user_exercise_date_key unique (user_id, exercise_id, done_date);

alter table exercise_log enable row level security;

drop policy if exists "own rows" on exercise_log;
create policy "own rows" on exercise_log for all using (user_id = auth.uid()) with check (user_id = auth.uid());
