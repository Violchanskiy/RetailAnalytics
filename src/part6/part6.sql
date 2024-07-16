DROP FUNCTION IF EXISTS PersonalOffers;

CREATE FUNCTION PersonalOffers(
    IN count_group integer, 
    IN max_churn_rate numeric,
    IN max_stability_index numeric,
    IN max_sku numeric, 
    IN max_margin numeric 
)
RETURNS TABLE (
    Customer_ID bigint,
    SKU_Name varchar, 
    Offer_Discount_Depth int 
)
AS $$
DECLARE
    GroupException RECORD;
BEGIN

    FOR GroupException IN (
        SELECT Customer_ID, Group_ID FROM Groups
       
        WHERE Group_Churn_Rate <= max_churn_rate
    
        AND Group_Stability_Index < max_stability_index
        ORDER BY Group_Affinity_Index DESC
    )
    LOOP
            SELECT Customer_ID, SKU_Name, Offer_Discount_Depth FROM (
            SELECT Groups.Customer_ID, SKU.SKU_Name,
            (COUNT(CASE WHEN Stores.SKU_ID = SKU.SKU_ID THEN 1 END) * 100.0) / COUNT(*) AS sku_share,
            ROW_NUMBER() OVER (PARTITION BY Groups.Customer_ID, SKU.Group_ID
            ORDER BY (COUNT(CASE WHEN Stores.SKU_ID = SKU.SKU_ID THEN 1 END) * 100.0) / COUNT(*) DESC) AS rank 
            FROM Customers
            INNER JOIN Groups ON Customers.Customer_ID = Groups.Customer_ID
            INNER JOIN SKU ON Groups.Group_ID = SKU.Group_ID
            INNER JOIN Stores ON SKU.SKU_ID = Stores.SKU_ID
            WHERE Groups.Customer_ID = GroupException.Customer_ID
            GROUP BY Groups.Customer_ID, SKU.SKU_Name
        ) AS sku_group_share;
      
        Offer_Discount_Depth := CEIL(max_margin * (stores.SKU_Retail_Price - stores.SKU_Purchase_Price) / stores.SKU_Retail_Price);
      
        IF Offer_Discount_Depth >= CEIL(Group_Minimum_Discount * 1.05 / 5) * 5 THEN
        RETURN QUERY sku_group_share.Customer_ID, sku_group_share.SKU_Name, Offer_Discount_Depth;
        END IF;
        END LOOP;
      
    RETURN;
END;
$$
LANGUAGE plpgsql;

SELECT * FROM PersonalOffers(100, 100, 100, 2, 10);




