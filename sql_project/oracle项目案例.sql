-- 综合金融案例：股票分析系统
-- 一、创建数据库表结构
-- 1. 基础表：股票代码表
-- 股票代码表
CREATE TABLE stk_code (
    scode      VARCHAR2(6) PRIMARY KEY,      -- 股票代码
    sname      VARCHAR2(50) NOT NULL,        -- 股票名称
    market     VARCHAR2(10) DEFAULT 'SZ',     -- 市场：SZ-深市, SH-沪市, BJ-北交
    industry   VARCHAR2(50),                 -- 行业分类
    list_date  DATE,                         -- 上市日期
    delist_date DATE,                        -- 退市日期
    status     VARCHAR2(1) DEFAULT '1'       -- 状态：1-正常, 0-停牌, 9-退市
);

-- 创建索引
CREATE INDEX idx_stk_market ON stk_code(market);
CREATE INDEX idx_stk_industry ON stk_code(industry);
CREATE BITMAP INDEX idx_stk_status ON stk_code(status);

select * from stk_code;

-- 2. 核心表：行情数据表
-- 日行情表（分区表提高查询性能）
CREATE TABLE stk_daily (
    scode      VARCHAR2(6),                   -- 股票代码
    trade_date DATE,                          -- 交易日期
    open_price NUMBER(10,2),                  -- 开盘价
    close_price NUMBER(10,2),                 -- 收盘价
    high_price  NUMBER(10,2),                 -- 最高价
    low_price   NUMBER(10,2),                 -- 最低价
    volume      NUMBER(15),                   -- 成交量(手)
    amount      NUMBER(20,2),                 -- 成交额(万元)
    pct_change  NUMBER(6,2),                  -- 涨跌幅%
    pe_ratio    NUMBER(8,2),                 -- 市盈率
    pb_ratio    NUMBER(6,2),                 -- 市净率
    turnover_rate NUMBER(6,2),               -- 换手率%
    CONSTRAINT pk_stk_daily PRIMARY KEY (scode, trade_date)
)
PARTITION BY RANGE (trade_date) (
    PARTITION p_2020 VALUES LESS THAN (DATE '2021-01-01'),
    PARTITION p_2021 VALUES LESS THAN (DATE '2022-01-01'),
    PARTITION p_2022 VALUES LESS THAN (DATE '2023-01-01'),
    PARTITION p_2023 VALUES LESS THAN (DATE '2024-01-01'),
    PARTITION p_2024 VALUES LESS THAN (DATE '2025-01-01'),
    PARTITION p_future VALUES LESS THAN (MAXVALUE) -- 分区函数
);

-- 创建索引
CREATE INDEX idx_daily_date ON stk_daily(trade_date);
CREATE INDEX idx_daily_pct ON stk_daily(pct_change);
CREATE INDEX idx_daily_volume ON stk_daily(volume);


select * from stk_daily;

-- 财务指标表
CREATE TABLE stk_finance (
    scode       VARCHAR2(6),                  -- 股票代码
    report_date DATE,                         -- 报告期
    report_type VARCHAR2(2),                  -- 报告类型：Q1-一季报, HY-半年报, Q3-三季报, A-年报
    revenue     NUMBER(20,2),                 -- 营业收入(亿元)
    net_profit  NUMBER(20,2),                 -- 净利润(亿元)
    roe         NUMBER(6,2),                  -- 净资产收益率%
    gross_margin NUMBER(6,2),                 -- 毛利率%
    debt_ratio  NUMBER(6,2),                 -- 资产负债率%
    eps         NUMBER(6,2),                  -- 每股收益
    bvps        NUMBER(8,2),                  -- 每股净资产
    total_assets NUMBER(20,2),               -- 总资产(亿元)
    CONSTRAINT pk_stk_finance PRIMARY KEY (scode, report_date, report_type)
);

CREATE INDEX idx_finance_date ON stk_finance(report_date);
CREATE INDEX idx_finance_roe ON stk_finance(roe);

