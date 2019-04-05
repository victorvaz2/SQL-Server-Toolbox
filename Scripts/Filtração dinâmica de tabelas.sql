/*
Script criado por Victor Cotting Vaz
Modificado por: ColoqueSeuNomeAquiEmCasoDeModificação
Data: 02/03/2016
Descrição: 	Deletar as tuplas (registros, linhas, rows, tuples) de tabelas e que possuam mais que '@qtd_dias' de de existencia.
		O valor de @qtd_dias é definido na primeira linha executável de código, seguido por @qtd_meses.
			O script obtém dinamicamente os nomes dos atributos chaves, seus tipos e tamanhos, além de criar uma tabela
		temporária. Esta tabela é usada como um índice, contendo todas as chaves primárias que serão deletadas.
			A deleção destas tabelas é feita em lotes. O tamanho do lote poderá ser modificado alterando o valor de uma 
		unica variável.
*/

/*Declaração de variáveis alteráveis*/
DECLARE @qtd_dias INT = 90; 		--Quantidade de dias de vida máxima que os registros deverão ter. Deve ser equivalente a @qtd_meses (...3 = 90, 2 = 60, 1 = 30).
DECLARE @qtd_meses INT = 3; 		--Quantidade de meses de vida máxima que os registros deveão ter. Deve ser equivalente a @qtd_dias (...90 = 3, 60 = 2, 30 = 1).
DECLARE @tamanhoLote INT = 100000   --Quantidade de registros que deverão ser deletados de cada vez.
DECLARE @nomeTabela VARCHAR(100);	--Nome da tabela que será filtrada.
DECLARE @atributoTempo VARCHAR(50);	--Nome do atributo que define o tempo de vida de cada registro.
SET @nomeTabela = 'GLB_CHAVE_CPL';	--**********************************************MODIFICAR NOME DA TABELA!!*******************************************
SET @atributoTempo = 'data'			--**********************************************MODIFICAR NOME DO ATRIBUTO*******************************************

/*Declaração de variáveis fixas (não alterá-las)*/
DECLARE @selectPK VARCHAR(400)				--Armazena o SELECT utilizado para obter as primary keys da tabela.
DECLARE @pk VARCHAR(50)						--Armazena os nomes das primary key da tabela, um por vez, dentro de um loop. Transfere estes nomes para o @selectPK.
DECLARE @selectTipo VARCHAR(400)			--Armazena o SELECT utilizado para obter o tipo de cada primary key da tabela.
DECLARE @tipo VARCHAR(50)					--Armazena o tipo das primary key da tabela, um por vez, dentro de um loop. Transfere estes nomes para o @selectTipo.
DECLARE @createTable VARCHAR(800)			--Armazena o CREATE TABLE utilizado para criar a tabela 'cleanse', que é usada para armazenar todos os valores das
											--primary keys que serão deletadas.
DECLARE @selectTamanhoChar VARCHAR(400)		--Armazena o SELECT utilizado para obter o tamanho das primary keys que sejam de algum tipo de char.
DECLARE @tamanhoChar VARCHAR(10)			--Armazena o valor numerico do tamanho das primary keys, e o transfere para o @selectTamanhoChar.
DECLARE @selectTamanhoNumero1 VARCHAR(400)	--Armazena o SELECT utilizado para obter o tamanho das primary keys que sejam de um tipo numérico.
DECLARE @tamanhoNumero1 VARCHAR(5)			--Armazena o valor numérico do tamanho das primary keys, e o transfere para o @selectTamanhoNumero1.
DECLARE @selectTamanhoNumero2 VARCHAR(400)	--Armazena o SELECT utilizado para obter o número de casas decimais das primary keys que sejam de um tipo numérico.
DECLARE @tamanhoNumero2 VARCHAR(5)			--Armazena o valor 
DECLARE @insertInto VARCHAR(800)			--
DECLARE @pkInsert VARCHAR(400)				--
DECLARE @deleteFrom VARCHAR(1000)			--

