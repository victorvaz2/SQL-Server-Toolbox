/*Checar sessão com páginas de tempdb reservadas*/

SELECT database_transaction_log_bytes_reserved,session_id 
FROM sys.dm_tran_database_transactions AS tdt 
INNER JOIN sys.dm_tran_session_transactions AS tst 
ON tdt.transaction_id = tst.transaction_id 
WHERE database_id = 2;

/*Checar sessão com páginas reservadas, o que foi executado e o que está sendo executado*/

SELECT tdt.database_transaction_log_bytes_reserved,tst.session_id,
       t.[text], [statement] = COALESCE(NULLIF(
         SUBSTRING(
           t.[text],
           r.statement_start_offset / 2,
           CASE WHEN r.statement_end_offset < r.statement_start_offset
             THEN 0
             ELSE( r.statement_end_offset - r.statement_start_offset ) / 2 END
         ), ''
       ), t.[text])
     FROM sys.dm_tran_database_transactions AS tdt
     INNER JOIN sys.dm_tran_session_transactions AS tst
     ON tdt.transaction_id = tst.transaction_id
         LEFT OUTER JOIN sys.dm_exec_requests AS r
         ON tst.session_id = r.session_id
         OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
     WHERE tdt.database_id = 2;  
  
  