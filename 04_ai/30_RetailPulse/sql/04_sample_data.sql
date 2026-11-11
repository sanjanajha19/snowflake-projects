USE ROLE RETAILPULSE_DEMO_ROLE;
USE WAREHOUSE RETAILPULSE_DEMO_WH;
USE DATABASE RETAILPULSE_AI;
USE SCHEMA DATA;

INSERT OVERWRITE INTO STORES
SELECT 'STR-'||LPAD(i::VARCHAR,3,'0'),
       CASE MOD(i,4) WHEN 0 THEN 'Metro Central ' WHEN 1 THEN 'Market Square '
            WHEN 2 THEN 'City Hub ' ELSE 'Neighborhood ' END||i,
       CASE MOD(i,3) WHEN 0 THEN 'FLAGSHIP' WHEN 1 THEN 'MALL' ELSE 'NEIGHBORHOOD' END,
       CASE MOD(i,4) WHEN 0 THEN 'NORTH' WHEN 1 THEN 'SOUTH' WHEN 2 THEN 'EAST' ELSE 'WEST' END,
       CASE MOD(i,8) WHEN 0 THEN 'Chicago' WHEN 1 THEN 'Boston' WHEN 2 THEN 'Atlanta'
            WHEN 3 THEN 'Dallas' WHEN 4 THEN 'Seattle' WHEN 5 THEN 'Denver'
            WHEN 6 THEN 'New York' ELSE 'Los Angeles' END,
       25+MOD(i*71,2200)/100.0,
       -124+MOD(i*97,5700)/100.0,
       8000+MOD(i*1777,42000)
FROM (SELECT ROW_NUMBER() OVER(ORDER BY SEQ4()) i FROM TABLE(GENERATOR(ROWCOUNT=>20)));

INSERT OVERWRITE INTO PRODUCTS
SELECT 'PRD-'||LPAD(i::VARCHAR,4,'0'),
       CASE MOD(i,8) WHEN 0 THEN 'Premium Coffee Machine ' WHEN 1 THEN 'Wireless Headphones '
            WHEN 2 THEN 'Smart Blender ' WHEN 3 THEN 'Organic Skin Care Set '
            WHEN 4 THEN 'Running Shoes ' WHEN 5 THEN 'Cotton Jacket '
            WHEN 6 THEN 'Home Air Purifier ' ELSE 'Stainless Cookware ' END||i,
       CASE MOD(i,6) WHEN 0 THEN 'ELECTRONICS' WHEN 1 THEN 'HOME_APPLIANCES'
            WHEN 2 THEN 'BEAUTY' WHEN 3 THEN 'SPORTS' WHEN 4 THEN 'APPAREL' ELSE 'HOME' END,
       CASE MOD(i,4) WHEN 0 THEN 'PREMIUM' WHEN 1 THEN 'CORE' WHEN 2 THEN 'VALUE' ELSE 'SEASONAL' END,
       CASE MOD(i,5) WHEN 0 THEN 'NOVA' WHEN 1 THEN 'APEX' WHEN 2 THEN 'LUMINA'
            WHEN 3 THEN 'TERRA' ELSE 'ORBIT' END,
       15+MOD(i*41,18000)/100.0,
       35+MOD(i*79,36000)/100.0,
       IFF(MOD(i,6)=2,365,730),
       3+MOD(i,18),
       TRUE
FROM (SELECT ROW_NUMBER() OVER(ORDER BY SEQ4()) i FROM TABLE(GENERATOR(ROWCOUNT=>60)));

-- Give the flagship product a stable name and commercial profile.
UPDATE PRODUCTS
SET PRODUCT_NAME='Apex Barista Pro Coffee Machine', CATEGORY='HOME_APPLIANCES',
    SUBCATEGORY='PREMIUM', BRAND='APEX', UNIT_COST_USD=180, LIST_PRICE_USD=399,
    LEAD_TIME_DAYS=14
WHERE PRODUCT_ID='PRD-0042';

