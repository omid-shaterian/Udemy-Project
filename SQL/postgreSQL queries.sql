SET search_path = analysis;


SELECT * FROM instructors;
SELECT * FROM courses;

-- creating indexes for performance improvements

CREATE INDEX idx_instructors_id_courses ON courses (instructors_id);
CREATE INDEX idx_instructors_id_instractors ON instructors (instructor_id);
CREATE INDEX idx_created_date ON courses (created_date);

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_courses_title_trgm ON courses USING GIN (courses_title gin_trgm_ops);

-- percentage of courses with their duration in questions compare to all data.

SELECT
(CAST(COUNT(*) AS FLOAT)/ (SELECT COUNT(*) FROM courses))*100 AS percent_of_duration_question
FROM courses
WHERE duration_questions IS NOT NULL

--1.1 Retrieve a list of all courses, including their
--title, rating, number of reviews, and the date they 
--were created.

SELECT 
courses_title,
rating,
num_reviews,
created_date
FROM courses;

--1.2 Calculate the average course rating for each 
--instructor. Display instructor names alongside their
--average rating. 

SELECT 
AVG(rating) AS average_rating,
full_name
FROM courses as c
JOIN instructors as i
ON c.instructors_id = i.instructor_id
GROUP BY 2
ORDER BY 1 DESC

--1.3 Identify the top 5 courses with the highest number
--of reviews.

SELECT
courses_title,
num_reviews
FROM courses
ORDER BY 2 DESC
LIMIT 5

--1.4 Retrieve the oldest 5 courses in the dataset by 
--their creation date.

SELECT
courses_title,
created_date
FROM courses
ORDER BY 2
LIMIT 5

-- 2.1 Find the average duration (in hours) of all 
--courses and compare it with each course’s duration to 
--see if it’s above or below average.

SELECT
courses_title,
duration_hours,
general_average,
CASE
	WHEN duration_hours > (SELECT AVG(duration_hours) FROM courses) THEN 'above'
	ELSE 'below'
END AS compared_to_average
FROM courses
CROSS JOIN (SELECT AVG(duration_hours) FROM courses) AS general_average
WHERE duration_hours IS NOT NULL

--2.2 Find courses with a rating above 4.5 and more than
--50,000 reviews. Include course title, rating, number 
--of reviews, and instructor name.

SELECT 
c.courses_title,
rating,
num_reviews,
full_name
FROM courses as c
JOIN instructors as i
ON c.instructors_id = i.instructor_id
WHERE rating > 4.5
AND num_reviews > 50000

--2.3 Create a report listing instructors who have at 
--least 3 courses, along with the total number of 
--reviews across all their courses.

SELECT
instructors_id,
full_name,
COUNT (c.courses_title) AS num_courses,
SUM(num_reviews) AS total_reviews
FROM courses as c
JOIN instructors as i
ON c.instructors_id = i.instructor_id
GROUP BY 1,2
HAVING COUNT(c.courses_title) > 2
ORDER BY 4,3 DESC

--2.4 Identify courses that have been updated in the 
--last 2 years. Display their title, last update date, and 
--instructor.

SELECT
c.courses_title,
full_name,
last_update_date
FROM courses as c
JOIN instructors as i
ON c.instructors_id = i.instructor_id
WHERE last_update_date IS NOT NULL
AND last_update_date >= (NOW() - INTERVAL '2 year')
ORDER BY 3 DESC

--2.5 Find the top 5 most popular topics 
--(keywords in titles, such as "Python" or "JavaScript")
--based on the number of reviews. (This may require some
--keyword filtering and counting.)

-- first solution
SELECT
SUM(CASE
		WHEN courses_title ILIKE '%python%' THEN 1
		ELSE 0
	END 
) AS python_related,
SUM(CASE
		WHEN courses_title ILIKE '%javascript%' THEN 1
		ELSE 0
	END 
) AS java_related,
SUM(CASE
		WHEN courses_title ILIKE '%data%' THEN 1
		ELSE 0
	END 
) AS data_related
FROM courses

--second solution(prefered)

DROP TABLE IF EXISTS keywords;
CREATE TABLE keywords (
    keyword VARCHAR(50)
);

INSERT INTO keywords (keyword)
VALUES 
('Python'), 
('Web Development'), 
('Data'), 
('Machine Learning'), 
('JavaScript'), 
('Excel'), 
('Digital Marketing'), 
('Project Management'), 
('SQL'), 
('Graphic Design'), 
('Personal Development'), 
('Photography'), 
('Ethical Hacking'), 
('AWS Certification'), 
('Financial'), 
('Public Speaking'), 
('Microsoft Office'), 
('Cyber Security'), 
('Business'), 
('Music Production'), 
('Video Editing'), 
('Artificial Intelligence'), 
('Blockchain'), 
('Cloud Computing'), 
('Leadership'), 
('Adobe Photoshop'), 
('Agile Methodologies'), 
('Mobile App Development'), 
('Copywriting'), 
('Fitness Training'), 
('Cooking'), 
('Meditation'), 
('Language Learning'), 
('Entrepreneurship'), 
('UX/UI'), 
('Networking'), 
('React'), 
('Angular'), 
('C++'), 
('Java'), 
('Tableau'), 
('Piano'), 
('SEO'),  
('Investing'), 
('Drawing'), 
('Animation'), 
('Robotics'), 
('Game Development');


