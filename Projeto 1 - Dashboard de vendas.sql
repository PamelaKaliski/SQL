--P1: Criar um dashboard de vendas com os principais indicadores de desempenho
-- e com os principais Drivers dos resultados

-- (Query 1) Receita, leads, conversão e ticket médio mês a mês
-- Colunas: mês, leads (#), vendas (#), receita (k, R$), conversão (%), ticket médio (k, R$)
SELECT *
FROM sales.funnel

SELECT *
FROM sales.products

WITH 
	leads as (
		SELECT DATE_TRUNC('month', visit_page_date) :: DATE as visit_page_month,
			   count(*) as visit_page_count
		FROM sales.funnel
		GROUP BY visit_page_month
		ORDER BY visit_page_month DESC
		),
	
	pagamento as(
		SELECT DATE_TRUNC('month', paid_date) :: DATE as paid_month,
			   count (*) as paid_count,
			   sum(pro.price * (1+fun.discount)) as Receita
		FROM sales.funnel as fun
		LEFT JOIN sales.products as pro
				on fun.product_id = pro.product_id
		WHERE paid_date is not null
		GROUP BY paid_month
		ORDER BY paid_month DESC
		)
SELECT 
	leads.visit_page_month as "Mês",
	leads.visit_page_count as "Leads",
	pagamento.paid_count as "Vendas",
	(pagamento.Receita /1000) as "Receita (R$)", -- Porque no gráfico esta com unidade milhares
	(pagamento.paid_count:: float/leads.visit_page_count::float) as "Conversão (%)",
	(pagamento.Receita/pagamento.paid_count)/1000 as "Ticket medio"
FROM leads
LEFT JOIN pagamento
	on leads.visit_page_month = pagamento.paid_month

-- (Query 2) Estados que mais venderam
-- Colunas: país, estado, vendas (#)
SELECT *
FROM sales.customers -- state e customer_id

SELECT 
	'Brasil' as País,
	cus.state as Estado,
	count(fun.paid_date) as Vendas
FROM sales.customers as cus
LEFT JOIN sales.funnel as fun
ON cus.customer_id = fun.customer_id
WHERE paid_date between '2021-08-01' and '2021-08-31'
GROUP BY País, Estado
ORDER BY Vendas DESC
LIMIT 5

-- (Query 3) Marcas que mais venderam no mês
-- Colunas: marca, vendas (#)
SELECT * FROM sales.products  -- Product_id and brand paid date

SELECT 
	pro.brand as marcas,
	count(fun.paid_date) as Vendas
	
FROM sales.funnel as fun
LEFT JOIN sales.products as pro
ON fun.product_id = pro.product_id
WHERE paid_date between '2021-08-01' and '2021-08-31'
GROUP BY marcas
ORDER BY Vendas DESC
LIMIT 5


-- (Query 4) Lojas que mais venderam
-- Colunas: loja, vendas (#)
SELECT * FROM sales.stores

SELECT 
	sto.store_name as Loja,
	count(fun.paid_date) as vendas

FROM sales.funnel as fun
LEFT JOIN sales.stores as sto
ON fun.store_id = sto.store_id
WHERE paid_date between '2021-08-01' and '2021-08-31'
GROUP BY Loja
ORDER BY vendas DESC
LIMIT 5



-- (Query 5) Dias da semana com maior número de visitas ao site
-- Colunas: dia_semana, dia da semana, visitas (#)

SELECT
	extract('dow' from visit_page_date) as dia_semana, --- Utilizado para extrair unidades de uma data/timestamp
	case 
		when extract('dow' from visit_page_date)=0 then 'domingo'
		when extract('dow' from visit_page_date)=1 then 'segunda'
		when extract('dow' from visit_page_date)=2 then 'terça'
		when extract('dow' from visit_page_date)=3 then 'quarta'
		when extract('dow' from visit_page_date)=4 then 'quinta'
		when extract('dow' from visit_page_date)=5 then 'sexta'
		when extract('dow' from visit_page_date)=6 then 'sábado'
		else null end as "dia da semana",
	count(*) as "visitas (#)"

from sales.funnel
where visit_page_date between '2021-08-01' and '2021-08-31'
group by dia_semana
order by dia_semana










