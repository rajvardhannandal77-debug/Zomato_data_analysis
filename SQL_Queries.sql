-- Zomato Data Analysis
-- SQL analysis queries based on zomato_clean_data.csv
-- SQL Dialect: MySQL 8.0+

/* =========================================================
   TABLE SETUP
   =========================================================
   Import the CSV into a table named `zomato_data`.
   The `Unnamed: 0` column is the original DataFrame index and
   is not required for analysis.
*/

CREATE TABLE zomato_data (
    address TEXT,
    name VARCHAR(255),
    online_order VARCHAR(10),
    book_table VARCHAR(10),
    rating DECIMAL(3,1),
    votes INT,
    location VARCHAR(255),
    cuisines TEXT,
    cost_per_person DECIMAL(10,2),
    type_of_restaurant VARCHAR(255)
);


/* =========================================================
   1. BASIC EXPLORATION
   ========================================================= */

-- 1. Total number of restaurants
SELECT COUNT(*) AS total_restaurants
FROM zomato_data;

-- 2. Number of distinct restaurant names
SELECT COUNT(DISTINCT name) AS unique_restaurants
FROM zomato_data;

-- 3. Number of locations
SELECT COUNT(DISTINCT location) AS total_locations
FROM zomato_data;

-- 4. Basic rating and cost summary
SELECT
    ROUND(AVG(rating), 2) AS avg_rating,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    ROUND(AVG(cost_per_person), 2) AS avg_cost_per_person
FROM zomato_data;


/* =========================================================
   2. LOCATION ANALYSIS
   ========================================================= */

-- 5. Restaurant count by location
SELECT
    location,
    COUNT(*) AS restaurant_count
FROM zomato_data
GROUP BY location
ORDER BY restaurant_count DESC;

-- 6. Locations with more than 500 restaurants
SELECT
    location,
    COUNT(*) AS restaurant_count
FROM zomato_data
GROUP BY location
HAVING COUNT(*) > 500
ORDER BY restaurant_count DESC;

-- 7. Average rating by location
SELECT
    location,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rating), 2) AS avg_rating
FROM zomato_data
GROUP BY location
HAVING COUNT(*) >= 10
ORDER BY avg_rating DESC;


/* =========================================================
   3. RATING ANALYSIS
   ========================================================= */

-- 8. Rating distribution
SELECT
    rating,
    COUNT(*) AS restaurant_count
FROM zomato_data
GROUP BY rating
ORDER BY rating DESC;

-- 9. Highly rated restaurants
SELECT
    name,
    location,
    rating,
    votes,
    cost_per_person
FROM zomato_data
WHERE rating >= 4.5
ORDER BY rating DESC, votes DESC;

-- 10. Restaurants with rating >= 4.0 and at least 500 votes
SELECT
    name,
    location,
    rating,
    votes
FROM zomato_data
WHERE rating >= 4.0
  AND votes >= 500
ORDER BY rating DESC, votes DESC;


/* =========================================================
   4. ONLINE ORDER & TABLE BOOKING ANALYSIS
   ========================================================= */

-- 11. Online-order availability
SELECT
    online_order,
    COUNT(*) AS restaurant_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomato_data), 2)
        AS percentage_of_restaurants
FROM zomato_data
GROUP BY online_order;

-- 12. Table-booking availability
SELECT
    book_table,
    COUNT(*) AS restaurant_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomato_data), 2)
        AS percentage_of_restaurants
FROM zomato_data
GROUP BY book_table;

-- 13. Average rating by online-order availability
SELECT
    online_order,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rating), 2) AS avg_rating
FROM zomato_data
GROUP BY online_order
ORDER BY avg_rating DESC;

-- 14. Average rating by table-booking availability
SELECT
    book_table,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rating), 2) AS avg_rating
FROM zomato_data
GROUP BY book_table
ORDER BY avg_rating DESC;


/* =========================================================
   5. COST ANALYSIS
   ========================================================= */

-- 15. Average cost by restaurant type
SELECT
    type_of_restaurant,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(cost_per_person), 2) AS avg_cost_per_person
FROM zomato_data
GROUP BY type_of_restaurant
ORDER BY avg_cost_per_person DESC;

-- 16. Restaurants with cost per person above the overall average
SELECT
    name,
    location,
    type_of_restaurant,
    cost_per_person
