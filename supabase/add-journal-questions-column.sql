-- Добавляет отдельное поле "Вопросы" в дневник (раньше было одно поле
-- "Вопросы и откровения" — теперь это два разных вопроса: "Вопросы" и
-- "Откровения"). Выполнить ОДИН РАЗ в Supabase -> SQL Editor -> New query -> Run.
-- Безопасно выполнять повторно.

alter table journal_entries add column if not exists questions text;
