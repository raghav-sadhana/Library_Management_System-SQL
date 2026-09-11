# Library Management System (SQL Project)

## Overview
This project simulates a **Library Management System** using **MySQL**, covering database design across multiple related tables (books, members, employees, branches, issued/return status). It includes CRUD operations, joins across tables, CTAS (Create Table As Select), and advanced business queries to analyze library operations, member behavior, and branch performance.

## Objective
The goal of this project is to answer key operational and business questions such as:
- Who are the members with overdue books?
- How is each branch performing in terms of issues, returns, and revenue?
- Which employees have processed the most book issues?
- Which members are issuing damaged books repeatedly?
- What is the rental income by book category?

## ER Diagram
![ER Diagram](Library_Management_System%20ER-Diagram.png)

## Database Schema
The project uses the following tables:

| Table | Description |
|---|---|
| books | Book details (isbn, title, category, rental price, status, author, publisher) |
| members | Library member details (member_id, name, address, registration date) |
| employees | Employee details (emp_id, name, salary, branch_id) |
| branch | Branch details (branch_id, manager_id, address, contact number) |
| issued_status | Records of books issued (issued_id, member, employee, book, date) |
| return_status | Records of books returned (return_id, issued_id, return date, book quality) |

Each table's primary key was added and data types corrected (dates, prices, IDs) as part of the setup.

## Tools Used
- **MySQL** (MySQL Workbench)
- SQL concepts: DDL/DML, primary keys, joins (INNER/LEFT), GROUP BY/HAVING, CTAS, DATEDIFF, aggregate functions

## Project Workflow

### 1. Database & Table Setup
Created the database, added primary keys to all 6 tables, and corrected data types for dates, prices, and salary fields.

### 2. Business Analysis (Key Queries)

**1. Create a new book record**
```sql
INSERT INTO books 
(isbn, book_title, category, rental_price, status, author, publisher) 
VALUES 
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```

**2. Update an existing member's address**
```sql
UPDATE members
SET member_address = '780 Oak St'
WHERE member_id = 'C103';
```

**3. Delete a record from Issued Status**
```sql
DELETE FROM issued_status
WHERE issued_id = 'IS107';
```

**4. Retrieve all books issued by a specific employee**
```sql
SELECT 
* 
FROM issued_status
WHERE issued_emp_id = 'E101';
```

**5. Members who have issued more than one book**
```sql
SELECT 
issued_member_id,
COUNT(issued_id) AS Issued_Books
FROM issued_status
GROUP BY issued_member_id
HAVING issued_books > 1
ORDER BY issued_books;
```

**6. Summary table of book issue counts (CTAS)**
```sql
CREATE TABLE Book_Count AS 
		SELECT 
		book_title,
		COUNT(issued_id) AS Book_Issued_Count
		FROM books AS b
		INNER JOIN issued_status AS i
		ON b.isbn = i.issued_book_isbn
		GROUP BY book_title;
```

**7. Retrieve all books in a specific category**
```sql
SELECT 
*
FROM books 
WHERE category = 'History';
```

**8. Total rental income by category**
```sql
SELECT 
category,
SUM(rental_price) AS Total_Rent
FROM books
GROUP BY category;
```

**9. Members registered in the last 900 days**
```sql
SELECT 
member_id,
DATEDIFF(CURRENT_DATE(), reg_date) AS Last_Registration
FROM members
WHERE DATEDIFF(CURRENT_DATE(), reg_date) <= 900;
```

**10. Employees with branch manager and branch details**
```sql
SELECT 
e.emp_id,
e.emp_name,
b.manager_id,
e2.emp_name AS Manager_Name,
b.branch_id,
b.branch_address,
b.contact_no
FROM employees AS e
INNER JOIN branch AS b
ON e.branch_id = b.branch_id
INNER JOIN employees AS e2 
ON e2.emp_id = b.manager_id;
```

**11. Books with rental price above $7 (CTAS)**
```sql
CREATE TABLE Expensive_Books AS 
  SELECT 
	*
	FROM books 
	WHERE rental_price  >= 7;
```

