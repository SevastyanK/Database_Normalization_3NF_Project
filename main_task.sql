--Создадим таблицу с свервисами, service_id - автоинкрементый первичный ключ
create table services (
	service_id serial primary key,
	service text,
	service_addr text
	);

--Заполним данными из основной таблицы. Получилось 6 сервисов.
insert into services (service, service_addr)
select distinct 
	service,
	service_addr
from autoservice_data;

--Создадим таблицу с работниками, worker_id - автоинкрементый первичный ключ
create table workers (
	worker_id serial primary key,
	first_name text,
	last_name text,
	w_exp integer,
	w_phone text,
	wages integer
	);
	
--Заполнили 41 работника
insert into workers (first_name, last_name, w_exp, w_phone, wages)
select distinct
	split_part (w_name, ' ', 1) as first_name,
	split_part (w_name, ' ', 2) as last_name,
	w_exp::integer,
	w_phone,
	wages::integer
from autoservice_data;

--Создадим таблицу с клиентами, client_id - автоинкрементый первичный ключ
create table clients (
	client_id serial primary key,
	first_name text,
	last_name text,
	email text,
	password text,
	phone text
	);	

--Заполнили 524 клиента
insert into clients (first_name, last_name, email, "password", phone)
select distinct 
	split_part ("name", ' ', 1) as first_name,
	split_part ("name", ' ', 2) as last_name,
	email,
	"password",
	phone
from autoservice_data; 

--Создадим таблицу с машинами, car_id - автоинкрементый ключ. Можно было бы создать отдельную таблицу с цветами авто, но
--как правило, цвет прописан при создании машины и поэтому он не может измениться, даже если производитель переименует цвет,
--поэтому его можно оставить в сущности cars
create table cars(
	car_id serial primary key,
	vin text,
	car_number text,
	car text,
	color text
	);
	
--Заполнили 524 авто
insert into cars(vin, car_number, car, color)
select distinct
	vin,
	car_number,
	car,
	color
from autoservice_data;

--Теперь осталось создать сущность с заказами. Туда и пойдут те поля, которые не удалось заполнить, тк они уникальны для каждого заказа
--А те данные, которые удалось заполнить, заполним из созданных сущностей
create table orders (
	order_id serial primary key,
	date date,
	service_id integer,
	worker_id integer,
	card text,
	payment integer,
	pin integer,
	mileage integer,
	client_id integer,
	car_id integer
	);

--Объединим созданные таблицы с исходной с помощью join, чтобы получить id
--получили 85 662 заказа
insert into orders (date, service_id, worker_id, card, payment, pin, mileage, client_id, car_id)
select distinct
	date,
	s.service_id,
	w.worker_id,
	card,
	payment::integer,
	pin::integer,
	mileage,
	cl.client_id,
	cr.car_id
from autoservice_data as ad
join services as s on s.service = ad.service and s.service_addr = ad.service_addr
join workers as w on w.w_phone = ad.w_phone
join clients as cl on cl.phone = ad.phone
join cars as cr on cr.vin = ad.vin;

--Теперь у нас есть все таблицы, и нужно построить связи по ключам между ними. По сути у нас будет таблица с заказами в отношении
--один ко многим к другим таблицам. Установим ограничения по внешним ключам
alter table orders
add constraint fk_service
foreign key (service_id) references services(service_id),
add constraint fk_worker
foreign key (worker_id) references workers(worker_id),
add constraint fk_client
foreign key (client_id) references clients(client_id),
add constraint fk_car
foreign key (car_id) references cars(car_id);

--Привели таблицу к 3 нормальной форме. Есть уникальные ключи, каждый атрибут атомарный и нет атрибутов, которые бы зависели тразнистивно
--(надеюсь правильно написал слово - по памяти :D)

--Добавим индексы по одному столбцу в каждой таблице
create index orders_date_index on orders(date);
create index cars_vin_index on cars(vin);
create index services_address_index on services (service_addr);
create index workers_phone_index on workers (w_phone);
create index clients_email_index on clients (email);
create index client_discount_index on client_discount (client_id);
create index discount_index on discount (discount_id);
