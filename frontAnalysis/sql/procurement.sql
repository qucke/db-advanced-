USE Front;
GO
SET NOCOUNT ON;
GO

SELECT 
    YEAR(s.DateAdd) AS [Год],
    ot.Description AS [Тип операции],
    COUNT(*) AS [Операций],
    CAST(ABS(SUM(s.[Count])) AS decimal(18,3)) AS [Количество],
    CAST(ABS(SUM(s.Amount)) AS decimal(18,2)) AS [Сумма, руб.]
FROM dbo.bm_StorageOperations s
JOIN dbo.bm_StorageOperationsType ot ON s.OperationID = ot.ID
GROUP BY YEAR(s.DateAdd), ot.Description
ORDER BY [Год], [Тип операции];
GO

SELECT TOP (10)
    p.description AS [Товар],
    CAST(SUM(s.[Count]) AS decimal(18,3)) AS [Количество],
    CAST(SUM(s.Amount) AS decimal(18,2)) AS [Сумма, руб.]
FROM dbo.bm_StorageOperations s
JOIN dbo.product p ON p.id = s.ProductID
WHERE s.OperationID = 1
GROUP BY p.description
ORDER BY SUM(s.Amount) DESC;
GO