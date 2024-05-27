--- Foodmart Data Schema

   -------------------------------------------------------------------------

------ Entity Sets ------

-- Store Table (Entity)

CREATE TABLE Stores (
	store_id		int,
	store_name		varchar(100) NOT NULL,
	address			varchar(500) NOT NULL UNIQUE,
	PRIMARY KEY (store_id)
);


-- Product Table (Entity)

CREATE TABLE Products (
	product_id		int,
	product_name	varchar(200) NOT NULL,
	product_category	varchar(100) NOT NULL,
	production_date		date NOT NULL,
	expiration_date		date,
	unit_price		int NOT NULL,
	PRIMARY KEY (product_id)
);


-- Vendor Table (Entity)

CREATE TABLE Vendors (
	vendor_id		int,
	vendor_name		varchar(300) NOT NULL,
	vendor_phone	int,
	vendor_email	varchar(100),
	vendor_adress		varchar(500) NOT NULL UNIQUE,
	PRIMARY KEY (vendor_id)
);



-- Customer Table (Entity)

CREATE TABLE Customers (
	customer_id		int,
	first_name		varchar(50) NOT NULL,
	last_name		varchar(50) NOT NULL,
	customer_phone		int,
	customer_email		varchar(100),
	customer_address		varchar(500),
	PRIMARY KEY (customer_id)
);


CREATE TABLE Customer_Loyalty (
	card_id		int,
	customer_id		int NOT NULL,
	points		int NOT NULL,
	PRIMARY KEY (card_id),
	FOREIGN KEY (customer_id) REFERENCES Customers (customer_id)
);


-- Staff Related:

CREATE TABLE Departments (
	department_id	int,
	dept_name		varchar(100) NOT NULL,
	dept_budget		int NOT NULL,
	PRIMARY KEY (department_id)
);


CREATE TABLE Staff (
	employee_id		int,
	store_id 		int NOT NULL,
	first_name		varchar(50) NOT NULL,
	last_name		varchar(50) NOT NULL,
	employee_email		varchar(100) NOT NULL UNIQUE,
	employee_phone		int,
	department_id		int NOT NULL,
	role_name			varchar(50) NOT NULL,
	salary			int NOT NULL,
	hire_date		date NOT NULL,
	performance_rating		int,
	PRIMARY KEY (employee_id),
	FOREIGN KEY (store_id) REFERENCES Stores (store_id),
	FOREIGN KEY (department_id) REFERENCES Departments (department_id)
);


-- Sales Table (Entity)

CREATE TABLE Sales (
	sale_id		int,
	store_id		int NOT NULL,
	total_amount		int NOT NULL,
	sale_date		date NOT NULL,
	customer_id		int NOT NULL,
	employee_id		int NOT NULL,
	PRIMARY KEY (sale_id),
	FOREIGN KEY (customer_id) REFERENCES Customers (customer_id),
	FOREIGN KEY (employee_id) REFERENCES Staff (employee_id),
	FOREIGN KEY (store_id) REFERENCES Stores (store_id)
);


CREATE TABLE Managing (
	manager_id		int,
	managing_id		int NOT NULL,
	PRIMARY KEY (manager_id),
	FOREIGN KEY (manager_id) REFERENCES Staff (employee_id),
	FOREIGN KEY (managing_id) REFERENCES Staff (employee_id)
);




-- Delivery Company Table

CREATE TABLE Delivery_Company (
	company_id		int NOT NULL,
	company_name	varchar(300) NOT NULL,
	company_address		varchar(500) NOT NULL,
	company_contact		varchar(100),
	PRIMARY KEY (company_id)
);


-- Deliveries Table (Entity)

CREATE TABLE Deliveries (
	order_id		int,
	company_id		int NOT NULL,
	store_id		int NOT NULL,
	delivery_date		date NOT NULL,
	PRIMARY KEY (order_id),
	FOREIGN KEY (company_id) REFERENCES Delivery_Company (company_id)
);



-- Vendor Orders Table (Entity)

