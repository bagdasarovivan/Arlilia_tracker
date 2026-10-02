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

-- RLS сознательно не включаем: приложение личное, ссылка не публикуется,
-- доступ к таблицам открыт через anon-ключ напрямую.

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
