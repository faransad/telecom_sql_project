
CREATE DATABASE IF NOT EXISTS Telecom_Provider;
USE Telecom_Provider;

-- -------------------------------
-- TABLE: Customer
-- Purpose: stores demographic and contact information.
-- -------------------------------
DROP TABLE IF EXISTS Customer;
CREATE TABLE Customer (
    customer_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE,
	email VARCHAR(100) CHECK (email REGEXP '^[^@]+@[^@]+\\.[^@]+$'),
    location_id INT NOT NULL,
    registration_date DATE NOT NULL,
    status ENUM('active', 'inactive') NOT NULL,
	FOREIGN KEY (location_id) REFERENCES Location(location_id)
)ENGINE=InnoDB;


-- -------------------------------
-- TABLE: Subscription
-- Purpose: connects customers with specific service plans.
-- -------------------------------
DROP TABLE IF EXISTS Subscription;
CREATE TABLE Subscription (
    subscription_id INT PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CHECK(start_date < end_date),
    status ENUM('active', 'inactive') NOT NULL,
	customer_id INT NOT NULL,
    plan_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON UPDATE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES ServicePlan(plan_id)
)ENGINE=InnoDB;


-- -------------------------------
-- TABLE: SubscriptionPromotion
-- Purpose: connect subscriptions with promotions flexibly and accurately/.
-- -------------------------------
DROP TABLE IF EXISTS SubscriptionPromotion;
CREATE TABLE SubscriptionPromotion (
    subscription_id INT NOT NULL,
    promotion_id INT NOT NULL,
    applied_date DATE NOT NULL,
    PRIMARY KEY (subscription_id, promotion_id),
    FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (promotion_id) REFERENCES Promotion(promotion_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- -------------------------------
-- TABLE: Promotion
-- Purpose: manage discount campaigns.
-- -------------------------------
DROP TABLE IF EXISTS Promotion;
CREATE TABLE Promotion (
    promotion_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('active', 'expired') NOT NULL,
    plan_id INT NOT NULL,
    FOREIGN KEY (plan_id) REFERENCES ServicePlan(plan_id)
)ENGINE=InnoDB;


-- -------------------------------
-- TABLE: ServicePlan
-- Purpose: defines the features and pricing of plans.
-- -------------------------------
DROP TABLE IF EXISTS ServicePlan;
CREATE TABLE ServicePlan (
    plan_id INT PRIMARY KEY,
    plan_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) CHECK (price > 0),
    data_limit_gb DECIMAL(10,2) NOT NULL,
    call_minutes INT NOT NULL,
    sms_count INT NOT NULL,
    validity_days INT NOT NULL,
    status ENUM('active', 'inactive') NOT NULL
)ENGINE=InnoDB;


-- -------------------------------
-- TABLE: UsageData
-- Purpose: stores call, SMS, and data usage per subscription per day.
-- -------------------------------
DROP TABLE IF EXISTS UsageData;
CREATE TABLE UsageData (
    usage_id INT PRIMARY KEY,
    usage_type ENUM('call', 'sms', 'data') NOT NULL,
	amount DECIMAL(10,2) NOT NULL, -- minutes for call, count for sms, MB for data   
    subscription_id INT NOT NULL,
    network_element_id INT NOT NULL,
    time_id INT NOT NULL,
    FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id) 
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
    FOREIGN KEY (network_element_id) REFERENCES NetworkElement(network_element_id),
	FOREIGN KEY (time_id) REFERENCES Time(time_id)
)ENGINE=InnoDB;


-- -------------------------------
-- TABLE: Billing
-- Purpose: represents monthly bills for subscriptions.
-- -------------------------------
DROP TABLE IF EXISTS Billing;
CREATE TABLE Billing (
    billing_id INT PRIMARY KEY,
    billing_period_start DATE NOT NULL,
    CHECK (billing_period_start < billing_period_end),
    billing_period_end DATE NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    discount_amount DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    final_amount DECIMAL(10,2) GENERATED ALWAYS AS (IFNULL(total_amount, 0) - IFNULL(discount_amount, 0)) STORED,
    status ENUM('paid', 'unpaid', 'pending') NOT NULL,
    subscription_id INT NOT NULL,
    FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id) ON DELETE RESTRICT
) ENGINE=InnoDB;


-- -------------------------------
-- TABLE: Transaction
-- Purpose: logs financial activity such as online payments or bank transfers.
-- -------------------------------
DROP TABLE IF EXISTS Transaction;
CREATE TABLE Transaction (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_type ENUM('deposit', 'withdraw', 'transfer') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status ENUM('success', 'failed', 'pending') NOT NULL,
    description TEXT NOT NULL,
	customer_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) 
	ON UPDATE CASCADE
	ON DELETE RESTRICT
)ENGINE=InnoDB;


