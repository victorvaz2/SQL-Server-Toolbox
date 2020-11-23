--==========================================================================
-- Obtaining the commands
--
--ONLY FOR ENTERPRISE EDITION
--==========================================================================

--Alter their values at will
DECLARE @schema varchar(50)				= 'dbo';
DECLARE @table varchar(75)				= 'table_name';
DECLARE @index_id int					= NULL;
DECLARE @partition_number int			= NULL;
DECLARE @data_compression varchar(4)	= 'ROW'		 --ROW, PAGE, NONE(Para decompress) 

--DO NOT ALTER THIS
DECLARE @cmd varchar(1000) = 'sp_estimate_data_compression_savings '''+ @schema +''','''+@table+''','+convert(varchar,@index_id)+','+convert(varchar,@partition_number)+','''+@data_compression+''''
DECLARE @cmdNoIndexOrPartition varchar(1000) = 'sp_estimate_data_compression_savings '''+ @schema +''','''+@table+''','+'NULL'+','+'NULL'+','''+@data_compression+''''

--Prints commands with and without an index_id or partition_number
PRINT @cmd;
PRINT @cmdNoIndexOrPartition;

--==========================================================================
-- Savings IN %
--
--size_with_current_compression_setting		= current
--size_with_requested_compression_setting	= future
--==========================================================================

SELECT 100 - ((future*100)/current)

--==========================================================================
-- Compress the data
--==========================================================================

ALTER TABLE @table REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = @data_compression)

