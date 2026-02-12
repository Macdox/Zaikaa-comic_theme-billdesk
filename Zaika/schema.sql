-- Table: users
-- Extracted from 'usignup' view and 'settinguporder' view logic
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    mobile VARCHAR(15) NOT NULL,
    password VARCHAR(255), -- Stores hashed password. Nullable for auto-created users (e.g. from orders).
    year INTEGER,          -- Nullable based on 'staff' role logic in 'usignup'
    branch VARCHAR(100)    -- Nullable based on 'staff' role logic in 'usignup'
);

-- Table: shops
-- Extracted from 'add_shop' and 'admin_panel' views
CREATE TABLE shops (
    shop_id SERIAL PRIMARY KEY,
    shop_name VARCHAR(255) NOT NULL,
    passkey VARCHAR(255) NOT NULL -- Simple distinct password for each shop
);

-- Table: menuitems
-- Extracted from 'add_shop' and 'home' views
CREATE TABLE menuitems (
    id SERIAL PRIMARY KEY,
    shop_id INTEGER REFERENCES shops(shop_id) ON DELETE CASCADE, -- Linked to shops table
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    availability INTEGER DEFAULT 1 -- Logic uses 1 for Available, 0 for Unavailable
);

-- Table: orderlist
-- Extracted from 'settinguporder' and 'confirm_order' views
CREATE TABLE orderlist (
    order_id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    contact_no VARCHAR(15) NOT NULL,
    shop_id INTEGER REFERENCES shops(shop_id), -- Ideally a foreign key, though not strictly enforced in raw SQL
    item_name VARCHAR(255) NOT NULL,
    qty INTEGER NOT NULL,
    total_amt DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'Pending', -- Values: 'Pending', 'Approved', 'Completed', 'Delivered'
    tokenid INTEGER,                      -- Null initially, generated upon approval
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mode_of_payment VARCHAR(50)           -- Values: 'cash', 'Online'
);