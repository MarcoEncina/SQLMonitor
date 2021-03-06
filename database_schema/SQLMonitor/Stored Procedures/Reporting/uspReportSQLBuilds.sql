USE [SQLMonitor]
GO

IF OBJECT_ID(N'[Reporting].[uspReportSQLBuilds]') IS NOT NULL
DROP PROCEDURE [Reporting].[uspReportSQLBuilds]
GO

CREATE PROCEDURE [Reporting].[uspReportSQLBuilds]
    @TabularReport bit = 1,
    @HTMLOutput xml = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [Monitor].[ServerInfo] AS ServerInfo WHERE ServerInfo.RecordStatus = 'A') 
       AND EXISTS (SELECT 1 FROM [dbo].[SystemParams] WHERE [ParamName] LIKE 'SQLServer_BuildVersion%')
    BEGIN
        IF (@TabularReport = 1)
        BEGIN
            SELECT
                COALESCE(m.[ServerAlias], s.[ServerName]) AS [ServerName], s.[ProductVersion], s.[ProductLevel],
                p.[ParamValue] AS [LatestBuild]
            FROM [Monitor].[ServerInfo] s
                INNER JOIN [dbo].[MonitoredServers] m ON s.ServerName = COALESCE(m.[ServerAlias], m.[ServerName])
                INNER JOIN [dbo].[SystemParams]  p ON 
                'SQLServer_BuildVersion_' + (CASE
                    WHEN s.[ProductVersion] LIKE '8.0%'  THEN '2000' 
                    WHEN s.[ProductVersion] LIKE '9.0%'  THEN '2005' 
                    WHEN s.[ProductVersion] LIKE '10.0%' THEN '2008' 
                    WHEN s.[ProductVersion] LIKE '10.5%' THEN '2008R2'
                    WHEN s.[ProductVersion] LIKE '11.0%' THEN '2012'
                    WHEN s.[ProductVersion] LIKE '12.0%' THEN '2014'
                    WHEN s.[ProductVersion] LIKE '13.0%' THEN '2016'
                    WHEN s.[ProductVersion] LIKE '14.0%' THEN '2017'
                END) = p.[ParamName] 
                --AND s.[ProductVersion] < p.[ParamValue]
            WHERE m.[RecordStatus] = 'A' AND s.[RecordStatus] = 'A'
            ORDER BY p.[ParamName] DESC, m.[ServerOrder] ASC, COALESCE(m.[ServerAlias], s.[ServerName]) ASC
        END
        ELSE
        BEGIN
            SET @HTMLOutput =
                N'<H2>SQL Server Builds</H2>' +
                N'<table border="1">' +
                N'<thead><tr>' +
                    '<th align="left">ServerName</th>' +
                    '<th align="left">ProductVersion</th>' +
                    '<th align="left">ProductLevel</th>' +
                    '<th align="left">LatestBuild</th>' +
                N'</tr></thead>' +
                N'<tbody>' +
                CAST ( ( SELECT 
                            td = COALESCE(m.[ServerAlias], s.[ServerName]), '', 
                            td = s.[ProductVersion],  '', 
                            td = s.[ProductLevel],  '', 
                            td = p.[ParamValue], ''
                        FROM [Monitor].[ServerInfo] s
                            INNER JOIN [dbo].[MonitoredServers] m ON s.ServerName = COALESCE(m.[ServerAlias], m.[ServerName])
                            INNER JOIN [dbo].[SystemParams]  p ON 
                            'SQLServer_BuildVersion_' + (CASE
                                WHEN s.[ProductVersion] LIKE '8.0%'  THEN '2000' 
                                WHEN s.[ProductVersion] LIKE '9.0%'  THEN '2005' 
                                WHEN s.[ProductVersion] LIKE '10.0%' THEN '2008' 
                                WHEN s.[ProductVersion] LIKE '10.5%' THEN '2008R2'
                                WHEN s.[ProductVersion] LIKE '11.0%' THEN '2012'
                                WHEN s.[ProductVersion] LIKE '12.0%' THEN '2014'
                                WHEN s.[ProductVersion] LIKE '13.0%' THEN '2016'
                                WHEN s.[ProductVersion] LIKE '14.0%' THEN '2017'
                            END) = p.[ParamName] 
                            --AND s.[ProductVersion] < p.[ParamValue]
                        WHERE m.[RecordStatus] = 'A' AND s.[RecordStatus] = 'A'
                        ORDER BY p.[ParamName] DESC, m.[ServerOrder] ASC, COALESCE(m.[ServerAlias], s.[ServerName]) ASC
                        FOR XML PATH('tr'), TYPE 
                ) AS NVARCHAR(MAX) ) +
                N'</tbody></table><p/>';
        END
    END
    ELSE
    BEGIN
        SET @HTMLOutput = '';
    END

    RETURN 0;
END

GO


USE [master]
GO

/*
USE [SQLMonitor];
DECLARE @emailbody xml = '';
EXEC [Reporting].[uspReportSQLBuilds] @TabularReport = 0, @HTMLOutput = @emailbody OUTPUT;
SELECT @emailbody AS HTMLOutput;

EXEC [Reporting].[uspReportSQLBuilds] @TabularReport = 1;
*/
