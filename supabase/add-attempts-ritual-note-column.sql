-- Добавляет необязательное текстовое описание к вопросу "Соблюдал речевой
-- ритуал?" (кнопка "+ Добавить описание" в мастере подходов). Выполнить
-- ОДИН РАЗ в Supabase -> SQL Editor -> New query -> Run. Безопасно
-- выполнять повторно.

alter table attempts add column if not exists ritual_note text;