-- -------------------------------
-- TABLE: Payment
-- Purpose: records customer payments toward bills.
-- -------------------------------
DROP TABLE IF EXISTS Payment;
CREATE TABLE Payment (
    payment_id INT PRIMARY KEY,
	payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL CHECK(amount_paid >= 0),
    payment_status ENUM('completed', 'failed', 'pending') NOT NULL,
    billing_id INT NOT NULL,
    FOREIGN KEY (billing_id) REFERENCES Billing(billing_id) ON DELETE RESTRICT
)ENGINE=InnoDB;


-- -------------------------------
-- TABLE: Location
-- Purpose: supports geographical references across entities.
-- -------------------------------
DROP TABLE IF EXISTS Location;
CREATE TABLE Location (
    location_id INT PRIMARY KEY,
    city VARCHAR(50) UNIQUE,
    country VARCHAR(50) UNIQUE
)ENGINE=InnoDB;


-- -------------------------------
-- TABLE: NetworkElement
-- Purpose: models infrastructure components such as cell towers.
-- -------------------------------
DROP TABLE IF EXISTS NetworkElement;
CREATE TABLE NetworkElement (
    network_element_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    element_type ENUM('tower', 'router', 'switch') NOT NULL,
    status ENUM('active', 'inactive') NOT NULL,
	location_id INT NOT NULL,
	employee_id INT NOT NULL,
    FOREIGN KEY (location_id) REFERENCES Location(location_id),
	FOREIGN KEY (employee_id) REFERENCES Employee(employee_id)
    )ENGINE=InnoDB;


-- -------------------------------
-- TABLE: Time
-- Purpose: provides a time dimension for reporting and analysis.
-- -------------------------------
DROP TABLE IF EXISTS Time;
CREATE TABLE Time (
    time_id INT PRIMARY KEY,
    full_timestamp TIMESTAMP NOT NULL,
    day_of_week VARCHAR(20) NOT NULL,
    part_of_day ENUM('morning', 'afternoon', 'evening', 'night') NOT NULL
)ENGINE=InnoDB;


-- -------------------------------
-- TABLE: Employee
-- Purpose: stores staff information
-- -------------------------------
DROP TABLE IF EXISTS Employee;
CREATE TABLE Employee (
    employee_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    role ENUM('support', 'network_admin') NOT NULL,
    status ENUM('active', 'inactive') NOT NULL
)ENGINE=InnoDB;


-- -------------------------------
-- TABLE: CustomerSupport
-- Purpose: log support tickets and staff interactions.
-- -------------------------------
DROP TABLE IF EXISTS CustomerSupport;
CREATE TABLE CustomerSupport (
    support_id INT PRIMARY KEY,
    support_type ENUM('technical', 'billing') NOT NULL,
    description TEXT NOT NULL,
    status ENUM('open', 'closed', 'in_progress') NOT NULL,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
	closed_at TIMESTAMP NULL DEFAULT NULL,
    priority ENUM('low', 'medium', 'high'),
    customer_id INT NOT NULL,
    employee_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON UPDATE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES Employee(employee_id)
)ENGINE=InnoDB;

SHOW TABLES;
-- -------------------------------
-- Populate Sample Data
-- -------------------------------

