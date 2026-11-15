USE Front;
GO
SET NOCOUNT ON;
GO

SELECT TOP (10)
    p.description AS [Товар],
    CAST(SUM(CASE WHEN ot.Description = 'Поступление' THEN s.[Count] ELSE 0 END) AS decimal(18,3)) AS [Приход],
    CAST(SUM(CASE WHEN ot.Description = 'Списание' THEN s.[Count] ELSE 0 END) AS decimal(18,3)) AS [Списание],
    CAST(SUM(s.[Count]) AS decimal(18,3)) AS [Баланс по движениям]
FROM dbo.bm_StorageOperations s
JOIN dbo.bm_StorageOperationsType ot ON ot.ID = s.OperationID
JOIN dbo.product p ON p.id = s.ProductID
GROUP BY p.description
ORDER BY ABS(SUM(s.[Count])) DESC;
GO

SELECT TOP (10)
    x.[Товар],
    CAST(x.Rest AS decimal(18,3)) AS [Остаток (Rest)],
    CONVERT(varchar(19), x.DateAdd, 120) AS [Последняя операция]
FROM (
    SELECT 
        p.description AS [Товар],
        s.Rest,
        s.DateAdd,
        ROW_NUMBER() OVER (PARTITION BY s.ProductID ORDER BY s.DateAdd DESC, s.ID DESC) AS rn
    FROM dbo.bm_StorageOperations s
    JOIN dbo.product p ON p.id = s.ProductID
) x
WHERE x.rn = 1
ORDER BY ABS(x.Rest) DESC;
GO

SELECT 'product.onhand' AS [Показатель],
       SUM(CASE WHEN onhand IS NOT NULL THEN 1 ELSE 0 END) AS [Значение]
FROM dbo.product
UNION ALL SELECT 'stock', COUNT(*) FROM dbo.stock
UNION ALL SELECT 'storagesonhand', COUNT(*) FROM dbo.storagesonhand
UNION ALL SELECT 'storages', COUNT(*) FROM dbo.storages;
GO