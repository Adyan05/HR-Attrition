-- HR Attrition Analytics - PostgreSQL
-- Dataset: HR-Employee-Attrition.csv
-- Business goal: identify attrition drivers and high-risk employee segments.

-- Optional: run this separately while connected to the default postgres database.
-- CREATE DATABASE hr_analytics;

-- After creating the database, connect to hr_analytics before running the rest.

DROP VIEW IF EXISTS hr_analysis;
DROP TABLE IF EXISTS hr_employee_attrition;

CREATE TABLE hr_employee_attrition (
    Age INT,
    Attrition VARCHAR(10),
    BusinessTravel VARCHAR(50),
    DailyRate INT,
    Department VARCHAR(100),
    DistanceFromHome INT,
    Education INT,
    EducationField VARCHAR(100),
    EmployeeCount INT,
    EmployeeNumber INT,
    EnvironmentSatisfaction INT,
    Gender VARCHAR(20),
    HourlyRate INT,
    JobInvolvement INT,
    JobLevel INT,
    JobRole VARCHAR(100),
    JobSatisfaction INT,
    MaritalStatus VARCHAR(50),
    MonthlyIncome INT,
    MonthlyRate INT,
    NumCompaniesWorked INT,
    Over18 VARCHAR(5),
    OverTime VARCHAR(10),
    PercentSalaryHike INT,
    PerformanceRating INT,
    RelationshipSatisfaction INT,
    StandardHours INT,
    StockOptionLevel INT,
    TotalWorkingYears INT,
    TrainingTimesLastYear INT,
    WorkLifeBalance INT,
    YearsAtCompany INT,
    YearsInCurrentRole INT,
    YearsSinceLastPromotion INT,
    YearsWithCurrManager INT
);

-- Import the CSV after creating the table.
-- In psql you can use:
-- \copy hr_employee_attrition FROM 'C:/Users/adyan/OneDrive/Desktop/AdyLearn/HRAnalytics/HR-Employee-Attrition.csv' WITH (FORMAT csv, HEADER true);

-- Data quality checks

SELECT *
FROM hr_employee_attrition
LIMIT 10;

SELECT COUNT(*) AS total_rows
FROM hr_employee_attrition;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE Attrition IS NULL) AS missing_attrition,
    COUNT(*) FILTER (WHERE Age IS NULL) AS missing_age,
    COUNT(*) FILTER (WHERE Department IS NULL) AS missing_department,
    COUNT(*) FILTER (WHERE MonthlyIncome IS NULL) AS missing_income
FROM hr_employee_attrition;

SELECT EmployeeNumber, COUNT(*) AS duplicate_count
FROM hr_employee_attrition
GROUP BY EmployeeNumber
HAVING COUNT(*) > 1;

SELECT
    COUNT(DISTINCT EmployeeCount) AS employee_count_values,
    COUNT(DISTINCT StandardHours) AS standard_hours_values,
    COUNT(DISTINCT Over18) AS over18_values
FROM hr_employee_attrition;

-- Analysis view for SQL, Python, and Power BI

CREATE VIEW hr_analysis AS
SELECT
    *,
    CASE
        WHEN Attrition = 'Yes' THEN 1
        ELSE 0
    END AS attrition_flag,

    CASE
        WHEN Age < 25 THEN 'Under 25'
        WHEN Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN Age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_group,

    CASE
        WHEN MonthlyIncome < 3000 THEN 'Low Income'
        WHEN MonthlyIncome BETWEEN 3000 AND 7000 THEN 'Medium Income'
        ELSE 'High Income'
    END AS income_band,

    CASE
        WHEN DistanceFromHome <= 5 THEN 'Near'
        WHEN DistanceFromHome BETWEEN 6 AND 15 THEN 'Medium Distance'
        ELSE 'Far'
    END AS distance_band,

    CASE
        WHEN JobSatisfaction = 1 THEN 'Low'
        WHEN JobSatisfaction = 2 THEN 'Medium'
        WHEN JobSatisfaction = 3 THEN 'High'
        WHEN JobSatisfaction = 4 THEN 'Very High'
    END AS satisfaction_level,

    CASE
        WHEN WorkLifeBalance = 1 THEN 'Bad'
        WHEN WorkLifeBalance = 2 THEN 'Good'
        WHEN WorkLifeBalance = 3 THEN 'Very Good'
        WHEN WorkLifeBalance = 4 THEN 'Best'
    END AS work_life_balance_group,

    CASE
        WHEN YearsSinceLastPromotion = 0 THEN 'Promoted Recently'
        WHEN YearsSinceLastPromotion BETWEEN 1 AND 3 THEN '1-3 Years'
        WHEN YearsSinceLastPromotion BETWEEN 4 AND 7 THEN '4-7 Years'
        ELSE '8+ Years'
    END AS promotion_wait_band,

    CASE
        WHEN YearsAtCompany < 2 THEN '0-1 Years'
        WHEN YearsAtCompany BETWEEN 2 AND 5 THEN '2-5 Years'
        WHEN YearsAtCompany BETWEEN 6 AND 10 THEN '6-10 Years'
        ELSE '10+ Years'
    END AS tenure_band
