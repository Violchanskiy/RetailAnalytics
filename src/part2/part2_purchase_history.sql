DROP VIEW IF EXISTS PurchaseHistory CASCADE;

CREATE OR REPLACE VIEW  PurchaseHistory AS
            SELECT Cards.Customer_ID, Transactions.Transaction_ID, Transactions.Transaction_DateTime,  SKU.Group_ID,
                SUM(SKU_Purchase_Price * SKU_Amount) AS Group_Cost,  
                SUM(SKU_Summ) AS Group_summ,
                SUM(SKU_Summ_Paid)AS Group_Summ_Paid 
       FROM Transactions 
JOIN Cards ON Cards.Customer_Card_ID = Transactions.Customer_Card_ID
JOIN Checks  ON Transactions.Transaction_ID = Checks.Transaction_ID
JOIN SKU  ON SKU.SKU_ID = Checks.SKU_ID
JOIN Stores ON SKU.SKU_ID = Stores.SKU_ID
AND Transactions.Transaction_Store_ID = Stores.Transaction_Store_ID
GROUP BY Cards.Customer_ID, Transactions.Transaction_ID, Transactions.Transaction_DateTime,  SKU.Group_ID;
 

select * from PurchaseHistory
    where group_id = 1 and transaction_id > 100;
select * from PurchaseHistory
    where Group_Cost < 50;
select customer_id, transaction_datetime, group_summ
from PurchaseHistory
    where transaction_datetime < '2018-03-01';