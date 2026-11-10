-- Новая версия ФТ и дневника (тексты логопеда от 10 ноября).
-- Выполнить ОДИН РАЗ в Supabase -> SQL Editor -> New query -> Run.
-- Безопасно выполнять повторно. Старые записи не затрагиваются.
-- ВАЖНО: выполнить ДО того, как открывать обновлённое приложение.

-- 1) ФТ: все отметки (ритуал, начало речи, речь по методике, голос,
--    что было трудно, подробности) хранятся одним полем.
alter table attempts add column if not exists ft jsonb;

-- 2) Дневник: новые вопросы.
alter table journal_entries add column if not exists lessons text;        -- «Логопедические занятия: над чем работал»
alter table journal_entries add column if not exists ft_notes text;       -- «ФТ: наблюдения, что удалось»
alter table journal_entries add column if not exists sleep_quality text;  -- «Высыпаюсь» / «Не высыпаюсь»

-- 3) Цель всех ФТ на день (и её описание) — одна строка на день.
create table if not exists day_goals (
  user_id uuid not null references auth.users(id),
  goal_date date not null,
  goal text,
  description text,
  updated_at timestamptz not null default now(),
  primary key (user_id, goal_date)
);
alter table day_goals enable row level security;
drop policy if exists "own rows" on day_goals;
create policy "own rows" on day_goals for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 4) Чтобы автоочистка (auto-scrub-old-data.sql) тоже стирала новые поля —
--    если вы её уже включали, выполните этот файл ещё раз после
--    обновлённого auto-scrub-old-data.sql.

-- Обновить кэш схемы (иначе приложение может не видеть новые колонки)
notify pgrst, 'reload schema';