FROM hr_employee_attrition;

-- Q1. What is the overall attrition rate?

SELECT
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage
FROM hr_analysis;

-- Q2. Which department has the highest attrition?

SELECT
    Department,
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage
FROM hr_analysis
GROUP BY Department
ORDER BY attrition_percentage DESC;

-- Q3. Which job roles have the highest attrition?

SELECT
    JobRole,
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage
FROM hr_analysis
GROUP BY JobRole
ORDER BY attrition_percentage DESC;

-- Q4. Does overtime increase attrition?

SELECT
    OverTime,
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage
FROM hr_analysis
GROUP BY OverTime
ORDER BY attrition_percentage DESC;

-- Q5. Are low-income employees more likely to leave?

SELECT
    income_band,
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage,
    ROUND(AVG(MonthlyIncome), 2) AS average_monthly_income
FROM hr_analysis
GROUP BY income_band
ORDER BY attrition_percentage DESC;

-- Q6. Does distance from home affect attrition?

SELECT
    distance_band,
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage,
    ROUND(AVG(DistanceFromHome), 2) AS average_distance_from_home
FROM hr_analysis
GROUP BY distance_band
ORDER BY attrition_percentage DESC;

-- Q7. Are younger employees leaving more?

SELECT
    age_group,
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage,
    ROUND(AVG(Age), 2) AS average_age
FROM hr_analysis
GROUP BY age_group
ORDER BY attrition_percentage DESC;

-- Q8. Does job satisfaction affect attrition?

SELECT
    satisfaction_level,
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage
FROM hr_analysis
GROUP BY satisfaction_level
ORDER BY attrition_percentage DESC;

-- Q9. Does work-life balance affect attrition?

SELECT
    work_life_balance_group,
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage
FROM hr_analysis
GROUP BY work_life_balance_group
ORDER BY attrition_percentage DESC;

-- Q10. Are employees leaving because of slow promotion?

SELECT
    promotion_wait_band,
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage,
    ROUND(AVG(YearsSinceLastPromotion), 2) AS average_years_since_last_promotion
FROM hr_analysis
GROUP BY promotion_wait_band
ORDER BY attrition_percentage DESC;

SELECT
    Attrition,
    ROUND(AVG(YearsInCurrentRole), 2) AS average_years_in_current_role,
    ROUND(AVG(YearsSinceLastPromotion), 2) AS average_years_since_last_promotion,
    ROUND(AVG(YearsAtCompany), 2) AS average_years_at_company
FROM hr_analysis
GROUP BY Attrition;

-- Q11. Which employee segments are high risk?

SELECT
    Department,
    JobRole,
    age_group,
    income_band,
    OverTime,
    COUNT(*) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_percentage
FROM hr_analysis
GROUP BY Department, JobRole, age_group, income_band, OverTime
HAVING COUNT(*) >= 5
ORDER BY attrition_percentage DESC, total_employees DESC;

-- Q12. Which employees have the highest risk score?
-- This is a simple business-rule score, not a machine-learning model.

SELECT
    EmployeeNumber,
    Age,
    Department,
    JobRole,
    MonthlyIncome,
    OverTime,
    JobSatisfaction,
    WorkLifeBalance,
    YearsSinceLastPromotion,
    Attrition,
    (
        CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END +
        CASE WHEN MonthlyIncome < 3000 THEN 1 ELSE 0 END +
        CASE WHEN Age < 30 THEN 1 ELSE 0 END +
        CASE WHEN JobSatisfaction <= 2 THEN 1 ELSE 0 END +
        CASE WHEN WorkLifeBalance <= 2 THEN 1 ELSE 0 END +
        CASE WHEN YearsSinceLastPromotion >= 4 THEN 1 ELSE 0 END
    ) AS risk_score
FROM hr_analysis
ORDER BY risk_score DESC, MonthlyIncome ASC;

-- HR recommendations supported by this analysis:
-- 1. Review overtime workload and hiring needs.
-- 2. Review compensation bands for high-risk roles and low-income employees.
-- 3. Improve onboarding, mentoring, and career support for younger employees.
-- 4. Use satisfaction and work-life balance findings to target manager follow-ups.
-- 5. Create clearer promotion criteria and internal mobility paths.
-- 6. Investigate high-attrition roles with HR interviews and pulse surveys.