INSERT INTO Customer (customer_id, full_name, phone, email, location_id, registration_date, status) VALUES
(1, 'John Smith', '09121234501', 'john.smith@example.com', 1, '2024-01-15', 'active'),
(2,'Emily Johnson', '09121234502', 'emily.johnson@example.com', 2, '2023-12-20', 'active'),
(3,'Michael Brown', '09121234503', 'michael.brown@example.com', 3, '2024-02-01', 'inactive'),
(4,'Olivia Davis', '09121234504', 'olivia.davis@example.com', 4, '2024-03-12', 'active'),
(5,'Daniel Wilson', '09121234505', 'daniel.wilson@example.com', 5, '2024-01-30', 'active'),
(6,'Sophia Miller', '09121234506', 'sophia.miller@example.com', 1, '2023-11-18', 'inactive'),
(7,'James Taylor', '09121234507', 'james.taylor@example.com', 2, '2024-02-25', 'active'),
(8,'Ava Moore', '09121234508', 'ava.moore@example.com', 3, '2024-03-05', 'active'),
(9,'William Anderson', '09121234509', 'william.anderson@example.com', 4, '2024-01-05', 'inactive'),
(10,'Charlotte Thomas', '09121234510', 'charlotte.thomas@example.com', 5, '2024-04-01', 'active'),
(11,'Benjamin Jackson', '09121234511', 'ben.jackson@example.com', 1, '2024-04-10', 'active'),
(12,'Mia White', '09121234512', 'mia.white@example.com', 2, '2024-03-15', 'inactive'),
(13,'Henry Harris', '09121234513', 'henry.harris@example.com', 3, '2024-02-22', 'active'),
(14,'Grace Martin', '09121234514', 'grace.martin@example.com', 4, '2024-01-08', 'inactive'),
(15,'Logan Thompson', '09121234515', 'logan.thompson@example.com', 5, '2023-12-28', 'active'),
(16,'Ella Garcia', '09121234516', 'ella.garcia@example.com', 1, '2024-03-01', 'active'),
(17,'Alexander Martinez', '09121234517', 'alex.martinez@example.com', 2, '2024-02-19', 'inactive'),
(18,'Lily Robinson', '09121234518', 'lily.robinson@example.com', 3, '2024-01-22', 'active'),
(19,'Sebastian Clark', '09121234519', 'seb.clark@example.com', 4, '2024-02-12', 'active'),
(20,'Chloe Rodriguez', '09121234520', 'chloe.rodriguez@example.com', 5, '2024-03-17', 'inactive'),
(21,'David Lewis', '09121234521', 'david.lewis@example.com', 1, '2024-02-14', 'active'),
(22,'Sofia Lee', '09121234522', 'sofia.lee@example.com', 2, '2024-03-29', 'active'),
(23,'Matthew Walker', '09121234523', 'matthew.walker@example.com', 3, '2024-01-11', 'inactive'),
(24,'Amelia Hall', '09121234524', 'amelia.hall@example.com', 4, '2024-04-02', 'active'),
(25,'Lucas Allen', '09121234525', 'lucas.allen@example.com', 5, '2024-01-27', 'active'),
(26,'Harper Young', '09121234526', 'harper.young@example.com', 1, '2024-02-07', 'inactive'),
(27,'Nathan King', '09121234527', 'nathan.king@example.com', 2, '2024-03-06', 'active'),
(28,'Zoe Wright', '09121234528', 'zoe.wright@example.com', 3, '2024-01-18', 'active'),
(29,'Liam Scott', '09121234529', 'liam.scott@example.com', 4, '2024-03-10', 'inactive'),
(30,'Isabella Green', '09121234530', 'isabella.green@example.com', 5, '2024-04-05', 'active'),
(31,'Ethan Baker', '09121234531', 'ethan.baker@example.com', 1, '2024-01-02', 'active');


INSERT INTO Subscription (subscription_id, start_date, end_date, status, customer_id, plan_id) VALUES
(1, '2024-01-01', '2024-12-31', 'active', 1, 1),
(2, '2024-02-01', '2024-11-30', 'inactive', 2, 2),
(3, '2024-03-15', '2025-03-14', 'active', 3, 3),
(4, '2024-04-01', '2025-03-31', 'inactive', 4, 4),
(5, '2024-05-10', '2025-05-09', 'active', 5, 5),
(6, '2024-06-01', '2025-05-31', 'active', 6, 1),
(7, '2024-07-20', '2025-07-19', 'active', 7, 2),
(8, '2024-08-05', '2025-08-04', 'inactive', 8, 3),
(9, '2024-09-01', '2025-08-31', 'active', 9, 4),
(10, '2024-10-15', '2025-10-14', 'active', 10, 5),
(11, '2024-11-01', '2025-10-31', 'inactive', 11, 1),
(12, '2024-12-01', '2025-11-30', 'active', 12, 2),
(13, '2024-01-10', '2025-01-09', 'inactive', 13, 3),
(14, '2024-02-20', '2025-02-19', 'active', 14, 4),
(15, '2024-03-25', '2025-03-24', 'active', 15, 5),
(16, '2024-04-15', '2025-04-14', 'inactive', 16, 1),
(17, '2024-05-05', '2025-05-04', 'active', 17, 2),
(18, '2024-06-20', '2025-06-19', 'active', 18, 3),
(19, '2024-07-01', '2025-06-30', 'inactive', 19, 4),
(20, '2024-08-10', '2025-08-09', 'active', 20, 5),
(21, '2024-09-15', '2025-09-14', 'active', 21, 1),
(22, '2024-10-01', '2025-09-30', 'inactive', 22, 2),
(23, '2024-11-05', '2025-11-04', 'active', 23, 3),
(24, '2024-12-15', '2025-12-14', 'active', 24, 4),
(25, '2024-01-30', '2025-01-29', 'inactive', 25, 5),
(26, '2024-02-10', '2025-02-09', 'active', 26, 1),
(27, '2024-03-10', '2025-03-09', 'active', 27, 2),
(28, '2024-04-20', '2025-04-19', 'inactive', 28, 3),
(29, '2024-05-15', '2025-05-14', 'active', 29, 4),
(30, '2024-06-05', '2025-06-04', 'active', 30, 5),
(31, '2024-07-10', '2025-07-09', 'active', 31, 1);


