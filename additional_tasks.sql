--1 доп. задание. Сделать таблицу скидок и дать скидку самым частым клиентам
--Для начала создадим таблицу скидок и добавим одно поле (скидка для постоянников)
create table discount (
	discount_id serial primary key,
	discount_name text,
	discount_percentage integer
	);

--Теперь создадим таблицу скидок, так как у каждого клиента может быть несколько скидок, а скидка может быть у нескольких клиентов
--Поэтому создаётся промежуточная таблица для преобразования связи многие ко многим. Так у каждого клиента будут свои скидки
create table client_discount (
	client_discount_id serial primary key,
	client_id integer,
	discount_id integer,
	foreign key (client_id) references clients(client_id),
	foreign key (discount_id) references discount(discount_id)
	);

--Добавим скидку для постоянных клиентов
insert into discount (discount_name, discount_percentage)
values ('Скидка для постоянных клиентов', 10);

--Сделаем скидку постоянным клиентам. Для этого добавим их и id скидки в таблицу скидок клиентов.
insert into client_discount (client_id, discount_id)
select c.client_id, c.discount_id
from (
	select o.client_id, count(o.order_id) as order_counts, d.discount_name, d.discount_id
	from orders o
	cross join discount as d
	where d.discount_name = 'Скидка для постоянных клиентов'
	group by client_id, d.discount_name, d.discount_id
	order by order_counts desc
	limit 52 --10% от 524 (всего клиентов)
	) as c

--2 доп. задание. Поднять 3м самым результативным механикам ЗП на 10%
update workers
set wages = wages * 1.10
where worker_id in (
    select worker_id
    from orders
    group by worker_id
    order by sum(payment) desc
    limit 3
	);

--3 доп. задание. Сделать представление для директора: филиал, количество заказов за последний месяц,
--заработанная сумма, заработанная сумма за вычетом зарплаты
create view monthly_document as (
	select
	    s.service as service_region,
	    s.service_addr as service_address,
	    count(o.order_id) as monthly_order_count,
	    sum(o.payment) as monthly_income,
	    sum(o.payment) - sum(w.wages) as monthly_margin
	from orders as o
	join services s on o.service_id = s.service_id
	join workers w on o.worker_id = w.worker_id
	where o.date >= (select max(date) from orders) - interval '1 month'
	group by s.service_id
	);

--4 доп. задание. Сделать рейтинг самых надёжных авто (ну и соответственно смамых ненадёжных)
--Рейтинг сделаем по кол-ву заказов в таблице orders для данной марки (чем больше заказов, тем ненадёжнее машина)
--Топ-5 самых надёжных авто: Saturn, Peugeot, Chrysler, Subary, Regal (сомнительно, но окэй)
--Топ-5 самых НЕнадёжных авто: Mitsubishi, GEM, Jeep, Hummer, Kia (тоже сомнительно :D)
create view cars_rating as(
	select
		c.car, 
		count(o.car_id) as count_of_repairs
	from cars as c
	join orders as o on c.car_id = o.car_id
	group by c.car
	order by count_of_repairs
	);
	
--5 доп. задание. Найти самый удачный цвет для каждой модели авто
--Создадим представление, в котором в целом отражены кол-ва ремонтов машин по марке и цвету (для каждого цвета марки)
create view repairs_by_colors as(
	select
		c.car,
		c.color, 
		count(o.car_id) as repair_counts
	from cars as c
	join orders as o on c.car_id = o.car_id
	group by c.car, c.color
	order by c.car
	);

--Теперь выберем для каждой марки строки с минимальным кол-вом ремонтов
create view min_repairs as (
	select rbc.car, min(rbc.repair_counts) as min_count
	from repairs_by_colors as rbc
	group by car
	);

--И, наконец, оставляем только цвета марок, для которых было минимальное количество ремонтов
--Получилось 43 строки, когда марок 42, потому что у Saab 2 удачных цвета))
create view lucky_colors as (
	select rbc.car, rbc.color
	from repairs_by_colors as rbc
	left join min_repairs as mr on rbc.repair_counts = mr.min_count and rbc.car = mr.car
	where mr.min_count is not null
	order by rbc.car
	);
