### 1. Предикат сравнения

> Вывести id, name клиентов, имеющих хотя бы одну тренировку в залах San Diego
```sql
select distinct c.id, c.name 
from client c
join client_trainer ct on c.id = ct.id_client
join gym g on ct.id_gym = g.id
where g.location = 'San Diego';
```

### 2. Предикат `between`

> Вывести имена тренеров, которые проводили тренировки в период в 01.01.2000 по 01.01.2010. Для каждого тренера вывести даты проведения занятия. Записи отсортировать по возрастанию даты.
```sql
select c.name, ct.date
from client c 
join trainer t on t.id_origin = c.id
join client_trainer ct on ct.id_trainer = t.id_origin
where ct.date between '2000-01-01' and '2010-01-01' order by ct.date
```

### 3. Предикат `like`

Предикат `like` сопоставляет строковый атрибут с регулярным выражением.

* `%` соответствует любой последовательности сиволов, включая пустую строку.
* `_` соответствует одному любоум символу.

> Вывести клиентов, имя которых начинается на 'N'
```sql
select c.name 
from client c where c.name like 'N%';
```

### 4. Предикат `in`

> Получить идентификаторы и имена клиентов последних добавленных 10-ти клиентов
```sql
select c.id, c.name
from client c
where c.id not in (select c.id from client c limit((select count(*) from client) - 10));
```

### 5. Предикат `exists`

> Получить идентификаторы и имена резидентов сети, у которых НЕ было проведено ни одной тренировки
```sql
select c.id, c.name from client c
where not exists (
	select 1 from client_trainer ct
	where ct.id_client = c.id
);
```
**Примечание:**
`select 1` используется для проверки наличия строк, подходящих под условие


### 6. Предикат `all`

> Получить идентификтор, имя и стоимость тренера с самой большой стоимостью тренировочного часа
```sql
select c.id, c.name, t.price_per_hour
from client c 
join trainer t on t.id_origin = c.id
where t.price_per_hour >= all (select price_per_hour from trainer) limit 1;
```
**Алгоритм:**
1. Объединяем таблицы клиентов и тренеров внутренне, получаем информацию только тренерах
2. Получем тренера, почасовая ставка которого `>=` ставок всех остальных тренеров


### 7. Агрегатные функции по столбцам

Агрегатная функция применяется к множеству значений и возвращает одно значение:
`AVG()`, `ALL()`, `MIN()`, `MAX()`.

> Получить кол-во клиентов, которые хоть раз тренировались, общую выручку и среднюю выручку на тренера
```sql
select count(distinct ct.id_client) as "Number of Clients",
       sum(t.price_per_hour) as "Total Revenue",
       avg(t.price_per_hour) as "Average Revenue per Trainer"
from client_trainer ct
join trainer t on ct.id_trainer = t.id_origin;
```
**Алгоритм:**
1. Считаем количество уникальных записей с идентификаторами клиента
2. Для записей из таблицы тренировок суммируем ставки тренеров, получая выручку
3. Аналогично п.2 получаем среднюю выручку из рассчета на тренера

### 8. Скаляный подзапрос 

Скалярный подзапрос возвращает одно значение

> Получить суммарное кол-во оборудывания в залах Портланда
```sql
select count(*) as "Equipment count in Portland gyms" from equipment as e
join gym as g on e.id_gym = g.id
where g.location = 'Portland';
```

Посчитали сколько записей об оборудывании ссылаются на зал, находящийся в Портланде

### 9, 10. Оператор `case`

Секции `case` выполняются последовательно и не продолжаются, если текущее условие истино.

> Для каждой тренировки вывсти ее статус
```sql
select ct.id_client, ct.id_trainer, ct.date,
case
	when ct.date > current_timestamp then 'Upcoming'
	when ct.date = current_timestamp then 'Ongoing'
	else 'Completed'
end as training_status
from client_trainer as ct;
```

> Для каждого клиента получить его категорию в зависимости от стоимости
```sql
select id_origin as trainer_id,
case 
	when price_per_hour < 2000 then 'Low Price'
	when price_per_hour < 5000 then 'Medium Price'
	when price_per_hour < 10000 then 'High Price'
	else 'Premium Price'
end as price_category
from trainer;
```

### 11. Локальная таблица

Локальная таблица видна только в рамках сессии, где была создана. При завершении сессии таблица удаляется. Если имя локальной таблицы совпадает с именем постоянной, то постоянная затеняется до удаления временной.

> Создать локальную таблицу 
```sql
create temporary table BestClients as
select c.id as client_id, 
       c.name as client_name, 
       count(ct.id_trainer) as total_sessions, 
       sum(t.price_per_hour) as total_spent
from client c
join client_trainer ct on c.id = ct.id_client
join trainer t on ct.id_trainer = t.id_origin
group by c.id, c.name;

select BestClients.client_name, BestClients.total_sessions from BestClients;
```

Получили таблицу с информацией о каждом клиенте

### 12. Инструкция `SELECT`, использующая вложенные коррелированные подзапросы в качестве производных таблиц в предложении `FROM`

`union` позволяет объединить результаты двух запросов в один результат

> Определить самого популярного и самого дорого тренера. Для первого вывести кол-во тренировок, для второго - почасовую ставку.

```sql
select 'Most Popular Trainer' as "Criteria", c.name as "Trainer Name", top_trainer.session_count as "Session Count"
from client c
join (
    select id_trainer, count(*) as session_count
    from client_trainer
    group by id_trainer
    order by session_count desc
    limit 1
) as top_trainer on c.id = top_trainer.id_trainer

union

select 'Most Expensive Trainer' as "Criteria", c.name as "Trainer Name", expensive_trainer.max_price as "Price per Hour"
from client c
join (
    select id_origin, max(price_per_hour) as max_price
    from trainer
    group by id_origin
    order by max_price desc
    limit 1
) as expensive_trainer on c.id = expensive_trainer.id_origin;
```

