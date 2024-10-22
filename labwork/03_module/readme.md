# SQL модулью

SQL модули делятся на три категории:
    
1. Функция 
2. Хранимая процедура
3. Триггер

## Функция

### 1. Скалярная функция

> Функция возразвращает 1, если подписка клиента с указанным id активна. Иначе возвращается 0.

```sql
create or replace function is_sub_active(id_cl uuid)
returns boolean as
$$
begin
    if (select 1 from Subscription as sub where sub.id=(select id_subscription from client where id=id_cl) and sub.expires_at > current_timestamp) then
		return 1;
	else
		return 0;
	end if;
end;
$$
language plpgsql;
```

### 2. Подставляемая табличная функция

> Сформировать таблицу активных клиентов

```sql
create or replace function get_active_clients()
returns table(id uuid, name text, expired_at timestamp) as
$$
begin
    return query 
    select c.id, c.name, s.expires_at
    from client as c
	join Subscription s on c.id_subscription=s.id
    where is_sub_active(c.id);
end;
$$
language plpgsql;
```

### 3. Многооператорная табличная функция

> Добавить к фукнции п.2 тег, определяющий возрастную группу клиента в зависимости от переданного параметра 

```sql
create or replace function get_active_clients_with_marked_age(threshold smallint)
returns table(id uuid, name text, expired_at timestamp, age_category text) as
$$
begin
    return query 
    select c.id, c.name, s.expires_at,
        case 
            when c.age < threshold then 'teen'
            else 'adult'
        end as age_category
    from client as c
    join subscription s on c.id_subscription = s.id
    where is_sub_active(c.id);
end;
$$
language plpgsql;
```

### 4. Рекурсивная функция

> Рекурсивно замнумеровать клиентов, вернуть таблицу вида id, str(num--id)

```sql
CREATE OR REPLACE FUNCTION get_tokenized_ids()
RETURNS TABLE(id integer, token text) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE numeration(num) AS (
        SELECT 1 AS num
        UNION ALL
        SELECT nm.num + 1
        FROM numeration nm
        WHERE nm.num < (SELECT count(*) FROM trainer)
    )
    SELECT 
        n.num AS id,
        CONCAT(n.num, '--', t.id_origin) AS string
    FROM 
        numeration n
    JOIN 
        trainer t ON n.num = (SELECT count(*) FROM trainer WHERE id_origin <= t.id_origin)
    ORDER BY 
        n.num;
END;
$$ LANGUAGE plpgsql;
```

## Процедура

### 5. Простая хранимая процедура

> Вывести сообщение о кол-ве тренеров

```sql
create or replace procedure get_trainer_count()
language plpgsql
as $$
begin
    raise notice 'Total number of trainers: %', (select count(*) from trainer);
end;
$$;
```

### 6. Рекурсивная хранимая процедура

> Поднять тренерам зарплату с уровнями от [_level_filter, _bound]

```sql
create or replace procedure update_price(in _level_filter int, in _bound int)
language plpgsql
as 
$$
declare 
    _trainer_id uuid;

begin
    update trainer 
    set price_per_hour = price_per_hour + 1.75 * level
    where level = _level_filter;

    if _level_filter < _bound then
        call update_price(_level_filter + 1, _bound);
    else
        raise notice 'job finished';
    end if;

end
$$;
```

### 7. Процедура с курсором

> Для каждого тренера вывести ID и кол-во записей о тренировках

```sql
create or replace procedure get_trainers_with_sessions(n integer)
language plpgsql
as $$
declare
    trainer_cursor cursor for
        select t.id_origin, count(w.id) as sessions
        from trainer t
        left join workout w on w.id_trainer = t.id_origin
        group by t.id_origin
        having count(w.id) > n;
    trainer_record record;
begin
    open trainer_cursor;

    loop
        fetch trainer_cursor into trainer_record;
        exit when not found;

        raise notice 'Trainer ID: %, Sessions: %', trainer_record.id_origin, trainer_record.sessions;
    end loop;

    close trainer_cursor;
end;
```

### 8. Процедура доступа к метаданным

> Вывести информацию о таблицах и типах атрибутов

```sql
create or replace procedure get_table_metadata()
language plpgsql
as $$
declare
    rec record;
begin
    for rec in
        select table_name, column_name, data_type
        from information_schema.columns
        where table_schema = 'public'
    loop
        raise notice 'Table: %, Column: %, Type: %', rec.table_name, rec.column_name, rec.data_type;
    end loop;
end;
$$;
```

## Триггер

### 9. Триггер AFTER

> При добавлении нового клиента сети автоматически создавать ему подписку на 10 дней

```sql
CREATE OR REPLACE FUNCTION create_subscription_for_new_client()
RETURNS TRIGGER AS $$
DECLARE
    new_subscription_id UUID;
BEGIN
    new_subscription_id := uuid_generate_v4();
    
    INSERT INTO subscription (id, expires_at)
    VALUES (new_subscription_id, CURRENT_TIMESTAMP + INTERVAL '10 days');  
    UPDATE client
    SET id_subscription = new_subscription_id
    WHERE id = NEW.id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER after_client_insert
AFTER INSERT ON client
FOR EACH ROW
EXECUTE FUNCTION create_subscription_for_new_client();
```

### 10. Триггер INSTEAD OF

> Создадим представление

```sql
CREATE OR REPLACE VIEW owner_subscription_view AS
SELECT 
    c.id AS owner_id,
    s.id AS subscription_id,
    s.expires_at
FROM client c
JOIN subscription s ON c.id_subscription = s.id;
```

> Создадим триггер

```sql
CREATE OR REPLACE FUNCTION handle_owner_subscription_update()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE subscription
    SET expires_at = NEW.expires_at
    WHERE id = NEW.subscription_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

> Установим триггер

```sql
CREATE TRIGGER instead_of_owner_subscription_update
INSTEAD OF UPDATE ON owner_subscription_view
FOR EACH ROW
EXECUTE FUNCTION handle_owner_subscription_update();
```

> Использовние

```sql
UPDATE owner_subscription_view
SET expires_at = CURRENT_TIMESTAMP + INTERVAL '90 days'
WHERE owner_id = '...';
```