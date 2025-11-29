-- =============================================
-- PROJECT 4: MARKETING CAMPAIGN ANALYTICS (SQL)
-- =============================================

-- 1) CREATE DATABASE
CREATE DATABASE marketing_campaign_analytics;
USE marketing_campaign_analytics;

-- =============================================
-- 2) CREATE TABLES
-- =============================================

-- CUSTOMER ACQUISITION TABLE
CREATE TABLE customer_acquisition (
    customer_id VARCHAR(50),
    acquisition_date DATE,
    campaign_id VARCHAR(50),
    campaign_name VARCHAR(200),
    channel VARCHAR(100),
    first_order_value DECIMAL(10,2),
    country VARCHAR(100),
    device VARCHAR(50),
    is_retained_30d INT,
    campaign_id_norm VARCHAR(50),
    campaign_key INT
);

-- CAMPAIGN PERFORMANCE TABLE
CREATE TABLE campaign_performance (
    date DATE,
    campaign_id VARCHAR(50),
    campaign_name VARCHAR(200),
    channel VARCHAR(100),
    ad_group VARCHAR(100),
    impressions INT,
    clicks INT,
    spend DECIMAL(10,2),
    revenue DECIMAL(10,2),
    country VARCHAR(100),
    device VARCHAR(50),
    ctr DECIMAL(10,4),
    cpc DECIMAL(10,4),
    roas DECIMAL(10,4),
    campaign_id_norm VARCHAR(50),
    campaign_key INT
);

-- =============================================
-- 3) BASIC DATA CLEANING QUERIES
-- =============================================

-- Remove blank or null campaign IDs
DELETE FROM customer_acquisition
WHERE campaign_key IS NULL;

DELETE FROM campaign_performance
WHERE campaign_key IS NULL;

-- Standardize channel formatting
UPDATE customer_acquisition
SET channel = TRIM(LOWER(channel));

UPDATE campaign_performance
SET channel = TRIM(LOWER(channel));

-- =============================================
-- 4) KPI QUERIES
-- =============================================

-- Total Impressions
SELECT SUM(impressions) AS total_impressions
FROM campaign_performance;

-- Total Clicks
SELECT SUM(clicks) AS total_clicks
FROM campaign_performance;

-- Total Leads
SELECT COUNT(*) AS total_leads
FROM customer_acquisition;

-- Total Spend
SELECT SUM(spend) AS total_spend
FROM campaign_performance;

-- Total Revenue (from both tables)
SELECT 
    (SELECT SUM(revenue) FROM campaign_performance) +
    (SELECT SUM(first_order_value) FROM customer_acquisition) AS total_revenue;

-- CTR
SELECT 
    SUM(clicks) / NULLIF(SUM(impressions),0) AS ctr
FROM campaign_performance;

-- Conversion Rate
SELECT 
    COUNT(*) / NULLIF((SELECT SUM(clicks) FROM campaign_performance),0) AS conversion_rate
FROM customer_acquisition;

-- CPL
SELECT 
    SUM(spend) / NULLIF(COUNT(*),0) AS cpl
FROM customer_acquisition
JOIN campaign_performance USING (campaign_key);

-- ROAS
SELECT 
    SUM(revenue) / NULLIF(SUM(spend),0) AS roas
FROM campaign_performance;

-- =============================================
-- 5) CHANNEL PERFORMANCE
-- =============================================

-- ROAS by Channel
SELECT 
    channel,
    SUM(revenue) AS revenue,
    SUM(spend) AS spend,
    SUM(revenue) / NULLIF(SUM(spend),0) AS roas
FROM campaign_performance
GROUP BY channel
ORDER BY roas DESC;

-- CTR by Channel
SELECT 
    channel,
    SUM(clicks) / NULLIF(SUM(impressions),0) AS ctr
FROM campaign_performance
GROUP BY channel;

-- Spend vs Revenue by Channel
SELECT 
    channel,
    SUM(spend) AS total_spend,
    SUM(revenue) AS total_revenue
FROM campaign_performance
GROUP BY channel;

-- =============================================
-- 6) AUDIENCE & SEGMENT INSIGHTS
-- =============================================

-- Leads by Country
SELECT country, COUNT(*) AS total_leads
FROM customer_acquisition
GROUP BY country
ORDER BY total_leads DESC;

-- Heatmap: ROAS by Channel & Country
SELECT 
    cp.channel,
    cp.country,
    SUM(cp.revenue) / NULLIF(SUM(cp.spend),0) AS roas
FROM campaign_performance cp
GROUP BY cp.channel, cp.country;

-- =============================================
-- 7) TIME SERIES ANALYSIS
-- =============================================

-- Revenue Over Time
SELECT date, SUM(revenue) AS daily_revenue
FROM campaign_performance
GROUP BY date
ORDER BY date;

-- Spend Over Time
SELECT date, SUM(spend) AS daily_spend
FROM campaign_performance
GROUP BY date
ORDER BY date;

-- =============================================
-- 8) FUNNEL METRICS
-- =============================================

-- Campaign Funnel Summary
SELECT 
    cp.campaign_name,
    SUM(cp.impressions) AS impressions,
    SUM(cp.clicks) AS clicks,
    COUNT(ca.customer_id) AS leads,
    SUM(cp.revenue) AS revenue
FROM campaign_performance cp
LEFT JOIN customer_acquisition ca USING (campaign_key)
GROUP BY cp.campaign_name;

-- CTR, CVR, CPL, ROAS by Campaign
SELECT 
    cp.campaign_name,
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks,
    SUM(clicks) / NULLIF(SUM(impressions),0) AS ctr,
    COUNT(ca.customer_id) AS leads,
    COUNT(ca.customer_id) / NULLIF(SUM(clicks),0) AS conversion_rate,
    SUM(spend) / NULLIF(COUNT(ca.customer_id),0) AS cpl,
    SUM(cp.revenue) / NULLIF(SUM(spend),0) AS roas
FROM campaign_performance cp
LEFT JOIN customer_acquisition ca USING (campaign_key)
GROUP BY cp.campaign_name;

-- =============================================
-- END OF PROJECT 4 SQL SCRIPT
-- =============================================
