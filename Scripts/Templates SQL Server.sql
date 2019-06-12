/******************************
* Indice:
*
* BOAS PRATICAS DE PROGRAMACAO
* PADRAO DE NOMES DE SCRIPTS
* PROCEDURES
* TABELAS
* VIEWS
* ADDICIONAR COLUNAS
* ALTERAR COLUNAS
******************************/

--#######################################################################BOAS PRATICAS DE PROGRAMACAO###########################################################################

/********************************************************************************
*
* Idente o codigo e mantenha-o identado!
* Comente todas as linhas ou blocos de codigo que ache pertinente uma explicacao!
* Palavras chaves em CAIXA ALTA!
* Utilize @ para variaveis temporarias!
* Utilize # para tabelas temporarias!
* Utilize TAB para identacao!
* Utilize nomes consistentes (de facil entendimento)!
* Nao comente demais o codigo!
* Evite linhas muito longas!
* Nao utilize acentuacao grafica!
*
********************************************************************************/

--#########################################################################PADRAO DE NOMES DE SCRIPTS#############################################################################

/*******************************************************************************
*                                                                               
* Procedures, VIEWs, Tabelas: 		NUMERO - MODULO - @NOME.sql                 
* Alteracao/Adicao de colunas:		NUMERO - MODULO - @TABELA @COLUNA.sql       
* Alteracao/Adicao de Primary Keys:	NUMERO - MODULO - Primary Key - @TABELA.sql 
*                                                                               
*******************************************************************************/

--###############################################################################PROCEDURES########################################################################################

/**********************************
* Template de criacao de Procedure
* Descricao breve
* Entrada (INPUT)
* Saida (OUTPUT)
*
* Exemplo de uso
*
* Nome e data do ultimo a modificar
*
**********************************/

--Exemplo:

/********************************************************************************************************************
*                                                                                                                   *
* Procedure executa quando o InterfacePDV falha.                                                                    *
* INPUT: CD_FILIAL (INT) e DT_PROC (DATETIME).                                                                      *
* OUTPUT: Insercao dos registros de vendas de convenio não parcelados na tabela RC_VD_CONV, parcelados caso preciso.*
*                                                                                                                   *
* Ex.: EXEC P_ALGO_XYZ 545,'2012-05-01'                                                                             *
*                                                                                                                   *
* Ultimo a modificar: Victor Vaz (02/12/2016)                                                                       *
*                                                                                                                   *
********************************************************************************************************************/

/* Checagem se existe a PROCEDURE no banco. */
IF EXISTS
(
    SELECT *
    FROM   sys.procedures
    WHERE  NAME = 'P_ALGO_XYZ'														/* Nome da procedure */
)
	BEGIN
	   DROP PROCEDURE P_ALGO_XYZ;													/* Nome da procedure */
	END;
GO

/* Script da procedure
CREATE PROCEDURE P_ALGO_XYZ (@CD_FILIAL INT,@DT_PROC AS DATETIME) AS 
...
*/

--##############################################################################TABELAS#########################################################################################

/*************************************
* Template de criacao de Tabela
* Descricao breve
*
* Observacoes importantes a considerar
*
* Nome e data do ultimo a modificar
*
*************************************/

--Exemplo:

/**************************************************************
* 
* Armazena dados de vendas a serem mostradas pelo InterfacePDV.
*
* STS_CLI = 1 (Algo1), 2 (Algo2), 3 (Algo3).
* FLAG_X = 1 (Não foi parcelado algo xyz).
*
* Ultimo a modificar: Victor Vaz (02/12/2016)
*
**************************************************************/

/* Checagem se existe a tabela no banco. */
IF NOT EXISTS
(
    SELECT *
    FROM   SYS.TABLES
    WHERE  NAME = 'ALGO_XYZ'															/* Nome da tabela */
)	
	BEGIN	
	
	/* Script de criacao da tabela, exemplo abaixo:
	
		CREATE TABLE [dbo].[ALGO_XYZ](	
			[CD_VD] [int] IDENTITY(1,1) NOT NULL,										--Codigo de Venda
			[Chave_PK2] [int] NOT NULL,													--Codigo XYZ
			[NM_CLI] [varchar] NOT NULL,												--Nome do cliente
			[ETC] [xyz] NULL,															--ETC
			
		CONSTRAINT [PK_ALGO_XYZ] PRIMARY KEY CLUSTERED 									 
		(	
			[CODIGO] ASC,																--Colunas seguidas da ordem (ASC (ascendente) ou DESC (decrescente)) 
			[CD_CONTROLE] ASC	
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

		--Criacao de constraints DEFAULT
		ALTER TABLE [dbo].[ALGO_XYZ] 
		ADD CONSTRAINT [DF_ALGO_XYZ_CODIGO]  DEFAULT ((0)) FOR [CODIGO]
		ALTER TABLE [dbo].[ALGO_XYZ] 
		ADD CONSTRAINT [DF_ALGO_XYZ_CD_USU_CORRECAO]  DEFAULT ((0)) FOR [CD_USU_CORRECAO]

		--Criacao de Foreing Keys (FKs)
		ALTER TABLE [dbo].[ALGO_XYZ]  WITH CHECK ADD CONSTRAINT [FK_ALGO_XYZ_ADM_ERRO] FOREIGN KEY([CODIGO])
		REFERENCES [dbo].[ADM_ERRO] ([CODIGO])
		ALTER TABLE [dbo].[ALGO_XYZ] CHECK CONSTRAINT [FK_ALGO_XYZ_ADM_ERRO]
	*/
	END;

