# ALY 6600 – Lab Assignment 8: CTEs, BI Connection & Git

**Author:** Nikita Mishra  
**University:** Northeastern University  
**Course:** ALY 6600 – Data Warehousing & Querying  
**Database:** Sakila Sample Database  
**SQL Platform:** Snowflake  
**BI Tool:** Microsoft Power BI  
**Version Control:** Git & GitHub

---

## 1. Project Overview

This project demonstrates the use of Common Table Expressions (CTEs) in SQL to perform multi-step business analysis using the Sakila sample database.

The project focuses on customer spending analysis, store performance comparison, business intelligence visualization, Git version control, and customer recency classification.

SQL queries were developed and executed in Snowflake using the normalized Sakila schema (`SAKILA.NORM`). Power BI was used to visualize monthly revenue trends, while GitHub was used to maintain and version the SQL code.

## 2. Project Objectives

- Use a single CTE to identify customers whose total spending exceeds average customer spending.
- Build chained CTEs to analyze above-average customers and rank stores by customer count and revenue.
- Connect Snowflake to Power BI and create an interactive dashboard.
- Apply dashboard filters to analyze monthly revenue and store performance.
- Understand the importance of Git and version control in analytics engineering.
- Extend SQL analysis by classifying customers based on rental recency.

## 3. Technologies Used

| Technology | Purpose |
|---|---|
| SQL | Data querying and analysis |
| Snowflake | Cloud data warehouse |
| CTEs | Breaking complex queries into logical steps |
| Power BI | Business intelligence and visualization |
| Git | Version control |
| GitHub | SQL project repository |

## 4. SQL Analysis

### Task 1: Single CTE – Above-Average Customer Spending

Created a CTE named `customer_spend` to calculate the total lifetime payment amount for each customer.

The outer query identifies customers whose total spending exceeds the average of all customer-level spending totals.

**Key findings:**
- 285 customers had above-average spending.
- Combined lifetime spending: $38,024.18.
- The highest-spending customer was Karl Seal, with $221.55.

### Task 2: Chained CTEs – Store Performance Analysis

Developed three chained CTEs:

1. `customer_spend` – Calculates total spending per customer.
2. `above_avg_customers` – Identifies customers spending above the average.
3. `above_avg_customers_by_store` – Connects customers to their home stores and store cities.

The final query uses `RANK()`, `GROUP BY`, and `LIMIT 5` to rank stores based on above-average customer counts, with revenue as the tie-breaker.

**Key findings:**

| Store | Above-Average Customers | Revenue |
|---|---:|---:|
| Lethbridge | 160 | $21,285.61 |
| Woodridge | 125 | $16,738.57 |

Lethbridge ranked first because it had more above-average-spending customers.

### Task 3: Power BI Dashboard – Monthly Revenue Analysis

Connected Snowflake to Power BI Desktop using **DirectQuery**.

Created a clustered column chart to visualize monthly revenue from above-average-spending customers across the two stores.

**Dashboard filters:**
- Payment Month – Date-range slicer.
- Store City – Store-level filtering.

**Key findings:**
- July 2005 revenue: $16,128.25.
- August 2005 revenue: $13,667.28.
- Combined July and August revenue: $29,795.53.
- These two months contributed 78.4% of the total revenue.

### Task 4: Git and Version Control

Used GitHub to maintain the SQL assignment and organize the project files.

The repository contains the SQL queries used for the Write, Explain, and Extend sections.

Git version control supports code tracking, collaboration, change history, and recovery of previous versions.

## 5. Part 2 – SQL Concepts and Explanations

The project also explores four important concepts:

- **CTEs vs. Subqueries:** Compared readability, reuse, and query complexity.
- **CTE Reference Order:** Explained sequential, top-down CTE execution and recursive CTEs.
- **BI Dashboard Filters:** Compared DirectQuery and Import connection patterns.
- **Git in dbt:** Explained version control, collaboration, merge conflicts, and maintaining SQL models as the source of truth.

## 6. Part 3 – Customer Recency Classification

Extended the analysis to classify customers according to the number of days since their most recent rental.

The query uses multiple CTEs, `MAX()`, `DATEDIFF()`, `CASE WHEN`, `ORDER BY`, and `LIMIT`.

**Customer classification:**

| Classification | Days Since Last Rental |
|---|---|
| Active | 90 days or fewer |
| At Risk | 91–180 days |
| Lapsed | More than 180 days |

The reference date is dynamically calculated using the latest rental date in the dataset rather than the current date.

**Key findings:**
- Identified the top 20 At Risk customers by lifetime spending.
- Combined lifetime spending: $3,488.79.
- Their last rental dates ranged from August 21 to August 23, 2005.

## 7. Repository Structure

```text
ALY6600-Lab8/
│
├── ALY660_ Lab_Assignment_8.sql
│   └── SQL queries for Write, Explain, and Extend
│
└── README.md
    └── Project documentation
```

## 8. How to Run the SQL Queries

1. Open Snowflake.
2. Select the Sakila database and normalized schema.
3. Open the SQL file in this repository.
4. Execute the queries section by section.
5. Review the returned results.
6. Use the Task 3 query in Power BI Desktop to build the dashboard.

**Note:** Access to the course's Snowflake environment and the `SAKILA.NORM` schema is required.

## 9. Key Learning Outcomes

Through this assignment, I gained practical experience in:

- Writing and chaining SQL CTEs.
- Performing customer-level aggregations.
- Using joins, window functions, and ranking.
- Connecting Snowflake with Power BI.
- Building filtered business intelligence dashboards.
- Understanding DirectQuery and Import modes.
- Applying Git and GitHub for SQL version control.
- Developing customer segmentation and recency analysis.

---

**Project:** ALY 6600 – Lab Assignment 8  
**Author:** Nikita Mishra  
**Institution:** Northeastern University
