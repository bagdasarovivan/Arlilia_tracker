-- Добавляет поле "Цель подхода" (зачем было сказано) в таблицу подходов —
-- новый вопрос в мастере "Подходы". Выполнить ОДИН РАЗ в Supabase ->
-- SQL Editor -> New query -> Run. Безопасно выполнять повторно.

alter table attempts add column if not exists purpose text;
