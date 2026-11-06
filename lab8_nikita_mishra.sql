/* =====================================================================
   ALY 6600 - 9.9 Lab Assignment 8: CTEs, BI Connection and Git
   Student : Nikita Mishra
   Platform: Snowflake  |  Database: SAKILA  |  Schema: NORM
   ---------------------------------------------------------------------
   Sections
     PART 1 - WRITE   : Task 1 (single CTE), Task 2 (chained CTEs),
                        Task 3 (BI query + screenshot), Task 4 (Git)
     PART 2 - EXPLAIN : Q1-Q4 answered as comments
     PART 3 - EXTEND  : Customer recency classification (At Risk top 20)
   ---------------------------------------------------------------------
   Schema note: in this NORM schema PAYMENT has no CUSTOMER_ID column.
   A payment is linked to a customer through RENTAL
   (PAYMENT.RENTAL_ID -> RENTAL.CUSTOMER_ID), so every spend calculation
   below joins PAYMENT to RENTAL.
   ===================================================================== */

USE SCHEMA SAKILA.NORM;


/* =====================================================================
   PART 1 - WRITE
   ===================================================================== */

/* ---------------------------------------------------------------------
   Task 1: Single CTE
   Customers whose total spend exceeds the average of all customer totals.
   The average is taken over customer_spend (one row per customer), NOT
   over raw payment rows - averaging payments would give the average
   transaction (~$4), not the average customer (~$112).
   --------------------------------------------------------------------- */
WITH customer_spend AS (
    -- One row per customer: lifetime total of their payments
    SELECT
        r.customer_id,
        SUM(p.amount) AS total_spend
    FROM payment AS p
    JOIN rental  AS r
        ON r.rental_id = p.rental_id
    GROUP BY r.customer_id
)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    cs.total_spend
FROM customer_spend AS cs
JOIN customer AS c
    ON c.customer_id = cs.customer_id
WHERE cs.total_spend > (SELECT AVG(total_spend) FROM customer_spend)
ORDER BY cs.total_spend DESC;


/* ---------------------------------------------------------------------
   Task 2: Chained CTEs
   Top five stores by number of above-average-spending customers, with
   each store's total revenue from those customers.

   Design decisions:
   - A customer is attributed to their home store (CUSTOMER.STORE_ID).
   - "Revenue from those customers" = the lifetime spend of the
     above-average customers belonging to that store.
   - Ranking: customer count first, revenue as the tie-breaker.
   - Sakila has only 2 stores, so LIMIT 5 returns 2 rows; the query is
     still written to return the top five if more stores existed.
   --------------------------------------------------------------------- */
WITH customer_spend AS (
    -- Step 1: total spend per customer
    SELECT
        r.customer_id,
        SUM(p.amount) AS total_spend
    FROM payment AS p
    JOIN rental  AS r
        ON r.rental_id = p.rental_id
    GROUP BY r.customer_id
),

above_avg_customers AS (
    -- Step 2: keep only customers above the average customer total
    SELECT
        customer_id,
        total_spend
    FROM customer_spend
    WHERE total_spend > (SELECT AVG(total_spend) FROM customer_spend)
),

above_avg_customers_by_store AS (
    -- Step 3: attach each customer's home store and its city label
    SELECT
        a.customer_id,
        a.total_spend,
        s.store_id,
        ci.city AS store_city
    FROM above_avg_customers AS a
    JOIN customer AS c
        ON c.customer_id = a.customer_id
    JOIN store    AS s
        ON s.store_id = c.store_id
    JOIN address  AS ad
        ON ad.address_id = s.address_id
    JOIN city     AS ci
        ON ci.city_id = ad.city_id
)

-- Final step: aggregate by store, rank, and keep the top five
SELECT
    RANK() OVER (
        ORDER BY COUNT(customer_id) DESC, SUM(total_spend) DESC
    )                         AS store_rank,
    store_id,
    store_city,
    COUNT(customer_id)        AS above_avg_customer_count,
    SUM(total_spend)          AS revenue_from_above_avg_customers
FROM above_avg_customers_by_store
GROUP BY store_id, store_city
ORDER BY store_rank
LIMIT 5;


/* ---------------------------------------------------------------------
   Task 3: BI tool connection (Power BI DirectQuery variant of Task 2)
   Same above-average logic, but broken out by store and payment month so
   the dashboard has a date dimension to filter on. The Task 2 output
   alone has only 2 rows, which makes a filter meaningless.

   Visualization: bar chart - revenue_from_above_avg_customers by
   payment_month, coloured by store_city
   Filter        : payment_month (date range) and/or store_city slicer
   --------------------------------------------------------------------- */
WITH customer_spend AS (
    SELECT
        r.customer_id,
        SUM(p.amount) AS total_spend
    FROM SAKILA.NORM.PAYMENT AS p
    JOIN SAKILA.NORM.RENTAL  AS r
        ON r.rental_id = p.rental_id
    GROUP BY r.customer_id
),

