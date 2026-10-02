-- Arlilia tracker: схема базы данных
-- Выполнить один раз в Supabase SQL Editor (Project -> SQL Editor -> New query -> Run)

create extension if not exists pgcrypto;

-- Отдельные речевые подходы (вкладка "Подходы")
create table if not exists attempts (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  title text,
  mindset_before text,
  reaction_after text,
  ritual boolean,
  voice numeric,
  voice_note text,
  hand numeric,
  hand_note text,
  anxiety numeric,
  anxiety_note text
);

-- Дневник дня (вкладка "Дневник"), одна запись на дату
create table if not exists journal_entries (
  id uuid primary key default gen_random_uuid(),
  entry_date date not null unique,
  created_at timestamptz not null default now(),
  mood text,
  glad text,
  worry text,
  daily_routine text,
  sleep_hours numeric,
  difficulties text,
  reflections text,
  tricks text,
  praise text,
  intentions text
);

-- Настройки приложения (вкладка "Настройки"), одна строка с id = 1
create table if not exists app_settings (
  id int primary key,
  start_date date
);

-- RLS сознательно не включаем: приложение личное, ссылка не публикуется,
-- доступ к таблицам открыт через anon-ключ напрямую.
--
-- ОБНОВЛЕНО: в приложении добавлен вход/регистрация (Supabase Auth), и теперь
-- несколько человек могут пользоваться одним приложением со своими отдельными
-- данными. См. миграцию "Многопользовательский доступ" ниже — её нужно выполнить.

-- ---------------------------------------------------------------------
-- Миграция с более ранней версии схемы (если таблицы уже существовали
-- с другим набором колонок) — безопасно выполнять повторно:
--
-- alter table attempts add column if not exists mindset_before text;
-- alter table attempts add column if not exists reaction_after text;
-- alter table attempts add column if not exists anxiety numeric;
-- alter table attempts add column if not exists voice_note text;
-- alter table attempts add column if not exists hand_note text;
-- alter table attempts add column if not exists anxiety_note text;
--
-- alter table attempts drop column if exists mindset;
-- alter table attempts drop column if exists anxiety_speech;
-- alter table attempts drop column if exists errors_work;
-- alter table attempts drop column if exists anxiety_general;
-- alter table attempts drop column if exists causes;
--
-- alter table journal_entries drop column if exists session_note;
-- alter table journal_entries drop column if exists contacts_count;
-- alter table journal_entries drop column if exists relax_in_pause;
--
-- create table if not exists app_settings (id int primary key, start_date date);
-- alter table app_settings disable row level security;

-- ---------------------------------------------------------------------
-- Многопользовательский доступ (вход/регистрация через Supabase Auth)
-- Выполнить один раз в Supabase SQL Editor. Безопасно выполнять повторно.
--
-- 1) Добавляем user_id на все три таблицы.
-- alter table attempts add column if not exists user_id uuid references auth.users(id);
-- alter table journal_entries add column if not exists user_id uuid references auth.users(id);
-- alter table app_settings add column if not exists user_id uuid references auth.users(id);
--
-- 2) app_settings теперь — одна строка на пользователя (ключ по user_id вместо id).
-- alter table app_settings drop constraint if exists app_settings_pkey;
-- alter table app_settings drop column if exists id;
-- delete from app_settings where user_id is null;
-- alter table app_settings add primary key (user_id);
--
-- 3) В дневнике теперь разрешена одна запись на дату НА ПОЛЬЗОВАТЕЛЯ
--    (а не одна запись на дату вообще).
-- alter table journal_entries drop constraint if exists journal_entries_entry_date_key;
-- alter table journal_entries add constraint journal_entries_entry_date_user_key unique (entry_date, user_id);
--
-- 4) Перенос старых данных (записанных ДО появления user_id) на свой аккаунт:
--    сначала зарегистрируйтесь в самом приложении, затем в Supabase Dashboard ->
--    Authentication -> Users скопируйте свой UID и подставьте его сюда:
-- update attempts set user_id = 'ВАШ-UID-СЮДА' where user_id is null;
-- update journal_entries set user_id = 'ВАШ-UID-СЮДА' where user_id is null;
-- update app_settings set user_id = 'ВАШ-UID-СЮДА' where user_id is null;
--
-- 5) Включаем RLS: каждый видит и пишет только свои строки.
-- alter table attempts enable row level security;
-- alter table journal_entries enable row level security;
-- alter table app_settings enable row level security;
--
-- drop policy if exists "own rows" on attempts;
-- create policy "own rows" on attempts for all using (user_id = auth.uid()) with check (user_id = auth.uid());
-- drop policy if exists "own rows" on journal_entries;
-- create policy "own rows" on journal_entries for all using (user_id = auth.uid()) with check (user_id = auth.uid());
-- drop policy if exists "own rows" on app_settings;
-- create policy "own rows" on app_settings for all using (user_id = auth.uid()) with check (user_id = auth.uid());
--
-- 6) По умолчанию Supabase требует подтверждение email при регистрации.
--    Чтобы можно было сразу входить после регистрации без письма:
--    Dashboard -> Authentication -> Providers -> Email -> выключить "Confirm email".
