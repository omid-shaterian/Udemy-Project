# udemy project
A detail journal of my data analysis project using more than 83,000 udemy courses.

## project stages

 - finding and downloading the dataset
 - data cleaning and preprocessing
	 - removing unnecessary columns
	 - duration column
	 - removing duplicate columns
 - solving business problems in postgresql
 - saving queries as views and query optimization visualization
**Handling the Duration Column**  

The `duration` column required separation into two distinct columns, as it contained data in two different units: hours and questions. To achieve this, I used the following formulas in Excel:  

- **Hours**:  
  ```  
  =IF(OR(ISNUMBER(SEARCH("hour", F2)), ISNUMBER(SEARCH("hours", F2))), LEFT(F2, FIND(" ", F2) - 1) * 1, "")  
  ```  
- **Questions**:  
  ```  
  =IF(ISNUMBER(SEARCH("question", F2)), VALUE(LEFT(F2, FIND(" ", F2) - 1)), "")  
  ```  

These formulas scan the `duration` column to identify rows containing the keywords *hours*, *hour*, or *questions*. The relevant text is removed using the `LEFT` function, and the numeric values are extracted and placed into their respective columns (`duration_hours` or `duration_questions`). This resulted in two separate integer columns representing the different units. It’s worth noting that entries in the *questions* column accounted for less than 5% of the data.  

Once the data was appropriately separated, I copied the values from the new columns (`duration_hours` and `duration_questions`) and removed the original `duration` column to streamline the dataset.  

**Converting the CSV File to a PostgreSQL Table**  

Finally, I converted the cleaned CSV file into a PostgreSQL table using an online tool for ease of further analysis.
