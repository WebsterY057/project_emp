-- 综合金融案例：股票分析系统（MySQL 8.0+ 版本）
-- 一、创建数据库表结构
-- 1. 基础表：股票代码表
-- 创建数据库
CREATE DATABASE IF NOT EXISTS stock_analysis DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE stock_analysis;

-- 股票代码表
CREATE TABLE stk_code (
    scode      VARCHAR(6) PRIMARY KEY,       -- 股票代码
    sname      VARCHAR(50) NOT NULL,         -- 股票名称
    market     VARCHAR(10) DEFAULT 'SZ',     -- 市场：SZ-深市, SH-沪市, BJ-北交
    industry   VARCHAR(50),                   -- 行业分类
    list_date  DATE,                         -- 上市日期
    delist_date DATE,                        -- 退市日期
    status     CHAR(1) DEFAULT '1',         -- 状态：1-正常, 0-停牌, 9-退市
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 创建索引
CREATE INDEX idx_stk_market ON stk_code(market);
CREATE INDEX idx_stk_industry ON stk_code(industry);
CREATE INDEX idx_stk_status ON stk_code(status);
CREATE INDEX idx_list_date ON stk_code(list_date);

-- 2. 核心表：行情数据表
-- 日行情表
CREATE TABLE stk_daily (
    id         INT AUTO_INCREMENT,
    scode      VARCHAR(6) NOT NULL,            -- 股票代码
    trade_date DATE NOT NULL,                  -- 交易日期
    open_price DECIMAL(10,2),                  -- 开盘价
    close_price DECIMAL(10,2),                 -- 收盘价
    high_price  DECIMAL(10,2),                 -- 最高价
    low_price   DECIMAL(10,2),                 -- 最低价
    volume      BIGINT,                        -- 成交量(手)
    amount      DECIMAL(20,2),                 -- 成交额(万元)
    pct_change  DECIMAL(6,2),                  -- 涨跌幅%
    pe_ratio    DECIMAL(8,2),                  -- 市盈率
    pb_ratio    DECIMAL(6,2),                  -- 市净率
    turnover_rate DECIMAL(6,2),               -- 换手率%
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 修改：主键包含 scode 和 trade_date
    PRIMARY KEY (id, scode, trade_date),
    
    UNIQUE KEY uk_stk_daily (scode, trade_date),
    KEY idx_daily_date (trade_date),
    KEY idx_daily_pct (pct_change),
    KEY idx_daily_volume (volume),
    KEY idx_scode_date (scode, trade_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
PARTITION BY RANGE COLUMNS(trade_date) (
    PARTITION p_2020 VALUES LESS THAN ('2021-01-01'),
    PARTITION p_2021 VALUES LESS THAN ('2022-01-01'),
    PARTITION p_2022 VALUES LESS THAN ('2023-01-01'),
    PARTITION p_2023 VALUES LESS THAN ('2024-01-01'),
    PARTITION p_2024 VALUES LESS THAN ('2025-01-01'),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

-- 财务指标表
CREATE TABLE stk_finance (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    scode       VARCHAR(6) NOT NULL,           -- 股票代码
    report_date DATE NOT NULL,                  -- 报告期
    report_type VARCHAR(2),                     -- 报告类型：Q1-一季报, HY-半年报, Q3-三季报, A-年报
    revenue     DECIMAL(20,2),                 -- 营业收入(亿元)
    net_profit  DECIMAL(20,2),                 -- 净利润(亿元)
    roe         DECIMAL(6,2),                  -- 净资产收益率%
    gross_margin DECIMAL(6,2),                 -- 毛利率%
    debt_ratio  DECIMAL(6,2),                 -- 资产负债率%
    eps         DECIMAL(6,2),                  -- 每股收益
    bvps        DECIMAL(8,2),                  -- 每股净资产
    total_assets DECIMAL(20,2),               -- 总资产(亿元)
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_stk_finance (scode, report_date, report_type),
    KEY idx_finance_date (report_date),
    KEY idx_finance_roe (roe),
    KEY idx_scode_report (scode, report_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 资金流向表
CREATE TABLE stk_capital (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    scode         VARCHAR(6) NOT NULL,
    trade_date    DATE NOT NULL,
    main_inflow   DECIMAL(15,2),              -- 主力净流入(万元)
    retail_inflow DECIMAL(15,2),               -- 散户净流入(万元)
    north_inflow  DECIMAL(15,2),               -- 北向资金净流入(万元)
    buy_volume    BIGINT,                      -- 大单买入量(手)
    sell_volume   BIGINT,                      -- 大单卖出量(手)
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_stk_capital (scode, trade_date),
    KEY idx_capital_date (trade_date),
    KEY idx_scode_capital (scode, trade_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 插入示例数据
-- 1. 插入股票代码数据
INSERT INTO stk_code (scode, sname, market, industry, list_date) VALUES
('000001', '平安银行', 'SZ', '银行', '1991-04-03'),
('000002', '万科A', 'SZ', '房地产', '1991-01-29'),
('600519', '贵州茅台', 'SH', '食品饮料', '2001-08-27'),
('601318', '中国平安', 'SH', '保险', '2007-03-01'),
('300750', '宁德时代', 'SZ', '电力设备', '2018-06-11'),
('000858', '五粮液', 'SZ', '食品饮料', '1998-04-27'),
('600036', '招商银行', 'SH', '银行', '2002-04-09');

-- 2. 插入行情数据（2024年1月）
DELIMITER //
CREATE PROCEDURE insert_daily_data()
BEGIN
    DECLARE v_date DATE DEFAULT '2024-01-02';
    DECLARE v_counter INT DEFAULT 0;
    
    WHILE v_counter < 20 DO
        -- 模拟生成数据
        INSERT INTO stk_daily (scode, trade_date, open_price, close_price, high_price, low_price, volume, amount, pct_change, pe_ratio, pb_ratio, turnover_rate) VALUES
        ('000001', v_date, 10.5, 10.8 + RAND()*0.4, 11.0, 10.3, 1000000 + RAND()*500000, 10800 + RAND()*5000, 2.86 + RAND()*3, 8.5, 0.85, 2.5),
        ('000002', v_date, 8.2, 8.5 + RAND()*0.3, 8.8, 8.0, 800000 + RAND()*400000, 6800 + RAND()*3000, 3.66 + RAND()*2, 7.2, 0.92, 1.8),
        ('600519', v_date, 1680, 1700 + RAND()*40, 1720, 1675, 50000 + RAND()*20000, 85000 + RAND()*30000, 1.19 + RAND()*2, 35.5, 12.3, 0.8),
        ('601318', v_date, 45.5, 46.2 + RAND()*1, 47.0, 45.0, 800000 + RAND()*400000, 37000 + RAND()*15000, 0.86 + RAND()*2, 9.8, 1.2, 1.2),
        ('300750', v_date, 180.5, 182.3 + RAND()*3, 185.0, 179.5, 200000 + RAND()*100000, 36500 + RAND()*15000, 1.35 + RAND()*2, 25.3, 4.5, 2.1);
        
        SET v_date = DATE_ADD(v_date, INTERVAL 1 DAY);
        -- 跳过周末
        IF DAYOFWEEK(v_date) = 1 OR DAYOFWEEK(v_date) = 7 THEN
            SET v_date = DATE_ADD(v_date, INTERVAL 2 DAY);
        END IF;
        
        SET v_counter = v_counter + 1;
    END WHILE;
END//
DELIMITER ;

CALL insert_daily_data();
DROP PROCEDURE insert_daily_data;

-- 3. 插入财务数据
INSERT INTO stk_finance (scode, report_date, report_type, revenue, net_profit, roe, gross_margin, debt_ratio, eps, bvps, total_assets) VALUES
('000001', '2023-12-31', 'A', 1798.36, 464.55, 10.3, 28.5, 92.1, 1.98, 19.23, 55800),
('000002', '2023-12-31', 'A', 4527.98, 226.18, 8.5, 20.3, 75.2, 1.95, 22.89, 19600),
('600519', '2023-12-31', 'A', 1476.94, 747.34, 33.5, 91.8, 22.3, 59.49, 177.4, 2830),
('601318', '2023-12-31', 'A', 11804.44, 856.65, 13.8, 45.2, 89.3, 4.68, 33.92, 112400),
('300750', '2023-12-31', 'A', 4009.17, 441.21, 22.8, 21.4, 73.2, 10.05, 44.13, 7610);

-- 4. 插入资金流向数据
INSERT INTO stk_capital (scode, trade_date, main_inflow, retail_inflow, north_inflow, buy_volume, sell_volume) VALUES
('000001', '2024-01-15', 12500.5, -3200.2, 8500.3, 50000, 32000),
('000001', '2024-01-16', 8300.2, -2100.5, 6500.8, 42000, 38000),
('600519', '2024-01-15', 85000.8, -12000.5, 65000.2, 20000, 15000),
('600519', '2024-01-16', 92000.3, -8500.2, 72000.5, 22000, 18000),
('601318', '2024-01-15', 32000.5, -8500.3, 25000.2, 85000, 72000),
('300750', '2024-01-15', 45000.8, -6200.5, 38000.3, 65000, 58000);


-- 三、综合查询案例
-- 案例1：多表关联查询 - 股票基本信息与行情
-- 查询特定日期所有股票行情
SELECT 
    c.scode AS '股票代码',
    c.sname AS '股票名称',
    c.industry AS '行业',
    d.trade_date AS '交易日期',
    d.close_price AS '收盘价',
    d.pct_change AS '涨跌幅(%)',
    d.volume AS '成交量(手)',
    d.amount AS '成交额(万元)',
    f.roe AS '净资产收益率(%)',
    cp.main_inflow AS '主力净流入(万)'
FROM stk_code c
INNER JOIN stk_daily d ON c.scode = d.scode 
    AND d.trade_date = '2024-01-15'
LEFT JOIN (
    SELECT scode, MAX(report_date) as latest_date
    FROM stk_finance
    GROUP BY scode
) f_latest ON c.scode = f_latest.scode
LEFT JOIN stk_finance f ON c.scode = f.scode 
    AND f.report_date = f_latest.latest_date
LEFT JOIN stk_capital cp ON c.scode = cp.scode 
    AND cp.trade_date = '2024-01-15'
WHERE c.status = '1'
ORDER BY d.amount DESC;

-- 案例2：窗口函数应用 - 技术指标计算
-- 计算每只股票的移动平均线等技术指标
WITH price_data AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        high_price,
        low_price,
        volume,
        -- 5日移动平均
        AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS ma5,
        -- 20日移动平均
        AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS ma20,
        -- 计算涨跌
        close_price - LAG(close_price, 1) OVER (
            PARTITION BY scode ORDER BY trade_date
        ) AS price_change,
        -- 计算RSI的组成部分
        CASE 
            WHEN close_price > LAG(close_price, 1) OVER (PARTITION BY scode ORDER BY trade_date)
            THEN close_price - LAG(close_price, 1) OVER (PARTITION BY scode ORDER BY trade_date)
            ELSE 0 
        END AS gain,
        CASE 
            WHEN close_price < LAG(close_price, 1) OVER (PARTITION BY scode ORDER BY trade_date)
            THEN LAG(close_price, 1) OVER (PARTITION BY scode ORDER BY trade_date) - close_price
            ELSE 0 
        END AS loss
    FROM stk_daily
    WHERE trade_date >= '2024-01-01'
)
SELECT 
    p.*,
    c.sname,
    -- 计算RSI（14日）
    ROUND(100 - 100 / (1 + 
        AVG(gain) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
        ) / NULLIF(
            AVG(loss) OVER (
                PARTITION BY scode 
                ORDER BY trade_date 
                ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
            ), 0
        )
    ), 2) AS rsi14,
    -- 计算MACD信号
    ROUND((ma5 - ma20), 2) AS macd_diff,
    -- 成交量5日平均
    ROUND(AVG(volume) OVER (
        PARTITION BY scode 
        ORDER BY trade_date 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ), 0) AS volume_ma5
FROM price_data p
JOIN stk_code c ON p.scode = c.scode
WHERE c.sname = '平安银行'
ORDER BY p.scode, p.trade_date;


-- 案例3：CTE递归 - 计算连续上涨天数
-- MySQL 8.0+ 支持递归CTE
WITH RECURSIVE consecutive_up AS (
    -- 锚点：每只股票的每个上涨起点
    SELECT 
        d1.scode,
        d1.trade_date,
        d1.close_price,
        1 AS up_days,
        d1.trade_date AS start_date
    FROM stk_daily d1
    WHERE EXISTS (
        SELECT 1 
        FROM stk_daily d2 
        WHERE d2.scode = d1.scode 
        AND d2.trade_date = DATE_SUB(d1.trade_date, INTERVAL 1 DAY)
        AND d1.close_price > d2.close_price
    )
    
    UNION ALL
    
    -- 递归：连续上涨
    SELECT 
        d.scode,
        d.trade_date,
        d.close_price,
        cu.up_days + 1,
        cu.start_date
    FROM stk_daily d
    INNER JOIN consecutive_up cu ON d.scode = cu.scode 
        AND d.trade_date = DATE_ADD(cu.trade_date, INTERVAL 1 DAY)
    WHERE d.close_price > cu.close_price
)
SELECT 
    c.sname AS '股票名称',
    cu.scode AS '股票代码',
    cu.start_date AS '开始日期',
    MAX(cu.trade_date) AS '结束日期',
    MAX(cu.up_days) AS '连续上涨天数',
    ROUND(
        (MAX(d2.close_price) - MIN(d1.close_price)) / MIN(d1.close_price) * 100, 
        2
    ) AS '累计涨幅(%)'
FROM consecutive_up cu
JOIN stk_code c ON cu.scode = c.scode
JOIN stk_daily d1 ON cu.scode = d1.scode AND cu.start_date = d1.trade_date
JOIN stk_daily d2 ON cu.scode = d2.scode AND cu.trade_date = d2.trade_date
WHERE cu.up_days >= 3
GROUP BY c.sname, cu.scode, cu.start_date
ORDER BY MAX(cu.up_days) DESC, cu.scode;

-- 案例4：子查询应用 - 龙头股筛选
-- 筛选行业龙头（市值最大、ROE最高）
SELECT 
    industry AS '行业',
    sname AS '股票名称',
    scode AS '股票代码',
    ROUND(market_cap, 2) AS '市值(亿元)',
    roe AS 'ROE(%)',
    ranking AS '行业排名'
FROM (
    SELECT 
        c.industry,
        c.sname,
        c.scode,
        -- 计算市值（简化：收盘价*假设总股本）
        d.close_price * 10000 AS market_cap,
        f.roe,
        -- 按市值排名
        ROW_NUMBER() OVER (
            PARTITION BY c.industry 
            ORDER BY d.close_price * 10000 DESC
        ) AS market_cap_rank,
        -- 按ROE排名
        ROW_NUMBER() OVER (
            PARTITION BY c.industry 
            ORDER BY f.roe DESC
        ) AS roe_rank,
        -- 综合排名
        ROW_NUMBER() OVER (
            PARTITION BY c.industry 
            ORDER BY (d.close_price * 10000) * 0.7 + COALESCE(f.roe, 0) * 0.3 DESC
        ) AS ranking
    FROM stk_code c
    INNER JOIN (
        SELECT scode, close_price
        FROM stk_daily
        WHERE trade_date = (
            SELECT MAX(trade_date) 
            FROM stk_daily
        )
    ) d ON c.scode = d.scode
    LEFT JOIN (
        SELECT scode, MAX(roe) AS roe
        FROM stk_finance
        WHERE report_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
        GROUP BY scode
    ) f ON c.scode = f.scode
    WHERE c.status = '1' 
        AND c.industry IS NOT NULL
        AND c.industry != ''
) t
WHERE ranking = 1  -- 各行业第一名
ORDER BY market_cap DESC;


-- 案例5：复杂分析 - 资金流向与股价关系
-- 资金流向与股价相关性分析
WITH capital_analysis AS (
    SELECT 
        c.scode,
        s.sname,
        c.trade_date,
        c.main_inflow,
        c.retail_inflow,
        c.north_inflow,
        d.close_price,
        d.pct_change,
        -- 计算资金流向排名
        RANK() OVER (
            PARTITION BY c.trade_date 
            ORDER BY c.main_inflow DESC
        ) AS inflow_rank,
        -- 计算价格变化排名
        RANK() OVER (
            PARTITION BY c.trade_date 
            ORDER BY ABS(d.pct_change) DESC
        ) AS pct_change_rank,
        -- 计算5日平均资金流入
        AVG(c.main_inflow) OVER (
            PARTITION BY c.scode 
            ORDER BY c.trade_date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS ma5_inflow,
        -- 计算5日平均涨跌幅
        AVG(d.pct_change) OVER (
            PARTITION BY c.scode 
            ORDER BY c.trade_date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS ma5_pct_change
    FROM stk_capital c
    INNER JOIN stk_daily d ON c.scode = d.scode AND c.trade_date = d.trade_date
    INNER JOIN stk_code s ON c.scode = s.scode
    WHERE c.trade_date >= '2024-01-01'
),
correlation_analysis AS (
    SELECT 
        scode,
        sname,
        -- 计算相关性
        (
            (COUNT(*) * SUM(main_inflow * pct_change) - SUM(main_inflow) * SUM(pct_change)) /
            SQRT(
                (COUNT(*) * SUM(main_inflow * main_inflow) - SUM(main_inflow) * SUM(main_inflow)) *
                (COUNT(*) * SUM(pct_change * pct_change) - SUM(pct_change) * SUM(pct_change))
            )
        ) AS inflow_price_corr,
        -- 统计资金净流入天数
        SUM(CASE WHEN main_inflow > 0 THEN 1 ELSE 0 END) AS inflow_positive_days,
        COUNT(*) AS total_days
    FROM capital_analysis
    GROUP BY scode, sname
)
SELECT 
    scode AS '股票代码',
    sname AS '股票名称',
    ROUND(inflow_price_corr, 4) AS '资金价格相关性',
    ROUND(inflow_positive_days * 100.0 / total_days, 2) AS '资金净流入天数占比(%)',
    CASE 
        WHEN inflow_price_corr > 0.7 THEN '强正相关'
        WHEN inflow_price_corr > 0.3 THEN '正相关'
        WHEN inflow_price_corr > -0.3 THEN '弱相关'
        WHEN inflow_price_corr > -0.7 THEN '负相关'
        ELSE '强负相关'
    END AS '相关性强度'
FROM correlation_analysis
WHERE inflow_price_corr IS NOT NULL
ORDER BY ABS(inflow_price_corr) DESC;


-- 四、创建视图和存储过程
-- 1. 创建视图加速查询
-- 每日行情汇总视图
CREATE OR REPLACE VIEW v_daily_summary AS
SELECT 
    d.trade_date,
    c.industry,
    COUNT(DISTINCT d.scode) AS stock_count,
    ROUND(AVG(d.pct_change), 2) AS avg_pct_change,
    ROUND(SUM(d.amount), 2) AS total_amount,
    SUM(d.volume) AS total_volume,
    SUM(CASE WHEN d.pct_change > 0 THEN 1 ELSE 0 END) AS up_count,
    SUM(CASE WHEN d.pct_change < 0 THEN 1 ELSE 0 END) AS down_count,
    ROUND(AVG(d.pe_ratio), 2) AS avg_pe,
    ROUND(AVG(d.pb_ratio), 2) AS avg_pb
FROM stk_daily d
INNER JOIN stk_code c ON d.scode = c.scode
WHERE d.trade_date >= '2024-01-01'
GROUP BY d.trade_date, c.industry
ORDER BY d.trade_date DESC, c.industry;

-- 股票综合信息视图
CREATE OR REPLACE VIEW v_stock_comprehensive AS
SELECT 
    c.scode,
    c.sname,
    c.industry,
    d.trade_date,
    d.close_price,
    d.pct_change,
    d.volume,
    d.amount,
    f.roe,
    f.eps,
    cp.main_inflow,
    ROW_NUMBER() OVER (PARTITION BY c.industry ORDER BY d.close_price DESC) AS industry_price_rank,
    ROW_NUMBER() OVER (PARTITION BY c.industry ORDER BY f.roe DESC) AS industry_roe_rank
FROM stk_code c
LEFT JOIN stk_daily d ON c.scode = d.scode 
    AND d.trade_date = (SELECT MAX(trade_date) FROM stk_daily)
LEFT JOIN stk_finance f ON c.scode = f.scode 
    AND f.report_date = (SELECT MAX(report_date) FROM stk_finance WHERE scode = c.scode)
LEFT JOIN stk_capital cp ON c.scode = cp.scode 
    AND cp.trade_date = (SELECT MAX(trade_date) FROM stk_daily)
WHERE c.status = '1';


-- 2. 创建存储过程
-- 计算股票技术指标存储过程
-- 删除已存在的存储过程
DROP PROCEDURE IF EXISTS sp_get_tech_indicators;

DELIMITER //

CREATE PROCEDURE sp_get_tech_indicators(
    IN p_scode VARCHAR(6) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- 使用多个CTE逐步计算
    WITH base_data AS (
        SELECT 
            trade_date,
            close_price,
            high_price,
            low_price,
            volume,
            LAG(close_price, 1) OVER (ORDER BY trade_date) AS prev_close
        FROM stk_daily
        WHERE scode = p_scode COLLATE utf8mb4_unicode_ci
            AND trade_date BETWEEN p_start_date AND p_end_date
    ),
    with_gain_loss AS (
        SELECT 
            trade_date,
            close_price,
            high_price,
            low_price,
            volume,
            CASE 
                WHEN close_price > prev_close THEN close_price - prev_close
                ELSE 0 
            END AS gain,
            CASE 
                WHEN close_price < prev_close THEN prev_close - close_price
                ELSE 0 
            END AS loss
        FROM base_data
    ),
    with_ma AS (
        SELECT 
            trade_date,
            close_price,
            high_price,
            low_price,
            volume,
            gain,
            loss,
            -- 移动平均
            AVG(close_price) OVER (
                ORDER BY trade_date 
                ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
            ) AS ma5,
            AVG(close_price) OVER (
                ORDER BY trade_date 
                ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
            ) AS ma20,
            AVG(close_price) OVER (
                ORDER BY trade_date 
                ROWS BETWEEN 59 PRECEDING AND CURRENT ROW
            ) AS ma60,
            -- 标准差
            STDDEV(close_price) OVER (
                ORDER BY trade_date 
                ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
            ) AS std20
        FROM with_gain_loss
    ),
    with_rsi AS (
        SELECT 
            trade_date,
            close_price,
            high_price,
            low_price,
            volume,
            ma5,
            ma20,
            ma60,
            std20,
            AVG(gain) OVER (
                ORDER BY trade_date 
                ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
            ) AS avg_gain_14,
            AVG(loss) OVER (
                ORDER BY trade_date 
                ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
            ) AS avg_loss_14
        FROM with_ma
    )
    SELECT 
        trade_date AS '交易日期',
        ROUND(close_price, 2) AS '收盘价',
        ROUND(high_price, 2) AS '最高价',
        ROUND(low_price, 2) AS '最低价',
        volume AS '成交量',
        ROUND(ma5, 2) AS 'MA5',
        ROUND(ma20, 2) AS 'MA20',
        ROUND(ma60, 2) AS 'MA60',
        ROUND(ma5 - ma20, 2) AS 'MACD差值',
        ROUND(ma20 + 2 * std20, 2) AS '布林上轨',
        ROUND(ma20 - 2 * std20, 2) AS '布林下轨',
        ROUND(
            CASE 
                WHEN avg_loss_14 = 0 THEN 100
                ELSE 100 - 100 / (1 + avg_gain_14 / avg_loss_14)
            END, 2
        ) AS 'RSI14'
    FROM with_rsi
    ORDER BY trade_date;
END//

DELIMITER ;

-- 测试调用
CALL sp_get_tech_indicators('000001', '2024-01-01', '2024-01-15');

SELECT VERSION();

-- 创建函数
-- 先删除原有函数
DROP FUNCTION IF EXISTS fn_calculate_return;

-- 重新创建函数，指定排序规则
DELIMITER //

CREATE FUNCTION fn_calculate_return(
    p_scode VARCHAR(6) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
    p_start_date DATE,
    p_end_date DATE
) RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_start_price DECIMAL(10,2);
    DECLARE v_end_price DECIMAL(10,2);
    DECLARE v_return DECIMAL(10,2);
    
    -- 获取起始价格
    SELECT close_price INTO v_start_price
    FROM stk_daily
    WHERE scode = p_scode COLLATE utf8mb4_unicode_ci 
        AND trade_date = p_start_date;
    
    -- 获取结束价格
    SELECT close_price INTO v_end_price
    FROM stk_daily
    WHERE scode = p_scode COLLATE utf8mb4_unicode_ci
        AND trade_date = p_end_date;
    
    -- 计算收益率
    IF v_start_price IS NOT NULL AND v_start_price > 0 THEN
        SET v_return = ROUND((v_end_price - v_start_price) / v_start_price * 100, 2);
    ELSE
        SET v_return = NULL;
    END IF;
    
    RETURN v_return;
END//

DELIMITER ;

-- 使用函数
SELECT 
    scode,
    sname,
    fn_calculate_return(scode, '2024-01-02', '2024-01-31') AS return_rate
FROM stk_code
WHERE status = '1';


-- 五、触发器示例
-- 创建审计日志表
CREATE TABLE stk_daily_audit2 (
    id INT AUTO_INCREMENT PRIMARY KEY,
    scode VARCHAR(6),
    trade_date DATE,
    old_close_price DECIMAL(10,2),
    new_close_price DECIMAL(10,2),
    change_pct DECIMAL(6,2),
    action_type ENUM('INSERT', 'UPDATE', 'DELETE'),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_name VARCHAR(50)
);

-- 创建触发器记录价格变更
DELIMITER //

CREATE TRIGGER trg_stk_daily_audit
AFTER UPDATE ON stk_daily
FOR EACH ROW
BEGIN
    DECLARE v_change_pct DECIMAL(6,2);
    
    IF OLD.close_price != NEW.close_price THEN
        SET v_change_pct = ROUND((NEW.close_price - OLD.close_price) / OLD.close_price * 100, 2);
        
        INSERT INTO stk_daily_audit2 (
            scode, 
            trade_date, 
            old_close_price, 
            new_close_price, 
            change_pct, 
            action_type, 
            user_name
        ) VALUES (
            NEW.scode,
            NEW.trade_date,
            OLD.close_price,
            NEW.close_price,
            v_change_pct,
            'UPDATE',
            USER()
        );
    END IF;
END//

DELIMITER ;

-- 测试触发器
UPDATE stk_daily 
SET close_price = close_price * 1.05  -- 上涨5%
WHERE scode = '000001' 
    AND trade_date = '2024-01-15';
    
SELECT * FROM stk_daily_audit2;

-- 六、事件调度（定时任务）

-- 启用事件调度器
SET GLOBAL event_scheduler = ON;

-- 创建每日汇总事件
DELIMITER //

CREATE EVENT ev_daily_summary2
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '18:00:00')
DO
BEGIN
    -- 插入每日汇总数据
    INSERT INTO daily_market_summary (
        summary_date,
        total_stocks,
        avg_pct_change,
        total_amount,
        up_count,
        down_count
    )
    SELECT 
        trade_date,
        COUNT(DISTINCT scode),
        ROUND(AVG(pct_change), 2),
        ROUND(SUM(amount), 2),
        SUM(CASE WHEN pct_change > 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN pct_change < 0 THEN 1 ELSE 0 END)
    FROM stk_daily
    WHERE trade_date = CURDATE() - INTERVAL 1 DAY
    GROUP BY trade_date;
    
    -- 记录日志
    INSERT INTO event_log (event_name, run_time, status)
    VALUES ('ev_daily_summary', NOW(), 'SUCCESS');
END//

DELIMITER ;


-- 七、性能优化
-- 1. 创建复合索引
-- 为常用查询创建复合索引
CREATE INDEX idx_daily_scode_date ON stk_daily(scode, trade_date DESC);
CREATE INDEX idx_finance_scode_report ON stk_finance(scode, report_date DESC);
CREATE INDEX idx_capital_scode_date ON stk_capital(scode, trade_date DESC);

-- 创建全文索引（用于股票名称搜索）
ALTER TABLE stk_code ADD FULLTEXT INDEX idx_sname_fulltext (sname);

-- 使用全文索引搜索
SELECT * FROM stk_code 
WHERE MATCH(sname) AGAINST('平安' IN NATURAL LANGUAGE MODE);

-- 添加新分区
ALTER TABLE stk_daily REORGANIZE PARTITION p_future INTO (
    PARTITION p_2025 VALUES LESS THAN ('2026-01-01'),
    PARTITION p_future VALUES LESS THAN (MAXVALUE)
);

-- 删除旧分区
ALTER TABLE stk_daily DROP PARTITION p_2020;


-- 八、完整查询练习
-- 练习1：寻找"黄金交叉"股票
-- 方法一
WITH moving_averages AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        -- 计算5日均线
        AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS ma5,
        -- 计算20日均线
        AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS ma20
    FROM stk_daily
),
ma_with_lag AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        ma5,
        ma20,
        -- 获取前一天的5日均线
        LAG(ma5, 1) OVER (
            PARTITION BY scode 
            ORDER BY trade_date
        ) AS ma5_yesterday,
        -- 获取前一天的20日均线
        LAG(ma20, 1) OVER (
            PARTITION BY scode 
            ORDER BY trade_date
        ) AS ma20_yesterday
    FROM moving_averages
),
golden_cross AS (
    SELECT DISTINCT
        m.scode,
        m.trade_date,
        m.close_price,
        ROUND(m.ma5, 2) AS ma5,
        ROUND(m.ma20, 2) AS ma20
    FROM ma_with_lag m
    WHERE m.ma5_yesterday <= m.ma20_yesterday  -- 昨日5日线在20日线下
        AND m.ma5 > m.ma20                      -- 今日5日线上穿20日线
        AND m.trade_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT 
    c.sname AS '股票名称',
    g.scode AS '股票代码',
    g.trade_date AS '交叉日期',
    g.close_price AS '收盘价',
    g.ma5 AS '5日均线',
    g.ma20 AS '20日均线',
    ROUND(g.ma5 - g.ma20, 2) AS '差值',
    f.roe AS 'ROE(%)',
    d.main_inflow AS '主力流入(万)'
FROM golden_cross g
JOIN stk_code c ON g.scode = c.scode
LEFT JOIN (
    SELECT scode, MAX(report_date) as latest_date
    FROM stk_finance
    GROUP BY scode
) f_latest ON g.scode = f_latest.scode
LEFT JOIN stk_finance f ON g.scode = f.scode AND f.report_date = f_latest.latest_date
LEFT JOIN stk_capital d ON g.scode = d.scode AND d.trade_date = g.trade_date
WHERE c.status = '1'
ORDER BY g.trade_date DESC, (g.ma5 - g.ma20) DESC;


-- 方法二使用子查询
WITH ma_calculations AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        AVG(close_price) OVER w5 AS ma5,
        AVG(close_price) OVER w20 AS ma20
    FROM stk_daily
    WINDOW 
        w5 AS (PARTITION BY scode ORDER BY trade_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW),
        w20 AS (PARTITION BY scode ORDER BY trade_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW)
),
golden_cross AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        ROUND(ma5, 2) AS ma5,
        ROUND(ma20, 2) AS ma20,
        ROUND(LAG(ma5, 1) OVER (PARTITION BY scode ORDER BY trade_date), 2) AS ma5_yesterday,
        ROUND(LAG(ma20, 1) OVER (PARTITION BY scode ORDER BY trade_date), 2) AS ma20_yesterday
    FROM ma_calculations
    WHERE trade_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT 
    c.sname AS '股票名称',
    g.scode AS '股票代码',
    g.trade_date AS '交叉日期',
    g.close_price AS '收盘价',
    g.ma5 AS '5日均线',
    g.ma20 AS '20日均线',
    ROUND(g.ma5 - g.ma20, 2) AS '差值',
    f.roe AS 'ROE(%)',
    d.main_inflow AS '主力流入(万)'
FROM golden_cross g
JOIN stk_code c ON g.scode = c.scode
LEFT JOIN (
    SELECT scode, MAX(report_date) as latest_date
    FROM stk_finance
    GROUP BY scode
) f_latest ON g.scode = f_latest.scode
LEFT JOIN stk_finance f ON g.scode = f.scode AND f.report_date = f_latest.latest_date
LEFT JOIN stk_capital d ON g.scode = d.scode AND d.trade_date = g.trade_date
WHERE c.status = '1'
    AND g.ma5_yesterday <= g.ma20_yesterday
    AND g.ma5 > g.ma20
ORDER BY g.trade_date DESC, (g.ma5 - g.ma20) DESC;

-- 三
-- 第一步：计算移动平均
WITH ma_data AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        ROUND(AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ), 2) AS ma5,
        ROUND(AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ), 2) AS ma20
    FROM stk_daily
    WHERE trade_date >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)  -- 多取一些数据
),
-- 第二步：计算前一天的移动平均
ma_with_lag AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        ma5,
        ma20,
        LAG(ma5, 1) OVER (
            PARTITION BY scode 
            ORDER BY trade_date
        ) AS ma5_yesterday,
        LAG(ma20, 1) OVER (
            PARTITION BY scode 
            ORDER BY trade_date
        ) AS ma20_yesterday
    FROM ma_data
),
-- 第三步：筛选黄金交叉
golden_cross AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        ma5,
        ma20
    FROM ma_with_lag
    WHERE ma5_yesterday <= ma20_yesterday
        AND ma5 > ma20
        AND trade_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
-- 第四步：关联其他信息
SELECT 
    c.sname AS '股票名称',
    g.scode AS '股票代码',
    g.trade_date AS '交叉日期',
    g.close_price AS '收盘价',
    g.ma5 AS '5日均线',
    g.ma20 AS '20日均线',
    ROUND(g.ma5 - g.ma20, 2) AS '差值',
    f.roe AS 'ROE(%)',
    d.main_inflow AS '主力流入(万)'
FROM golden_cross g
JOIN stk_code c ON g.scode = c.scode
LEFT JOIN (
    SELECT scode, MAX(report_date) as latest_date
    FROM stk_finance
    GROUP BY scode
) f_latest ON g.scode = f_latest.scode
LEFT JOIN stk_finance f ON g.scode = f.scode AND f.report_date = f_latest.latest_date
LEFT JOIN stk_capital d ON g.scode = d.scode AND d.trade_date = g.trade_date
WHERE c.status = '1'
ORDER BY g.trade_date DESC, (g.ma5 - g.ma20) DESC;

-- 四完全避免嵌套函数
WITH daily_ma AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        -- 计算5日均线
        AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS ma5_raw,
        -- 计算20日均线
        AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS ma20_raw
    FROM stk_daily
    WHERE trade_date >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)  -- 多取一些数据
),
formatted_ma AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        ROUND(ma5_raw, 2) AS ma5,
        ROUND(ma20_raw, 2) AS ma20,
        ROUND(LAG(ma5_raw, 1) OVER (PARTITION BY scode ORDER BY trade_date), 2) AS ma5_yesterday,
        ROUND(LAG(ma20_raw, 1) OVER (PARTITION BY scode ORDER BY trade_date), 2) AS ma20_yesterday
    FROM daily_ma
)
SELECT 
    c.sname AS '股票名称',
    f.scode AS '股票代码',
    f.trade_date AS '交叉日期',
    f.close_price AS '收盘价',
    f.ma5 AS '5日均线',
    f.ma20 AS '20日均线',
    ROUND(f.ma5 - f.ma20, 2) AS '差值',
    fi.roe AS 'ROE(%)',
    ca.main_inflow AS '主力流入(万)'
FROM formatted_ma f
JOIN stk_code c ON f.scode = c.scode
LEFT JOIN stk_finance fi ON f.scode = fi.scode 
    AND fi.report_date = (
        SELECT MAX(report_date) 
        FROM stk_finance 
        WHERE scode = f.scode
    )
LEFT JOIN stk_capital ca ON f.scode = ca.scode AND ca.trade_date = f.trade_date
WHERE c.status = '1'
    AND f.ma5_yesterday <= f.ma20_yesterday
    AND f.ma5 > f.ma20
    AND f.trade_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY f.trade_date DESC, (f.ma5 - f.ma20) DESC;