DROP VIEW IF EXISTS popular_keywords;
CREATE VIEW  popular_keywords AS
SELECT 
DATE_PART('year', created_date) AS year,
keyword,
COUNT(*) AS course_count
FROM courses c
JOIN keywords k
ON c.courses_title ILIKE '%' || k.keyword || '%'
GROUP BY 1,2
ORDER BY 1 DESC

--3.1 Assuming a fixed price per course (e.g., €50),
--estimate the total revenue generated by each course
--based on its number of reviews
--(assuming each review represents a purchase). 
--Show course title, total reviews, estimated revenue,
--and instructor.

SELECT 
full_name,
SUM(num_reviews * 50) AS estimated_revenue_in_euro
FROM courses c
JOIN instructors i
ON c.instructors_id = i.instructor_id
GROUP BY 1
ORDER BY 2 DESC

--3.2  Calculate the total number of hours an instructor has created across
--all their courses. Identify the top 3 instructors with the highest total 
--course hours.


SELECT
full_name,
SUM(duration_hours) AS total_hours_created
FROM courses c
JOIN instructors i
ON c.instructors_id = i.instructor_id
WHERE duration_hours IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

--3.3 For each course, calculate an "engagement score" by dividing the number
--of reviews by the course duration (to see reviews per hour). Identify courses
--with a high engagement score.(the courses that have above average review numbers and duration)

DROP VIEW IF EXISTS engagement_score;
CREATE VIEW engagement_score AS
SELECT 
courses_title,
rating,
full_name,
num_reviews,
duration_hours,
CASE
	WHEN num_reviews = 0 THEN 0
	ELSE (num_reviews / duration_hours)
END  AS course_engagement
FROM courses c
JOIN instructors i
ON c.instructors_id = i.instructor_id
WHERE duration_hours IS NOT NULL
AND num_reviews > (SELECT AVG(num_reviews) FROM courses)
AND duration_hours > (SELECT AVG(duration_hours) FROM courses)
ORDER BY 6 DESC

--3.4  Compare instructors based on their average course rating and total
--number of reviews. Identify any instructors with high ratings but low
--review counts (or vice versa).

SELECT
full_name,
AVG(rating) AS average_rating,
SUM(num_reviews) AS total_reviews
FROM courses c
JOIN instructors i
ON c.instructors_id = i.instructor_id
GROUP BY 1
HAVING SUM(num_reviews) > 0
ORDER BY 2 DESC,3 

--3.5 Count the number of new courses created each year. Use this data later
--in Power BI to create a time series visualization showing course creation
--trends over time.

SELECT
DATE_PART('year', created_date) AS year_of_creation,
COUNT(courses_title) AS number_of_courses
FROM courses
GROUP BY 1
ORDER BY 1;

--4.1 Calculate the growth rate of new courses created per instructor over
--the years. Find instructors who have increased their course creation rate
--significantly.

SELECT
MIN(created_date),
MAX(created_date)
FROM courses

CREATE VIEW instructor_growth AS
WITH all_years AS (
    -- Generate a series of years from 2010 to 2023
    SELECT GENERATE_SERIES(2010, 2023) AS year
),
instructor_courses AS (
    -- Get course count per instructor per year
    SELECT
        instructors_id,
        DATE_PART('year', created_date) AS year,
        COUNT(*) AS course_count
    FROM courses c
    GROUP BY instructors_id, year
),
expanded_data AS (
    -- Cross join instructors with all years, left join with instructor_courses to fill missing years with NULL
    SELECT
        i.instructor_id,
        a.year,
        ic.course_count  -- This should be NULL if there's no matching record
    FROM
        instructors i
    CROSS JOIN all_years a
    LEFT JOIN instructor_courses ic
    ON i.instructor_id = ic.instructors_id AND a.year = ic.year
),
growth_rates AS (
    -- Calculate the growth rate for each instructor year-over-year
    SELECT instructor_id, year,
           LAG(course_count) OVER (PARTITION BY instructor_id ORDER BY year) AS previous_year_count,
           course_count,
           CASE
               WHEN LAG(course_count) OVER (PARTITION BY instructor_id ORDER BY year) > 0 THEN
                   ((course_count - LAG(course_count) OVER (PARTITION BY instructor_id ORDER BY year))::FLOAT /
                   LAG(course_count) OVER (PARTITION BY instructor_id ORDER BY year)) * 100
               ELSE NULL
           END AS growth_rate
    FROM expanded_data
)
SELECT
full_name,
year,
growth_rate
FROM growth_rates g
JOIN instructors i
ON g.instructor_id = i.instructor_id
WHERE growth_rate > 50
ORDER BY 3 DESC