FROM zomato_data
WHERE cost_per_person > (
    SELECT AVG(cost_per_person)
    FROM zomato_data
)
ORDER BY cost_per_person DESC;


/* =========================================================
   6. RESTAURANT TYPE ANALYSIS
   ========================================================= */

-- 17. Most common restaurant types
SELECT
    type_of_restaurant,
    COUNT(*) AS restaurant_count
FROM zomato_data
GROUP BY type_of_restaurant
ORDER BY restaurant_count DESC;

-- 18. Restaurant types with average rating above 4.0
SELECT
    type_of_restaurant,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rating), 2) AS avg_rating
FROM zomato_data
GROUP BY type_of_restaurant
HAVING AVG(rating) > 4.0
ORDER BY avg_rating DESC;


/* =========================================================
   7. CTE ANALYSIS
   ========================================================= */

-- 19. Top locations based on average rating,
--     considering locations with at least 20 restaurants
WITH location_summary AS (
    SELECT
        location,
        COUNT(*) AS restaurant_count,
        AVG(rating) AS avg_rating
    FROM zomato_data
    GROUP BY location
),
qualified_locations AS (
    SELECT
        location,
        restaurant_count,
        avg_rating
    FROM location_summary
    WHERE restaurant_count >= 20
)
SELECT
    location,
    restaurant_count,
    ROUND(avg_rating, 2) AS avg_rating
FROM qualified_locations
ORDER BY avg_rating DESC;

-- 20. Locations with above-average restaurant count
WITH location_counts AS (
    SELECT
        location,
        COUNT(*) AS restaurant_count
    FROM zomato_data
    GROUP BY location
)
SELECT
    location,
    restaurant_count
FROM location_counts
WHERE restaurant_count > (
    SELECT AVG(restaurant_count)
    FROM location_counts
)
ORDER BY restaurant_count DESC;


/* =========================================================
   8. WINDOW FUNCTION ANALYSIS
   ========================================================= */

-- 21. Rank restaurants by rating within each location
SELECT
    name,
    location,
    rating,
    votes,
    DENSE_RANK() OVER (
        PARTITION BY location
        ORDER BY rating DESC, votes DESC
    ) AS location_rank
FROM zomato_data;

-- 22. Top 3 restaurants in each location
WITH ranked_restaurants AS (
    SELECT
        name,
        location,
        rating,
        votes,
        DENSE_RANK() OVER (
            PARTITION BY location
            ORDER BY rating DESC, votes DESC
        ) AS location_rank
    FROM zomato_data
)
SELECT
    name,
    location,
    rating,
    votes,
    location_rank
FROM ranked_restaurants
WHERE location_rank <= 3
ORDER BY location, location_rank;

-- 23. Rank restaurant types by average cost
WITH type_cost AS (
    SELECT
        type_of_restaurant,
        ROUND(AVG(cost_per_person), 2) AS avg_cost
    FROM zomato_data
    GROUP BY type_of_restaurant
)
SELECT
    type_of_restaurant,
    avg_cost,
    DENSE_RANK() OVER (ORDER BY avg_cost DESC) AS cost_rank
FROM type_cost
ORDER BY cost_rank;


/* =========================================================
   9. BUSINESS-ORIENTED ANALYSIS
   ========================================================= */

-- 24. Popular restaurants based on votes
SELECT
    name,
    location,
    votes,
    rating,
    cost_per_person
FROM zomato_data
ORDER BY votes DESC
LIMIT 20;

-- 25. High-rated and highly voted restaurants
SELECT
    name,
    location,
    rating,
    votes,
    cost_per_person
FROM zomato_data
WHERE rating >= 4.0
  AND votes >= 1000
ORDER BY votes DESC;

-- 26. Locations with strong ratings and large restaurant presence
SELECT
    location,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rating), 2) AS avg_rating,
    ROUND(AVG(cost_per_person), 2) AS avg_cost_per_person
FROM zomato_data
GROUP BY location
HAVING COUNT(*) >= 20
   AND AVG(rating) >= 4.0
ORDER BY avg_rating DESC, restaurant_count DESC;

-- 27. Cost segment analysis
SELECT
    CASE
        WHEN cost_per_person < 300 THEN 'Budget'
        WHEN cost_per_person < 700 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS cost_segment,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rating), 2) AS avg_rating
FROM zomato_data
GROUP BY cost_segment
ORDER BY restaurant_count DESC;


/* =========================================================
   END
   ========================================================= */