select * from stk_finance;

-- 资金流向表
CREATE TABLE stk_capital (
    scode      VARCHAR2(6),
    trade_date DATE,
    main_inflow   NUMBER(15,2),              -- 主力净流入(万元)
    retail_inflow NUMBER(15,2),               -- 散户净流入(万元)
    north_inflow  NUMBER(15,2),               -- 北向资金净流入(万元)
    buy_volume    NUMBER(15),                 -- 大单买入量(手)
    sell_volume   NUMBER(15),                 -- 大单卖出量(手)
    CONSTRAINT pk_stk_capital PRIMARY KEY (scode, trade_date)
);


-- 二、插入示例数据
-- 1. 插入股票代码数据
INSERT INTO stk_code VALUES ('000001', '平安银行', 'SZ', '银行', DATE '1991-04-03', NULL, '1');
INSERT INTO stk_code VALUES ('000002', '万科A', 'SZ', '房地产', DATE '1991-01-29', NULL, '1');
INSERT INTO stk_code VALUES ('600519', '贵州茅台', 'SH', '食品饮料', DATE '2001-08-27', NULL, '1');
INSERT INTO stk_code VALUES ('601318', '中国平安', 'SH', '保险', DATE '2007-03-01', NULL, '1');
INSERT INTO stk_code VALUES ('300750', '宁德时代', 'SZ', '电力设备', DATE '2018-06-11', NULL, '1');

-- 2. 插入行情数据（模拟2024年1月数据）
DECLARE
    v_date DATE := DATE '2024-01-02';
BEGIN
    FOR i IN 1..20 LOOP
        INSERT INTO stk_daily VALUES ('000001', v_date, 10.5, 10.8, 11.0, 10.3, 
                                     1000000, 10800, 2.86, 8.5, 0.85, 2.5);
        INSERT INTO stk_daily VALUES ('000002', v_date, 8.2, 8.5, 8.8, 8.0, 
                                     800000, 6800, 3.66, 7.2, 0.92, 1.8);
        INSERT INTO stk_daily VALUES ('600519', v_date, 1680, 1700, 1720, 1675, 
                                     50000, 85000, 1.19, 35.5, 12.3, 0.8);
        v_date := v_date + 1;
        -- 跳过周末
        IF TO_CHAR(v_date, 'D') IN ('1','7') THEN
            v_date := v_date + 2;
        END IF;
    END LOOP;
    COMMIT;
END;
/---新知识语法

-- 3. 插入财务数据
INSERT INTO stk_finance VALUES ('000001', DATE '2023-12-31', 'A', 1798.36, 464.55, 10.3, 28.5, 92.1, 1.98, 19.23, 55800);
INSERT INTO stk_finance VALUES ('600519', DATE '2023-12-31', 'A', 1476.94, 747.34, 33.5, 91.8, 22.3, 59.49, 177.4, 2830);
INSERT INTO stk_finance VALUES ('300750', DATE '2023-12-31', 'A', 4009.17, 441.21, 22.8, 21.4, 73.2, 10.05, 44.13, 7610);

-- 4. 插入资金流向数据
INSERT INTO stk_capital VALUES ('000001', DATE '2024-01-15', 12500.5, -3200.2, 8500.3, 50000, 32000);
INSERT INTO stk_capital VALUES ('600519', DATE '2024-01-15', 85000.8, -12000.5, 65000.2, 20000, 15000);


-- 三、综合查询案例
--案例1：多表关联查询 - 股票基本信息与行情
-- 查询2024年1月15日所有股票行情
SELECT 
    c.scode AS 股票代码,
    c.sname AS 股票名称,
    c.industry AS 行业,
    d.trade_date AS 交易日期,
    d.close_price AS 收盘价,
    d.pct_change AS 涨跌幅,
    d.volume AS 成交量,
    d.amount AS 成交额,
    f.roe AS 净资产收益率,
    cp.main_inflow AS 主力净流入
