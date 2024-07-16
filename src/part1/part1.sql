
DROP TABLE IF EXISTS Personal_data CASCADE;
DROP TABLE IF EXISTS Cards CASCADE;
DROP TABLE IF EXISTS Transactions CASCADE;
DROP TABLE IF EXISTS Checks CASCADE;
DROP TABLE IF EXISTS SKU CASCADE;
DROP TABLE IF EXISTS Stores CASCADE;
DROP TABLE IF EXISTS Groups_SKU CASCADE;
DROP TABLE IF EXISTS Date_of_analysis_formation CASCADE;


select * FROM Personal_data;
select * FROM Cards;
select * FROM Transactions;
select * FROM Checks;
select * FROM SKU;
select * FROM Stores;
select * FROM Groups_SKU;
select * FROM Date_of_analysis_formation;

CREATE TABLE IF NOT EXISTS Personal_data(
    Customer_ID BIGINT PRIMARY KEY  NOT NULL,
    Customer_Name VARCHAR(255) NOT NULL 
    CHECK (customer_name ~ '^[A-ZА-Я][a-zа-яё -]+$'),
    Customer_Surname VARCHAR(255) NOT NULL 
    CHECK (customer_surname ~ '^[A-ZА-Я][a-zа-яё -]+$'),
    Customer_Primary_Email VARCHAR(255) NOT NULL
     CHECK (customer_primary_email ~ '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
    Customer_Primary_Phone VARCHAR(15) NOT NULL
    CHECK (customer_primary_phone ~ '^[+][7][0-9]{10}')
);


CREATE TABLE IF NOT EXISTS Cards (
  Customer_Card_ID BIGINT PRIMARY KEY  NOT NULL,
  Customer_ID BIGINT NOT NULL,
  FOREIGN KEY (Customer_ID) REFERENCES Personal_data(Customer_ID)
);


CREATE TABLE IF NOT EXISTS Transactions (
  Transaction_ID BIGINT PRIMARY KEY  NOT NULL,
  Customer_Card_ID BIGINT NOT NULL,
  Transaction_Summ NUMERIC NOT NULL,
  Transaction_DateTime TIMESTAMP NOT NULL,
  Transaction_Store_ID BIGINT NOT NULL,
  FOREIGN KEY (Customer_Card_ID) REFERENCES Cards(Customer_Card_ID)
);

CREATE TABLE IF NOT EXISTS Groups_SKU(
  Group_ID BIGINT PRIMARY KEY  NOT NULL,
  Group_Name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS SKU(
  SKU_ID BIGINT PRIMARY KEY  NOT NULL,
  SKU_Name VARCHAR(255) NOT NULL,
  Group_ID BIGINT NOT NULL,
  FOREIGN KEY (Group_ID) REFERENCES Groups_SKU(Group_ID)
);

CREATE TABLE IF NOT EXISTS Checks (
  Transaction_ID BIGINT NOT NULL,
  SKU_ID BIGINT NOT NULL,
  SKU_Amount NUMERIC NOT NULL,
  SKU_Summ NUMERIC NOT NULL,
  SKU_Summ_Paid NUMERIC NOT NULL,
  SKU_Discount NUMERIC NOT NULL,
  FOREIGN KEY (Transaction_ID) REFERENCES Transactions(Transaction_ID),
  FOREIGN KEY (SKU_ID) REFERENCES SKU(SKU_ID)
);

CREATE TABLE IF NOT EXISTS Stores(
  Transaction_Store_ID BIGINT NOT NULL,
  SKU_ID BIGINT NOT NULL,
  SKU_Purchase_Price NUMERIC NOT NULL,
  SKU_Retail_Price NUMERIC NOT NULL,
  FOREIGN KEY (SKU_ID) REFERENCES SKU(SKU_ID)
);


CREATE TABLE IF NOT EXISTS Date_of_analysis_formation(
  Analysis_Formation TIMESTAMP DEFAULT current_date
);

CREATE OR REPLACE PROCEDURE import_all_tables_csv(
  IN table_name text, 
  IN path text
)
LANGUAGE plpgsql
AS $$
BEGIN
  EXECUTE format('COPY %I FROM %L WITH (FORMAT csv, HEADER false, DELIMITER E''\t'', ESCAPE ''\'')', table_name, path);
END;
$$;

SET DATESTYLE to iso, DMY;
CALL import_all_tables_csv('personal_data', '/Users/xavierha/Desktop/retail/SQL3_RetailAnalitycs_v1.0-1/datasets/Personal_Data_Mini.tsv');
CALL import_all_tables_csv('cards', '/Users/xavierha/Desktop/retail/SQL3_RetailAnalitycs_v1.0-1/datasets/Cards_Mini.tsv');
CALL import_all_tables_csv('transactions', '/Users/xavierha/Desktop/retail/SQL3_RetailAnalitycs_v1.0-1/datasets/Transactions_Mini.tsv');
CALL import_all_tables_csv('groups_sku', '/Users/xavierha/Desktop/retail/SQL3_RetailAnalitycs_v1.0-1/datasets/Groups_SKU_Mini.tsv');
CALL import_all_tables_csv('sku', '/Users/xavierha/Desktop/retail/SQL3_RetailAnalitycs_v1.0-1/datasets/SKU_Mini.tsv');
CALL import_all_tables_csv('checks', '/Users/xavierha/Desktop/retail/SQL3_RetailAnalitycs_v1.0-1/datasets/Checks_Mini.tsv');
CALL import_all_tables_csv('stores', '/Users/xavierha/Desktop/retail/SQL3_RetailAnalitycs_v1.0-1/datasets/Stores_Mini.tsv');
CALL import_all_tables_csv('date_of_analysis_formation', '/Users/xavierha/Desktop/retail//SQL3_RetailAnalitycs_v1.0-1/datasets/Date_Of_Analysis_Formation.tsv');
