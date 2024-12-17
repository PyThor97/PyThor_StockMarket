CREATE TABLE player_stocks (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    player_identifier VARCHAR(255),
    character_name VARCHAR(255),
    stock_name VARCHAR(255),
    shares INT,
    contribution INT
);
