-- Данный запрос получает число всех покупателей в таблице customers (шаг 4)
-- В задании не сказано, чтобы были отобраны уникальные покупатели, поэтому distinct не использовался
SELECT count(*) AS customers_count FROM customers;

-- Первый отчет: запрос формирует десятку лучших продавцов (шаг 5)
-- Группировка по employee_id, а не по имени - страховка от однофамильцев
-- INNER JOIN используется потому, что покупки непонятных продавцов мы учитывать не будем
-- и покупки без продавцов, если такие есть, мы тоже учитывать не будем
SELECT
	e.first_name || ' ' || e.last_name AS seller,
	count(s.sales_id) AS operations,
	floor(sum(s.quantity * p.price)) AS income
FROM sales s
INNER JOIN products p ON s.product_id = p.product_id
INNER JOIN employees e ON s.sales_person_id = e.employee_id
GROUP BY e.employee_id
ORDER BY income DESC
LIMIT 10;

-- Второй отчет - информация о продавцах, чья средняя выручка за сделку (шаг 5)
-- меньше средней выручки за сделку по всем продавцам.
-- Сначала определяю среднюю выручку по всем продавцам,
-- потом делаю CROSS JOIN и группирую по продавцу
WITH total AS (
	SELECT avg(s.quantity * p.price) AS total_avg
	FROM sales s
	INNER JOIN products p ON s.product_id = p.product_id
	INNER JOIN employees e ON s.sales_person_id = e.employee_id 
)
SELECT
	e.first_name || ' ' || e.last_name AS seller,
	floor(avg(s.quantity * p.price)) AS average_income
FROM sales s
INNER JOIN products p ON s.product_id = p.product_id
INNER JOIN employees e ON s.sales_person_id = e.employee_id
CROSS JOIN total AS t
GROUP BY e.employee_id,	seller,	t.total_avg
HAVING avg(s.quantity * p.price) < t.total_avg
ORDER BY average_income;

-- Третий запрос: выручка продавцов по дням недели  (шаг 5)
-- Группировка по employee_id, а не просто по имени - страховка от однофамильцев
-- Группировка и по дню недели, и по номеру дня недели использовалась потому, что
-- в результате нужно выдать день недели строкой, а в сортироввке использовать номер дня
WITH tbl AS (
	SELECT
		e.employee_id,
		e.first_name || ' ' || e.last_name AS seller,
		trim(to_char(s.sale_date,'day')) AS day_of_week,
		s.quantity * p.price AS sale_sum,
		EXTRACT(isodow FROM	sale_date) AS day_num
	FROM sales s
	INNER JOIN products p ON s.product_id = p.product_id
	INNER JOIN employees e ON s.sales_person_id = e.employee_id
)
SELECT
	tbl.seller,
	day_of_week,
	floor(sum(sale_sum)) AS income
FROM tbl
GROUP BY tbl.seller, tbl.day_of_week, tbl.employee_id, tbl.day_num
ORDER BY tbl.day_num, seller;