### 13. Инструкция `SELECT`, использующая вложенные подзапросы с уровнем вложенности 3.

> Выбрать клиента с наибольшим количеством тренировок
```sql
select c.name as "Top Client"
from client c
where id in (select id_client
            from client_trainer
            group by id_client
            having count(id_trainer) = (select max(session_count)
                                        from (select id_client, count(id_trainer) as session_count
                                              from client_trainer
                                              group by id_client) as session_data)) limit 1;
```
 
**Разберем запрос пошагово:**
1. Получение количества тренировок для клиентов, которые совершили хотя бы одну тренировку (Рассмотрение прочих не имеет смысла)
```sql
select id_client, count(id_client) as session_count 
from client_trainer
group by id_client;
```

2. Получить наибольшее значение сессий из выборки п.1
```sql
select max(session_count) from (select id_client, count(id_client) as session_count 
from client_trainer
group by id_client) as session_data;
```

3. Выбрать клиента, которому соответствует параметр `session_data`
```sql
select c.name as "Top Client"
from client c
where id in (select id_client
            from client_trainer
            group by id_client
            having count(id_trainer) = (select max(session_count)
                                        from (select id_client, count(id_trainer) as session_count
                                              from client_trainer
                                              group by id_client) as session_data)) limit 1;
```

### 14. Инструкция `SELECT`, консолидирующая данные с помощью предложения `GROUP BY`, но без предложения `HAVING`

> Вывести информацию о тренерах
```sql
select t.id_origin as "TrainerID", 
       t.price_per_hour as "TrainerPrice", 
       count(ct.id_client) as "ClientCount"
from trainer t
join client_trainer ct on t.id_origin = ct.id_trainer
group by t.id_origin, t.price_per_hour;
```

### 15. Инструкция `SELECT`, консолидирующая данные с помощью предложения `GROUP BY` и предложения `HAVING`

> Получить список тренеров, средняя цена за час которых больше средней цены по всем тренерам
```sql
select id_origin as "Trainer ID", avg(price_per_hour) as "Average Price"
from trainer
group by id_origin
having avg(price_per_hour) > (select avg(price_per_hour) from trainer);
```

### 16. Однострочная вставка

> Добавить тренажерный зал в Москве
```sql
insert into gym (location)
values ('Moscow');
```

### 17. Многострочная инструкция `INSERT`, выполняющая вставку в таблицу результирующего набора данных вложенного подзапроса

> Запланировать тренировку

```sql
insert into client_trainer (id_client, id_trainer, id_gym, date)
select c.id, t.id_origin, g.id, now() + interval '1 week'
from client c
join trainer t on t.id_origin = 'f35258f6-c71a-43c4-9a36-01a99695334c'
join gym g on g.location = 'Moscow'  
where c.name = 'Nikita'  
limit 1;
```

### 18. 19. `UPDATE`

> Поднять почасовую ставку на 10% тренерам, которые провели более 30-ти тренировок в последний месяц
```sql
update trainer
set price_per_hour = price_per_hour * 1.1 
where id_origin in (
    select id_trainer
    from client_trainer
    where date >= now() - interval '1 month'
    group by id_trainer
    having count(id) > 30
);
```

### 20. 21. `DELETE`
> Удалить тренажерные залы, которые не имеют никакого оборудывания

```sql
delete from gym
where id in (
    select g.id
    from gym g
    join equipment e on g.id = e.id_gym
    where e.id is null
);
```

### 22. Simple `CTE` (Common Table Expression)
```sql
with EliteTrainers as (
	select c.name, c.id 
	from client as c 
	join trainer as t
	on t.id_origin = c.id 
	where t.price_per_hour > 4500
)
	
select count(*) from EliteTrainers;
```

### 23. Recursive `CTE`
> Рекурсивно генерируем числа от 1 до len(trainer) и конкатинируем id тренеров с этими номерами.
```sql
create temporary table trainer_with_numeration (
    trainer_id uuid primary key,
    price_per_hour numeric(10, 2),
    number integer
);

with recursive numeration(num) as (
    select 1 as num
    union all
    select nm.num + 1
    from numeration nm
    where nm.num < (select count(*) from trainer)
)
insert into trainer_with_numeration (trainer_id, price_per_hour, number)
select 
    t.id_origin,
    t.price_per_hour,
    n.num
from 
    numeration n
join 
    trainer t on n.num = (select count(*) from trainer where id_origin <= t.id_origin)
order by 
    n.num;

select * from trainer_with_numeration;
```
---
### 24. Оконные функции

> **Оконная функция** - функция, работающая с набором строк. Набор строк именуется окном или партицией.

Синтаксис оконной функции:
```sql
SELECT
Название функции (столбец для вычислений) 
OVER (
      PARTITION BY столбец для группировки
      ORDER BY столбец для сортировки
      ROWS или RANGE выражение для ограничения строк в пределах группы
      )
```

**Пример №24.** Средняя ставка самых дорогих 10-ти тренеров сети.
```sql
select avg(tr.price_per_hour)
over() 
from (select price_per_hour from trainer order by price_per_hour desc limit 10) as tr limit 1;
```

### 25. Очистка от дубликтов с помощью `ROW_NUMBER()`
1. Создадим локальную таблицу с дубликатами
```sql
create temporary table trainer_with_duplicates as
select 
    t.id_origin, 
    t.price_per_hour
from 
    trainer t

union all  
select 
    t.id_origin, 
    t.price_per_hour
from 
    trainer t;
```