above_avg_customers AS (
    SELECT customer_id
    FROM customer_spend
    WHERE total_spend > (SELECT AVG(total_spend) FROM customer_spend)
)

SELECT
    c.store_id,
    ci.city                               AS store_city,
    DATE_TRUNC('month', p.payment_date)   AS payment_month,
    COUNT(DISTINCT r.customer_id)         AS above_avg_customer_count,
    SUM(p.amount)                         AS revenue_from_above_avg_customers
FROM SAKILA.NORM.PAYMENT AS p
JOIN SAKILA.NORM.RENTAL   AS r   ON r.rental_id    = p.rental_id
JOIN above_avg_customers AS a ON a.customer_id = r.customer_id
JOIN SAKILA.NORM.CUSTOMER AS c   ON c.customer_id  = r.customer_id
JOIN SAKILA.NORM.STORE    AS s   ON s.store_id     = c.store_id
JOIN SAKILA.NORM.ADDRESS  AS ad  ON ad.address_id  = s.address_id
JOIN SAKILA.NORM.CITY     AS ci  ON ci.city_id     = ad.city_id
GROUP BY c.store_id, ci.city, DATE_TRUNC('month', p.payment_date)
ORDER BY payment_month, c.store_id;



/* ---------------------------------------------------------------------
   Task 4: Git basics (commands run in terminal)

   git clone <course-repo-url>
   cd <course-repo-folder>
   -- create lab8_nikita_mishra.sql containing Task 1 and Task 2 queries
   git add lab8_nikita_mishra.sql
   git commit -m "Add Lab 8 CTE queries"
   git push origin main
   git log --oneline          -- shows the commit for the screenshot
   --------------------------------------------------------------------- */


/* =====================================================================
   PART 2 - EXPLAIN
   ===================================================================== */

/* ---------------------------------------------------------------------
   Q1. Task 1 rewritten with a subquery in the FROM clause
   --------------------------------------------------------------------- */
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    cs.total_spend
FROM (
        SELECT r.customer_id, SUM(p.amount) AS total_spend
        FROM payment AS p
        JOIN rental  AS r ON r.rental_id = p.rental_id
        GROUP BY r.customer_id
     ) AS cs
JOIN customer AS c
    ON c.customer_id = cs.customer_id
WHERE cs.total_spend > (
        SELECT AVG(t.total_spend)
        FROM (
                SELECT r.customer_id, SUM(p.amount) AS total_spend
                FROM payment AS p
                JOIN rental  AS r ON r.rental_id = p.rental_id
                GROUP BY r.customer_id
             ) AS t
      )
ORDER BY cs.total_spend DESC;

/*
   Both versions return the same rows. The CTE version is more readable
   because the per-customer aggregation is written once, named
   (customer_spend), and then used twice: once as the row source and once
   inside AVG(). The subquery version has to repeat the identical
   aggregation block, because a derived table in FROM cannot be seen from
   the WHERE-clause subquery. The reader has to read inside-out and
   confirm the two blocks are the same; if one is edited later and the
   other is not, the query silently compares against the wrong average.

   Threshold: with one derived step used once, the two styles are about
   equal. The CTE advantage becomes significant as soon as a step is
   referenced more than once (already true in Task 1) and decisively at
   two or more levels of nesting. Task 2 has three dependent steps
   (spend -> above-average -> store); as subqueries that would be three
   levels deep with the spend aggregation repeated, whereas the CTE
   version reads top to bottom, one named step at a time.
*/

/* ---------------------------------------------------------------------
   Q2. Could the first CTE in Task 2 reference the third CTE?
   ---------------------------------------------------------------------
   No. customer_spend cannot reference above_avg_customers_by_store.
   CTEs in a WITH clause are resolved sequentially, top-down: each CTE can
   reference only base tables and CTEs defined ABOVE it in the same WITH
   clause. When customer_spend is defined, above_avg_customers_by_store
   does not exist yet, so Snowflake raises an "object does not exist"
   error. It would also be circular: the third CTE is built from the
   second, which is built from the first, so the first cannot depend on
   the third.

   The one exception is a recursive CTE (WITH RECURSIVE), where a CTE
   references itself to walk a hierarchy (e.g. staff -> manager). That is
   self-reference with an anchor and a recursive member, not a forward
   reference, and Task 2 does not need it.
*/

/* ---------------------------------------------------------------------
   Q3. What happens when a dashboard filter is clicked?
   ---------------------------------------------------------------------
   It depends on the connection pattern:

   - Live connection (Tableau "Live" / Power BI "DirectQuery"): the BI
     tool does not filter locally. It wraps my Task 3 query as a
     subquery, adds a WHERE clause for the filter (e.g.
     WHERE payment_month BETWEEN ...), and sends that new SQL to
     Snowflake. The warehouse re-executes the query and returns only the
     filtered rows. Data is always current, but every click costs
     warehouse compute and network latency (Snowflake's result cache can
     return a repeated identical query instantly).

   - Extract (Tableau ".hyper" extract / Power BI "Import"): the query
     runs once at extract/refresh time and the result is stored inside
     the BI tool. Filter clicks are evaluated locally by the BI engine
     with no call to Snowflake, so they are fast and free, but the data
     is only as fresh as the last refresh.

   My setup: I connected Power BI Desktop to Snowflake using DirectQuery
   mode with a native SQL statement. Changes to the Payment Month and
   Store City slicers send filtered queries to Snowflake.

   One consequence specific to my queries: if I had used the Task 2
   query (which ends in LIMIT 5) as Custom SQL, a filter would be applied
   OUTSIDE the wrapped query, i.e. to the already-ranked top five, not
   re-rank stores within the filtered period. That is why the Task 3
   variant returns unranked store-month rows and lets the BI tool
   aggregate after filtering.
*/

