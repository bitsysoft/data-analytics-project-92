-- Число всех покупателей в таблице customers (шаг 4)
-- В задании не сказано, чтобы были отобраны уникальные покупатели, поэтому distinct не использовался
SELECT count(*) AS customers_count FROM customers;

-- Десятка лучших продавцов (шаг 5)
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

-- Информация о продавцах, чья средняя выручка за сделку меньше
-- средней выручки за сделку по всем продавцам (шаг 5).
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

-- Выручка продавцов по дням недели (шаг 5)
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

-- Данные по количеству уникальных покупателей и выручке, которую они принесли (шаг 6)
SELECT
	to_char(s.sale_date, 'YYYY-MM') AS selling_month,
	count(DISTINCT s.customer_id) AS total_customers,
	floor(sum(s.quantity * p.price)) AS income
FROM sales s
INNER JOIN products p ON s.product_id = p.product_id 
GROUP BY selling_month
ORDER  BY selling_month;

-- Покупатели, первая покупка которых была в ходе проведения акций (шаг 6)
WITH t AS (
	SELECT
		s.customer_id,
		s.sale_date,
		s.sales_person_id,
		p.price 
	FROM sales s
	INNER JOIN products p ON s.product_id = p.product_id
),
res AS (
	SELECT DISTINCT
		t.customer_id,
		t.sale_date,
		t.sales_person_id
	FROM t
	WHERE t.price = 0
	AND NOT EXISTS (SELECT * FROM t AS t2 WHERE t2.customer_id = t.customer_id AND t2.sale_date < t.sale_date)
)
SELECT
	(SELECT concat(first_name, ' ', last_name) FROM customers c WHERE c.customer_id = res.customer_id) AS customer,
	res.sale_date,t
	(SELECT concat(first_name, ' ', last_name) FROM employees e WHERE e.employee_id = res.sales_person_id) AS seller
FROM res
ORDER BY res.customer_id;