**12. Books not yet returned**
```sql
SELECT
*
FROM issued_status AS i
LEFT JOIN return_status AS r
ON i.issued_id = r.issued_id
WHERE r.issued_id IS NULL;
```

**13. Members with overdue books (Advanced)**
```sql
SELECT 
m.member_id,
m.member_name,
b.book_title,
i.issued_date,
(DATEDIFF(CURRENT_DATE(), i.issued_date) - 890) AS Overdues_By_Days
FROM members AS m
INNER JOIN issued_status AS i
on m.member_id = i.issued_member_id
INNER JOIN books AS b
ON b.isbn = i.issued_book_isbn
LEFT JOIN return_status AS r
ON r.issued_id = i.issued_id
WHERE 	r.issued_id IS NULL 
		AND 
        DATEDIFF(CURRENT_DATE(), i.issued_date) > 890;
```

**14. Branch performance report (Advanced)**
```sql
SELECT 
br.branch_id,
br.branch_address,
br.contact_no,
COUNT(i.issued_id) AS Total_Book_Issued,
COUNT(r.return_id) AS Total_Book_Return,
SUM(b.rental_price) AS Total_Revenue
FROM branch AS br
INNER JOIN employees AS e
ON br.branch_id = e.branch_id
INNER JOIN issued_status AS i
ON i.issued_emp_id = e.emp_id
LEFT JOIN return_status AS r
ON r.issued_id = i.issued_id
INNER JOIN books AS b
ON b.isbn = i.issued_book_isbn
GROUP BY br.branch_id, br.branch_address, br.contact_no;
```

**15. Active members in the last 28 months (CTAS, Advanced)**
```sql
CREATE TABLE active_members AS
		SELECT 
		DISTINCT m.*
		FROM members AS m
		INNER JOIN issued_status AS i
		ON m.member_id = i.issued_member_id
		WHERE i.issued_date >= CURRENT_DATE() - INTERVAL 28 MONTH;
```

**16. Top 3 employees by books processed (Advanced)**
```sql
SELECT 
e.emp_name,
COUNT(DISTINCT i.issued_id) AS Book_Processed,
b.branch_id,
b.branch_address
FROM employees AS e
INNER JOIN issued_status AS i
ON e.emp_id = i.issued_emp_id
INNER JOIN branch AS b
ON e.branch_id = b.branch_id
GROUP BY e.emp_name, b.branch_id, b.branch_address
ORDER BY book_processed DESC
LIMIT 3;
```

**17. Members issuing high-risk (damaged) books (Advanced)**
```sql
SELECT 
m.member_name,
i.issued_book_name,
COUNT(i.issued_id) AS Book_Issued
FROM members AS m
INNER JOIN issued_status AS i
ON m.member_id = i.issued_member_id
INNER JOIN return_status AS r
ON r.issued_id = i.issued_id
WHERE book_quality = 'damaged'
GROUP BY m.member_id, i.issued_book_name
HAVING book_issued > 2;
```

*(See `library_management_system.sql` for the full set of queries.)*

## Key Insights
- Overdue tracking highlights members holding books well beyond the return period.
- Branch-level reporting reveals differences in issue volume, return rates, and revenue across locations.
- A small set of employees handle a disproportionate share of book issuing activity.
- Certain members repeatedly return books in damaged condition, flaggable as high-risk borrowers.
- Rental income varies notably by book category.

## Repository Structure
library-management-system-sql/
│── er_diagram.jpg
│── library_management_system.sql
│── README.md


## How to Use
1. Clone this repository
2. Set up the required tables (`books`, `members`, `employees`, `branch`, `issued_status`, `return_status`) in a MySQL database
3. Run `library_management_system.sql` in MySQL Workbench (or any MySQL client) to reproduce the schema setup and analysis

## Author
*Raghav Sadhana*  
[LinkedIn](https://www.linkedin.com/in/raghav-sadhana-710a1a318) | [GitHub](https://github.com/raghav-sadhana)
