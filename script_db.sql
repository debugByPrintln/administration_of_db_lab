\prompt 'Enter schema name: ' schema_name
set val.name = :'schema_name';
DO $$
DECLARE
    renamed_columns INTEGER := 0;
    altered_tables INTEGER := 0;
    column_info RECORD;
BEGIN
    -- Получаем количество таблиц, которые будем менять
    SELECT COUNT(*) INTO altered_tables
    FROM (
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = current_setting('val.name') AND (column_name LIKE '%"%'
                                             OR column_name LIKE '%''%')
        GROUP BY table_name
    ) AS altered_tables;

    -- Получаем список столбцов в таблице, содержащих кавычки или апострофы
    FOR column_info IN (
        SELECT table_name, column_name
        FROM information_schema.columns
        WHERE table_schema = current_setting('val.name') AND (column_name LIKE '%"%'
                                             OR column_name LIKE '%''%')
    )
    LOOP
        -- Генерируем выражение для переименования столбца
        EXECUTE format('ALTER TABLE %I.%I RENAME COLUMN %I TO %I',
                       current_setting('val.name'),
                       column_info.table_name,
                       column_info.column_name,
                       REPLACE(REPLACE(column_info.column_name, '"', ''), '''', '')
                      );

        -- Увеличиваем счетчик переименованных столбцов
        renamed_columns := renamed_columns + 1;
    END LOOP;

    -- Выводим отчет
    RAISE NOTICE 'Схема: %', current_setting('val.name');
    RAISE NOTICE 'Cтолбцов переименовано: %', renamed_columns;
    RAISE NOTICE 'Таблиц изменено: %', altered_tables;
END;