INSERT INTO SubscriptionPromotion (subscription_id, promotion_id, applied_date) VALUES
(1, 2, '2025-03-01'),
(2, 5, '2025-03-01'),
(3, 1, '2025-03-02'),
(4, 3, '2025-03-03'),
(5, 6, '2025-03-04'),
(6, 2, '2025-03-05'),
(7, 7, '2025-03-06'),
(8, 4, '2025-03-06'),
(9, 9, '2025-03-07'),
(10, 7, '2025-03-08'),
(11, 1, '2025-03-09'),
(12, 3, '2025-03-10'),
(13, 2, '2025-03-11'),
(14, 8, '2025-03-12'),
(15, 5, '2025-03-13'),
(16, 6, '2025-03-14'),
(17, 9, '2025-03-15'),
(18, 1, '2025-03-16'),
(19, 2, '2025-03-17'),
(20, 3, '2025-03-18'),
(21, 7, '2025-03-18'),
(22, 4, '2025-03-19'),
(23, 5, '2025-03-20'),
(24, 6, '2025-03-21'),
(25, 2, '2025-03-22'),
(26, 8, '2025-03-23'),
(27, 1, '2025-03-24'),
(28, 3, '2025-03-25'),
(29, 5, '2025-03-26'),
(30, 6, '2025-03-27'),
(31, 7, '2025-03-28'),
(1, 10, '2025-03-28'),
(2, 9, '2025-03-29'),
(3, 2, '2025-03-30'),
(4, 4, '2025-03-30'),
(5, 1, '2025-03-31'),
(6, 3, '2025-03-31'),
(7, 8, '2025-03-05'),
(8, 9, '2025-03-14'),
(9, 10, '2025-03-20');


INSERT INTO Promotion (promotion_id, name, description, discount_value, start_date, end_date, status, plan_id) VALUES
(1, 'Welcome Bonus', '10% off on first month', 10.00, '2025-01-01', '2025-12-31', 'active', 1),
(2, 'Data Booster', '5 GB extra data free', 5.00, '2025-02-01', '2025-08-31', 'active', 2),
(3, 'Talk Time Saver', '20% off on call minutes', 8.00, '2025-01-15', '2025-06-30', 'expired', 3),
(4, 'SMS Frenzy', 'Unlimited SMS add-on', 6.00, '2025-03-01', '2025-07-01', 'active', 4),
(5, 'Combo Deal', 'All-in-one package discount', 15.00, '2025-01-20', '2025-12-31', 'active', 5),
(6, 'Loyalty Reward', 'Special rate for long-term users', 12.00, '2025-02-15', '2025-12-15', 'active', 1),
(7, 'Night Owl', 'Night usage discount', 7.00, '2025-03-01', '2025-09-30', 'active', 2),
(8, 'Weekend Treat', 'Weekend usage bonus', 9.00, '2025-04-01', '2025-10-01', 'active', 3),
(9, 'Student Saver', 'Student-exclusive discount', 10.00, '2025-01-10', '2025-12-31', 'active', 4),
(10, 'Festive Offer', 'Seasonal promotional package', 13.00, '2025-03-15', '2025-05-30', 'expired', 5);


INSERT INTO ServicePlan (plan_id, plan_name, price, data_limit_gb, call_minutes, sms_count, validity_days, status) VALUES
(1, 'Basic Plan', 9.99, 5.00, 100, 100, 30, 'active'),
(2, 'Standard Plan', 19.99, 10.00, 300, 300, 30, 'active'),
(3, 'Premium Plan', 29.99, 25.00, 1000, 500, 30, 'active'),
(4, 'Unlimited Talk Plan', 24.99, 3.00, 9999, 500, 30, 'active'),
(5, 'Data Max Plan', 34.99, 50.00, 500, 100, 30, 'active');


INSERT INTO UsageData (usage_id, usage_type, amount, subscription_id, network_element_id, time_id) VALUES
(1, 'call', 12.50, 1, 1, 1),
(2, 'sms', 5, 2, 2, 2),
(3, 'data', 350.75, 3, 3, 3),
(4, 'call', 7.30, 4, 1, 4),
(5, 'sms', 3, 5, 2, 5),
(6, 'data', 100.00, 6, 3, 6),
(7 ,'call', 20.00, 7, 1, 7),
(8, 'data', 250.25, 8, 2, 8),
(9, 'sms', 10, 9, 3, 9),
(10, 'call', 5.00, 10, 2, 10),
(11, 'data', 500.00, 1, 1, 3),
(12, 'sms', 2, 2, 3, 1),
(13, 'call', 15.00, 3, 2, 2),
(14, 'data', 75.25, 4, 3, 4),
(15, 'sms', 6, 5, 2, 5),
(16, 'call', 9.50, 6, 1, 6),
(17, 'data', 120.75, 7, 3, 7),
(18, 'sms', 8, 8, 2, 8),
(19, 'call', 18.25, 9, 1, 9),
(20, 'data', 300.00, 10, 3, 10);


