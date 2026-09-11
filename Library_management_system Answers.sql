# Create Database
CREATE DATABASE Library_Management_System;

# Use Database
USE Library_Management_System;

# Adding Primary Key
-- books (isbn)
ALTER TABLE books
MODIFY isbn VARCHAR(20),
ADD PRIMARY KEY (isbn);

-- branch (branch_id)
ALTER TABLE branch
MODIFY branch_id VARCHAR(20),
ADD PRIMARY KEY (branch_id);

-- employees (emp_id)
ALTER TABLE employees
MODIFY emp_id VARCHAR(20),
ADD PRIMARY KEY (emp_id);

-- issued_status (issued_id)
ALTER TABLE issued_status
MODIFY issued_id VARCHAR(20),
ADD PRIMARY KEY (issued_id);

-- members (member_id)
ALTER TABLE members
MODIFY member_id VARCHAR(20),
ADD PRIMARY KEY (member_id);

-- return_status (return_id)
ALTER TABLE return_status
MODIFY return_id VARCHAR(20),
ADD PRIMARY KEY (return_id);

# Correcting Data Types
-- Rental_Price
ALTER TABLE books
MODIFY rental_price FLOAT;

-- Salary
ALTER TABLE employees
MODIFY salary FLOAT;

-- Issued_Date
ALTER TABLE issued_status
MODIFY issued_date DATE;

-- Reg_Date
ALTER TABLE members
MODIFY reg_date DATE;

-- Return_Date
ALTER TABLE return_status
MODIFY return_date DATE;

# Project Tasks
-- Create a New Book Record -- 978-1-60129-456-2, To Kill a Mockingbird, Classic, 6.00, yes, Harper Lee, J.B. Lippincott & Co.
INSERT INTO books 
(isbn, book_title, category, rental_price, status, author, publisher) 
VALUES 
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- Update an Existing Member's Address
UPDATE members
SET member_address = '780 Oak St'
WHERE member_id = 'C103';

-- Delete a record from the Issued Status table - Objective: Delete the record with issued_id = 'IS107' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS107';

-- Retrieve all books issued by a specific employee - Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT 
* 
FROM issued_status
WHERE issued_emp_id = 'E101';

-- List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT 
issued_member_id,
COUNT(issued_id) AS Issued_Books
FROM issued_status
GROUP BY issued_member_id
HAVING issued_books > 1
ORDER BY issued_books;

-- Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_count
CREATE TABLE Book_Count AS 
		SELECT 
		book_title,
		COUNT(issued_id) AS Book_Issued_Count
		FROM books AS b
		INNER JOIN issued_status AS i
		ON b.isbn = i.issued_book_isbn
		GROUP BY book_title;
        
-- Retrieve all books in a specific category
SELECT 
*
FROM books 
WHERE category = 'History';

-- Find total rental income by category 
SELECT 
category,
SUM(rental_price) AS Total_Rent
FROM books
GROUP BY category;

-- List members who registered in last 900 days
SELECT 
member_id,
DATEDIFF(CURRENT_DATE(), reg_date) AS Last_Registration
FROM members
WHERE DATEDIFF(CURRENT_DATE(), reg_date) <= 900;

-- List Employees with their branch manager's name and their branch details 
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

-- Create a table of books with rental price above a certain threshold 7USD
CREATE TABLE Expensive_Books AS 
    SELECT 
	*
	FROM books 
	WHERE rental_price  >= 7;
    
-- Retrieve the list of books not yet returned 
SELECT
*
FROM issued_status AS i
LEFT JOIN return_status AS r
ON i.issued_id = r.issued_id
WHERE r.issued_id IS NULL;

# Advance Project Tasks
/* Identify Members with Overdue Books: 
Write a query to identify members who have overdue books (assume a 890-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue. */
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

/* Branch Performance Report: 
Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned, and the total revenue generated from book rentals. */
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

/* CTAS: Create a Table of Active Members: 
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
containing members who have issued at least one book in the last 28 months. */
CREATE TABLE active_members AS
		SELECT 
		DISTINCT m.*
		FROM members AS m
		INNER JOIN issued_status AS i
		ON m.member_id = i.issued_member_id
		WHERE i.issued_date >= CURRENT_DATE() - INTERVAL 28 MONTH;
        
/* Find Employees with the Most Book Issues Processed: 
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch. */
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

/* Identify Members Issuing High-Risk Books: 
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. 
Display the member name, book title, and the number of times they've issued damaged books. */
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
