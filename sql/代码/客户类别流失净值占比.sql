-- 计算客户类别流失净值占比表
WITH 客户指标表 AS (
    SELECT 
        `客户ID`,
        `客户细分`,
        `客户终身价值(美元)` AS 客户终身价值,
        `是否已流失`
    FROM `电子商务客户流失数据`
),
聚合结果表 AS (
    SELECT 
       `客户细分`,
        COUNT(`客户ID`) AS `用户总数`,
        SUM(`是否已流失`) AS `流失人数`,
        ROUND(AVG(`是否已流失`) * 100, 2) AS `流失率(%)`,
        SUM(CASE WHEN `是否已流失` = 1 THEN 客户终身价值 ELSE 0 END) AS `流失损失的潜在CLV`
    FROM 客户指标表
    GROUP BY `客户细分`
)
SELECT 
    `客户细分`,
    `用户总数`,
    `流失人数`,
    `流失率(%)`,
    ROUND(`流失损失的潜在CLV`, 2) AS `流失损失的潜在CLV`,
    ROUND(`流失损失的潜在CLV` * 100.0 / SUM(`流失损失的潜在CLV`) OVER (), 2) AS `流失CLV占比(%)`
FROM 聚合结果表
ORDER BY `流失率(%)` DESC;
