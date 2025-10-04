CREATE TABLE healthcare (
    report_date DATE,
    province VARCHAR(100),
    region VARCHAR(100),
    age_group VARCHAR(20),
    sex VARCHAR(10),
    cases INT
);

SELECT * FROM healthcare

-- Check distinct values 
SELECT DISTINCT age_group FROM healthcare ORDER BY age_group;
SELECT DISTINCT sex FROM healthcare;
SELECT MIN(report_date), MAX(report_date) FROM healthcare;

ALTER TABLE healthcare
  ADD CONSTRAINT chk_sex CHECK (sex IN ('M','F','NA'));

ALTER TABLE healthcare
  ADD CONSTRAINT chk_cases CHECK (cases >= 0);


--  12 Business Problems & SQL Solutions

-- 1. Total cases over time (national trend)?
SELECT report_date, SUM(cases) AS total_cases
FROM healthcare
GROUP BY report_date
ORDER BY report_date;


-- 2. Total cases by region?
SELECT region, SUM(cases) as total_cases
FROM healthcare
GROUP BY region
ORDER BY total_cases DESC;
--  This are total cases by region
-- "Flanders"	2821147
-- "Wallonia"	1495270
-- "Brussels"	515679
-- "NA"			67410


-- 3. Cases by province (regional drilldown)?
SELECT province, SUM(cases) as total_cases
FROM healthcare
GROUP BY province
ORDER BY total_cases DESC;
--  TOP 3 provice with highest cases
-- "province"		"total_cases"
-- "Antwerpen"			784763
-- "OostVlaanderen"		667986
-- "Hainaut"			541575


-- 4. Cases by age group?
SELECT age_group, SUM(cases) as total_cases
FROM healthcare
GROUP BY age_group
ORDER BY total_cases DESC;
-- TOP 3 cases by age group
-- "age_group"	"total_cases"
-- "30-39"		823094
-- "40-49"		745261
-- "20-29"		712106

-- 5. Male vs Female vs NA?
SELECT sex, SUM(cases) as total_cases
FROM healthcare
GROUP BY sex
ORDER BY total_cases DESC;
-- Male vs Female vs Unknown of total cases
-- "sex"	"total_cases"
-- "F"		2631331
-- "M"		2249682
-- "NA"	18493


-- 6. Cases trend in a specific region (e.g., Flanders)?
SELECT report_date, SUM(cases) AS total_cases
FROM healthcare
WHERE region = 'Flanders'
GROUP BY report_date
ORDER BY report_date asc;
--  you can find the trend if you ran the sql code


-- 7. Peak day of infections?
SELECT report_date, SUM(cases) as total_cases
FROM healthcare
GROUP BY report_date
ORDER BY total_cases desc;
-- TOP # days of highest interaction a day
-- "report_date"	"total_cases"
-- "2022-01-24"		76079
-- "2022-01-17"		62785
-- "2022-01-25"		62632


-- 8. Highest-affected province per age group
SELECT age_group, province, total_cases
FROM (
    SELECT 
        age_group,
        province,
        SUM(cases) AS total_cases,
        RANK() OVER (PARTITION BY age_group ORDER BY SUM(cases) DESC) AS rnk
    FROM healthcare
    GROUP BY age_group, province
) t
WHERE rnk = 1
ORDER BY age_group;
-- TOP 5 highest effected
"age_group"	"province"	"total_cases"
"0-9"	"Antwerpen"	61471
"10-19"	"Antwerpen"	110390
"20-29"	"Antwerpen"	114110
"30-39"	"Antwerpen"	133222
"40-49"	"Antwerpen"	118168


-- 9. 7-day rolling average (trend smoothing)?
SELECT report_date, SUM(cases) AS daily_cases,
  AVG(SUM(cases)) OVER (ORDER BY report_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_7d
FROM healthcare
GROUP BY report_date
ORDER BY report_date;
-- TOP 3
-- "report_date"	"daily_cases"	"rolling_avg_7d"
-- "2020-03-01"	19	19.0000000000000000
-- "2020-03-02"	19	19.0000000000000000
-- "2020-03-03"	34	24.0000000000000000


-- 10. Cases share by gender per age group?

SELECT age_group, sex, SUM(cases) AS total_cases,
       ROUND(SUM(cases) * 100.0 / SUM(SUM(cases)) OVER (PARTITION BY age_group), 2) AS pct_share
FROM healthcare
GROUP BY age_group, sex
ORDER BY age_group, sex;
-- TOP 10
-- "age_group"	"sex"	"total_cases"	"pct_share"
-- "0-9"		"F"			174943			48.09
-- "0-9"		"M"			188054			51.69
-- "0-9"		"NA"		784				0.22
-- "10-19"		"F"			331007			50.16
-- "10-19"		"M"			327959			49.70
-- "10-19"		"NA"		961				0.15
-- "20-29"		"F"			394611			55.41
-- "20-29"		"M"			315553			44.31
-- "20-29"		"NA"		1942			0.27
-- "30-39"		"F"			460396			55.93


-- 11. Province contribution to region totals
SELECT region, province, SUM(cases) AS province_cases,
       ROUND(SUM(cases) * 100.0 / SUM(SUM(cases)) OVER (PARTITION BY region), 2) AS pct_of_region
FROM healthcare
GROUP BY region, province
ORDER BY region, pct_of_region DESC;
-- TOP 5
-- "region"		"province"		"province_cases"	"pct_of_region"
-- "Brussels"	"Brussels"			515679				100.00
-- "Flanders"	"Antwerpen"			784763				27.82
-- "Flanders"	"OostVlaanderen"	667986				23.68
-- "Flanders"	"WestVlaanderen"	526405				18.66
-- "Flanders"	"VlaamsBrabant"		480158				17.02


-- 12. What percentage of total cases are from each region?
SELECT region, SUM(cases) AS total_cases,
ROUND(SUM(cases) * 100.0 / (SELECT SUM(cases) FROM healthcare), 2) AS percentage_of_total
FROM healthcare
GROUP BY region
ORDER BY percentage_of_total DESC;
-- "region"		"total_cases"	"percentage_of_total"
-- "Flanders"	2821147				57.58
-- "Wallonia"	1495270				30.52
-- "Brussels"	515679				10.53
-- "NA"			67410				1.38


-- Overall Summary 
-- 1. **National Trends** 

--    * The dataset spans from **2020 to 2022**, showing clear infection peaks (e.g., Jan 2022 with 76k cases in a day).
--    * Rolling averages smooth daily volatility and help spot overall waves.

-- 2. **Regional & Provincial Insights** 

--    * **Flanders dominates** with ~58% of total cases, followed by Wallonia (31%) and Brussels (11%).
--    * Within provinces, **Antwerpen leads** (784k cases), followed by OostVlaanderen and Hainaut.

-- 3. **Demographics (Age & Gender)** 

--    * The **30-39 age group** is the most affected (~823k cases), followed by 40-49 and 20-29.
--    * **Females report slightly more cases (2.63M)** than males (2.25M), but proportions vary by age group.

-- 4. **High-Impact Segments** 

--    * Antwerpen consistently tops cases across most age groups (0-9 to 40-49).
--    * Regional contributions reveal key hotspots driving local totals.

-- 5. **Strategic Insights** 💡

--    * Policies should focus on **working-age populations (20-49 years)**, as they form the majority of cases.
--    * Regional resource allocation should prioritize **Flanders and high-density provinces** like Antwerpen and OostVlaanderen.
