USE Front;
GO
SET NOCOUNT ON;
GO

--измерения

--stg.ranges
SELECT s.ID AS external_id, s.sizeid AS name, s.portionrate AS factor
FROM [size] AS s;
GO

--stg.categories
SELECT c.id AS external_id, c.description AS name,
       CASE WHEN c.ParentID = 0 THEN NULL ELSE c.ParentID END AS parent_id
FROM category AS c;
GO

--stg.vendors
SELECT v.id AS external_id, v.clientid AS name,
       v.clientgroup AS parent_id, vg.description AS parent_name
FROM vendors AS v
INNER JOIN vendorgroup AS vg ON vg.vendorgroupid = v.clientgroup;
GO

--stg.personnel
SELECT personid AS external_id,
       lastname + ' ' + firstname + ' ' + middlename AS name,
       lastname AS last_name, firstname AS first_name, middlename AS middle_name,
       securityaccess AS access_level,
       CASE WHEN flagpos = 1 THEN 1 ELSE 0 END AS has_pos_access,
       CASE WHEN deleteflag = 1 THEN 1 ELSE 0 END AS is_deleted
FROM personnel;
GO

--stg.payment_types
SELECT transtypeid AS external_id, description AS name
FROM transtype
WHERE transgroupid = 2;
GO

--stg.operation_types
SELECT ID AS external_id, Description AS name,
       CASE WHEN Factor = -1 THEN -1 ELSE 1 END AS factor
FROM bm_StorageOperationsType;
GO

--stg.event_types
SELECT DISTINCT Type AS name FROM bm_JournalSessions;
GO

--stg.products
SELECT id AS external_id, productid AS external_code, description AS name,
       CategoryID AS category_external_id, SizeID AS range_external_id,
       cost, IsUse AS is_active
FROM product;
GO

--stg.storages
SELECT s.id AS external_id, s.description AS name,
       s.CompanyID AS company_external_id, comp.CompanyName AS company_name,
       s.ResponsibleID AS responsible_person_external_id
FROM storages AS s
LEFT JOIN bm_Companies AS comp ON comp.ID = s.CompanyID;
GO

--факты

--stg.purchases
SELECT YEAR(s.DateAdd)*100 + MONTH(s.DateAdd) AS time_code,
       s.ProductID AS product_external_id,
       ISNULL(s.VendorID, 0) AS vendor_external_id,
       ISNULL(p.CategoryID, 0) AS category_external_id,
       s.StorageID AS storage_external_id,
       ISNULL(s.RangeID, 0) AS range_external_id,
       COUNT(*) AS lines_count,
       SUM(s.[Count]) AS quantity,
       SUM(s.Amount) AS amount,
       SUM(s.Amount)/NULLIF(SUM(s.[Count]),0) AS avg_price
FROM bm_StorageOperations AS s
JOIN product AS p ON p.id = s.ProductID
WHERE s.OperationID = 1
GROUP BY YEAR(s.DateAdd), MONTH(s.DateAdd), s.ProductID, s.VendorID, p.CategoryID, s.StorageID, s.RangeID;
GO

--stg.sales
SELECT YEAR(j.dater)*100 + MONTH(j.dater) AS time_code,
       p.id AS product_external_id,
       ISNULL(p.CategoryID, 0) AS category_external_id,
       COUNT(DISTINCT j.receiptn) AS receipts_count,
       COUNT(*) AS lines_count,
       SUM(CASE WHEN j.flagrefund = 0 THEN j.quantity ELSE 0 END) AS quantity,
       SUM(CASE WHEN j.flagrefund = 0 THEN j.amount ELSE 0 END) AS revenue,
       SUM(CASE WHEN j.flagrefund = 1 THEN j.amount ELSE 0 END) AS refund_amount,
       SUM(CASE WHEN j.flagrefund = 0 THEN j.amount ELSE 0 END) -
       SUM(CASE WHEN j.flagrefund = 1 THEN j.amount ELSE 0 END) AS net_revenue
FROM journal AS j
LEFT JOIN product AS p ON p.productid = j.id
WHERE j.transtype = 101
GROUP BY YEAR(j.dater), MONTH(j.dater), p.id, p.CategoryID;
GO

--stg.payments
SELECT YEAR(j.dater)*100 + MONTH(j.dater) AS time_code,
       j.transtype AS payment_type_external_id,
       COUNT(*) AS operations_count,
       SUM(j.amount) AS amount
FROM journal AS j
JOIN transtype AS t ON t.transtypeid = j.transtype
WHERE t.transgroupid = 2
GROUP BY YEAR(j.dater), MONTH(j.dater), j.transtype;
GO

--stg.personnel_sessions
SELECT YEAR(s.DateAdd)*100 + MONTH(s.DateAdd) AS time_code,
       ISNULL(s.PersonID, 0) AS person_external_id,
       s.Type AS event_type_name,
       COUNT(*) AS sessions_count,
       SUM(CASE WHEN s.IsError = 1 THEN 1 ELSE 0 END) AS errors_count
FROM bm_JournalSessions AS s
WHERE s.DateAdd IS NOT NULL
GROUP BY YEAR(s.DateAdd), MONTH(s.DateAdd), s.PersonID, s.Type;
GO

--stg.personnel_bonus
SELECT YEAR(b.Period)*100 + MONTH(b.Period) AS time_code,
       b.PersonID AS person_external_id,
       COUNT(*) AS bonus_records_count,
       SUM(b.BonusValue) AS bonus_value
FROM bm_BonusHistory AS b
WHERE b.Period IS NOT NULL
GROUP BY YEAR(b.Period), MONTH(b.Period), b.PersonID;
GO

--stg.stock
SELECT YEAR(s.DateAdd)*100 + MONTH(s.DateAdd) AS time_code,
       s.ProductID AS product_external_id,
       ISNULL(s.StorageID, 0) AS storage_external_id,
       s.OperationID AS operation_type_external_id,
       ISNULL(s.RangeID, 0) AS range_external_id,
       COUNT(*) AS lines_count,
       SUM(s.[Count]) AS quantity,
       SUM(s.Amount) AS amount,
       SUM(ABS(s.Amount)) AS turnover_amount
FROM bm_StorageOperations AS s
WHERE s.DateAdd IS NOT NULL
GROUP BY YEAR(s.DateAdd), MONTH(s.DateAdd), s.ProductID, s.StorageID, s.OperationID, s.RangeID;
GO