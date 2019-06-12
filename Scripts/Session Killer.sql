/*******************************************************************
***************************Blocker Killer***************************
********************************************************************/
/* Declaring variables */
DECLARE @Proteger int =669 --id conexão
DECLARE @SQL VARCHAR(MAX);
SET @SQL = '' ;

/*  */
SELECT 
	@SQL = @SQL + 'Kill  ' + CONVERT(VARCHAR, BLOCKED) + ';'
FROM MASTER..SYSPROCESSES
WHERE DBID = DB_ID() 
	  AND SPID > 50
	  AND BLOCKED> 0
	  AND SPID <> @@SPID
	  AND SPID=@PROTEGER;

EXEC(@SQL);
Print @sql;

go 666


/*******************************************************************
***************************Sleeping Killer**************************
********************************************************************/

BEGIN TRY DROP TABLE  #SP_WHO END TRY BEGIN CATCH END CATCH
  SET NOCOUNT ON;
  CREATE TABLE #SP_WHO
 (SPID       INT,
  ECID       INT,
  STATUS     VARCHAR(30),
  LOGINNAME  VARCHAR(150),
  HOSTNAME   VARCHAR(150),
  BLK        VARCHAR (3),
  DBNAME     VARCHAR(30),
  CMD        VARCHAR(50),
  REQUEST_ID INT
 );
 DECLARE @KILL VARCHAR (15),@COUNT INT 
 INSERT INTO #SP_WHO 
  EXEC SP_WHO
  DELETE FROM  #SP_WHO  WHERE STATUS <>'SLEEPING' OR SPID <50 OR HOSTNAME NOT LIKE '%AFEGANISTAO%'
  SET @COUNT=(SELECT COUNT(*) FROM #SP_WHO)
  WHILE (@COUNT > 0)
  BEGIN
  SELECT TOP 1 
  @KILL  ='KILL ' + CONVERT (VARCHAR,SPID) 
  FROM  #SP_WHO  
  EXEC (@KILL)
  PRINT @KILL
  DELETE TOP (1) FROM #SP_WHO
  SET @COUNT = @COUNT - 1
  END