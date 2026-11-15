USE Front;
GO
SET NOCOUNT ON;
GO

SELECT 
    p.securityaccess AS [Уровень доступа],
    COUNT(*) AS [Сотрудников],
    SUM(CASE WHEN p.flagpos = 1 THEN 1 ELSE 0 END) AS [POS],
    SUM(CASE WHEN p.flagsales = 1 THEN 1 ELSE 0 END) AS [Продажи],
    SUM(CASE WHEN p.flagreports = 1 THEN 1 ELSE 0 END) AS [Отчёты]
FROM dbo.personnel p
GROUP BY p.securityaccess
ORDER BY COUNT(*) DESC;
GO

SELECT TOP (10)
    p.personid AS [Код],
    LTRIM(RTRIM(ISNULL(p.lastname, '') + ' ' + ISNULL(p.firstname, ''))) AS [Сотрудник],
    (SELECT COUNT(*) FROM dbo.bm_JournalSessions s WHERE s.PersonID = p.personid) AS [Сессий],
    ISNULL((SELECT SUM(CASE WHEN s.IsError = 1 THEN 1 ELSE 0 END)
            FROM dbo.bm_JournalSessions s WHERE s.PersonID = p.personid), 0) AS [Ошибок],
    CAST(100.0 * ISNULL((SELECT SUM(CASE WHEN s.IsError = 1 THEN 1 ELSE 0 END)
            FROM dbo.bm_JournalSessions s WHERE s.PersonID = p.personid), 0)
        / NULLIF((SELECT COUNT(*) FROM dbo.bm_JournalSessions s WHERE s.PersonID = p.personid), 0)
        AS decimal(5,1)) AS [Доля ошибок, %]
FROM dbo.personnel p
WHERE EXISTS (SELECT 1 FROM dbo.bm_JournalSessions s WHERE s.PersonID = p.personid)
ORDER BY [Сессий] DESC;
GO