INSERT INTO Time (time_id, full_timestamp, day_of_week, part_of_day) VALUES
(1, '2025-05-01 08:30:00', 'Thursday', 'morning'),
(2, '2025-05-01 14:15:00', 'Thursday', 'afternoon'),
(3, '2025-05-02 19:45:00', 'Friday', 'evening'),
(4, '2025-05-03 23:00:00', 'Saturday', 'night'),
(5, '2025-05-04 09:20:00', 'Sunday', 'morning'),
(6, '2025-05-05 15:10:00', 'Monday', 'afternoon'),
(7, '2025-05-06 18:00:00', 'Tuesday', 'evening'),
(8, '2025-05-07 21:50:00', 'Wednesday', 'night'),
(9, '2025-05-08 07:40:00', 'Thursday', 'morning'),
(10, '2025-05-09 16:30:00', 'Friday', 'afternoon');


INSERT INTO NetworkElement (network_element_id, name, element_type, status, location_id, employee_id) VALUES
(1, 'Tower Alpha', 'tower', 'active', 1, 1),
(2, 'Router Beta', 'router', 'active', 2, 2),
(3, 'Switch Gamma', 'switch', 'active', 3, 3),
(4, 'Tower Delta', 'tower', 'inactive', 4, 2),
(5, 'Router Epsilon', 'router', 'active', 5, 3),
(6, 'Switch Zeta', 'switch', 'inactive', 1, 1),
(7, 'Tower Eta', 'tower', 'active', 2, 3),
(8, 'Router Theta', 'router', 'active', 3, 1),
(9, 'Switch Iota', 'switch', 'active', 4, 2),
(10, 'Tower Kappa', 'tower', 'active', 5, 2);


INSERT INTO Location (location_id, city, country) VALUES
(1, 'Berlin', 'Germany'),
(2, 'Barcelona', 'Spain'),
(3, 'Sydney', 'Australia'),
(4, 'Helsinki', 'Finland'),
(5, 'Tokyo', 'Japan');


INSERT INTO Employee (employee_id, full_name, email, role, status) VALUES
(1, 'Alice Jensen', 'alice.jensen@teleco.com', 'network_admin', 'active'),
(2, 'Markus Lindgren', 'markus.lindgren@teleco.com', 'support', 'active'),
(3, 'Chloe Dubois', 'chloe.dubois@teleco.com', 'network_admin', 'active');


INSERT INTO CustomerSupport (support_id, support_type, description, status, created_at, closed_at, priority,
 customer_id, employee_id) VALUES
(1, 'technical', 'Internet connection drops intermittently.', 'closed', '2024-11-01 10:15:00', '2024-11-02 14:30:00', 'high', 1, 1),
(2, 'billing', 'Discrepancy in the latest invoice.', 'open', '2025-05-30 08:45:00', NULL, 'medium', 2, 2),
(3, 'technical', 'Router is not turning on after reboot.', 'in_progress', '2025-06-01 09:00:00', NULL, 'high', 3, 3),
(4, 'billing', 'Need clarification on VAT charges.', 'closed', '2025-05-15 12:00:00', '2025-05-16 16:00:00', 'low', 4, 2),
(5, 'technical', 'Slow internet speed during evenings.', 'in_progress', '2025-06-01 19:00:00', NULL, 'medium', 5, 1);


INSERT INTO Billing (billing_id, billing_period_start, billing_period_end, issue_date, due_date, discount_amount, total_amount,
 status, subscription_id) VALUES
(1, '2025-04-01', '2025-04-30', '2025-05-01', '2025-05-10', 5.00, 50.00, 'paid', 1),
(2, '2025-04-01', '2025-04-30', '2025-05-01', '2025-05-10', 0.00, 60.00, 'unpaid', 2),
(3, '2025-03-01', '2025-03-31', '2025-04-01', '2025-04-10', 10.00, 55.00, 'paid', 3),
(4, '2025-04-15', '2025-05-14', '2025-05-15', '2025-05-25', 2.50, 45.00, 'pending', 4),
(5, '2025-05-01', '2025-05-31', '2025-06-01', '2025-06-10', 0.00, 70.00, 'paid', 5),
(6, '2025-04-01', '2025-04-30', '2025-05-01', '2025-05-10', 3.00, 40.00, 'paid', 6),
(7, '2025-03-01', '2025-03-31', '2025-04-01', '2025-04-10', 0.00, 65.00, 'unpaid', 7),
(8, '2025-05-01', '2025-05-31', '2025-06-01', '2025-06-10', 7.00, 80.00, 'pending', 8),
(9, '2025-05-01', '2025-05-31', '2025-06-01', '2025-06-10', 0.00, 75.00, 'paid', 9),
(10, '2025-03-15', '2025-04-14', '2025-04-15', '2025-04-25', 5.00, 50.00, 'unpaid', 10);


