-- 1. Предикат сравнения
-- Вывести идентификаторы и имена всех клиентов, имеющих хотя бы одну тренировку в San Diego.
select distinct c.id, c.name 
from client c
join client_trainer ct on c.id = ct.id_client
join gym g on ct.id_gym = g.id
where g.location = 'San Diego';

-- 2. Предикат between
-- Вывести имена тренеров, которые проводили тренировки в период в 01.01.2000 по 01.01.2010. Для каждого тренера вывести даты проведения занятия.
-- Записи отсортировать по возрастанию даты.
select c.name, ct.date
from client c 
join trainer t on t.id_origin = c.id
join client_trainer ct on ct.id_trainer = t.id_origin
where ct.date between '2000-01-01' and '2010-01-01' order by ct.date


-- 3. Предикат like
-- Вывести имена клиентов сети, имя которых начинается на 'N'
select c.name 
from client c where c.name like 'N%';


-- 4. Предикат in c вложенным подзапросом
-- Получить идентификаторы и имена клиентов последних добавленных 10-ти клиентов
select c.id, c.name
from client c
where c.id not in (select c.id from client c limit((select count(*) from client) - 10));


-- Предикат exists с вложенным подзапросом
-- Получить идентификаторы и имена резидентов сети, у которых НЕ было проведено ни одной тренировки
select c.id, c.name from client c
where not exists (
	select 1 from client_trainer ct
	where ct.id_client = c.id
);


-- Предикат сравнения с квантором all
-- Получить идентификтор, имя и стоимость тренера с самой большой стоимостью тренировочного часа
select c.id, c.name, t.price_per_hour
from client c 
join trainer t on t.id_origin = c.id
where t.price_per_hour >= all (select price_per_hour from trainer);


-- Агрегатные фукнции по столбцам
-- Получить кол-во клиентов, общую выручку и среднюю выручку на тренера
select count(ct.id_client) as "Number of Clients",
       sum(t.price_per_hour) as "Total Revenue",
       avg(t.price_per_hour) as "Average Revenue per Trainer"
from client_trainer ct
join trainer t on ct.id_trainer = t.id_origin;


-- №№№ подзапрос
-- Для кадждого города получить количество тренировок, проведенных раньше 05.05.2010 в его залах
select count(*) as "Equipment count in Portland gyms" from equipment as e
join gym as g on e.id_gym = g.id
where g.location = 'Portland';

-- Для каждой тренировки вывсти ее статус
select ct.id_client, ct.id_trainer, ct.date,
case
	when ct.date > current_timestamp then 'Upcoming'
	when ct.date = current_timestamp then 'Ongoing'
	else 'Completed'
end as training_status
from client_trainer as ct;
   

-- Для каждого клиента получить его категорию в зависимости от стоимости
select id_origin as trainer_id,
case 
	when price_per_hour < 2000 then 'Low Price'
	when price_per_hour < 5000 then 'Medium Price'
	when price_per_hour < 10000 then 'High Price'
	else 'Premium Price'
end as price_category
from trainer;




-- Определить самого популярного и самого дорого тренера. 
-- Для первого вывести кол-во тренировок, для второго - почасовую ставку.
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


-- Выбрать клиента с наибольшим количеством тренировок
select c.name as "Top Client"
from client c
where id in (select id_client
            from client_trainer
            group by id_client
            having count(id_trainer) = (select max(session_count)
                                        from (select id_client, count(id_trainer) as session_count
                                              from client_trainer
                                              group by id_client) as session_data)) limit 1;


-- Для каждого зала получить кол-во проведенных тренировок, уникальных сессий и уникальных клиентов
select t.id_origin as "TrainerID", 
       t.price_per_hour as "TrainerPrice", 
       count(ct.id_client) as "ClientCount"
from trainer t
join client_trainer ct on t.id_origin = ct.id_trainer
group by t.id_origin, t.price_per_hour;

-- Получить список тренеров, средняя цена за час которых больше средней цены по всем тренерам
select id_origin as "Trainer ID", avg(price_per_hour) as "Average Price"
from trainer
group by id_origin
having avg(price_per_hour) > (select avg(price_per_hour) from trainer);


-- Добавить тренажерный зал в Москве
insert into gym (location)
values ('Moscow');


-- Запланировать тренировку
insert into client_trainer (id_client, id_trainer, id_gym, date)
select c.id, t.id_origin, g.id, now()
from client c
join trainer t on t.id_origin = 'f35258f6-c71a-43c4-9a36-01a99695334c'
join gym g on g.location = 'Moscow'  
where c.name = 'Nikita'  
limit 1;


-- Поднять почасовую ставку на 10% тем тренерам, кто провел более 30-ти тренировок за последний месяц
update trainer
set price_per_hour = price_per_hour * 1.1 
where id_origin in (
    select id_trainer
    from client_trainer
    where date >= now() - interval '1 month'
    group by id_trainer
    having count(id) > 30
);


-- Усреднение ставки всем тренерам
update trainer
set price_per_hour = (select avg(price_per_hour)
                      from trainer)


-- Удалить тренажерные залы, которые не имеют никакого оборудывания
delete from gym
where id in (
    select g.id
    from gym g
    join equipment e on g.id = e.id_gym
    where e.id is null
);


-- Для каждого тренера получить кол-во уникальных клиентов и отсортировать их по убываню
with clientcount as (
    select 
        ct.id_trainer,
        count(distinct ct.id_client) as totalclients 
    from 
        client_trainer ct
    group by 
        ct.id_trainer
)
select 
    t.id_origin as trainerid,
    t.price_per_hour,
    cc.totalclients
from 
    clientcount cc
join 
    trainer t on cc.id_trainer = t.id_origin
order by 
    cc.totalclients desc; 


-- Подсчитать кол-во тренировок клиентов
with recursive client_levels as (
    select 
        ct.id_client,
        c.name as client_name,
        count(ct.id_trainer) as total_sessions
    from 
        client_trainer ct
    join 
        client c on ct.id_client = c.id
    group by 
        ct.id_client, c.name

    union all

    select 
        cl.id_client,
        cl.client_name,
        cl.total_sessions + 1 as total_sessions
    from 
        client_levels cl
    where 
        cl.total_sessions < (select max(total_sessions) from (
            select id_client, count(id_trainer) as total_sessions
            from client_trainer
            group by id_client
        ) as session_counts)
)
select 
    id_client,
    client_name,
    total_sessions as level
from 
    client_levels
order by 
    level desc;  


-- Получить среднюю цену тренера, максимальную и минимальную 
select 
    avg(t.price_per_hour) over() as AvgPrice,         
    min(t.price_per_hour) over() as MinPrice,         
    max(t.price_per_hour) over() as MaxPrice           
from  
    trainer t limit 1;


-- Самые активные клиенты зала
WITH ClientSessions AS (
    SELECT 
        ct.id_client,
        c.name AS client_name,
        COUNT(ct.id_trainer) AS total_sessions
    FROM 
        client_trainer ct
    JOIN 
        client c ON ct.id_client = c.id
    GROUP BY 
        ct.id_client, c.name
)
SELECT 
    cs.id_client,
    cs.client_name,
    cs.total_sessions,
    RANK() OVER (ORDER BY cs.total_sessions DESC) AS session_rank  
FROM 
    ClientSessions cs
ORDER BY 
    session_rank;