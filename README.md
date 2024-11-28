# Udemy Project
A detail journal of my data analysis project using more than 83,000 udemy courses.

## Project Stages

 - Finding and Downloading the Dataset
 - Data Cleaning and Preprocessing
	 - Removing Unnecessary Columns
	 - Duration Column
	 - Removing Duplicate Columns
 - Solving Business Problems in Postgresql
 - Saving Queries as Views and Query Optimization
 - Visualization

## Finding and Downloading the Dataset
In the initial stage of my project, I focused on finding a dataset that would be both engaging and unique. It was important to me to select a dataset that had not been extensively analyzed, avoiding popular options like the Titanic or COVID datasets, as these have been explored countless times. I aimed to work with data that was not only intriguing but also personally meaningful.

Given my positive experience with Udemy courses, which have played a significant role in shaping my career, I decided to explore datasets related to Udemy. This led me to search on Kaggle for suitable Udemy datasets, carefully selecting one that would best align with my project goals. My criteria included finding a dataset that was reasonably large but still manageable on my personal laptop. Additionally, I prioritized datasets that were recent and contained meaningful information that could be transformed into valuable insights.

After thorough exploration, I identified a dataset that closely met my standards and proceeded to use it for my project.
you can find the dataset here: [udemy courses dataset](https://www.kaggle.com/datasets/904c62591ed5be22928d131ce1e3a9de792c9d2c136b341582faf82d94a2af35)

## Data Cleaning and Preprocessing

### Removing Unnessecary Columns
The dataset comprises two tables, each with an `id` column as its primary key. These tables are linked through a foreign key, the `instructor_id`.

Although the data was relatively clean, there were several columns containing URLs for courses and instructor pictures. Since I did not plan to use this data for machine learning tasks like computer vision, these columns were unnecessary. To streamline the dataset and save space, I removed these irrelevant columns to keep the tables concise. Additionally, some columns, such as those containing ratings, required minor formatting adjustments, which I addressed during this initial stage of preparation.
### duration column

The `duration` column required separation into two distinct columns, as it contained data in two different units: hours and questions. To achieve this, I used the following formulas in Excel:

-   **Hours**:
    
    ```
    =IF(OR(ISNUMBER(SEARCH("hour", F2)), ISNUMBER(SEARCH("hours", F2))), LEFT(F2, FIND(" ", F2) - 1) * 1, "")  
    
    ```
    
-   **Questions**:
    
    ```
    =IF(ISNUMBER(SEARCH("question", F2)), VALUE(LEFT(F2, FIND(" ", F2) - 1)), "")  
    
    ```
    

These formulas scan the `duration` column to identify rows containing the keywords _hours_, _hour_, or _questions_. The relevant text is removed using the `LEFT` function, and the numeric values are extracted and placed into their respective columns (`duration_hours` or `duration_questions`). This resulted in two separate integer columns representing the different units. It’s worth noting that entries in the _questions_ column accounted for less than 5% of the data.

Once the data was appropriately separated, I copied the values from the new columns (`duration_hours` and `duration_questions`) and removed the original `duration` column to streamline the dataset.
To address the issue of duplicates in the `id` column, I used the `ROW_NUMBER()` function to identify and remove duplicate rows, keeping only the first occurrence of each row.

### Removing Duplicate Columns

Initially, I used the `id` column to identify duplicates, but encountered a problem: the `DELETE` statement removed all rows with a duplicate `course_id`, rather than just the specific rows identified by `ROW_NUMBER() > 1`.

To resolve this, I modified the query to use a Common Table Expression (CTE) directly within the `DELETE` statement. This allowed me to target only rows with `row_num > 1`, ensuring that duplicates were removed without affecting the first occurrence of each `course_id`.

Here’s the corrected query:

```sql
WITH duplicates AS (
    SELECT ctid, -- Unique row identifier
           ROW_NUMBER() OVER(PARTITION BY course_id ORDER BY course_id) AS row_num
    FROM udemy
)
DELETE FROM udemy
WHERE ctid IN (
    SELECT ctid FROM duplicates WHERE row_num > 1
);

```

### Explanation:

-   **`ctid`**: A unique identifier for each row in PostgreSQL, used to target specific rows for deletion. This ensures that only the intended duplicates are removed.
-   **`ROW_NUMBER()`**: Assigns a unique number to each row within a partition (`course_id`), ordered by `course_id`. The first instance receives `row_num = 1`.
-   **`WHERE row_num > 1`**: Ensures that only duplicate rows (those beyond the first occurrence) are marked for deletion.

This approach effectively removes duplicates while preserving the integrity of the dataset by retaining the first instance of each `course_id`.
## Solving Business Problems in PostgreSQL
In the next stage, I tackled approximately 20 business problems with the aim of extracting valuable insights from the available dataset. My approach began with analyzing general key indicators and then delved deeper into specific areas, such as course performance, key metrics, popular keywords, and other relevant aspects.  

I believe the insights derived from these queries offer valuable information about the most successful courses, the most active instructors, the most popular subjects, and other factors that can significantly enhance decision-making processes.  

The following sections provide explanations of some of the key queries I developed. For a comprehensive view of all the queries, please refer to the ‘Query Collection’ file.
### Identifying Popular Topics in Course Titles  

To determine the most popular topics (keywords in course titles such as "Python" or "JavaScript") based on the number of reviews, a multi-step approach was implemented. This involved tokenizing course titles, filtering relevant keywords, and analyzing the data using a dynamic matching approach.

#### Step 1: Tokenizing Course Titles  
The first step was to extract individual words from course titles. Using PostgreSQL's `UNNEST` and `STRING_TO_ARRAY` functions, course titles were split into individual tokens.  

```sql
WITH tokenized_titles AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(LOWER(courses_title), ' ')) AS word
    FROM courses
)
```

#### Step 2: Filtering Tokens  
Next, common stopwords (e.g., "and," "the") and non-alphanumeric tokens were excluded. This helped refine the dataset to focus on potentially meaningful keywords.  

```sql
filtered_tokens AS (
    SELECT 
        word
    FROM tokenized_titles
    WHERE word NOT IN ('and', 'the', 'of', 'to', 'in', 'for', 'with', 'on', 'by', 'a', 'an', 'is', 'at', 'or', 'as')
    AND word ~ '^[a-z0-9]+$'
)
```

#### Step 3: Counting Words  
The remaining words were then aggregated and ranked based on their frequency of occurrence.  

```sql
word_count AS (
    SELECT 
        word, 
        COUNT(*) AS word_count
    FROM filtered_tokens
    GROUP BY word
    ORDER BY word_count DESC
)
SELECT * 
FROM word_count
LIMIT 100;
```

#### Refining Results  
Although this approach significantly reduced noise, some remaining words were not course subjects. To improve accuracy, a curated list of approximately 50 relevant keywords was created and stored in a `keywords` table.  

```sql
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
-- additional entries omitted for brevity
('Robotics'), 
('Game Development');
```

#### Step 4: Non-Equijoin for Keyword Matching  
A non-equijoin was then used to match course titles dynamically with the curated keywords.  

**Key Mechanism:**  
- The `ILIKE` operator allows case-insensitive matching.
- The pattern `ILIKE '%' || k.keyword || '%'` checks if a course title contains any keyword from the table.

```sql
SELECT c.title, k.keyword
FROM courses c
JOIN keywords k 
ON c.title ILIKE '%' || k.keyword || '%';
```

**Explanation:**  
- **Dynamic Pattern Matching:** For each course title, the database searches for a match with every keyword in the `keywords` table.  
- **String Concatenation:** The `ILIKE` condition ensures that keywords are matched anywhere in the title.  

**Example:**  
If a course title is "Learn Python Programming," the keyword "Python" will be identified as a match, creating a result pair.

This methodology provided a robust solution to identify and rank popular topics, ensuring the results were meaningful and aligned with real-world insights.
### Calculating Engagement Score  

To evaluate the engagement of each course, an "engagement score" was calculated by dividing the number of reviews by the course duration (reviews per hour). This approach provides insights into which courses deliver the most engagement relative to their length.

#### Filtering Outliers  
Before identifying the courses with the highest engagement scores, a filtering process was applied to exclude outliers. Courses with below-average duration and review counts were removed. This ensured the results were not skewed by courses with disproportionately high reviews but extremely short durations.

#### Query Implementation  

```sql
SELECT 
    courses_title,
    rating,
    full_name,
    num_reviews,
    duration_hours,
    CASE
        WHEN num_reviews = 0 THEN 0
        ELSE (num_reviews / duration_hours)
    END AS course_engagement
FROM courses c
JOIN instructors i
ON c.instructors_id = i.instructor_id
WHERE duration_hours IS NOT NULL
AND num_reviews > (SELECT AVG(num_reviews) FROM courses)
AND duration_hours > (SELECT AVG(duration_hours) FROM courses)
ORDER BY course_engagement DESC;
```

#### Key Details of the Query  

1. **Engagement Score Calculation:**  
   - The engagement score was defined as:  
     engagement score = number of reviews / duration in hours
   - A `CASE` statement was used to handle cases where the number of reviews was zero, assigning an engagement score of `0` in such instances.

2. **Join with Instructor Information:**  
   - The query joined the `courses` table with the `instructors` table to include instructor names (`full_name`) alongside course details.

3. **Filtering Criteria:**  
   - Courses were included only if:  
     - `num_reviews` exceeded the average number of reviews.  
     - `duration_hours` exceeded the average course duration.

4. **Sorting Results:**  
   - The results were ordered by `course_engagement` in descending order to highlight the most engaging courses at the top.
### Calculating the Growth Rate  

To identify instructors who have significantly increased their course creation rate over time, we calculated the year-over-year growth rate of new courses created per instructor.  

#### Approach  

1. **Determine the Time Span:**  
   First, the overall time span of course creation was determined using the following query:  
   ```sql
   SELECT MIN(created_date), MAX(created_date) FROM courses;
   ```  
   This provided the earliest and latest course creation dates in the dataset.  

2. **Addressing Inactive Years:**  
   Many instructors were inactive during certain years, making it challenging to calculate year-over-year growth rates. To address this, we created a complete dataset of all years (from 2010 to 2023) and cross-joined it with the instructors table to ensure that every instructor had a record for each year, even if they were inactive.

#### Query Explanation  

```sql
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
        ic.course_count  -- NULL for inactive years
    FROM
        instructors i
    CROSS JOIN all_years a
    LEFT JOIN instructor_courses ic
    ON i.instructor_id = ic.instructors_id AND a.year = ic.year
),
growth_rates AS (
    -- Calculate year-over-year growth rate for each instructor
    SELECT 
        instructor_id, 
        year,
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
ORDER BY growth_rate DESC;
```  

#### Key Steps  

1. **Generate Complete Dataset:**  
   - A table of years (`all_years`) was generated for the desired range (2010–2023).  
   - This table was cross-joined with the `instructors` table, ensuring every instructor had an entry for all years.  

2. **Calculate Year-Over-Year Growth Rate:**  
   - The `LAG()` function was used to get the course count for the previous year for each instructor.  
   - The growth rate was then calculated as:  
     Growth Rate = ((Current Year Course Count - Previous Year Course Count) /Previous Year Course Count)* 100
    
   - Growth rates were calculated only when there was a valid course count for the previous year.

3. **Filter and Sort Results:**  
   - Only instructors with a growth rate exceeding 50% in any given year were included in the results.  
   - Results were sorted in descending order of growth rate.  
## Saving Views and Optimizing Queries  

After crafting the queries, I saved the more complex ones as views to streamline their use in Power BI for creating visualizations. Additionally, I created indexes for frequently used columns to enhance the speed and efficiency of query execution. This optimization significantly improved the processing time for complex queries, such as keyword categorization (question 2.5), as demonstrated in the images available in the image folder.