INSERT INTO Transaction (transaction_type, amount, status, description, customer_id) VALUES
('deposit', 100.00, 'success', 'Top-up via credit card', 1),
('withdraw', 50.00, 'success', 'Bill payment deduction', 2),
('transfer', 30.00, 'success', 'Transferred to family account', 3),
('deposit', 75.00, 'pending', 'Pending bank processing', 4),
('withdraw', 60.00, 'failed', 'Insufficient balance', 5),
('deposit', 120.00, 'success', 'Direct debit recharge', 6),
('transfer', 40.00, 'success', 'Transferred to another number', 7),
('withdraw', 55.00, 'success', 'Monthly bill auto-payment', 8),
('deposit', 90.00, 'success', 'Top-up via app', 9),
('withdraw', 65.00, 'pending', 'Scheduled deduction', 10);


INSERT INTO Payment (payment_id, amount_paid, payment_status, billing_id) VALUES
(1, 55.00, 'completed', 1),
(2, 60.00, 'completed', 2),
(3, 45.00, 'failed', 3),
(4, 70.00, 'completed', 4),
(5, 50.00, 'pending', 5),
(6, 65.00, 'completed', 6),
(7, 80.00, 'completed', 7),
(8, 40.00, 'failed', 8),
(9, 90.00, 'completed', 9),
(10, 75.00, 'pending', 10);


-- 1. Count number of customers registered in each city
SELECT 
	l.city, 
    COUNT(c.customer_id) AS num_customers
FROM Location l
JOIN Customer c ON l.location_id = c.location_id
GROUP BY l.city
ORDER BY num_customers DESC;


-- 2. Count active towers/routers/switches per city
SELECT 
    l.city,
    ne.element_type,
    COUNT(ne.network_element_id) AS active_elements
FROM NetworkElement ne
JOIN Location l ON ne.location_id = l.location_id
WHERE ne.status = 'active'
GROUP BY l.city, ne.element_type
ORDER BY l.city;

    
-- 3. Support tickets handled by each employee
SELECT 
    e.full_name AS employee_name,
    e.role,
    cs.status,
    COUNT(cs.support_id) AS ticket_count
FROM CustomerSupport cs
JOIN Employee e ON cs.employee_id = e.employee_id
GROUP BY e.full_name, e.role, cs.status
ORDER BY e.full_name, cs.status;
    
    
-- 4. Average resolution time for closed tickets
SELECT 
    AVG(TIMESTAMPDIFF(HOUR, cs.created_at, cs.closed_at)) AS avg_resolution_hours
FROM CustomerSupport cs
WHERE cs.status = 'closed' AND cs.closed_at IS NOT NULL;
  
  
-- 5. Identify customers with Above-Average final bill
SELECT 
    c.customer_id,
    c.full_name,
    AVG(b.final_amount) AS avg_bill
FROM Customer c
JOIN Subscription s ON c.customer_id = s.customer_id
JOIN Billing b ON s.subscription_id = b.subscription_id
GROUP BY c.customer_id, c.full_name
HAVING 
    AVG(b.final_amount) > (
        SELECT AVG(final_amount)
        FROM Billing
    )
ORDER BY avg_bill DESC;


-- 6. Days taken to pay each completed bill
SELECT 
  b.billing_id,
  DATEDIFF(p.payment_date, b.issue_date) AS days_to_pay
FROM Billing b
JOIN Payment p ON b.billing_id = p.billing_id
WHERE p.payment_status = 'completed';


-- 7. Top revenue generating service plans
SELECT sp.plan_name, SUM(b.final_amount) AS total_revenue
FROM Billing b
JOIN Subscription s ON b.subscription_id = s.subscription_id
JOIN ServicePlan sp ON s.plan_id = sp.plan_id
GROUP BY sp.plan_name
ORDER BY total_revenue DESC
LIMIT 5;


-- 8. Latest bill details for each customer
SELECT 
    c.customer_id,
    c.full_name,
    b.billing_id,
    b.billing_period_end,
    b.final_amount
FROM Customer c
JOIN Subscription s ON c.customer_id = s.customer_id
JOIN Billing b ON s.subscription_id = b.subscription_id
WHERE 
    b.billing_period_end = (
        SELECT MAX(b2.billing_period_end)
        FROM Billing b2
        WHERE b2.subscription_id = s.subscription_id
    );


-- 9. Show each customer’s name, their active service plan, total data used and total call
-- duration this month (based on UsageData and Subscription)
SELECT 
    c.full_name,
    sp.plan_name,
    SUM(CASE WHEN ud.usage_type = 'call' THEN ud.amount ELSE 0 END) AS total_call_minutes,
    ROUND(SUM(CASE WHEN ud.usage_type = 'data' THEN ud.amount ELSE 0 END) / 1024, 2) AS total_data_gb,
    SUM(CASE WHEN ud.usage_type = 'sms' THEN ud.amount ELSE 0 END) AS total_sms_sent
