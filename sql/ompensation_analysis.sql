-- =====================================================
-- Canadian Compensation & Labour Market Analysis
-- SQL Business Analysis
-- =====================================================

-- Data Source:
-- Statistics Canada wage data processed using Python.
--
-- Purpose:
-- Use SQL to analyze compensation levels, market gaps,
-- wage growth, and labour-market competitiveness.

-- =====================================================
-- Business Question 1
-- Which occupational groups have the largest negative
-- compensation gaps in Nova Scotia compared with Canada
-- in 2025?
-- =====================================================

SELECT
    noc_code,
    Occupation,
    nova_scotia_wage,
    canada_wage,
    market_gap_pct
FROM occupation_scorecard
ORDER BY market_gap_pct ASC;

-- =====================================================
-- Business Question 2
-- Which occupational groups are currently near or above
-- the Canadian compensation benchmark?
-- =====================================================

SELECT
    noc_code,
    Occupation,
    nova_scotia_wage,
    canada_wage,
    market_gap_pct,
    market_position
FROM occupation_scorecard
WHERE market_position IN ('Near Market', 'Above Market')
ORDER BY market_gap_pct DESC;

-- =====================================================
-- Business Question 3
-- Classify occupational groups according to their
-- compensation competitiveness.
--
-- SQL Concepts:
-- CASE
-- ORDER BY
-- =====================================================

SELECT
    noc_code,
    Occupation,
    market_gap_pct,

    CASE
        WHEN market_gap_pct < -10 THEN 'High Risk'
        WHEN market_gap_pct < -5 THEN 'Moderate Risk'
        WHEN market_gap_pct < 5 THEN 'Competitive'
        ELSE 'Above Market'
    END AS compensation_risk

FROM occupation_scorecard

ORDER BY market_gap_pct;

-- =====================================================
-- Business Question 4
-- What is the average market gap for each market
-- competitiveness category?
--
-- SQL Concepts:
-- GROUP BY
-- AVG
-- COUNT
-- =====================================================

SELECT

    market_position,

    COUNT(*) AS number_of_occupations,

    ROUND(
        AVG(market_gap_pct),
        2
    ) AS average_market_gap

FROM occupation_scorecard

GROUP BY market_position;

-- =====================================================
-- Business Question 5
-- Which occupational groups have remained below the
-- Canadian benchmark on average during 2021–2025?
--
-- SQL Concepts:
-- WHERE
-- GROUP BY
-- AVG
-- HAVING
-- ORDER BY
-- =====================================================

SELECT

    noc_code,

    Occupation,

    ROUND(
        AVG(market_gap_pct),
        2
    ) AS average_market_gap

FROM occupation_trends

WHERE year BETWEEN 2021 AND 2025

GROUP BY
    noc_code,
    Occupation

HAVING AVG(market_gap_pct) < 0

ORDER BY average_market_gap ASC;

-- =====================================================
-- Business Question 6
-- What are the five highest-paying occupational groups
-- in Nova Scotia (2025)?
--
-- SQL Concepts:
-- ORDER BY
-- DESC
-- LIMIT
-- =====================================================

SELECT
    noc_code,
    Occupation,
    nova_scotia_wage
FROM occupation_scorecard
ORDER BY nova_scotia_wage DESC
LIMIT 5;

-- =====================================================
-- Business Question 7
-- Which occupational groups are currently below market
-- and also experienced slower wage growth than Canada?
--
-- SQL Concepts:
-- JOIN
-- WHERE
-- GROUP BY
-- HAVING
-- =====================================================

SELECT
    s.noc_code,
    s.Occupation,
    s.market_gap_pct,
    ROUND(
        (
            MAX(CASE WHEN t.year = 2025 THEN t.nova_scotia_wage END) -
            MAX(CASE WHEN t.year = 2015 THEN t.nova_scotia_wage END)
        )
        /
        MAX(CASE WHEN t.year = 2015 THEN t.nova_scotia_wage END)
        * 100,
        2
    ) AS ns_growth_pct,

    ROUND(
        (
            MAX(CASE WHEN t.year = 2025 THEN t.canada_wage END) -
            MAX(CASE WHEN t.year = 2015 THEN t.canada_wage END)
        )
        /
        MAX(CASE WHEN t.year = 2015 THEN t.canada_wage END)
        * 100,
        2
    ) AS canada_growth_pct

FROM occupation_scorecard AS s

JOIN occupation_trends AS t
    ON s.noc_code = t.noc_code

