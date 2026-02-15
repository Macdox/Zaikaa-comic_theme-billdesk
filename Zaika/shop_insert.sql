-- =========================
-- INSERT INTO SHOPS TABLE
-- =========================

INSERT INTO shops (shop_name, passkey) VALUES
('Cheese N'' Giggles', 'cheese123'),
('Sweet Little Things', 'sweet123'),
('Wok This Way', 'wok123'),
('Crunch n'' Sip', 'crunch123'),
('China Bistro', 'china123'),
('Creamy & Crunchy Junction', 'creamy123'),
('Coco n Crunch', 'coco123'),
('Cornfetti Chips', 'corn123'),
('ChocoTaco Tales', 'taco123'),
('BOMBAY STREET', 'bombay123'),
('Tropica Theory', 'tropica123'),
('Flavour Baazi', 'flavour123');


-- =========================
-- INSERT INTO MENU ITEMS
-- =========================

-- 1. Cheese N' Giggles
INSERT INTO menuitems (shop_id, name, price) VALUES
(1, 'White Sauce Pasta (Half)', 60),
(1, 'White Sauce Pasta (Full)', 100),
(1, 'Red Sauce Pasta (Half)', 60),
(1, 'Red Sauce Pasta (Full)', 110),
(1, 'Jain White Sauce Pasta (Half)', 60),
(1, 'Jain White Sauce Pasta (Full)', 110),
(1, 'Cheese Balls (Half)', 60),
(1, 'Cheese Balls (Full)', 100),
(1, 'Cheesy Corn', 80);

-- 2. Sweet Little Things
INSERT INTO menuitems (shop_id, name, price) VALUES
(2, 'Blueberry Cream Cheesecake', 60),
(2, 'Biscoff Cream Cheesecake', 70),
(2, 'Red Velvet Cream Cheesecake', 80),
(2, 'Pineapple Cupcake', 50),
(2, 'Strawberry Cupcake', 50),
(2, 'Coffee Mousse Cake', 60);

-- 3. Wok This Way
INSERT INTO menuitems (shop_id, name, price) VALUES
(3, 'Chinese Bhel', 35),
(3, 'Hot Bhel', 40),
(3, 'Manchurian Bhel', 49),
(3, 'Manchurian', 39),
(3, 'Chilli Manchurian', 65);

-- 4. Crunch n' Sip
INSERT INTO menuitems (shop_id, name, price) VALUES
(4, 'Strawberry Bliss (Chewy Boba)', 69),
(4, 'Blueberry Magic (Chewy Boba)', 70),
(4, 'Biscoff Dream (Chewy Boba)', 70),
(4, 'Choco Treat (Chewy Boba)', 70),
(4, 'Strawberry Burst (Popping Boba)', 90),
(4, 'Blueberry Burst (Popping Boba)', 90),
(4, 'Blueberry Cloud (Milkshake)', 60),
(4, 'Strawberry Velvet (Milkshake)', 60),
(4, 'Masala Crunch (Wafer Pav)', 30),
(4, 'Cheese Crunch (Cheese Wafer Pav)', 40),
(4, 'Masala Crunch + Any Popping Boba (Combo)', 110);

-- 5. China Bistro
INSERT INTO menuitems (shop_id, name, price) VALUES
(5, 'SteamBurst Dumplings', 79),
(5, 'Pepper Toss Noodles with Manchurian & Gravy', 89),
(5, 'China Bistro Signature Bowl', 129);

-- 6. Creamy & Crunchy Junction
INSERT INTO menuitems (shop_id, name, price) VALUES
(6, 'Strawberry Chocolate Rush', 110),
(6, 'Strawberry Mello Stick', 90),
(6, 'Chocolate Mein Dooba Fondue', 120),
(6, 'Boondi Cream Burst', 70);

-- 7. Coco n Crunch
INSERT INTO menuitems (shop_id, name, price) VALUES
(7, 'Nachos Salsa', 50),
(7, 'Nachos Cheese', 50),
(7, 'Nachos Chaat', 65),
(7, 'Extra Cheese', 10),
(7, 'Extra Salsa', 10),
(7, 'Extra Jalapeno', 5),
(7, 'Extra Capsicum', 5),
(7, 'Extra Corn', 5),
(7, 'Cold Coco', 50),
(7, 'Choco Chips Topping', 10),
(7, 'Oreo Topping', 10),
(7, 'Wafer Roll Topping', 10);


