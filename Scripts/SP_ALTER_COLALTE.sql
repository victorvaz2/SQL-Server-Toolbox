/*******************************************************
***** Alters all tables collate to a specified one *****
*******************************************************/

IF EXISTS (SELECT 1 FROM SYS.PROCEDURES WHERE NAME ='SP_ALTER_COLALTE')
    BEGIN 
    DROP PROCEDURE SP_ALTER_COLALTE
    END 
GO

CREATE PROCEDURE SP_ALTER_COLALTE (@Collate VARCHAR (30) =NULL) AS 
	IF @Collate IS NULL 
    BEGIN
		SELECT 'Please insert the collate' 
		RETURN
    END 

	/* Checks if temp tables exists */
	BEGIN TRY
		DROP TABLE #tmpErro, #indices,#COMANDOS,#INDICES_COLUNAS;
	END TRY
	BEGIN CATCH
	END CATCH;

	/* Declares variables */
	CREATE TABLE #tmpErro
    (Tabela   VARCHAR(1000),
	 scommand VARCHAR(500),
	 sMsgErr  VARCHAR(5000),
	 SCOL     VARCHAR(1000) COLLATE Latin1_General_CI_AS
    );

   CREATE TABLE #indices
   (Nome_index      VARCHAR(1000),
	--index_column_id INT,
	is_unique       INT,
	tabela          VARCHAR(1000),
	is_primary_key  INT
   );
   
   CREATE TABLE #INDICES_COLUNAS
   (Nome_index      VARCHAR(1000),
	index_column_id INT,
	coluna          VARCHAR(1000)
   );

   CREATE TABLE #COMANDOS
   (COMANDO_DROP   VARCHAR(MAX),
	COMANDO_CREATE VARCHAR(MAX),
	NOME_TABELA    VARCHAR(MAX),
	NOME_INDEX	   VARCHAR(MAX)
	);

	DECLARE @sCmd 		  VARCHAR(600), 
			@Tbl 		  VARCHAR(1000),
			@cln 		  VARCHAR(1000),
			@NOME_INDEX   VARCHAR (1000),
			@DROP_INDEX   VARCHAR(MAX),
			@CREATE_INDEX VARCHAR(MAX);

	PRINT 'Fetching tables';
	DECLARE CurCollate CURSOR FAST_FORWARD
	FOR 
    SELECT c.TABLE_NAME,
           'ALTER TABLE ['+c.TABLE_NAME+'] ALTER COLUMN ['+COLUMN_NAME+'] '+CASE
                                                                                WHEN DATA_TYPE IN('Text', 'NText')
                                                                                THEN DATA_TYPE
                                                                                WHEN CHARACTER_MAXIMUM_LENGTH = -1
                                                                                THEN DATA_TYPE+'(MAX)'
                                                                                ELSE DATA_TYPE+'('+CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(4))+')'
                                                                            END + ' COLLATE ' + @Collate + ' ' + CASE IS_NULLABLE
                                                                                                                             WHEN 'YES'
                                                                                                                             THEN 'NULL'
                                                                                                                             ELSE 'NOT NULL'
                                                                                                                         END,
           COLUMN_NAME
    FROM Information_Schema.Columns c
         INNER JOIN Information_Schema.tables t ON c.TABLE_NAME = t.TABLE_NAME
    WHERE c.COLLATION_NAME IS NOT NULL
          AND c.COLLATION_NAME <> @Collate
          AND t.TABLE_TYPE = 'BASE TABLE'
          /*AND c.TABLE_NAME NOT LIKE '%DSYNC%'*/
    ORDER BY c.TABLE_NAME ASC;

	OPEN CurCollate;
	FETCH NEXT FROM CurCollate INTO @tbl, @sCmd, @CLN;
	WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC (@sCmd);
        END TRY
        BEGIN CATCH
            INSERT INTO #tmpErro
			SELECT @tbl,
				   @sCmd,
				   ERROR_MESSAGE(),
				   @CLN;

            INSERT INTO #indices
            SELECT i.Name,
				   i.is_unique,
				   tabela.tabela,
				   i.is_primary_key
            FROM sys.indexes i
                        INNER JOIN #tmpErro tabela ON OBJECT_ID(tabela) = i.object_id
  		    WHERE tabela.TABELA = @tbl
			      AND TABELA.SCOL = @CLN;

            INSERT INTO #indices_COLUNAS
		    SELECT i.Name,
				   ic.index_column_id,
				   c.Name
				  
		    FROM sys.indexes i
				 INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id
													AND ic.index_id = i.index_id
				 LEFT JOIN sys.columns c ON c.object_id = ic.object_id
										    AND c.column_id = ic.column_id
				 INNER JOIN #tmpErro tabela ON OBJECT_ID(tabela) = i.object_id
		    WHERE tabela.TABELA = @tbl
				  AND TABELA.SCOL = @CLN;
        END CATCH;
        FETCH NEXT FROM CurCollate INTO @tbl, @sCmd, @CLN;
    END;
	
	PRINT 'Done';
	CLOSE CurCollate;
	DEALLOCATE CurCollate;

	PRINT 'Fetching indexes';
	DECLARE @ID_COL INT;
	
	DECLARE BUSCA_INDICES CURSOR FAST_FORWARD FOR 
	SELECT DISTINCT (NOME_INDEX) 
	FROM #INDICES

 	OPEN BUSCA_INDICES 
	FETCH NEXT FROM BUSCA_INDICES INTO @NOME_INDEX
	WHILE @@FETCH_STATUS=0

	BEGIN
		PRINT @NOME_INDEX;
		SET @DROP_INDEX ='';
		IF EXISTS (SELECT 1 FROM #indices WHERE IS_UNIQUE = 1 AND IS_PRIMARY_KEY = 1 and NOME_INDEX=@NOME_INDEX )
		BEGIN
			PRINT 'Fetching primary keys';
			
			SELECT @DROP_INDEX ='ALTER TABLE '+TABELA+' DROP CONSTRAINT ' +@NOME_INDEX,
				   @CREATE_INDEX='ALTER TABLE '+TABELA+' ADD CONSTRAINT ' +@NOME_INDEX + '(' 
			FROM #INDICES 
			WHERE NOME_INDEX= @NOME_INDEX;

			DECLARE MONTA_INDICE_PRIMARY CURSOR FAST_FORWARD FOR 
			SELECT INDEX_COLUMN_ID 
			FROM #indices_COLUNAS 
			WHERE NOME_INDEX =@NOME_INDEX;

			OPEN MONTA_INDICE_PRIMARY;
			FETCH NEXT FROM MONTA_INDICE_PRIMARY INTO @ID_COL;
			WHILE @@FETCH_STATUS=0		 
			BEGIN 
				SELECT @CREATE_INDEX = @CREATE_INDEX+ COLUNA + ',' 
				FROM #INDICES_COLUNAS
				WHERE NOME_INDEX = @NOME_INDEX 
					  AND INDEX_COLUMN_ID = @ID_COL;
				FETCH NEXT FROM MONTA_INDICE_PRIMARY INTO @ID_COL;
			END;
		
			SET @CREATE_INDEX = LEFT (@CREATE_INDEX, LEN(@CREATE_INDEX)-1) +')';
		    CLOSE MONTA_INDICE_PRIMARY;
		    DEALLOCATE MONTA_INDICE_PRIMARY;
	   END
	   ELSE  
	   IF EXISTS (SELECT 1 FROM #indices WHERE IS_UNIQUE = 1 AND IS_PRIMARY_KEY = 0 and NOME_INDEX=@NOME_INDEX)	
	   BEGIN
			PRINT 'Fetching unique keys';
			
			SELECT @DROP_INDEX ='DROP INDEX '+ @NOME_INDEX+ ' ON '+TABELA,
				   @CREATE_INDEX = 'CREATE UNIQUE NONCLUSTERED INDEX '+@NOME_INDEX+ ' ON ' +TABELA +'('
			FROM #INDICES
			WHERE NOME_INDEX= @NOME_INDEX

			DECLARE MONTA_INDICE_UNIQUE CURSOR FAST_FORWARD FOR 
			SELECT INDEX_COLUMN_ID 
			FROM #indices_COLUNAS 
			WHERE NOME_INDEX =@NOME_INDEX
			
			OPEN MONTA_INDICE_UNIQUE;
			FETCH NEXT FROM MONTA_INDICE_UNIQUE INTO @ID_COL;
			WHILE @@FETCH_STATUS=0
			BEGIN 
				SELECT @CREATE_INDEX = @CREATE_INDEX+ COLUNA + ',' 
				FROM #INDICES_COLUNAS
				WHERE NOME_INDEX = @NOME_INDEX 
					  AND INDEX_COLUMN_ID = @ID_COL;

				FETCH NEXT FROM MONTA_INDICE_UNIQUE INTO @ID_COL;
			END 
		
			SET @CREATE_INDEX = LEFT (@CREATE_INDEX, LEN(@CREATE_INDEX)-1) +')'
		    CLOSE MONTA_INDICE_UNIQUE
		    DEALLOCATE MONTA_INDICE_UNIQUE
		END
	    ELSE 
		IF EXISTS (SELECT 1 FROM #indices WHERE IS_UNIQUE = 0 and  NOME_INDEX=@NOME_INDEX)
		BEGIN
			PRINT 'Fetching nonclustered indexes';
			SELECT @DROP_INDEX ='DROP INDEX '+ @NOME_INDEX+ ' ON '+TABELA,
				   @CREATE_INDEX = 'CREATE NONCLUSTERED INDEX '+@NOME_INDEX+ ' ON ' +TABELA +'('
			FROM #INDICES
			WHERE NOME_INDEX= @NOME_INDEX;
			
			DECLARE MONTA_INDICE CURSOR FAST_FORWARD FOR 
			SELECT INDEX_COLUMN_ID 
			FROM #indices_COLUNAS 
			WHERE NOME_INDEX =@NOME_INDEX

			OPEN MONTA_INDICE;
			FETCH NEXT FROM MONTA_INDICE INTO @ID_COL;
			WHILE @@FETCH_STATUS=0
			BEGIN 
				SELECT @CREATE_INDEX = @CREATE_INDEX+ COLUNA + ',' 
				FROM #INDICES_COLUNAS 
				WHERE NOME_INDEX = @NOME_INDEX 
					  AND INDEX_COLUMN_ID = @ID_COL;

				FETCH NEXT FROM MONTA_INDICE INTO @ID_COL;
			END 
		
			SET @CREATE_INDEX = LEFT (@CREATE_INDEX, LEN(@CREATE_INDEX)-1) +')';
			CLOSE MONTA_INDICE;
			DEALLOCATE MONTA_INDICE;
		END;
		INSERT INTO #COMANDOS
		SELECT @DROP_INDEX,
				@CREATE_INDEX,
				TABELA,
				@NOME_INDEX
		FROM #INDICES 
		WHERE NOME_INDEX =@NOME_INDEX;
		FETCH NEXT FROM BUSCA_INDICES INTO @NOME_INDEX;
	END;
	
	CLOSE BUSCA_INDICES;
	DEALLOCATE BUSCA_INDICES;


	SELECT comando_drop,
		   scommand,
		   comando_create,
		   tabela 
	FROM #COMANDOS  com inner join 
		 #tmpErro err on tabela=nome_tabela;


 --SELECT * FROM #indices  
-- SELECT * FROM #tmpErro

 --SELECT * FROM #indices  
-- SELECT * FROM #indices_COLUNAS
 --SELECT * FROM #indices 
 --SELECT * FROM #indices IND INNER JOIN #indices_COLUNAS COL ON IND.NOME_INDEX=COL.NOME_INDEX WHERE COL.NOME_INDEX ='IX_PDV_CONSLD_ERROS_DT_MOV'
 