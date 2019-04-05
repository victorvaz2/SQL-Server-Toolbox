***************************************************************************************************************************
*                                                                                                                         *
*      Script utiliza os arquivos de pico de CPU gerados de minuto em minuto em formato XML pelo próprio SQL Server e os  *
* mostra em uma lista com a última hora (60 valores), ordenados pelo tempo (mais recente primeiro).                       *
*      O primeiro mostra somente 1 resultado, o pico de CPU da última hora.                                               *
*      O segundo mostra todos os 60 minutos e seus respectivos picos.                                                     *
*                                                                                                                         *
***************************************************************************************************************************

DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 

SELECT MAX([SQL Server Process CPU Utilization]) FROM (
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
) AS z;

-----------------------------------------------------------------------------------------------------------------------------------------------
***********************************************************************************************************************************************
-----------------------------------------------------------------------------------------------------------------------------------------------

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