FROM stk_code c
JOIN stk_daily d ON c.scode = d.scode 
    AND d.trade_date = DATE '2024-01-15'
LEFT JOIN stk_finance f ON c.scode = f.scode 
    AND f.report_date = (SELECT MAX(report_date) FROM stk_finance WHERE scode = c.scode)
LEFT JOIN stk_capital cp ON c.scode = cp.scode 
    AND cp.trade_date = DATE '2024-01-15'
WHERE c.status = '1'
ORDER BY d.amount DESC;

--案例2：窗口函数应用 - 技术指标计算
-- 计算每只股票的移动平均线、RSI等技术指标
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
        -- 计算RSI（相对强弱指数）的组成部分
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
    WHERE trade_date >= DATE '2024-01-01'
)
SELECT 
    p.*,
    c.sname,
    -- 计算RSI（14日）
    100 - 100 / (1 + 
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
    ) AS rsi14,
    -- 计算MACD信号
    (ma5 - ma20) AS macd_diff,
    -- 成交量5日平均
    AVG(volume) OVER (
        PARTITION BY scode 
        ORDER BY trade_date 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS volume_ma5
FROM price_data p
JOIN stk_code c ON p.scode = c.scode
WHERE c.sname = '平安银行'
ORDER BY p.scode, p.trade_date;

-- 案例3：递归CTE - 计算连续上涨天数
-- 找出连续上涨超过3天的股票
WITH RECURSIVE consecutive_up AS (
    -- 锚点：每只股票的每个上涨起点
    SELECT 
        scode,
        trade_date,
        close_price,
        1 AS up_days,
        trade_date AS start_date
    FROM stk_daily d1
    WHERE close_price > (
        SELECT close_price 
        FROM stk_daily d2 
        WHERE d2.scode = d1.scode 
        AND d2.trade_date = d1.trade_date - 1
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
    JOIN consecutive_up cu ON d.scode = cu.scode 
        AND d.trade_date = cu.trade_date + 1
    WHERE d.close_price > cu.close_price
)
SELECT 
    c.sname,
    cu.scode,
    cu.start_date,
    MAX(cu.trade_date) AS end_date,
    MAX(cu.up_days) AS consecutive_days,
    ROUND(
        (MAX(d2.close_price) - MIN(d1.close_price)) / MIN(d1.close_price) * 100, 
        2
    ) AS total_increase_pct
FROM consecutive_up cu
JOIN stk_code c ON cu.scode = c.scode
JOIN stk_daily d1 ON cu.scode = d1.scode AND cu.start_date = d1.trade_date
JOIN stk_daily d2 ON cu.scode = d2.scode AND cu.trade_date = d2.trade_date
WHERE cu.up_days >= 3
GROUP BY c.sname, cu.scode, cu.start_date
ORDER BY consecutive_days DESC;

-- 案例4：子查询应用 - 龙头股筛选
-- 筛选行业龙头（市值最大、ROE最高）
SELECT 
    industry,
    sname AS 股票名称,
    scode AS 股票代码,
    market_cap AS 市值,
    roe,
    ranking
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
            ORDER BY f.roe DESC NULLS LAST
        ) AS roe_rank,
        -- 综合排名
        ROW_NUMBER() OVER (
            PARTITION BY c.industry 
            ORDER BY (d.close_price * 10000) * 0.7 + f.roe * 0.3 DESC
        ) AS ranking
    FROM stk_code c
    JOIN stk_daily d ON c.scode = d.scode 
        AND d.trade_date = (SELECT MAX(trade_date) FROM stk_daily)
    LEFT JOIN (
        SELECT scode, MAX(roe) AS roe
        FROM stk_finance
        WHERE report_date >= ADD_MONTHS(SYSDATE, -12)
        GROUP BY scode
    ) f ON c.scode = f.scode
    WHERE c.status = '1' AND c.industry IS NOT NULL
) t
WHERE ranking = 1  -- 各行业第一名
ORDER BY market_cap DESC;


