# Telecommunications Database Project 

This project implements a relational OLTP database for a telecommunications provider, using MySQL. It includes schema design, sample data, and analytical SQL queries for business insights.

## Contents
- `create_schema.sql`: Script to create all tables with proper constraints
- `insert_sample_data.sql`: Sample data for each table
- `analysis_queries.sql`: SQL queries for analytics and reporting
- `etl_summary_query.sql`: ETL-based aggregation for service plan usage
- `stored_procedure.sql`: A stored procedure for customer billing summary

## Setup Instructions
1. **Environment**: MySQL 8.x (tested with MySQL Workbench)
2. **Run Order**:
   - Step 1: `create_schema.sql`
   - Step 2: `insert_sample_data.sql`
   - Step 3: `stored_procedure.sql` 
   - Step 4: `analysis_queries.sql`
   - Step 5: `etl_summary_query.sql`

Make sure to enable foreign key checks and run scripts in the correct order to avoid dependency issues.

## Notes
- `DROP TABLE IF EXISTS` statements are used to make re-execution easier.
- All queries were tested and run without errors in MySQL Workbench.
- Ensure correct date formats (e.g., `YYYY-MM-DD`) when adding your own data.
- The project uses realistic telecom scenarios like billing, usage analysis, promotions, and failed transactions.

## Optional: Public SQL Script
You can access the full SQL script via this link:
📎 https://github.com/faransad/telecom_sql_project.git 

---

## Author
Faranak Sadeghi (Data Analyst Master's Student)  
Course: Data Warehouse and Database Management Systems
University Assignment – June 2025