--##############################################################################VIEWS#########################################################################################

/*************************************
* Template de criacao de VIEW
* Descricao breve
*
* Observacoes importantes a considerar
*
* Nome e data do ultimo a modificar
*
*************************************/

--Exemplo:

/*******************************************************************************
*
* Mostra os registros relacionados a XYZ que foram vendidos nos ultimos 10 dias.
*
* STS_CLI = 1 (Algo1), 2 (Algo2), 3 (Algo3).
*
* Ultimo a modificar: Victor Vaz (02/12/2016)
*
*******************************************************************************/

/* Checagem se existe a VIEW no banco. */
IF EXISTS
(
    SELECT *
    FROM   sys.views
    WHERE  object_id = OBJECT_ID(N'V_ALGO_XYZ')							/* Nome da VIEW */
)
	BEGIN
	   DROP VIEW [dbo].[V_ALGO_XYZ];											/* Nome da VIEW */
	END;
GO

CREATE VIEW V_ALGO_XYZ AS 														/* Nome da VIEW */

/* Script da view */


--##############################################################################ADDICIONAR COLUNAS#############################################################################

/*****************************************
* Template de criacao de ADICIONAR COLUNAS
* Descricao breve
*
* Observacoes importantes a considerar
*
* Nome e data do ultimo a modificar
*
*****************************************/

--Exemplo:

/********************************************
*
* Coluna guarda possiveis estados de algo.
*
* STS_XYZ = 1 (Algo1), 2 (Algo2), 3 (Algo3).
*
* Ultimo a modificar: Victor Vaz (02/12/2016)
*
********************************************/

/* Checagem se existe a coluna determinada, na tabela determinada, no banco. */
IF NOT EXISTS
(
    SELECT *
    FROM   SYS.COLUMNS
    WHERE  NAME = 'STS_XYZ'																	/* Nome da coluna */
		 AND OBJECT_ID = OBJECT_ID('ALGO_XYZ')												/* Nome da tabela */
)
	BEGIN
		
		/* Script de adicao da coluna, exemplo abaixo: 
		
		ALTER TABLE ALGO_XYZ
		ADD STS_XYZ INT NOT NULL
						CONSTRAINT DF_ALGO_XYZ_STS_XYZ DEFAULT(0);
		*/
	END;

--##############################################################################ALTERAR COLUNAS#############################################################################

/****************************************
* Template de criacao de ALTERAR COLUNAS
* Justificativa breve
*
* Observacoes importantes a considerar
*
* Nome e data do ultimo a modificar
*
****************************************/

--Exemplo:

/****************************************************************************************************
*
* Coluna deveria guardar possiveis estados de algo, porem o tipo anterior (money) era desnecessario, 
* tipo int economiza em espaco.
*
* Ultimo a modificar: Victor Vaz (02/12/2016)
*
****************************************************************************************************/

/* Checagem se existe a coluna determinada, na tabela determinada, no banco. */
IF EXISTS
(
    SELECT *
    FROM   SYS.COLUMNS
    WHERE  NAME = 'STS_XYZ'														/* Nome da coluna */
		 AND OBJECT_ID = OBJECT_ID('ALGO_XYZ')									/* Nome da tabela */
)
    BEGIN

		/* Script de alteracao da coluna, exemplo abaixo: 
		
		ALTER TABLE ALGO_XYZ ALTER COLUMN STS_XYZ INT;
		*/
    
	END;

--##############################################################################PRIMARY KEYS#############################################################################

/**************************************
* Template de criacao de PRIMARY KEYS
* Justificativa breve
*
* Observacoes importantes a considerar
*
* Nome e data do ultimo a modificar
*
**************************************/

--Exemplo:

/****************************************************************************************************************
* 
* Devido a mudanças na regra de negócio, autorizadas pelo Ramam Freitas, e devido a nova coluna de código de xyz,
* utilizadas pela aplicação App_xyz, ...
*
* Ultimo a modificar: Victor Vaz (02/12/2016)
*
****************************************************************************************************************/

/* Checagem se existe uma PRIMARY KEY, na tabela, no banco. */
IF NOT EXISTS
(
    SELECT *
    FROM   INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE  CONSTRAINT_TYPE = 'PRIMARY KEY'
		 AND TABLE_NAME = 'ALGO_XYZ'																		/* Nome da tabela */
		 AND TABLE_SCHEMA = 'dbo'
)
    BEGIN
	
	/* Script de criacao da PRIMARY KEY, exemplo abaixo:
	
						   Tabela                   Nome da PK                  Colunas separadas por ',' 
	   ALTER TABLE [dbo].[ALGO_XYZ] ADD CONSTRAINT [PK_ALGO_XYZ] PRIMARY KEY CLUSTERED ([COD_XYZ])
	*/
	
    END;