FROM Customer c
JOIN Subscription s ON c.customer_id = s.customer_id
JOIN ServicePlan sp ON s.plan_id = sp.plan_id
JOIN UsageData ud ON s.subscription_id = ud.subscription_id
JOIN Time t ON ud.time_id = t.time_id
WHERE s.status = 'active' AND t.full_timestamp BETWEEN '2025-05-01' AND '2025-05-31 23:59:59'
GROUP BY c.customer_id, c.full_name, sp.plan_name
ORDER BY total_data_gb DESC;
    
    
-- 10. Find the top 5 customers based on total usage (sum of data in GB + call minutes + SMS count) in May 2025, using CTEs.
    WITH MayUsageData AS (
    SELECT 
        ud.subscription_id,
        ud.usage_type,
        SUM(ud.amount) AS total_amount
    FROM UsageData ud
    JOIN Time t ON ud.time_id = t.time_id
    WHERE t.full_timestamp BETWEEN '2025-05-01' AND '2025-05-31 23:59:59'
    GROUP BY ud.subscription_id, ud.usage_type
),
AggregatedUsage AS (
    SELECT 
        s.customer_id,
        SUM(CASE WHEN m.usage_type = 'call' THEN m.total_amount ELSE 0 END) AS total_call_minutes,
        ROUND(SUM(CASE WHEN m.usage_type = 'data' THEN m.total_amount ELSE 0 END) / 1024, 2) AS total_data_gb,
        SUM(CASE WHEN m.usage_type = 'sms' THEN m.total_amount ELSE 0 END) AS total_sms,
        (
            SUM(CASE WHEN m.usage_type = 'call' THEN m.total_amount ELSE 0 END) +
            SUM(CASE WHEN m.usage_type = 'sms' THEN m.total_amount ELSE 0 END) +
            ROUND(SUM(CASE WHEN m.usage_type = 'data' THEN m.total_amount ELSE 0 END) / 1024, 2)
        ) AS usage_score
    FROM MayUsageData m
    JOIN Subscription s ON m.subscription_id = s.subscription_id
    GROUP BY s.customer_id
)
SELECT 
    c.full_name,
    a.total_call_minutes,
    a.total_data_gb,
    a.total_sms,
    a.usage_score
FROM AggregatedUsage a
JOIN Customer c ON a.customer_id = c.customer_id
ORDER BY a.usage_score DESC
LIMIT 5;


-- 11. Stored Procedure to get detailed billing summary for a given customer

DELIMITER $$
CREATE PROCEDURE GetCustomerBillingSummary(IN input_customer_id INT)
BEGIN
    SELECT 
        c.full_name,
        s.subscription_id,
        b.billing_id,
        b.billing_period_start,
        b.billing_period_end,
        b.total_amount,
        b.discount_amount,
        b.final_amount,
        b.status AS billing_status,
        p.payment_status,
        p.payment_date,
        p.amount_paid,
        CASE
            WHEN b.status = 'paid' AND p.payment_status = 'completed' THEN '✓ Fully Paid'
            WHEN b.status = 'pending' AND p.payment_status = 'pending' THEN '⧗ Pending Payment'
            ELSE '⚠ Check Status'
        END AS billing_note
    FROM Customer c
    JOIN Subscription s ON c.customer_id = s.customer_id
    JOIN Billing b ON s.subscription_id = b.subscription_id
    LEFT JOIN Payment p ON b.billing_id = p.billing_id
    WHERE c.customer_id = input_customer_id
    ORDER BY b.billing_period_start DESC;
END$$

DELIMITER ;
CALL GetCustomerBillingSummary(5);  -- Example customer_id


-- 12. Promotion effectiveness
WITH PromoUsage AS (
    SELECT 
        sp.promotion_id,
        p.name AS promotion_name,
        COUNT(DISTINCT sp.subscription_id) AS times_applied,
        SUM(CASE WHEN u.usage_type = 'data' THEN u.amount ELSE 0 END) AS total_data_mb,
        SUM(CASE WHEN u.usage_type = 'call' THEN u.amount ELSE 0 END) AS total_call_minutes,
        SUM(CASE WHEN u.usage_type = 'sms' THEN u.amount ELSE 0 END) AS total_sms
    FROM SubscriptionPromotion sp
    JOIN Promotion p ON sp.promotion_id = p.promotion_id
    JOIN UsageData u ON sp.subscription_id = u.subscription_id
    JOIN Time t ON u.time_id = t.time_id
    WHERE t.full_timestamp >= sp.applied_date
    GROUP BY sp.promotion_id, p.name
),
PromoBilling AS (
    SELECT 
        sp.promotion_id,
        SUM(b.final_amount) AS total_billed_after_promo
    FROM SubscriptionPromotion sp
    JOIN Billing b ON sp.subscription_id = b.subscription_id
    WHERE b.billing_period_start >= sp.applied_date
    GROUP BY sp.promotion_id
)
SELECT 
    pu.promotion_id,
    pu.promotion_name,
    pu.times_applied,
    pu.total_data_mb,
    pu.total_call_minutes,
    pu.total_sms,
    pb.total_billed_after_promo,
    RANK() OVER (ORDER BY pb.total_billed_after_promo DESC) AS billing_rank