/*Início da filtração, não alterar nada abaixo*/
/*Passos:
1- Obter as primary keys da tabela.
2- Obter o tipo das primary keys das tabelas.
3- Realizar a construção do CREATE TABLE para criar a tabela de limpeza de acordo com os tipos
	1- Caso o tipo não possua tamanho, somente colocar o tipo
	2- Caso o tipo possua tamanho de char, colocar o tipo e o tamanho de char
	3- Caso o tipo possua tamanho numérico, colocar o tipo e o tamanho numérico
	4- Caso o tipo possua tamanho numérico e número de casas decimais, colocar os dois
4- Inserir todos os registros que tenham mais de @qtd_dias ou @qtd_meses
5- Deletar todos os registros da tabela que será filtrada que esteja também na tabela 'cleanse'
*/
SET @selectPK = 'DECLARE cursor1 CURSOR fast_forward read_only for 
SELECT Col.Column_Name from 
INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab, 
INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE Col 
WHERE 
Col.Constraint_Name = Tab.Constraint_Name
AND Col.Table_Name = Tab.Table_Name
AND Constraint_Type =''PRIMARY KEY''
AND Col.Table_Name = ''' + @nomeTabela + ''''
SET @selectTipo = 'DECLARE cursor2 CURSOR fast_forward read_only for
SELECT DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_NAME = ''' + @nomeTabela + ''' AND 
COLUMN_NAME = '''
SET @selectTamanhoChar = 'DECLARE cursor3 CURSOR fast_forward read_only for
SELECT CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_NAME = ''' + @nomeTabela + ''' AND 
COLUMN_NAME = '''
SET @selectTamanhoNumero1 = 'DECLARE cursor4 CURSOR fast_forward read_only for
SELECT NUMERIC_PRECISION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_NAME = ''' + @nomeTabela + ''' AND 
COLUMN_NAME = '''
SET @selectTamanhoNumero2 = 'DECLARE cursor5 CURSOR fast_forward read_only for
SELECT NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_NAME = ''' + @nomeTabela + ''' AND 
COLUMN_NAME = '''
SET @createTable = 'CREATE TABLE cleanse ('
SET @insertInto = 'INSERT INTO cleanse ('
SET @pkInsert = ''
SET @deleteFrom = 'WHILE @@ROWCOUNT > 0 ' + char(13) + 'BEGIN' + char(13) + 'DELETE TOP(' + convert(char(9), @tamanhoLote) + ') FROM ' + @nomeTabela + 
' WHERE ' + @nomeTabela + '.'
--Fim da preparação de variáveis.
--Executa o cursor para obter as chaves primárias
EXECUTE (@selectPK)
OPEN cursor1
FETCH NEXT FROM cursor1 INTO @pk;
--Só será finalizado quando o cursor não obter nenhuma tupla.
WHILE @@FETCH_STATUS = 0
BEGIN
--Preparação de SELECT, CREATE TABLE, DELETE FROM e obtenção de chaves primárias com seus tipos e tamanhos respectivos.
	SET @selectTipo = @selectTipo + @pk + ''''
	EXECUTE (@selectTipo)
	SET @selectTipo = LEFT (@selectTipo , LEN(@selectTipo )-(LEN(@pk)+1));
	OPEN cursor2
	FETCH NEXT FROM cursor2 INTO @tipo;
	SET @createTable = @createTable + @pk + ' ' + @tipo
	SET @insertInto = @insertInto + @pk + ','
	SET @pkInsert = @pkInsert + @pk + ', '
	SET @deleteFrom = @deleteFrom + @pk + ' = cleanse.' + @pk + ' AND ' + @nomeTabela + '.'
	--Preparação do CREATE TABLE para caso não tenha tamanho.
	IF (CHARINDEX('int', @tipo) > 0 OR CHARINDEX('bigint', @tipo) > 0 OR CHARINDEX('bit', @tipo) > 0 OR CHARINDEX('date', @tipo) > 0OR CHARINDEX('datetime', @tipo) > 0
		OR CHARINDEX('datetime2', @tipo) > 0 OR CHARINDEX('integer', @tipo) > 0 OR CHARINDEX('money', @tipo) > 0 OR CHARINDEX('smallint', @tipo) > 0
		OR CHARINDEX('smalldatetime', @tipo) > 0 OR CHARINDEX('smallmoney', @tipo) > 0 OR CHARINDEX('timestamp', @tipo) > 0 OR CHARINDEX('tinyint', @tipo) > 0
		OR CHARINDEX('uniqueidentifier', @tipo) > 0 OR CHARINDEX('xml', @tipo)> 0)
	BEGIN
		SET @createTable = @createTable + ',' + CHAR(13)
	END
	--Preparação do CREATE TABLE para caso só tenha tamanho.
	ELSE IF (CHARINDEX('varchar', @tipo) > 0 OR CHARINDEX('nvarchar', @tipo) > 0 OR CHARINDEX('char', @tipo) > 0 OR CHARINDEX('nchar', @tipo) > 0)
	BEGIN
		SET @selectTamanhoChar = @selectTamanhoChar + @pk + ''''
		EXECUTE(@selectTamanhoChar)
		OPEN cursor3
		FETCH NEXT FROM cursor3 INTO @tamanhoChar;
		SET @createTable = @createTable + ' (' + @tamanhoChar + '),' + CHAR(13)
		SET @selectTamanhoChar = 'DECLARE cursor3 CURSOR fast_forward read_only for