INSERT OVERWRITE INTO PROMOTIONS VALUES
('PRO-001','Weekend Home Event','HOME_APPLIANCES',DATEADD('day',-3,CURRENT_DATE()),DATEADD('day',5,CURRENT_DATE()),20,'ALL','ALL'),
('PRO-002','Connected Living','ELECTRONICS',DATEADD('day',-5,CURRENT_DATE()),DATEADD('day',9,CURRENT_DATE()),15,'ALL','ALL'),
('PRO-003','Beauty Refresh','BEAUTY',DATEADD('day',-10,CURRENT_DATE()),DATEADD('day',4,CURRENT_DATE()),18,'STORE','NORTH'),
('PRO-004','Run Ready','SPORTS',DATEADD('day',-7,CURRENT_DATE()),DATEADD('day',7,CURRENT_DATE()),12,'ALL','WEST'),
('PRO-005','Seasonal Apparel','APPAREL',DATEADD('day',-14,CURRENT_DATE()),DATEADD('day',2,CURRENT_DATE()),25,'ONLINE','ALL'),
('PRO-006','Home Essentials','HOME',DATEADD('day',-2,CURRENT_DATE()),DATEADD('day',12,CURRENT_DATE()),10,'STORE','SOUTH');

INSERT OVERWRITE INTO INVENTORY
SELECT s.STORE_ID, p.PRODUCT_ID, CURRENT_DATE(),
       5+MOD(ABS(HASH(s.STORE_ID,p.PRODUCT_ID)),95),
       MOD(ABS(HASH('R',s.STORE_ID,p.PRODUCT_ID)),8),
       MOD(ABS(HASH('T',s.STORE_ID,p.PRODUCT_ID)),25),
       8+MOD(ABS(HASH('S',s.STORE_ID,p.PRODUCT_ID)),18),
       15+MOD(ABS(HASH('P',s.STORE_ID,p.PRODUCT_ID)),25),
       DATEADD('day',-MOD(ABS(HASH(s.STORE_ID,p.PRODUCT_ID)),30),CURRENT_DATE())
FROM STORES s CROSS JOIN PRODUCTS p;

-- Pin one product to show a risk/excess transfer opportunity.
UPDATE INVENTORY SET ON_HAND_QTY=7, RESERVED_QTY=3, IN_TRANSIT_QTY=0, SAFETY_STOCK_QTY=12
WHERE PRODUCT_ID='PRD-0042' AND STORE_ID IN ('STR-011','STR-012','STR-015');
UPDATE INVENTORY SET ON_HAND_QTY=95, RESERVED_QTY=2, IN_TRANSIT_QTY=0, SAFETY_STOCK_QTY=15
WHERE PRODUCT_ID='PRD-0042' AND STORE_ID='STR-003';

INSERT OVERWRITE INTO SALES
WITH n AS (
  SELECT ROW_NUMBER() OVER(ORDER BY SEQ4()) i FROM TABLE(GENERATOR(ROWCOUNT=>6000))
), x AS (
  SELECT i,
         'STR-'||LPAD((MOD(i*7,20)+1)::VARCHAR,3,'0') STORE_ID,
         'PRD-'||LPAD((MOD(i*11,60)+1)::VARCHAR,4,'0') PRODUCT_ID,
         1+MOD(i,4) UNITS,
         DATEADD('minute',-MOD(i*97,90*24*60),CURRENT_TIMESTAMP()) SALE_TIME
  FROM n
)
SELECT 'SAL-'||LPAD(x.i::VARCHAR,8,'0'), x.SALE_TIME, x.STORE_ID, x.PRODUCT_ID,
       IFF(MOD(x.i,3)=0,'ONLINE','STORE'), x.UNITS,
       ROUND(x.UNITS*p.LIST_PRICE_USD,2),
       ROUND(x.UNITS*p.LIST_PRICE_USD*IFF(MOD(x.i,5)=0,0.20,IFF(MOD(x.i,7)=0,0.10,0)),2),
       ROUND(x.UNITS*p.LIST_PRICE_USD*(1-IFF(MOD(x.i,5)=0,0.20,IFF(MOD(x.i,7)=0,0.10,0))),2),
       ROUND(x.UNITS*p.UNIT_COST_USD,2),
       CASE WHEN p.CATEGORY='HOME_APPLIANCES' AND x.SALE_TIME::DATE>=DATEADD('day',-3,CURRENT_DATE()) THEN 'PRO-001'
            WHEN p.CATEGORY='ELECTRONICS' AND x.SALE_TIME::DATE>=DATEADD('day',-5,CURRENT_DATE()) THEN 'PRO-002'
            ELSE NULL END
FROM x JOIN PRODUCTS p ON p.PRODUCT_ID=x.PRODUCT_ID;

-- Add strong recent velocity for the flagship product at risk stores.
INSERT INTO SALES
SELECT 'DEMO-42-'||LPAD(i::VARCHAR,4,'0'), DATEADD('hour',-MOD(i*3,72),CURRENT_TIMESTAMP()),
       CASE MOD(i,3) WHEN 0 THEN 'STR-011' WHEN 1 THEN 'STR-012' ELSE 'STR-015' END,
       'PRD-0042','STORE',2,798,159.60,638.40,360,'PRO-001'
