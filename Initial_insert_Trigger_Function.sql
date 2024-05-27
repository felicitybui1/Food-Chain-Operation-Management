INSERT INTO Delivery_Company (company_id, company_name, company_address, company_contact)
VALUES 
(1, 'Delivery Corp', '123 Delivery Lane, City, State, 12345', 'contact@deliverycorp.com'),
(2, 'Quick Ship', '456 Speed St, City, State, 67890', 'info@quickship.com'),
(3, 'Package Pros', '789 Parcel Place, City, State, 11223', 'support@packagepros.com');


-- Insert into stores
INSERT INTO Stores (store_id, store_name, address) 
VALUES (1, 'Store 1', '123 ABC Street'), 
       (2, 'Store 2', '456 DEF Street');

-- Insert into products
INSERT INTO Products (product_id, product_name, product_category, production_date, expiration_date, unit_price, unit_cost) 
VALUES (1, 'Product 1', 'Category 1', '2023-07-01', '2023-12-01', 100, 50), 
       (2, 'Product 2', 'Category 2', '2023-07-01', '2023-12-01', 150, 75);
-- Insert into deliveries
INSERT INTO Deliveries (order_id, store_id, company_id, delivery_date) 
VALUES (8, 1, 1, '2023-07-15');

-- Insert into products_in_deliveries
INSERT INTO Products_in_Deliveries (order_id, product_id, quantity, unit_cost)
VALUES (8, 1, 20, 50);

-- Check Store_Inventory after insertion
SELECT * FROM Store_Inventory;






INSERT INTO Departments (department_id, dept_name, dept_budget)
VALUES 
(1, 'Human Resources', 2000),
(2, 'Marketing', 4000),
(3, 'Sales', 6000),
(4, 'Operations', 8000),
(5, 'IT', 3000);


-- Insert into customers
INSERT INTO Customers (customer_id, first_name, last_name, customer_phone, customer_email, customer_address) 
VALUES (1, 'John', 'Doe', 123456, 'john.doe@example.com', '123 ABC Street'), 
       (2, 'Jane', 'Doe', 987654, 'jane.doe@example.com', '456 DEF Street');

-- Insert into staff
INSERT INTO Staff (employee_id, store_id, first_name, last_name, employee_email, employee_phone, department_id, role_id, salary, hire_date, performance_rating) 
VALUES (1, 1, 'Employee', 'One', 'employee.one@example.com', 123456789, 1, 1, 50000, '2023-01-01', 5), 
       (2, 2, 'Employee', 'Two', 'employee.two@example.com', 987654321, 2, 2, 75000, '2023-01-01', 5);


-- Insert into sales
INSERT INTO Sales (sale_id, store_id, total_amount, sale_date, customer_id, employee_id)
VALUES (1, 1, 500, '2023-07-15', 1, 1),
       (2, 2, 750, '2023-07-15', 2, 2);
	   
INSERT INTO Sales (sale_id, store_id, total_amount, sale_date, customer_id, employee_id)
VALUES (24, 1, 500, '2023-07-15', 1, 1);

-- Insert into products_sold
INSERT INTO Products_Sold (sale_id, product_id, quantity_sold, unit_price)
VALUES (24, 1, 1, 100);

-- Check Store_Inventory after insertion
SELECT * FROM Store_Inventory;


-- Inserting minimum inventory level for Product 1 in Store 1
INSERT INTO Min_Inventory_Level (store_id, product_id, min_inventory_level) VALUES (1, 1, 10);




CREATE OR REPLACE FUNCTION reorder_trigger() RETURNS TRIGGER AS $$
DECLARE
    _min_inventory_level INT;
BEGIN
    SELECT min_inventory_level 
    FROM Min_Inventory_Level
    WHERE store_id = OLD.store_id AND product_id = OLD.product_id INTO _min_inventory_level;

    IF OLD.inventory_level >= _min_inventory_level AND NEW.inventory_level < _min_inventory_level THEN
        RAISE NOTICE 'Inventory level for product_id % in store_id % is below the minimum. Please reorder.', NEW.product_id, NEW.store_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER check_reorder
AFTER UPDATE ON Store_Inventory
FOR EACH ROW
EXECUTE FUNCTION reorder_trigger();
