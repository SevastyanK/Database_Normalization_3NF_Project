create TABLE autoservice_data (
    date date,
    service text,
    service_addr text,
    w_name text,
    w_exp text,
    w_phone text,
    wages integer,
    card text,
    payment text,
    pin text,
    name text,
    phone text,
    email text,
    password text,
    car text,
    mileage integer,
    vin text,
    car_number text,
    color text
);

--Найдём кол-во сотрудников
select count(distinct w_name)
from autoservice_data as ad;

--У каждого сотрудника есть только один номер телефона, поэтому можем восстановить w_name по w_phone
--Далее восстановим все атрибуты сотрудника по очереди по имени
select w_name, count(distinct w_phone)
from autoservice_data as ad 
group by w_name;

--Восстановим имена по номеру телефона
update autoservice_data as ad
set w_name = w.w_name
from
	(select distinct w_name, w_phone
	from autoservice_data 
	where w_name IS NOT NULL AND w_phone IS NOT null
	) as w
where ad.w_phone = w.w_phone;

--Восстановим опыт работы по имени
update autoservice_data as ad
set w_exp = w.w_exp
from
	(select distinct w_exp, w_name
	from autoservice_data
	where w_exp is not null and w_name is not null
	) as w
where ad.w_name = w.w_name;

--Восстановим ЗП по имени
update autoservice_data as ad
set wages = w.wages
from
	(select distinct wages, w_name
	from autoservice_data
	where wages is not null and w_name is not null
	) as w
where ad.w_name = w.w_name;

--Восстановим номера телефонов по именам
update autoservice_data as ad
set w_phone = w.w_phone
from
	(select distinct w_phone, w_name
	from autoservice_data
	where w_phone is not null and w_name is not null
	) as w
where ad.w_name = w.w_name;

--Проверка на остаток незаполненных строк - их не осталось
select w_name, w_phone, w_exp, wages
from autoservice_data ad 
where w_name is null or w_phone is null or w_exp is null or wages is null;

--Оказалось, что сотрудник работает только в одном городе и в одном сервисе
--Поэтому далее восстановим город сервиса и адрес по имени сотрудника
select w_name, count(distinct service) as town, count(distinct service_addr) as service_name
from autoservice_data ad 
group by w_name;

--Восстановим город сервиса по имени сотрудника (по сути можно и по телефону, тк он уникален у каждого сотрудника)
update autoservice_data as ad
set service = w.service
from
	(select distinct service, w_name
	from autoservice_data
	where service is not null and w_name is not null
	) as w
where ad.w_name = w.w_name;

--Восстановим адрес сервиса по имени сотрудника
update autoservice_data as ad
set service_addr = w.service_addr
from
	(select distinct service_addr, w_name
	from autoservice_data
	where service_addr is not null and w_name is not null
	) as w
where ad.w_name = w.w_name;

--Проверим на незаполненные поля - всё ок
select service, service_addr 
from autoservice_data ad 
where service is null or service_addr is null;

--Теперь перейдём к восстановлению данных по клиентам
--Оказалось, что у каждого клиента один номер телефона, поэтому используем его для заполнения имён
--Тут я решил проверить сразу несколько столбцов на уникальность по номеру телефона, чтобы сделать всё в одном запросе
--А не разбивать снова на несколько "единичных")) И решил перебрать остальные поля сразу по телефону
--Оказалось, что атрибуты email, password, vin, car_number, name уникальны по полю телефона (аналогичным способом)
-- По сути это значит, что у клиента один email-pass, одна машина (vin и car_number) и один телефон
select "name", count(distinct phone)
from autoservice_data ad 
group by "name";

--Восстановим перечисленные выше атрибуты по номеру телефона клиента
update autoservice_data as ad
set "name" = w."name",
	"password" = w."password",
	email = w.email,
	vin = w.vin,
	car_number = w.car_number
from
	(select distinct email, password , vin, car_number, name, phone
	from autoservice_data
	where email is not null and "name" is not null and vin is not null and car_number is not null and "password" is not null and phone is not null
	) as w
where ad.phone = w.phone;

--Так как атрибутов много, то не все поля могли заполниться (не всегда могла найтись комбинация из 5 ненулевых значений сразу)
--Видимо, избыточности хватило, чтобы такое провернуть - NULL значений не осталось, всё заполнено
select email, password , vin, car_number, name, phone
from autoservice_data ad 
where email is null or "name" is null or vin is null or car_number is null or "password" is null or phone is null;

--Теперь заполним сам героический номер телефона (можно по любому из атрибутов выше, тк они уникальны друг относительно друга)
update autoservice_data as ad
set phone = w.phone
from
	(select distinct name, phone
	from autoservice_data
	where "name" is not null and phone is not null
	) as w
where ad.name = w.name;

--Марку машины и цвет можно заполнить по vin коду, так как у каждого вин кода своя марка и цвет
--По сути, так как одному vin коду соответствует один car_number, то восстанавливать можно и по car number
update autoservice_data as ad
set car = w.car,
    color = w.color
from
	(select distinct car, color, vin
	from autoservice_data
	where car is not null and color is not null and vin is not null
	) as w
where ad.vin = w.vin;

--Проверка
select car, color , vin
from autoservice_data ad 
where car is null or color is null or vin is null;

--Атрибуты, которые не удаётся заполнить (pin, mileage, card, payment). Для них не удалость найти уникальных комбинаций атрибутов
--по которым можно было бы однозначно восстановить эти данные. В целом это логично, так как эти данные меняются от заказа к заказу
--Пробег, пин, карта и платеж могут быть уникальны для каждого заказа целиком, но даже так получается несколько значений
--По сути так и должно быть, ведь эти данные каждый раз меняются (pin, пробег, платёж), а карт может быть несколько у клиента