FROM (SELECT ROW_NUMBER() OVER(ORDER BY SEQ4()) i FROM TABLE(GENERATOR(ROWCOUNT=>45)));

INSERT OVERWRITE INTO RETURNS
SELECT 'RET-'||LPAD(i::VARCHAR,6,'0'),
       'SAL-'||LPAD((MOD(i*31,6000)+1)::VARCHAR,8,'0'),
       'STR-'||LPAD((MOD(i*7,20)+1)::VARCHAR,3,'0'),
       IFF(MOD(i,5)=0,'PRD-0042','PRD-'||LPAD((MOD(i*11,60)+1)::VARCHAR,4,'0')),
       DATEADD('day',-MOD(i*5,60),CURRENT_DATE()),
       1, 40+MOD(i*73,360),
       CASE MOD(i,5) WHEN 0 THEN 'DEFECT' WHEN 1 THEN 'NOT_AS_EXPECTED'
            WHEN 2 THEN 'SIZE_OR_FIT' WHEN 3 THEN 'DAMAGED' ELSE 'CHANGED_MIND' END
FROM (SELECT ROW_NUMBER() OVER(ORDER BY SEQ4()) i FROM TABLE(GENERATOR(ROWCOUNT=>260)));

INSERT OVERWRITE INTO DOCUMENTS VALUES
('DOC-001','PRODUCT_REVIEW','Coffee machine leaking after cleaning','PRD-0042','HOME_APPLIANCES','NORTH','QUALITY',DATEADD('day',-8,CURRENT_DATE()),2.0,'The coffee quality is excellent, but water began leaking from the base after the first cleaning cycle. The quick-start guide does not explain how to seat the reservoir correctly.','reviews/prd0042_leak.txt'),
('DOC-002','PRODUCT_REVIEW','Great coffee but confusing setup','PRD-0042','HOME_APPLIANCES','WEST','USABILITY',DATEADD('day',-5,CURRENT_DATE()),3.0,'The machine makes very good coffee. Setup was confusing and the grinder calibration steps were missing from the printed guide.','reviews/prd0042_setup.txt'),
('DOC-003','SUPPORT_CASE','Reservoir seal replacement requests','PRD-0042','HOME_APPLIANCES','ALL','QUALITY',DATEADD('day',-4,CURRENT_DATE()),NULL,'Support received repeated contacts about reservoir seals on batch B42-SEP. Agents advised customers to reseat the seal, but some units required replacement.','support/prd0042_seal.txt'),
('DOC-004','PRODUCT_GUIDE','Apex Barista Pro setup and cleaning','PRD-0042','HOME_APPLIANCES','ALL','GUIDANCE',DATEADD('month',-4,CURRENT_DATE()),NULL,'Before first use, lock the water reservoir firmly until the alignment marks meet. Run one rinse cycle. For cleaning, remove and reseat the silicone seal before reinstalling the reservoir.','guides/prd0042_setup.txt'),
('DOC-005','RETURN_POLICY','Retail return and defect policy',NULL,'ALL','ALL','POLICY',DATEADD('year',-1,CURRENT_DATE()),NULL,'Products may be returned within 30 days. Defective appliances qualify for replacement or refund after validation. Store teams must record product, batch, reason, and evidence. High-value refunds require supervisor approval.','policies/returns.txt'),
('DOC-006','STORE_NOTE','Weekend appliance promotion readiness',NULL,'HOME_APPLIANCES','EAST','PROMOTION',DATEADD('day',-2,CURRENT_DATE()),NULL,'Several eastern stores reported that display inventory was counted as sellable inventory. Teams were instructed to separate display units and validate on-hand quantities before the weekend event.','store_notes/appliance_readiness.txt'),
('DOC-007','PRODUCT_REVIEW','Headphones pairing problem','PRD-0001','ELECTRONICS','SOUTH','USABILITY',DATEADD('day',-12,CURRENT_DATE()),2.0,'Pairing repeatedly failed with Android devices until the firmware was updated. The update instructions were difficult to locate.','reviews/headphones_pairing.txt'),
('DOC-008','SUPPORT_CASE','Air purifier filter availability','PRD-0007','HOME','WEST','AVAILABILITY',DATEADD('day',-9,CURRENT_DATE()),NULL,'Customers asked when replacement filters would return to stock. Support linked to an older product page that showed an incorrect availability date.','support/air_filter.txt');
