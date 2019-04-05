SELECT
    sproc.spid as SessionID,
    sproc.blocked as Blocked,
    sproc.cpu as CPU_Time,
    sproc.hostname as Hostname,
    sproc.cmd as Command,
    sproc.loginame as Username,
    DMVExecConn.client_net_address,
    DMVExecConn.connect_time as Connected_at,
    sproc.program_name as ProgramName
FROM
    sys.sysprocesses as sproc
        inner join
        sys.dm_exec_connections as DMVExecConn on
        sproc.spid = DMVExecConn.session_id
WHERE   sproc.status <> 'background'
	   --AND sproc.cmd <> 'AWAITING COMMAND'		 --Only those actually executing
ORDER BY 1 ASC;