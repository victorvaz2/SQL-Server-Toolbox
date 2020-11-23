/*********************************************************************
* Find ways to get a better database.                                *
*********************************************************************/

--====================================================================
--Find all not trusted FKs and constraints
--====================================================================
SELECT '[' + s.name + '].[' + o.name + '].[' + i.name + ']' AS keyname
from sys.foreign_keys i
INNER JOIN sys.objects o ON i.parent_object_id = o.object_id
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE i.is_not_trusted = 1 AND i.is_not_for_replication = 0;
GO


--====================================================================
--Find tables with no Primary Key
--====================================================================
SELECT SCHEMA_NAME(schema_id) AS SchemaName,name AS TableName
FROM sys.tables
WHERE OBJECTPROPERTY(OBJECT_ID,'TableHasPrimaryKey') = 0
ORDER BY SchemaName, TableName;


--====================================================================
--Find table scans/seeks/etc from all tables
--====================================================================
SELECT OBJECT_NAME(object_id) AS Table_Name, *
FROM sys.dm_db_index_usage_stats
WHERE DB_NAME(database_id) LIKE '%@Database_Name%';


--====================================================================
--Find indexes fragmentation
--====================================================================
SELECT OBJECT_NAME(object_id) as ObjName ,* 
FROM sys.dm_db_index_physical_stats(NULL,NULL,NULL,NULL,NULL)	 --DatabaseID, ObjectID, IndexID, Partition, Mode
ORDER BY avg_fragmentation_in_percent DESC	


--====================================================================
--Find all exact index duplicates
--====================================================================
WITH indexcols
     AS (SELECT object_id AS id,
                index_id AS indid,
                name,
         (
             SELECT CASE keyno
                        WHEN 0
                        THEN NULL
                        ELSE colid
                    END AS [data()]
             FROM sys.sysindexkeys AS k
             WHERE k.id = i.object_id
                   AND k.indid = i.index_id
             ORDER BY keyno,
                      colid
             FOR XML PATH('')
         ) AS cols,
         (
             SELECT CASE keyno
                        WHEN 0
                        THEN colid
                        ELSE NULL
                    END AS [data()]
             FROM sys.sysindexkeys AS k
             WHERE k.id = i.object_id
                   AND k.indid = i.index_id
             ORDER BY colid
             FOR XML PATH('')
         ) AS inc
         FROM sys.indexes AS i)
     SELECT OBJECT_SCHEMA_NAME(c1.id)+'.'+OBJECT_NAME(c1.id) AS 'Table',
            c1.name AS 'Index',
            c2.name AS 'Exact_Duplicate'
     FROM indexcols AS c1
          JOIN indexcols AS c2 ON c1.id = c2.id
                                  AND c1.indid < c2.indid
                                  AND c1.cols = c2.cols
                                  AND c1.inc = c2.inc;
								  
								  
--====================================================================
--Find last 60 minutes of top CPU usage
--====================================================================
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 

	SELECT TOP(60) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
                   SystemIdle AS [System Idle Process], 
                   100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
                   DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
    FROM ( 
          SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
                record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
                AS [SystemIdle], 
                record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
                'int') 
                AS [SQLProcessUtilization], [timestamp] 
          FROM ( 
                SELECT [timestamp], convert(xml, record) AS [record] 
                FROM sys.dm_os_ring_buffers 
                WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
                AND record LIKE '%<SystemHealth>%') AS x 
          ) AS y 
    ORDER BY record_id DESC
	
	
--====================================================================
--Check sp_configure important configs
--====================================================================
sp_configure 'show advanced options', 1
RECONFIGURE;