/* ---------------------------------------------------------------------
   Q4. Why does dbt require Git?
   ---------------------------------------------------------------------
   In dbt, every model is a .sql SELECT file (like my CTE queries), and
   the code in the repository IS the source of truth: dbt builds the
   warehouse tables from those files, so the repository defines what
   the warehouse contains. dbt Cloud projects connect to a Git repo, and
   production jobs run from a specific branch, so changes reach
   production only through commits, reviews (pull requests) and merges.
   Git gives history (who changed what, when, and why, via messages like
   "Add Lab 8 CTE queries"), the ability to roll back a bad model, and
   branches so developers can work without breaking production.

   Team scenario without version control: my teammate and I both open
   the shared lab8 .sql file. I change customer_spend to exclude
   payments with NULL rental_id; they rename above_avg_customers and
   change the ranking tie-breaker. Whoever saves last overwrites the
   other's work, with no error and no record it happened. The store
   ranking changes and nobody can tell which version produced last
   week's dashboard.

   With Git (as in Task 4), the second person's git push is rejected
   because the remote has a commit they do not have. They must
   git pull, and if we edited the same lines Git marks a merge conflict
   (<<<<<<< / ======= / >>>>>>>) that has to be resolved deliberately.
   Both changes are preserved in the commit history and either can be
   reverted.
*/


/* =====================================================================
   PART 3 - EXTEND: Customer recency classification
   ---------------------------------------------------------------------
   Requirement: each customer's most recent rental date, days since that
   rental, and a band (Active <= 90 days, At Risk 91-180, Lapsed > 180).
   Return the top 20 At Risk customers by lifetime spend.

   Design decisions:
   - Reference date = latest rental date in the data, not CURRENT_DATE
     and not a hard-coded literal. Sakila rentals end in 2006, so
     CURRENT_DATE would label every customer "Lapsed". MAX(rental_date)
     measures recency relative to the end of the business's own data.
   - DATEDIFF('day', ...) returns a whole number of days, so the bands
     <= 90, 91-180 and > 180 have no gaps or overlaps (day 90 = Active,
     day 91 and day 180 = At Risk, day 181 = Lapsed).
   - Lifetime spend is aggregated in its own CTE, per customer, and
     joined afterwards. Computing it in the same GROUP BY as recency
     would not inflate it here, but keeping the grains separate avoids
     row fan-out if more joins are added later.
   ===================================================================== */
WITH reference_date AS (
    -- Single-row "as of" date: the last rental recorded in the data
    SELECT MAX(rental_date) AS as_of_date
    FROM rental
),

customer_recency AS (
    -- Recency calculation: most recent rental and days since it
    SELECT
        r.customer_id,
        MAX(r.rental_date)                                   AS most_recent_rental_date,
        DATEDIFF('day', MAX(r.rental_date), rd.as_of_date)   AS days_since_last_rental
    FROM rental AS r
    CROSS JOIN reference_date AS rd
    GROUP BY r.customer_id, rd.as_of_date
),

customer_lifetime_spend AS (
    -- One row per customer: lifetime total of payments
    SELECT
        r.customer_id,
        SUM(p.amount) AS lifetime_spend
    FROM payment AS p
    JOIN rental  AS r
        ON r.rental_id = p.rental_id
    GROUP BY r.customer_id
),

customer_recency_band AS (
    -- Classification using CASE WHEN on whole-day recency
    SELECT
        cr.customer_id,
        cr.most_recent_rental_date,
        cr.days_since_last_rental,
        CASE
            WHEN cr.days_since_last_rental <= 90  THEN 'Active'
            WHEN cr.days_since_last_rental <= 180 THEN 'At Risk'
            ELSE 'Lapsed'
        END AS recency_band
    FROM customer_recency AS cr
)

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    rb.most_recent_rental_date,
    rb.days_since_last_rental,
    rb.recency_band,
    ls.lifetime_spend
FROM customer_recency_band AS rb
JOIN customer_lifetime_spend AS ls
    ON ls.customer_id = rb.customer_id
JOIN customer AS c
    ON c.customer_id = rb.customer_id
WHERE rb.recency_band = 'At Risk'
ORDER BY ls.lifetime_spend DESC, c.customer_id
LIMIT 20;


SELECT CURRENT_WAREHOUSE();
