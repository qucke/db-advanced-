USE Front;
GO
SET NOCOUNT ON;
GO

SELECT 
    COUNT(*) AS [Всего],
    SUM(CASE WHEN v.IsUse = 1 THEN 1 ELSE 0 END) AS [Активных],
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(v.INN)), '') IS NOT NULL THEN 1 ELSE 0 END) AS [С ИНН],
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(v.KPP)), '') IS NOT NULL THEN 1 ELSE 0 END) AS [С КПП],
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(v.contactperson)), '') IS NOT NULL THEN 1 ELSE 0 END) AS [С контактным лицом]
FROM dbo.vendors v;
GO

SELECT TOP (10)
    v.id AS [Код],
    LTRIM(RTRIM(ISNULL(v.lastname, '') + ' ' + ISNULL(v.firstname, ''))) AS [Поставщик],
    vg.description AS [Группа],
    COUNT(DISTINCT s.ProductID) AS [Позиций],
    CAST(SUM(s.Amount) AS decimal(18,2)) AS [Закупки, руб.],
    CAST(100.0 * SUM(s.Amount) / SUM(SUM(s.Amount)) OVER () AS decimal(5,1)) AS [Доля, %]
FROM dbo.bm_StorageOperations s
JOIN dbo.vendors v ON v.id = s.VendorID
LEFT JOIN dbo.vendorgroup vg ON vg.vendorgroupid = v.clientgroup
WHERE s.OperationID = 1
GROUP BY v.id, v.lastname, v.firstname, vg.description
ORDER BY SUM(s.Amount) DESC;
GO

SELECT 'bm_Contracts' AS [Объект], COUNT(*) AS [Строк] FROM dbo.bm_Contracts
UNION ALL
SELECT 'bm_Companies', COUNT(*) FROM dbo.bm_Companies;
GO