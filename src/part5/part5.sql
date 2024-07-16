DROP FUNCTION IF EXISTS rewardGroupDetermination(real, real, real);
CREATE FUNCTION rewardGroupDetermination (churn_idx REAL, trans_share_max REAL, marge_share_avl REAL)
RETURNS TABLE (Customer_ID BIGINT, Group_ID BIGINT, Offer_Discount_Depth REAL)
LANGUAGE plpgsql AS
$$
BEGIN
    FOR curr_row IN SELECT * FROM full_groups_view LOOP
        IF (curr_row.group_churn_rate <= churn_idx AND
            curr_row.group_discount_share <= trans_share_max AND
            curr_row.Average_Margin * marge_share_avl / 100 >=
            CEIL((curr_row.group_minimum_discount * 100) / 5.0) * 0.05 * curr_row.Average_Margin) THEN
            RETURN NEXT (curr_row.customer_id, curr_row.group_id, CEIL((curr_row.group_minimum_discount * 100) / 5.0) * 5);
        END IF;
    END LOOP;
END;
$$;


SELECT * FROM generate_growth_offers('18.08.2022 00:00:00', '18.08.2022 00:00:00', 1, 3 ,70, 30)
DROP FUNCTION generate_growth_offers(start_date_in VARCHAR,
    end_date_in VARCHAR,
    additional_transactions INT,
    max_churn_index INT,
    max_discount_share DECIMAL,
    allowable_margin_share DECIMAL);


CREATE OR REPLACE FUNCTION generate_growth_offers(
    start_date_in DATA,
    end_date_in DATA,
    additional_transactions INT,
    max_churn_index INT,
    max_discount_share DECIMAL,
    allowable_margin_share DECIMAL
)
RETURNS TABLE (
    Customer_ID BIGINT, 
    Start_Date DATE, 
    End_Date DATE, 
    Required_Transactions_Count real, 
    Group_Name VARCHAR, 
    Offer_Discount_Depth real
) AS $$
DECLARE

BEGIN
    WITH tmp AS ( 
        SELECT c.customer_id, (CEIL(EXTRACT(EPOCH FROM (TO_TIMESTAMP('18.08.2022 00:00:00', 'DD.MM.YYYY HH24:MI:SS') - (TO_TIMESTAMP('18.08.2022 00:00:00', 'DD.MM.YYYY HH24:MI:SS')))) / Customer_Frequency) + 1)::integer as Required_Transactions_Count
        FROM customers c
    )
    SELECT tmp.customer_id, start_date_in, end_date_in, tmp.Required_Transactions_Count, m.Group_Name, m.Offer_Discount_Depth FROM tmp
    JOIN main(2, '00.00.0000 00.00.0000', Required_Transactions_Count,  1.15, 3, 70, 30) as m ON tmp.customer_id = m.custumer_id;
    

END;
$$ LANGUAGE plpgsql;


