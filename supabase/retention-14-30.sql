-- Срок хранения подробностей: подходы 14 дней, дневник 30 дней.
-- Можно запускать сколько угодно раз и независимо от того, запускали ли вы
-- auto-scrub-old-data.sql раньше. Выполнить в Supabase -> SQL Editor -> New query -> Run.
--
-- После срока удаляются ТОЛЬКО подробности (тексты, оценки, ФТ).
-- Сам факт подхода (дата и время) и отметка «дневник заполнен» остаются —
-- по ним считаются календарь, серия и «дней осознанных занятий».
-- Удаление подробностей НЕОБРАТИМО.

-- ШАГ 1. Колонки-отметки (если их ещё нет).
alter table journal_entries add column if not exists scrubbed_at timestamptz;
alter table attempts add column if not exists scrubbed_at timestamptz;

-- ШАГ 2. Функция очистки (dry_run = true — только посчитать, ничего не менять).
create or replace function scrub_old_data(journal_days int default 30, attempt_days int default 14, dry_run boolean default true)
returns table(what text, rows_affected bigint)
language plpgsql security definer set search_path = public as $$
begin
  if dry_run then
    return query select 'дневник: будет очищено'::text,
      (select count(*) from journal_entries where scrubbed_at is null and entry_date <= current_date - journal_days);
    return query select 'подходы: будет очищено'::text,
      (select count(*) from attempts where scrubbed_at is null and created_at < now() - make_interval(days => attempt_days));
    return;
  end if;

  update journal_entries set
    mood = null, glad = null, worry = null, speech_mode = null, daily_routine = null,
    sleep_hours = null, sleep_note = null, difficulties = null, questions = null,
    reflections = null, tricks = null, praise = null, intentions = null,
    lessons = null, ft_notes = null, sleep_quality = null,
    scrubbed_at = now()
  where scrubbed_at is null and entry_date <= current_date - journal_days;

  update attempts set
    title = null, mindset_before = null, reaction_after = null,
    ritual = null, ritual_note = null,
    voice = null, voice_note = null, hand = null, hand_note = null,
    anxiety = null, anxiety_note = null, purpose = null, ft = null,
    scrubbed_at = now()
  where scrubbed_at is null and created_at < now() - make_interval(days => attempt_days);
end $$;

-- ШАГ 3. Включить расширение для расписания (если уже включено — ничего не случится).
create extension if not exists pg_cron;

-- ШАГ 4. Ночная очистка в 03:30 UTC (06:30 по Москве). Если такая задача
-- уже была — она заменится новой с новыми сроками.
do $$ begin perform cron.unschedule('scrub-old-data'); exception when others then null; end $$;
select cron.schedule('scrub-old-data', '30 3 * * *', $$ select scrub_old_data(30, 14, false) $$);

-- ШАГ 5. ПРОВЕРКА. Первый запрос покажет, сколько записей будет очищено
-- этой ночью (ничего не меняя). Второй — что задача стоит в расписании.
select * from scrub_old_data(30, 14, true);
select jobname, schedule, active from cron.job where jobname = 'scrub-old-data';