SELECT CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_NAME = ' + @nomeTabela + ' AND 
COLUMN_NAME = '''
		CLOSE cursor3
		DEALLOCATE cursor3
	END
	--PREPARAÇÃO do CREATE TABLE para caso tenha tamanho e número de casas decimais.
	ELSE IF (CHARINDEX('numeric', @tipo) > 0 OR CHARINDEX('dec', @tipo) > 0 OR CHARINDEX('decimal', @tipo) > 0)
	BEGIN
		SET @selectTamanhoNumero1 = @selectTamanhoNumero1 + @pk + ''''
		SET @selectTamanhoNumero2 = @selectTamanhoNumero2 + @pk + ''''
		EXECUTE(@selectTamanhoNumero1)
		EXECUTE(@selectTamanhoNumero2)
		OPEN cursor4
		OPEN cursor5
		FETCH NEXT FROM cursor4 INTO @tamanhoNumero1;
		FETCH NEXT FROM cursor5 INTO @tamanhoNumero2;
		SET @createTable = @createTable + ' (' + @tamanhoNumero1 + ', ' + @tamanhoNumero2 + '),' + CHAR(13)
		CLOSE cursor4
		CLOSE cursor5
		DEALLOCATE cursor4
		DEALLOCATE cursor5
		SET @selectTamanhoNumero1 = 'DECLARE cursor4 CURSOR fast_forward read_only for
SELECT NUMERIC_PRECISION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_NAME = ' + @nomeTabela + ' AND
COLUMN_NAME = '''
		SET @selectTamanhoNumero2 = 'DECLARE cursor5 CURSOR fast_forward read_only for
SELECT NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_NAME = ' + @nomeTabela + ' AND 
COLUMN_NAME = '''
	END
	FETCH NEXT FROM cursor1 INTO @pk;
	CLOSE cursor2
	DEALLOCATE cursor2
END
CLOSE cursor1
DEALLOCATE cursor1
SET @createTable = LEFT (@createTable , LEN(@createTable)-2);
SET @createTable = @createTable + ')'
EXECUTE(@createTable)
SET @insertInto = LEFT (@insertInto , LEN(@insertInto)-1)
SET @pkInsert = LEFT (@pkInsert , LEN(@pkInsert)-1)
SET @insertInto = @insertInto + ')' + char(13) + 'SELECT ' + @pkInsert + ' FROM ' + @nomeTabela + ' WHERE ' + @atributoTempo + ' < (getdate()-@qtd_dias)'
EXECUTE(@insertInto)
SET @deleteFrom = LEFT (@deleteFrom , LEN(@deleteFrom)-(LEN(@nomeTabela)+5))
SET @deleteFrom = @deleteFrom + char(13) + 'END'
EXECUTE(@deleteFrom)
DROP TABLE cleanse
