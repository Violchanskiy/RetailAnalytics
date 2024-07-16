DROP VIEW IF EXISTS Groups CASCADE;
CREATE OR REPLACE VIEW Groups AS
WITH
  -- Актуальная маржа по группе
  Margin AS (
    SELECT
      customer_id,
      group_id,
      SUM(group_summ_paid - group_cost) as Group_Margin
    FROM PurchaseHistory
    GROUP BY customer_id, group_id
  ),
 -- Доля транзакций со скидкой
  Discount_Share AS (
    SELECT
      PurchaseHistory.customer_id,
      PurchaseHistory.group_id,
      COUNT(DISTINCT CASE WHEN Checks.sku_discount > 0 THEN Checks.transaction_id END) /
      NULLIF(COUNT(DISTINCT Checks.transaction_id), 0)::numeric AS Group_Discount_Share
    FROM PurchaseHistory
    JOIN Checks ON PurchaseHistory.transaction_id = Checks.transaction_id
    GROUP BY PurchaseHistory.customer_id, PurchaseHistory.group_id
  ),

  -- Минимальный размер скидки
  Minimum_Discount AS (
    SELECT
      PurchaseHistory.customer_id,
      PurchaseHistory.group_id,
      MIN(group_minimum_discount) AS Group_Minimum_Discount
    FROM PurchaseHistory
    JOIN PeriodsView ON PurchaseHistory.group_id = PeriodsView.group_id AND
      PeriodsView.customer_id = PurchaseHistory.customer_id
    GROUP BY PurchaseHistory.customer_id, PurchaseHistory.group_id
  ),

  -- Средний размер скидки
  Average_Discount AS (
    SELECT
      PurchaseHistory.customer_id,
      PurchaseHistory.group_id,
      AVG(group_summ_paid / group_summ) AS Group_Average_Discount
    FROM PurchaseHistory
    JOIN Checks ON PurchaseHistory.transaction_id = Checks.transaction_id
    WHERE sku_discount > 0
    GROUP BY customer_id, group_id
  ),

  -- Индекс востребованности
  Affenity_Index AS (
    SELECT
      PeriodsView.customer_id,
      PeriodsView.group_id,
      PeriodsView.group_purchase / COUNT(PurchaseHistory.transaction_id)::numeric AS group_affinity_index
    FROM PeriodsView
    JOIN PurchaseHistory ON PurchaseHistory.customer_id = PeriodsView.customer_id
    WHERE PurchaseHistory.transaction_datetime BETWEEN
      PeriodsView.first_group_purchase_date AND PeriodsView.last_group_purchase_date
    GROUP BY PeriodsView.customer_id, PeriodsView.group_id, PeriodsView.group_purchase
  ),

  -- Индекс оттока
  Churn_Rate AS (
    SELECT
      PurchaseHistory.customer_id,
      PurchaseHistory.group_id,
      (EXTRACT(EPOCH FROM (SELECT Analysis_Formation FROM Date_of_analysis_formation) -
        MAX(PurchaseHistory.Transaction_DateTime))) / 86400 /
      PeriodsView.group_frequency AS Group_Churn_Rate
    FROM PurchaseHistory
    JOIN PeriodsView ON PurchaseHistory.customer_id = PeriodsView.customer_id AND
      PurchaseHistory.group_id = PeriodsView.group_id
    GROUP BY PurchaseHistory.customer_id, PurchaseHistory.group_id, PeriodsView.group_frequency
  ),

  -- Индекс стабильности
  Stability_Index AS (
    SELECT
      intervals.customer_id,
      intervals.group_id,
      AVG(ABS(intervals.interval - PeriodsView.group_frequency) / PeriodsView.group_frequency) AS Group_Stability_Index
    FROM (
      SELECT
        PurchaseHistory.customer_id,
        PurchaseHistory.group_id,
        PurchaseHistory.transaction_id,
        PurchaseHistory.transaction_datetime,
        EXTRACT(DAY FROM (PurchaseHistory.transaction_datetime -
          LAG(PurchaseHistory.transaction_datetime) OVER
          (PARTITION BY PurchaseHistory.customer_id, PurchaseHistory.group_id
           ORDER BY PurchaseHistory.transaction_datetime))) AS interval
      FROM PurchaseHistory
    ) intervals
    JOIN PeriodsView ON intervals.customer_id = PeriodsView.customer_id AND intervals.group_id = PeriodsView.group_id
    GROUP BY intervals.customer_id, intervals.group_id
  )

SELECT DISTINCT
  PurchaseHistory.customer_id,
  PurchaseHistory.group_id,
  group_affinity_index,
  Group_Churn_Rate,
  COALESCE(Group_Stability_Index, 0) AS Group_Stability_Index,
  Group_Margin,
  Group_Discount_Share,
  Group_Minimum_Discount,
  Group_Average_Discount
FROM PurchaseHistory
JOIN Margin ON Margin.group_id = PurchaseHistory.group_id AND Margin.customer_id = PurchaseHistory.customer_id
JOIN Discount_Share ON Discount_Share.group_id = PurchaseHistory.group_id AND Discount_Share.customer_id = PurchaseHistory.customer_id
JOIN Minimum_Discount ON Minimum_Discount.group_id = PurchaseHistory.group_id AND Minimum_Discount.customer_id = PurchaseHistory.customer_id
JOIN Average_Discount ON Average_Discount.group_id = Minimum_Discount.group_id AND Average_Discount.customer_id = Discount_Share.customer_id
JOIN Affenity_Index ON Affenity_Index.group_id = PurchaseHistory.group_id AND Affenity_Index.customer_id = PurchaseHistory.customer_id
JOIN Churn_Rate ON Churn_Rate.group_id = PurchaseHistory.group_id AND Churn_Rate.customer_id = PurchaseHistory.customer_id
JOIN Stability_Index ON Stability_Index.group_id = PurchaseHistory.group_id AND Stability_Index.customer_id = PurchaseHistory.customer_id
GROUP BY PurchaseHistory.customer_id, PurchaseHistory.group_id, group_affinity_index,  Group_Churn_Rate,
Group_Stability_Index,Group_Margin,Group_Discount_Share, Group_Minimum_Discount, Group_Average_Discount;