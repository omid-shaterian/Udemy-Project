# Udemy Project
A detail journal of my data analysis project using more than 83,000 udemy courses.

## Project Stages

 - Finding and Downloading the Dataset
 - Data Cleaning and Preprocessing
	 - Removing Unnecessary Columns
	 - Duration Column
	 - Removing Duplicate Columns
 - Solving Business Problems in Postgresql
 - sSaving Queries as Views and Query Optimization Visualization

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
