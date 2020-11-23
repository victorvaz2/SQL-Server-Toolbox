/************************************************************************
* Alters all columns in the database to the @collate collation.			*
*																		*
* Alter @collate and define the collation you wish.                 	*
************************************************************************/

DECLARE @collate nvarchar(100);
DECLARE @table nvarchar(255);
DECLARE @column_name nvarchar(255);
DECLARE @column_id int;
DECLARE @data_type nvarchar(255);
DECLARE @max_length int;
DECLARE @row_id int;
DECLARE @sql nvarchar(max);
DECLARE @sql_column nvarchar(max);
DECLARE @is_nullable int;

--The collation you wish to have
SET @collate = 'SQL_Latin1_General_CP1_CI_AS';

DECLARE local_table_cursor CURSOR FOR

SELECT [name]
FROM sysobjects
WHERE OBJECTPROPERTY(id, N'IsUserTable') = 1

OPEN local_table_cursor
FETCH NEXT FROM local_table_cursor
INTO @table

WHILE @@FETCH_STATUS = 0
BEGIN

    DECLARE local_change_cursor CURSOR FOR

	--Gather the necessary data
    SELECT ROW_NUMBER() OVER (ORDER BY c.column_id) AS row_id
        , c.name column_name
        , t.Name data_type
        , c.max_length
        , c.column_id
	   , c.is_nullable
    FROM sys.columns c
    JOIN sys.types t ON c.system_type_id = t.system_type_id
    LEFT OUTER JOIN sys.index_columns ic ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    LEFT OUTER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE c.object_id = OBJECT_ID(@table)
	AND c.collation_name <> @collate
    ORDER BY c.column_id

	--Places the data in the following variables, 1 row at a time
    OPEN local_change_cursor
    FETCH NEXT FROM local_change_cursor
    INTO @row_id, @column_name, @data_type, @max_length, @column_id, @is_nullable

    WHILE @@FETCH_STATUS = 0
    BEGIN

        IF (@data_type LIKE '%char%')
        BEGIN TRY
			
			IF @is_nullable = 0
			--Generates the NOT NULL constraints
				SET @sql = 'ALTER TABLE ' + @table + ' ALTER COLUMN ' + @column_name + ' ' + @data_type + '(' + CAST(@max_length AS nvarchar(100)) + ') COLLATE ' + @collate + ' NOT NULL' + ';'
			ELSE  
			--Generates the NULL constraints
				SET @sql = 'ALTER TABLE ' + @table + ' ALTER COLUMN ' + @column_name + ' ' + @data_type + '(' + CAST(@max_length AS nvarchar(100)) + ') COLLATE ' + @collate + ' NULL' + ';'
			
			--Prints the command that will be executed
			PRINT @sql
			--Executes the command
			EXEC (@sql)
			
        END TRY
        BEGIN CATCH
			PRINT 'ERROR: Some index or constraint rely on the column ' + @column_name + '. No conversion possible.'
			--PRINT @sql
        END CATCH

        FETCH NEXT FROM local_change_cursor
        INTO @row_id, @column_name, @data_type, @max_length, @column_id, @is_nullable

    END

    CLOSE local_change_cursor
    DEALLOCATE local_change_cursor

    FETCH NEXT FROM local_table_cursor
    INTO @table

END

CLOSE local_table_cursor
DEALLOCATE local_table_cursor

GO


/**********************************************************************************************************
***********************************************************************************************************
**********************************************************************************************************/

DECLARE @Collation VARCHAR(30)
SET @Collation = 'SQL_Latin1_General_CP1_CI_AS'
begin try drop table #tmpErro
end try begin catch end catch
create table #tmpErro (Tabela varchar(1000), scommand varchar(500), sMsgErr varchar(5000)) 
DECLARE @sCmd as varchar(600);
DECLARE @Tbl as  varchar (1000);
 
DECLARE  CurCollate CURSOR FAST_FORWARD FOR 
SELECT  
    c.TABLE_NAME,
	'ALTER TABLE [' + c.TABLE_NAME + '] ALTER COLUMN [' + COLUMN_NAME + '] ' + 
	CASE WHEN DATA_TYPE IN ('Text','NText') THEN DATA_TYPE
		WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN DATA_TYPE + '(MAX)'
	ELSE DATA_TYPE + '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(4)) + ')'
	END + ' COLLATE ' + @Collation + ' ' +
	CASE IS_NULLABLE WHEN 'YES'  THEN 'NULL' 
		ELSE 'NOT NULL' 
	END
FROM 
	Information_Schema.Columns c 
	INNER JOIN Information_Schema.tables t ON
	c.TABLE_NAME = t.TABLE_NAME  
WHERE 
	c.COLLATION_NAME IS NOT NULL 
	AND c.COLLATION_NAME <> 'SQL_Latin1_General_CP1_CI_AS'
	AND	t.TABLE_TYPE <> 'VIEW' 
	and c.TABLE_NAME not like '%DSYNC%' 
	order by c.TABLE_NAME


	OPEN CurCollate 
	FETCH NEXT FROM CurCollate INTO @tbl, @sCmd
	WHILE @@FETCH_STATUS=0
	BEGIN  
		BEGIN TRY
			EXEC (@sCmd);
		END TRY
		BEGIN CATCH  
			insert into #tmpErro
			SELECT 
				@tbl,
				@sCmd,
				ERROR_MESSAGE()
		END CATCH 
	 
	   FETCH NEXT FROM CurCollate INTO @tbl, @sCmd
	END 
	PRINT 'Concluido.'
	CLOSE CurCollate
	DEALLOCATE CurCollate

 	   select * from #tmpErro


/*
	 	 SELECT 
    IndexName = i.Name,
    ColName = c.Name, i.is_unique,
    tabela.tabela,
    i.is_primary_key
FROM 
    sys.indexes i
INNER JOIN 
    sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
INNER JOIN 
    sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    inner join #tmpErro tabela 
     on 
	object_id(tabela) =i.object_id

	where i.is_primary_key <>1
	*/