-- 案例5：复杂分析 - 资金流向与股价关系
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
        -- 计算资金与价格的相关性
        AVG(c.main_inflow) OVER (
            PARTITION BY c.scode 
            ORDER BY c.trade_date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS ma5_inflow,
        AVG(d.pct_change) OVER (
            PARTITION BY c.scode 
            ORDER BY c.trade_date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS ma5_pct_change
    FROM stk_capital c
    JOIN stk_daily d ON c.scode = d.scode AND c.trade_date = d.trade_date
    JOIN stk_code s ON c.scode = s.scode
    WHERE c.trade_date >= DATE '2024-01-01'
),
correlation_analysis AS (
    SELECT 
        scode,
        sname,
        -- 计算相关性
        ROUND(
            CORR(main_inflow, pct_change) OVER (PARTITION BY scode), 
            4
        ) AS inflow_price_corr,
        ROUND(
            CORR(ma5_inflow, ma5_pct_change) OVER (PARTITION BY scode), 
            4
        ) AS ma5_inflow_price_corr,
        -- 统计资金净流入天数
        COUNT(CASE WHEN main_inflow > 0 THEN 1 END) 
            OVER (PARTITION BY scode) AS inflow_positive_days,
        COUNT(*) OVER (PARTITION BY scode) AS total_days
    FROM capital_analysis
)
SELECT DISTINCT
    scode AS 股票代码,
    sname AS 股票名称,
    inflow_price_corr AS 资金价格当日相关性,
    ma5_inflow_price_corr AS 资金价格5日相关性,
    ROUND(inflow_positive_days * 100.0 / total_days, 2) AS 资金净流入天数占比,
    CASE 
        WHEN inflow_price_corr > 0.7 THEN '强正相关'
        WHEN inflow_price_corr > 0.3 THEN '正相关'
        WHEN inflow_price_corr > -0.3 THEN '弱相关'
        WHEN inflow_price_corr > -0.7 THEN '负相关'
        ELSE '强负相关'
    END AS 相关性强度
FROM correlation_analysis
WHERE inflow_price_corr IS NOT NULL
ORDER BY ABS(inflow_price_corr) DESC;


-- 四、创建物化视图和索引优化
-- 1. 创建物化视图加速复杂查询
-- 每日行情汇总物化视图
CREATE MATERIALIZED VIEW mv_daily_summary
REFRESH COMPLETE ON DEMAND
AS
SELECT 
    d.trade_date,
    c.industry,
    COUNT(DISTINCT d.scode) AS stock_count,
    AVG(d.pct_change) AS avg_pct_change,
    SUM(d.amount) AS total_amount,
    SUM(d.volume) AS total_volume,
    COUNT(CASE WHEN d.pct_change > 0 THEN 1 END) AS up_count,
    COUNT(CASE WHEN d.pct_change < 0 THEN 1 END) AS down_count,
    AVG(f.pe_ratio) AS avg_pe,
    AVG(f.pb_ratio) AS avg_pb
FROM stk_daily d
JOIN stk_code c ON d.scode = c.scode
LEFT JOIN stk_finance f ON d.scode = f.scode 
    AND f.report_date = (
        SELECT MAX(report_date) 
        FROM stk_finance f2 
        WHERE f2.scode = f.scode 
        AND f2.report_date <= d.trade_date
    )
WHERE d.trade_date >= DATE '2024-01-01'
GROUP BY d.trade_date, c.industry;

-- 创建索引加速刷新
CREATE INDEX idx_mv_daily_date ON mv_daily_summary(trade_date);
CREATE INDEX idx_mv_daily_industry ON mv_daily_summary(industry);


-- 2. 创建函数封装复杂逻辑
-- 计算股票技术指标函数
CREATE OR REPLACE FUNCTION get_technical_indicators(
    p_scode IN VARCHAR2,
    p_start_date IN DATE,
    p_end_date IN DATE
) RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
    WITH tech_data AS (
        SELECT 
            trade_date,
            close_price,
            high_price,
            low_price,
            volume,
            -- 移动平均
            AVG(close_price) OVER (ORDER BY trade_date ROWS 4 PRECEDING) AS ma5,
            AVG(close_price) OVER (ORDER BY trade_date ROWS 19 PRECEDING) AS ma20,
            AVG(close_price) OVER (ORDER BY trade_date ROWS 59 PRECEDING) AS ma60,
            -- 布林带
            AVG(close_price) OVER (ORDER BY trade_date ROWS 19 PRECEDING) 
                + 2 * STDDEV(close_price) OVER (ORDER BY trade_date ROWS 19 PRECEDING) AS boll_upper,
            AVG(close_price) OVER (ORDER BY trade_date ROWS 19 PRECEDING) 
                - 2 * STDDEV(close_price) OVER (ORDER BY trade_date ROWS 19 PRECEDING) AS boll_lower
        FROM stk_daily
        WHERE scode = p_scode
        AND trade_date BETWEEN p_start_date AND p_end_date
    )
    SELECT * FROM tech_data
    ORDER BY trade_date;
    
    RETURN v_cursor;
END;
/

-- 使用函数
DECLARE
    v_cur SYS_REFCURSOR;
    v_row tech_data%ROWTYPE;
BEGIN
    v_cur := get_technical_indicators('000001', DATE '2024-01-01', DATE '2024-01-31');
    LOOP
        FETCH v_cur INTO v_row;
        EXIT WHEN v_cur%NOTFOUND;
        -- 处理数据
        DBMS_OUTPUT.PUT_LINE(v_row.trade_date || ': ' || v_row.close_price);
    END LOOP;
    CLOSE v_cur;
END;
/

-- 五、性能优化建议
-- 1. 执行计划分析
-- 查看执行计划
EXPLAIN PLAN FOR
SELECT * FROM (
    -- 复杂查询
);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- 收集统计信息
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => 'STOCK_USER',
        tabname => 'STK_DAILY',
        estimate_percent => 20,
        cascade => TRUE
    );