CREATE TABLE Orders (
	order_id		int NOT NULL,
	vendor_id 	int NOT NULL,
	PRIMARY KEY (order_id),
	FOREIGN KEY (order_id) REFERENCES Deliveries (order_id),
	FOREIGN KEY (vendor_id) REFERENCES Vendors (vendor_id)
);



--------------------------------------------------------------------------

------ Relationship Sets ------

-- Inventory (between Stores, Products, Deliveries)

CREATE TABLE Store_Inventory (
	store_id 		int NOT NULL,
	product_id 		int NOT NULL,
	inventory_level			int NOT NULL,
	PRIMARY KEY (store_id, product_id),
	FOREIGN KEY (store_id) REFERENCES Stores (store_id),
	FOREIGN KEY (product_id) REFERENCES Products (product_id)
);


-- Products Bought (between Products and Sales)

CREATE TABLE Products_Sold (
	sale_id		int NOT NULL,
	product_id 		int NOT NULL,
	quantity_sold		int NOT NULL,
	PRIMARY KEY (sale_id, product_id),
	FOREIGN KEY (sale_id) REFERENCES Sales (sale_id),
	FOREIGN KEY (product_id) REFERENCES Products (product_id)
);


CREATE TABLE Products_in_Deliveries (
	order_id		int NOT NULL,
	product_id 		int NOT NULL,
	quantity 	int NOT NULL,
	unit_cost	int NOT NULL,
	PRIMARY KEY (order_id, product_id),
	FOREIGN KEY (order_id) REFERENCES Deliveries (order_id),
	FOREIGN KEY (product_id)	REFERENCES Products (product_id)
);


CREATE TABLE Min_Inventory_Level (
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    min_inventory_level INT NOT NULL,
    PRIMARY KEY (store_id, product_id),
    FOREIGN KEY (store_id) REFERENCES Stores (store_id),
    FOREIGN KEY (product_id) REFERENCES Products (product_id)
);



------ Triggers ------

-- Shared Update Inventory Function --

CREATE OR REPLACE FUNCTION update_inventory_level(_store_id INT, _product_id INT, _quantity INT) RETURNS VOID AS $$
BEGIN
    -- Attempt to update the row
    UPDATE Store_Inventory
    SET inventory_level = inventory_level + _quantity
    WHERE store_id = _store_id AND product_id = _product_id;

    -- If no row was updated, insert a new row
    IF NOT FOUND THEN
        INSERT INTO Store_Inventory (store_id, product_id, inventory_level)
        VALUES (_store_id, _product_id, _quantity);
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Increment Inventory Function --

CREATE OR REPLACE FUNCTION increment_inventory() RETURNS TRIGGER AS $$
DECLARE
    _store_id INT;
BEGIN
    SELECT store_id FROM Deliveries
    WHERE order_id = NEW.order_id INTO _store_id;

    PERFORM update_inventory_level(_store_id, NEW.product_id, NEW.quantity);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Decrement Inventory Function --

CREATE OR REPLACE FUNCTION decrement_inventory() RETURNS TRIGGER AS $$
DECLARE
    _store_id INT;
BEGIN
    -- Check if inventory level after decrement is less than 0
    IF ((SELECT inventory_level FROM Store_Inventory 
        WHERE product_id = NEW.product_id AND store_id = (SELECT store_id FROM Sales WHERE sale_id = NEW.sale_id)) - NEW.quantity_sold < 0) THEN
      RAISE EXCEPTION 'Inventory cannot be less than 0';
    END IF;

    SELECT store_id FROM Sales
    WHERE sale_id = NEW.sale_id INTO _store_id;

    PERFORM update_inventory_level(_store_id, NEW.product_id, -NEW.quantity_sold);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Inventroy Triggers --

CREATE TRIGGER update_inventory_after_delivery
AFTER INSERT ON Products_in_Deliveries
FOR EACH ROW
EXECUTE FUNCTION increment_inventory();

CREATE TRIGGER update_inventory_after_sale
AFTER INSERT ON Products_Sold
FOR EACH ROW
EXECUTE FUNCTION decrement_inventory();



--- Order Trigger ---
-- Triggered when the inventory level falls from above a certain minimum inventory level to below the minimum level --

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