--4.2  Identify any instructors who haven't updated any of their courses in 
--over two years. Display their name and the latest update date for each course.
EXPLAIN ANALYSE
SELECT
full_name,
courses_title,
last_update_date
FROM courses c
JOIN instructors i
ON c.instructors_id = i.instructor_id
WHERE NOW() - last_update_date > INTERVAL '2 years'
GROUP BY 1,2,3
ORDER BY 1,3


DROP VIEW IF EXISTS update_history;
CREATE VIEW update_history AS
SELECT
full_name,
courses_title,
rating,
num_reviews,
duration_hours,
CASE
	WHEN num_reviews = 0 THEN 0
	ELSE (num_reviews / duration_hours)
END  AS course_engagement,
CASE
	WHEN NOW() - last_update_date > INTERVAL '2 years' THEN 'not updated in the last 2 years'
	ELSE 'updated in the last 2 years'
END AS update_status
FROM courses c
JOIN instructors i
ON c.instructors_id = i.instructor_id
WHERE duration_hours IS NOT NULL

--4.3 Find instructors with a high consistency in course ratings
--(low variance in ratings across their courses).

SELECT 
full_name,
SUM(num_reviews) AS total_reviews,
COUNT(courses_title) AS number_of_courses,
STDDEV_POP(rating) AS rating_standard_deviation
FROM courses c
JOIN instructors i
ON c.instructors_id = i.instructor_id
GROUP BY 1
ORDER BY 3 DESC,4;

--4.4 Examine the titles of highly rated and reviewed courses to identify
--keywords associated with success. List keywords that appear frequently in
--top-rated courses and use these insights to suggest topics for new courses.


WITH course_rankings AS (
    SELECT 
        courses_title,
        rating,
        num_reviews,
        ROW_NUMBER() OVER (ORDER BY num_reviews DESC, rating DESC) AS rank
    FROM courses
),
successful_courses AS (
    SELECT 
        courses_title
    FROM course_rankings
    WHERE rank <= 100  -- Dynamically select the top 100 by rank
    OR rating >= 4.5  -- Allow courses with a high rating (or other criteria)
)

SELECT 
    k.keyword,
    COUNT(*) AS course_count
FROM successful_courses sc
JOIN keywords k 
    ON sc.courses_title ILIKE '%' || k.keyword || '%'  -- Keyword matching
GROUP BY 1
ORDER BY 2 DESC;

--4.5 exploring the data categorized by the keywords

DROP VIEW IF EXISTS keyword_exploration;
CREATE VIEW keyword_exploration AS
SELECT
keyword,
SUM(num_reviews) AS total_reviews,
AVG(rating) AS average_rating,
AVG(duration_hours) AS average_duration
FROM 
courses c
JOIN keywords k
ON c.courses_title ILIKE '%' || k.keyword || '%'
WHERE duration_hours IS NOT NULL
GROUP BY k.keyword

WITH keyword_courses AS(
SELECT 
k.keyword,
c.courses_title AS course_title
FROM courses c
JOIN keywords k
ON c.courses_title ILIKE '%' || k.keyword || '%'
)

SELECT
COUNT(DISTINCT course_title) AS keyword_course
FROM keyword_courses

-- dynamically searching for the most common words in the course titles

WITH tokenized_titles AS (
    -- Split course titles into individual words
    SELECT 
        UNNEST(STRING_TO_ARRAY(LOWER(courses_title), ' ')) AS word
    FROM courses
),
filtered_tokens AS (
    -- Exclude common stopwords and non-alphanumeric tokens
    SELECT 
        word
    FROM tokenized_titles
    WHERE word NOT IN ('and', 'the', 'of', 'to', 'in', 'for', 'with', 'on', 'by', 'a', 'an', 'is', 'at', 'or', 'as')
    AND word ~ '^[a-z0-9]+$' -- Keep only alphanumeric words
),
word_count AS (
    -- Count occurrences of each word
    SELECT 
        word, 
        COUNT(*) AS word_count
    FROM filtered_tokens
    GROUP BY word
    ORDER BY word_count DESC
)
-- Display the top N most common words
SELECT * 
FROM word_count
LIMIT 100;

--4.6 the most common titles among the instructors

WITH key_titles AS (
SELECT
UNNEST(STRING_TO_ARRAY(LOWER(job_title), ' ')) AS key_title
FROM instructors
)
SELECT
key_title,
COUNT(*) AS popular_title
FROM key_titles
WHERE key_title in ('instructor','engineer','coach','professional','developer','trainer','teacher','expert','consultant','designer','artist','certified','entrepreneur','founder','architect','author','trader','professor')
GROUP BY 1
ORDER BY 2 DESC
