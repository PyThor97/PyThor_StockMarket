#specify your db
USE [DB NAME];

#Create stocks table for global info

CREATE TABLE `pythor_stocks` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `stock_name` VARCHAR(50) NOT NULL,
    `stock_value` INT NOT NULL,
    `last_updated` DATETIME NOT NULL,
    `next_update` DATETIME NOT NULL
);

#Default values, insert according to your config

INSERT INTO `pythor_stocks` (`stock_name`, `stock_value`, `last_updated`, `next_update`)
VALUES
    ('Train', 100, NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    ('Oil', 100, NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    ('Spices', 100, NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY)),
    ('Gold', 100, NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY));

# Enable events for updating the values of the stock automaticly

SET GLOBAL event_scheduler = ON;

#Create an event to update stock values every 24 hours, you can change it if you want 

CREATE EVENT update_stock_values
ON SCHEDULE EVERY 1 DAY
DO
    UPDATE `pythor_stocks`
    SET 
        `stock_value` = FLOOR(RAND() * 251) - 50, -- ערכים בין -50 ל-200
        `last_updated` = NOW(),
        `next_update` = DATE_ADD(NOW(), INTERVAL 1 DAY);


#Create player table to track each player progress

CREATE TABLE `player_stocks` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(50) NOT NULL,
    `character_name` VARCHAR(50) NOT NULL,
    `stock_name` VARCHAR(50) NOT NULL,
    `shares` INT NOT NULL DEFAULT 0
);

CREATE TABLE category_contributions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_identifier VARCHAR(255) NOT NULL,
    character_name VARCHAR(255) NOT NULL,
    category_name VARCHAR(255) NOT NULL,
    total_contribution INT DEFAULT 0,
    UNIQUE (player_identifier, category_name)
);

