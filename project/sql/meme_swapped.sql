-- Вычисляемое поле effectiveTrader для MemeSwapped (контракт GemoonUniswapHook в ../rindexer.yaml).
--
-- Правило из abis/indexing.md: трейдер сделки = MemeSwapped.trader, иначе tx.from.
-- trader заполнен, только если фронт передал адрес в hookData свопа (наш Universal Router).
-- Сторонние роутеры (например gmgn) передают пустой hookData, и trader = 0x0. Тогда берётся
-- tx_from, отправитель транзакции (индексер пишет его благодаря `tx_from: true` у события).
-- Пока строка не переиндексирована, tx_from = NULL и поле отдаёт исходный trader.
--
-- PostGraphile превращает функцию <таблица>_<поле>(строка таблицы) в поле таблицы:
-- у типа MemeSwapped появляется effectiveTrader (сырые trader и txFrom тоже остаются).
--
-- Применять после первого запуска rindexer (таблица и колонка tx_from должны уже существовать):
--   psql "$DATABASE_URL" -f project/sql/meme_swapped.sql
-- Скрипт идемпотентный. Если у пользователя БД нет прав суперпользователя, GraphQL увидит
-- новое поле только после перезапуска rindexer.

CREATE OR REPLACE FUNCTION franky_gemoon_uniswap_hook.meme_swapped_effective_trader(
  s franky_gemoon_uniswap_hook.meme_swapped
) RETURNS char(42) LANGUAGE sql STABLE AS $$
  SELECT CASE
    WHEN s.trader <> '0x0000000000000000000000000000000000000000' THEN s.trader
    ELSE coalesce(s.tx_from, s.trader)
  END
$$;
-- Разрешает filter: { effectiveTrader: { equalTo: ... } } (сделки кошелька).
COMMENT ON FUNCTION franky_gemoon_uniswap_hook.meme_swapped_effective_trader(
  franky_gemoon_uniswap_hook.meme_swapped
) IS E'@filterable';
