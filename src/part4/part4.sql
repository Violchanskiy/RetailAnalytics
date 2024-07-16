DROP FUNCTION IF EXISTS main;
DROP FUNCTION IF EXISTS PeriodOne;
DROP FUNCTION IF EXISTS PeriodTwo;
DROP FUNCTION IF EXISTS reward;

CREATE OR REPLACE FUNCTION main (
        AverageCheckMethod integer,
        FirstNumOfTransactions varchar,
        NumOfTransactions bigint,
        AverageBill_increaseFactor numeric,
        MaxChurnIndex integer,
        MaxShareTransactions integer,
        MarginPercentage integer 
    )
    RETURNS TABLE (
        Customer_ID bigint,
        Required_Check_Measure real, 
        Group_Name varchar, 
        Offer_Discount_Depth real 
    )
LANGUAGE plpgsql AS
$$
BEGIN
IF (AverageCheckMethod = 1) THEN
RETURN QUERY SELECT period_date.Customer_ID::bigint, period_date.Required_Check_Measure::real, Groups_sku.group_name::varchar, GroupException.Offer_Discount_Depth::real
FROM PeriodOne(FirstNumOfTransactions, AverageBill_increaseFactor) AS period_date
JOIN GroupException(MaxChurnIndex, MaxShareTransactions, MarginPercentage) GroupException ON period_date.Customer_ID = GroupException.Customer_ID
JOIN Groups_sku Groups_sku ON Groups_sku.group_id = GroupException.Group_ID
ORDER BY 1;
ELSEIF (AverageCheckMethod = 2) THEN
RETURN QUERY SELECT period_transactions.Customer_ID::bigint, period_transactions.Required_Check_Measure::real, Groups_sku.group_name::varchar, GroupException.Offer_Discount_Depth::real
FROM PeriodTwo(NumOfTransactions, AverageBill_increaseFactor) AS period_transactions
JOIN GroupException(MaxChurnIndex, MaxShareTransactions, MarginPercentage) GroupException ON period_transactions.Customer_ID = GroupException.Customer_ID
JOIN Groups_sku ON Groups_sku.group_id = GroupException.Group_ID
ORDER BY 1;
ELSE
RAISE EXCEPTION 'The method for calculating the average bill was not selected correctly (1 - per period or 2 - per quantity)';
END IF;
END;
$$;

-- методику расчета по периоду
CREATE OR REPLACE FUNCTION PeriodOne(
    FirstNumOfTransactions varchar,
    AverageBill_increaseFactor real
)
RETURNS TABLE (
    Customer_ID bigint, 
    Required_Check_Measure real
)
LANGUAGE plpgsql AS
$$
DECLARE
    FirstDate date = split_part(FirstNumOfTransactions, ' ', 1)::date;
    LastDate date = split_part(FirstNumOfTransactions, ' ', 2)::date;
BEGIN
    IF (FirstDate IS NULL OR LastDate IS NULL OR LastDate <= FirstDate) THEN
        RAISE EXCEPTION 'Last date of the specified period must be later than the first date.';
    END IF;
    RETURN QUERY
    WITH clients AS (
        SELECT cards.Customer_ID, transactions.transaction_summ FROM transactions 
        JOIN cards  ON cards.customer_card_id = transactions.customer_card_id  
        WHERE transactions.transaction_datetime BETWEEN FirstDate AND LastDate 
    )
    SELECT clients.Customer_ID, ((SUM(transaction_summ) / COUNT(*)) * AverageBill_increaseFactor)::real AS required_check_measure FROM clients 
    GROUP BY clients.Customer_ID;
END;
$$;

--  методику расчета по количеству последних транзакций
CREATE OR REPLACE FUNCTION PeriodTwo(
    NumТransactions bigint,
    AverageBill_increaseFactor real
)
RETURNS TABLE (
    Customer_ID bigint, 
    Required_Check_Measure real
)
LANGUAGE plpgsql AS
$$
BEGIN
RETURN QUERY 
    WITH clients AS (
        SELECT cards.Customer_ID, transactions.transaction_summ, 
        ROW_NUMBER() OVER (PARTITION BY cards.Customer_ID ORDER BY transactions.transaction_datetime DESC) 
        FROM transactions 
        JOIN cards ON cards.customer_card_id = transactions.customer_card_id  
    )
    SELECT clients.Customer_ID, ((SUM(transaction_summ) / COUNT(*)) * AverageBill_increaseFactor) ::real AS required_check_measure FROM clients 
    GROUP BY clients.Customer_ID;
END;
$$;


CREATE OR REPLACE FUNCTION GroupException (
    MaxChurnIndex real, 
    MaxShareTransactions real,
    MarginPercentage real 
)
RETURNS TABLE (Customer_ID bigint, Group_ID bigint, Offer_Discount_Depth numeric) AS $$
BEGIN 
    RETURN QUERY
       WITH tmp as ( 
        -- выбирает записи из таблицы Groups, где показатель оттока меньше 3 и доля скидок меньше 70%.
            SELECT g.Group_Churn_Rate, g.Group_Discount_Share, g.Customer_ID::bigint, g.Group_ID::bigint, g.group_margin, g.group_affinity_index FROM Groups g
            WHERE g.Group_Churn_Rate < 3 AND g.Group_Discount_Share < 70.0 / 100
        ),
        tmp3 as (
        -- вычисляет сумму покупок и затрат для каждого клиента в каждой группе.
            SELECT p.customer_id, p.group_id,  SUM(p.group_summ-p.group_cost)/SUM(p.group_summ) as Offer_Discount_Depth FROM purchasehistory p 
            GROUP BY p.customer_id, p.group_id
        ),
        tmp2 as (
        -- соединяет таблицы tmp и tmp3, а затем выбирает записи, где минимальная скидка в периоде меньше, чем 30% от предложенной скидки.
            SELECT tmp.*, CEIL(per.group_minimum_discount / 0.05) * 5 as Offer_Discount_Depth FROM tmp 
            JOIN tmp3 ON  tmp3.Customer_ID = tmp.Customer_ID AND tmp3.group_id = tmp.Group_ID 
            JOIN (SELECT p.Customer_ID, p.Group_ID, p.group_minimum_discount FROM periodsview p) as per ON per.Customer_ID = tmp.Customer_ID 
            AND per.Group_ID = tmp.Group_ID
            WHERE CEIL(per.group_minimum_discount / 0.05) * 0.05  < tmp3.Offer_Discount_Depth * 30 / 100
        ),
        tmp4 as (
        -- обавляет столбец firstval, который содержит первое значение group_affinity_index для каждого клиента.
        -- я выбирает записи из tmp4, где firstval равен group_affinity_index, и возвращает их.
            SELECT tmp2.Customer_ID::bigint,
            tmp2.Group_ID::bigint, 
            tmp2.group_affinity_index, 
            tmp2.Offer_Discount_Depth,
            FIRST_VALUE(tmp2.group_affinity_index) OVER (
            PARTITION BY tmp2.Customer_ID ORDER BY tmp2.group_affinity_index DESC) as firstval 
            FROM tmp2
        )
        SELECT tmp4.Customer_ID::bigint, tmp4.Group_ID::bigint, tmp4.Offer_Discount_Depth FROM tmp4
        WHERE tmp4.firstval = tmp4.group_affinity_index;      
END;
$$ LANGUAGE plpgsql;

SELECT * from main(2, '01-20-2018 08-20-2022', 100,  1.15, 3, 70, 30);
SELECT * from main(1, '01-20-2010 08-20-2028', 100,  1.15, 3, 70, 30);