FROM PromoUsage pu
LEFT JOIN PromoBilling pb ON pu.promotion_id = pb.promotion_id
ORDER BY billing_rank;


-- 13. Total transaction amount by type
SELECT 
    transaction_type,
    SUM(amount) AS total_amount,
    COUNT(*) AS num_transactions
FROM Transaction
GROUP BY transaction_type
ORDER BY total_amount DESC;


-- 14. Monthly transaction volume in the last 3 months
SELECT 
    DATE_FORMAT(transaction_date, '%Y-%m') AS month,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_amount
FROM Transaction
WHERE transaction_date >= CURDATE() - INTERVAL 3 MONTH
GROUP BY month
ORDER BY month DESC;


-- 15. Top 5 customers by transaction volume
SELECT 
    c.full_name,
    SUM(t.amount) AS total_spent,
    COUNT(t.transaction_id) AS txn_count
FROM Transaction t
JOIN Customer c ON t.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_spent DESC
LIMIT 5;


-- 16. Customers with failed transactions who also contacted support    
SELECT 
    c.full_name,
    COUNT(DISTINCT t.transaction_id) AS failed_txns,
    COUNT(DISTINCT cs.support_id) AS support_tickets
FROM Customer c
JOIN Transaction t ON c.customer_id = t.customer_id
JOIN CustomerSupport cs ON c.customer_id = cs.customer_id
WHERE t.status = 'failed'
GROUP BY c.customer_id
HAVING support_tickets > 0
ORDER BY failed_txns DESC;


-- 17. Customer Transactions
-- Step 1: Start the transaction
START TRANSACTION;

-- Step 2: First valid transaction
INSERT INTO Transaction (
    transaction_type,
    amount,
    status,
    description,
    customer_id
) VALUES (
    'deposit',
    100.00,
    'success',
    'Initial top-up',
    1
);

-- Create a savepoint after the first insert
SAVEPOINT after_first;

-- Step 3: Problematic transaction (negative amount - suppose this is invalid)
INSERT INTO Transaction (
    transaction_type,
    amount,
    status,
    description,
    customer_id
) VALUES (
    'withdraw',
    -50.00,
    'failed',
    'System error: invalid amount',
    1
);

-- Realize the problem → Rollback to the savepoint
ROLLBACK TO SAVEPOINT after_first;

-- Step 4: Continue with another valid transaction
INSERT INTO Transaction (
    transaction_type,
    amount,
    status,
    description,
    customer_id
) VALUES (
    'withdraw',
    30.00,
    'success',
    'Customer withdrawal after rollback',
    1
);

-- Step 5: Everything OK → Commit
COMMIT;

-- Step 6: To confirm what remained in the table:
SELECT * FROM Transaction
WHERE customer_id = 1
ORDER BY transaction_date DESC;


-- 18. ETL Analysis: ServicePlan performance summary
-- Step 1:  Create reporting table (Load Target)
CREATE TABLE ServicePlanUsageSummary (
    plan_id INT NOT NULL,
    total_call_minutes DECIMAL(10,2),
    total_data_mb DECIMAL(10,2),
    total_sms_count INT,
    report_generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (plan_id, report_generated_at),
    FOREIGN KEY (plan_id) REFERENCES ServicePlan(plan_id)
);

-- Step 2: ETL query (Extract + Transform + Load)
INSERT INTO ServicePlanUsageSummary (plan_id, total_call_minutes, total_data_mb, total_sms_count)
SELECT 
    sp.plan_id,
    SUM(CASE WHEN u.usage_type = 'call' THEN u.amount ELSE 0 END) AS total_call_minutes,
    SUM(CASE WHEN u.usage_type = 'data' THEN u.amount ELSE 0 END) AS total_data_mb,
    SUM(CASE WHEN u.usage_type = 'sms' THEN u.amount ELSE 0 END) AS total_sms_count
FROM ServicePlan sp
JOIN Subscription s ON s.plan_id = sp.plan_id
JOIN UsageData u ON u.subscription_id = s.subscription_id
GROUP BY sp.plan_id;

-- Step 3: View the latest summary for all plans
SELECT *
FROM ServicePlanUsageSummary
ORDER BY report_generated_at DESC;