WHERE s.market_gap_pct < 0

GROUP BY
    s.noc_code,
    s.Occupation,
    s.market_gap_pct

HAVING ns_growth_pct < canada_growth_pct

ORDER BY s.market_gap_pct ASC;

-- =====================================================
-- Business Question 8
-- Which occupational groups should be prioritized for
-- compensation review based on both current and
-- persistent market gaps?
--
-- SQL Concepts:
-- CTE
-- AVG
-- GROUP BY
-- JOIN
-- CASE
-- =====================================================

WITH five_year_gap AS (

    SELECT
        noc_code,
        Occupation,
        ROUND(AVG(market_gap_pct), 2) AS avg_gap_2021_2025

    FROM occupation_trends

    WHERE year BETWEEN 2021 AND 2025

    GROUP BY
        noc_code,
        Occupation
)

SELECT
    s.noc_code,
    s.Occupation,
    s.market_gap_pct AS current_gap_2025,
    f.avg_gap_2021_2025,

    CASE
        WHEN s.market_gap_pct < -10
             AND f.avg_gap_2021_2025 < -10
            THEN 'Priority Review'

        WHEN s.market_gap_pct < -5
             OR f.avg_gap_2021_2025 < -5
            THEN 'Monitor'

        ELSE 'Competitive'
    END AS review_status

FROM occupation_scorecard AS s

JOIN five_year_gap AS f
    ON s.noc_code = f.noc_code

ORDER BY current_gap_2025 ASC;

-- =====================================================
-- Business Question 9
-- How do Nova Scotia occupational groups rank by
-- median hourly wage in 2025?
--
-- SQL Concepts:
-- Window Function
-- RANK
-- ORDER BY
-- =====================================================

SELECT
    noc_code,
    Occupation,
    nova_scotia_wage,

    RANK() OVER (
        ORDER BY nova_scotia_wage DESC
    ) AS wage_rank

FROM occupation_scorecard

ORDER BY wage_rank;


-- =====================================================
-- Business Question 10
-- Which occupational groups should be prioritized for
-- compensation review based on multiple indicators?
--
-- SQL Concepts:
-- CTE
-- JOIN
-- CASE
-- AVG
-- GROUP BY
-- Multiple Conditions
-- =====================================================

WITH historical_gap AS (

    SELECT
        noc_code,
        Occupation,
        ROUND(AVG(market_gap_pct), 2) AS avg_gap_2021_2025

    FROM occupation_trends

    WHERE year BETWEEN 2021 AND 2025

    GROUP BY
        noc_code,
        Occupation
),

growth_analysis AS (

    SELECT
        noc_code,

        ROUND(
            (
                MAX(CASE WHEN year = 2025 THEN nova_scotia_wage END) -
                MAX(CASE WHEN year = 2015 THEN nova_scotia_wage END)
            )
            /
            MAX(CASE WHEN year = 2015 THEN nova_scotia_wage END)
            * 100,
            2
        ) AS ns_growth_pct,

        ROUND(
            (
                MAX(CASE WHEN year = 2025 THEN canada_wage END) -
                MAX(CASE WHEN year = 2015 THEN canada_wage END)
            )
            /
            MAX(CASE WHEN year = 2015 THEN canada_wage END)
            * 100,
            2
        ) AS canada_growth_pct

    FROM occupation_trends

    GROUP BY noc_code
)

SELECT
    s.noc_code,
    s.Occupation,
    s.market_gap_pct AS gap_2025,
    h.avg_gap_2021_2025,
    g.ns_growth_pct,
    g.canada_growth_pct,

    CASE
        WHEN
            s.market_gap_pct < -10
            AND h.avg_gap_2021_2025 < -10
        THEN 'High Priority'

        WHEN
            s.market_gap_pct < -5
            OR h.avg_gap_2021_2025 < -5
        THEN 'Moderate Priority'

        ELSE 'Lower Priority'
    END AS compensation_priority

FROM occupation_scorecard AS s

JOIN historical_gap AS h
    ON s.noc_code = h.noc_code

JOIN growth_analysis AS g
    ON s.noc_code = g.noc_code

ORDER BY
    CASE
        WHEN s.market_gap_pct < -10
             AND h.avg_gap_2021_2025 < -10 THEN 1
        WHEN s.market_gap_pct < -5
             OR h.avg_gap_2021_2025 < -5 THEN 2
        ELSE 3
    END,
    s.market_gap_pct ASC;