END;
/
-- 分区维护
-- 添加新分区
ALTER TABLE stk_daily ADD PARTITION p_2025 
VALUES LESS THAN (DATE '2026-01-01');

-- 合并旧分区
ALTER TABLE stk_daily MERGE PARTITIONS p_2020, p_2021 
INTO PARTITION p_2020_2021;


-- 六、完整查询练习
-- 练习1：选股策略
-- 寻找"黄金交叉"股票（5日均线上穿20日均线）
WITH moving_averages AS (
    SELECT 
        scode,
        trade_date,
        close_price,
        AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS ma5,
        AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS ma20,
        LAG(AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ), 1) OVER (PARTITION BY scode ORDER BY trade_date) AS ma5_yesterday,
        LAG(AVG(close_price) OVER (
            PARTITION BY scode 
            ORDER BY trade_date 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ), 1) OVER (PARTITION BY scode ORDER BY trade_date) AS ma20_yesterday
    FROM stk_daily
    WHERE trade_date >= DATE '2024-01-01'
)
SELECT 
    c.sname,
    m.scode,
    m.trade_date,
    m.close_price,
    ROUND(m.ma5, 2) AS ma5,
    ROUND(m.ma20, 2) AS ma20,
    f.roe,
    d.main_inflow
FROM moving_averages m
JOIN stk_code c ON m.scode = c.scode
LEFT JOIN stk_finance f ON m.scode = f.scode 
    AND f.report_date = (SELECT MAX(report_date) FROM stk_finance WHERE scode = m.scode)
LEFT JOIN stk_capital d ON m.scode = d.scode AND m.trade_date = d.trade_date
WHERE m.ma5_yesterday <= m.ma20_yesterday  -- 昨日5日线在20日线下
    AND m.ma5 > m.ma20  -- 今日5日线上穿20日线
    AND c.status = '1'
ORDER BY m.trade_date DESC, m.ma5 - m.ma20 DESC;
