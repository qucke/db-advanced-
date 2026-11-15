USE Front;
GO
SET NOCOUNT ON;
GO

SELECT 
    YEAR(j.dater) AS [Год],
    COUNT(DISTINCT j.receiptn) AS [Чеков],
    COUNT(*) AS [Строк],
    CAST(SUM(j.quantity) AS decimal(18,3)) AS [Количество],
    CAST(SUM(j.amount) AS decimal(18,2)) AS [Выручка, руб.],
    CAST(SUM(j.amount) / NULLIF(COUNT(DISTINCT j.receiptn), 0) AS decimal(18,2)) AS [Средний чек, руб.]
FROM dbo.journal j
WHERE j.transtype = 101
GROUP BY YEAR(j.dater)
ORDER BY [Год];
GO

SELECT TOP (10)
    j.description AS [Товар],
    CAST(SUM(j.quantity) AS decimal(18,3)) AS [Количество],
    CAST(SUM(j.amount) AS decimal(18,2)) AS [Выручка, руб.]
FROM dbo.journal j
WHERE j.transtype = 101
  AND j.amount <> 0
GROUP BY j.description
ORDER BY SUM(j.amount) DESC;
GO

SELECT 
    t.description AS [Способ оплаты],
    COUNT(*) AS [Операций],
    CAST(SUM(j.amount) AS decimal(18,2)) AS [Сумма, руб.]
FROM dbo.journal j
JOIN dbo.transtype t ON t.transtypeid = j.transtype
WHERE j.transtype BETWEEN 211 AND 217
GROUP BY t.description
ORDER BY SUM(j.amount) DESC;
GO