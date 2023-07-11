-- Querie 1: Qual o genêro
SELECT * FROM sales.customers

SELECT 
	CASE
		WHEN ibge.gender = 'male' then 'Masculino'
		WHEN ibge.gender = 'female' then 'Feminino'
		END as "Gênero",
	COUNT(*) as "Clientes"
		
FROM sales.customers as cus
LEFT JOIN temp_tables.ibge_genders as ibge
ON LOWER(cus.first_name) = LOWER(ibge.first_name)
GROUP BY ibge.gender

-- Querie 2: Status profissional

SELECT DISTINCT professional_status
FROM sales.customers

SELECT 
	CASE 
		WHEN professional_status = 'freelancer' then 'freelancer'
		WHEN professional_status = 'retired' then 'aposentado(a)'
		WHEN professional_status = 'clt' then 'CLT'
		WHEN professional_status = 'self_employed' then 'Autônomo(a)'
		WHEN professional_status = 'other' then 'Outro'
		WHEN professional_status = 'businessman' then 'Empresário(a)'
		WHEN professional_status = 'civil_servant' then 'Funcionário(a) público(a)'
		WHEN professional_status = 'student' then 'Estudante'
		END as "Status profissional",
	(COUNT(*) :: float) / (SELECT COUNT(*) FROM sales.customers) as "Leads (%)"
		
		
FROM sales.customers
GROUP BY professional_status
ORDER BY "Leads (%)" DESC

-- Querie 3: Faixa Etária
CREATE FUNCTION DATEDIFF (unidade varchar, data_inicial date, data_final date) 
RETURNS integer
LANGUAGE SQL

as

$$
	SELECT 
		CASE 
					WHEN unidade in ('d', 'day', 'days') then (data_final - data_inicial) 
					WHEN unidade in ('w', 'week', 'weeks') then (data_final - data_inicial)/7
					WHEN unidade in ('m', 'month', 'months') then (data_final - data_inicial)/30
					WHEN unidade in ('y', 'year', 'years') then (data_final - data_inicial)/365						 
					END as diferenca
$$

select
	case
		when datediff('years', birth_date, current_date) < 20 then '0-20'
		when datediff('years', birth_date, current_date) < 40 then '20-40'
		when datediff('years', birth_date, current_date) < 60 then '40-60'
		when datediff('years', birth_date, current_date) < 80 then '60-80'
		else '80+' end "faixa etária",
		count(*)::float/(select count(*) from sales.customers) as "leads (%)"

from sales.customers
group by "faixa etária"
order by "faixa etária" desc

-- Querie 4: Faixa salarial

SELECT
	CASE
		WHEN income < 5000 then '0-5000'
		WHEN income < 10000 then '5000-10000'
		WHEN income < 15000 then '10000-15000'
		WHEN income < 20000 then '15000-20000'
		ELSE '20000+' END "faixa salarial",
		count(*)::float/(SELECT count(*) FROM sales.customers) as "leads (%)",
	CASE
		WHEN income < 5000 then 1
		WHEN income < 10000 then 2
		WHEN income < 15000 then 3
		WHEN income < 20000 then 4
		ELSE 5 END "ordem"

FROM sales.customers
GROUP BY "faixa salarial", "ordem"
ORDER BY "ordem" DESC
		
-- (Query 5) Classificação dos veículos visitados
-- Colunas: classificação do veículo, veículos visitados (#)

SELECT * FROM sales.products

-- Regra de negócio: Veículos novos tem até 2 anos e seminovos acima de 2 anos
WITH
	classificacao_veiculos as (
	
		SELECT
			fun.visit_page_date,
			pro.model_year,
			EXTRACT('year' FROM visit_page_date) - pro.model_year::int as idade_veiculo,
			CASE
				WHEN (EXTRACT('year' FROM visit_page_date) - pro.model_year::int)<=2 then 'novo'
				ELSE 'seminovo'
				END as "classificação do veículo"
		
		FROM sales.funnel as fun
		LEFT JOIN sales.products as pro
			ON fun.product_id = pro.product_id	
	)

SELECT
	"classificação do veículo",
	count(*) as "veículos visitados (#)"
FROM classificacao_veiculos
GROUP BY "classificação do veículo"

-- (Query 6) Idade dos veículos visitados
-- Colunas: Idade do veículo, veículos visitados (%), ordem
WITH
	faixa_de_idade_dos_veiculos as (
	
		SELECT
			fun.visit_page_date,
			pro.model_year,
			EXTRACT('year' from visit_page_date) - pro.model_year::int as idade_veiculo,
			CASE
				WHEN (extract('year' FROM visit_page_date) - pro.model_year::int)<=2 THEN 'até 2 anos'
				WHEN (extract('year' FROM visit_page_date) - pro.model_year::int)<=4 THEN 'de 2 à 4 anos'
				WHEN (extract('year' FROM visit_page_date) - pro.model_year::int)<=6 THEN 'de 4 à 6 anos'
				WHEN (extract('year' FROM visit_page_date) - pro.model_year::int)<=8 THEN 'de 6 à 8 anos'
				WHEN (extract('year' FROM visit_page_date) - pro.model_year::int)<=10 THEN 'de 8 à 10 anos'
				ELSE 'acima de 10 anos'
				END as "idade do veículo",
			CASE
				WHEN (extract('year' FROM visit_page_date) - pro.model_year::int)<=2 THEN 1
				WHEN (extract('year' FROM visit_page_date) - pro.model_year::int)<=4 THEN 2
				WHEN (extract('year' FROM visit_page_date) - pro.model_year::int)<=6 THEN 3
				WHEN (extract('year' FROM visit_page_date) - pro.model_year::int)<=8 THEN 4
				WHEN (extract('year' FROM visit_page_date) - pro.model_year::int)<=10 THEN 5
				ELSE 6
				END as "ordem"

		FROM sales.funnel as fun
		LEFT JOIN sales.products as pro
			ON fun.product_id = pro.product_id	
	)

SELECT
	"idade do veículo",
	count(*)::float/(SELECT count(*) FROM sales.funnel) as "veículos visitados (%)",
	ordem
FROM faixa_de_idade_dos_veiculos
GROUP BY "idade do veículo", ordem
ORDER BY ordem

-- (Query 7) Veículos mais visitados por marca
-- Colunas: brand, model, visitas (#)

SELECT
	pro.brand,
	pro.model,
	count(*) as "visitas (#)"

FROM sales.funnel as fun
LEFT JOIN sales.products as pro
	ON fun.product_id = pro.product_id
GROUP BY pro.brand, pro.model
ORDER BY pro.brand, pro.model, "visitas (#)"