-- ===============================
-- 8. Cornfetti Chips Menu Items
-- ===============================

INSERT INTO menuitems (shop_id, name, price) VALUES

-- Choose Your Own Chips Bag (₹80)
(8, 'Chips - American Style Cream & Onion', 80),
(8, 'Chips - Classic Salted', 80),
(8, 'Chips - West Indies Hot n Sweet Chilli', 80),
(8, 'Chips - India Magic Masala', 80),
(8, 'Chips - Spanish Tomato Tango', 80),
(8, 'Chips - Sizzling Hot', 80),
(8, 'Chips - Chile Limon', 80),
(8, 'Chips - Masala Munch (Kurkure)', 80),
(8, 'Chips - Bingo Mad Angles', 80),
(8, 'Chips - Banana Chips (Jain Style)', 80),

-- Classic Kullad Corn (₹59)
(8, 'Classic Kullad Corn - Butter Masala', 59),
(8, 'Classic Kullad Corn - Lemon Pepper', 59),
(8, 'Classic Kullad Corn - Chatpata Desi', 59),

-- Cheese Special Kullad Corn (₹65)
(8, 'Cheese Special Corn - Cheese Corn', 65),
(8, 'Cheese Special Corn - Peri Peri Cheese Corn', 65),
(8, 'Cheese Special Corn - Mayo Cheese Corn', 65),
(8, 'Cheese Special Corn - Tandoori Cheese Corn', 65),

-- Other Items
(8, 'Fusion & Spicy (Chips & Corn)', 100),
(8, 'Masala Sweet Paan', 15),

-- Extras
(8, 'Extra Cheese', 10),
(8, 'Extra Mayo', 10),
(8, 'Extra Cheese + Mayo', 15);


-- 9. ChocoTaco Tales
INSERT INTO menuitems (shop_id, name, price) VALUES
(9, 'Just Pass Tacos', 80),
(9, 'Proxy Lagao Canopy Khao', 50),
(9, 'Deadline Se Pehele MexiBowl', 60),
(9, 'Bunking Brownie Shots', 40),
(9, 'Tacos + Brownie Shots (Combo)', 110),
(9, 'Canopy + Brownie Shots (Combo)', 80);

-- 10. BOMBAY STREET
INSERT INTO menuitems (shop_id, name, price) VALUES
(10, 'Wafer Pav', 35),
(10, 'Shezwan Wafer Pav', 45),
(10, 'Cheese Wafer Pav', 60),
(10, 'Nutella Boboloni', 99),
(10, 'Cold Coffee', 60),
(10, 'Oreo Coffee', 70),
(10, 'KitKat Coffee', 70),
(10, 'Wafer Pav + Coffee (Combo)', 99),
(10, 'Boboloni + Coffee (Combo)', 149);

-- 11. Tropica Theory
INSERT INTO menuitems (shop_id, name, price) VALUES
(11, 'Mint Mojito', 60),
(11, 'Blue Lagoon', 70),
(11, 'Strawberry Blush', 70),
(11, 'Mango Chilli Punch', 70);

-- 12. Flavour Baazi
INSERT INTO menuitems (shop_id, name, price) VALUES
(12, 'Classic Veg Burger', 69),
(12, 'Cheese Veg Burger', 79),
(12, 'Veg Grill Sandwich', 69),
(12, 'Cheese Veg Grill Sandwich', 89),
(12, 'Aloo Tikki Sub (6 Inch)', 129),
(12, 'Cheese Aloo Tikki Sub (6 Inch)', 149),
(12, 'Paneer Tikka Sub (6 Inch)', 149),
(12, 'Cheese Paneer Tikka Sub (6 Inch)', 169),
(12, 'Aloo Tikka Mayo Bowl', 69),
(12, 'Paneer Tikka Mayo Bowl', 89),
(12, 'Strawberry Boba', 120),
(12, 'Coffee Boba', 130),
(12, 'Chocolate Boba', 150),
(12, 'The Giant Monster Sub (1 Ft)', 289);