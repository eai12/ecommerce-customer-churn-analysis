原表格数据导入全部都是varchar(255)的形式，需要将部分字段转换成INT和DECIMAL格或者float格式
-- 1. 改整数型 
ALTER TABLE  `电子商务客户流失数据`
MODIFY `流失标志` INT,
MODIFY `流失至今天数` INT,
MODIFY `客户存续月数` INT,
MODIFY `购买次数` INT,
MODIFY `客服工单数` INT,
MODIFY `退货次数` INT,
MODIFY `距上次购买天数` INT,
MODIFY `客服互动次数` INT,
MODIFY `营销邮件发送数` INT,
MODIFY `营销邮件打开数` INT,
MODIFY `营销邮件点击数` INT,
MODIFY `营销转化数` INT,
MODIFY `推荐次数` INT,
MODIFY `满意度评分` INT,
MODIFY `反馈评分` INT;

-- 2. 改浮点/金额型
ALTER TABLE  `电子商务客户流失数据`
MODIFY `总消费金额(美元)` DECIMAL(15,2),
MODIFY `平均订单金额(美元)` DECIMAL(15,2),
MODIFY `客户终身价值(美元)` DECIMAL(15,2),
MODIFY `流失收入影响(美元)` DECIMAL(15,2),
MODIFY `忠诚度评分` float(5,1);

-- 3.类别映射
UPDATE `电子商务客户流失数据` SET `是否已流失` = '1' WHERE `是否已流失` = '是';
UPDATE `电子商务客户流失数据` SET `是否已流失` = '0' WHERE `是否已流失` = '否';

-- 4.1 不同客户价值类别流失净值占比计算
WITH 客户指标表 AS (
    SELECT 
        `客户ID`,
        `客户细分`,
        `客户终身价值(美元)` AS 客户终身价值,
        `是否已流失`,
        `客户价值类别`
    FROM `电子商务客户流失数据`
),
聚合结果表 AS (
    SELECT 
        `客户价值类别` AS `客户类型`,
        COUNT(`客户ID`) AS `用户总数`,
        SUM(`是否已流失`) AS `流失人数`,
        ROUND(AVG(`是否已流失`) * 100, 2) AS `流失率(%)`,
        SUM(CASE WHEN `是否已流失` = 1 THEN 客户终身价值 ELSE 0 END) AS `流失损失的潜在CLV`
    FROM 客户指标表
    GROUP BY `客户价值类别`
)
SELECT 
    `客户类型`,
    `用户总数`,
    `流失人数`,
    `流失率(%)`,
    ROUND(`流失损失的潜在CLV`, 2) AS `流失损失的潜在CLV`,
    ROUND(`流失损失的潜在CLV` * 100.0 / SUM(`流失损失的潜在CLV`) OVER (), 2) AS `流失CLV占比(%)`
FROM 聚合结果表
ORDER BY `流失率(%)` DESC;

-- 4.2 客户价值类别流失净值占比表（4.1输出结果）
| 客户类型 | 用户总数 | 流失人数 | 流失率(%) | 流失损失的潜在CLV | 流失CLV占比(%) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 高价值 | 40063 | 16580 | 41.38 | 521008054.87 | 96.01 |
| 中价值 | 5002 | 2067 | 41.32 | 16339579.49 | 3.01 |
| 低价值 | 3980 | 1629 | 40.93 | 5114038.83 | 0.94 |
| 极低价值 | 955 | 377 | 39.48 | 197264.97 | 0.04 |
