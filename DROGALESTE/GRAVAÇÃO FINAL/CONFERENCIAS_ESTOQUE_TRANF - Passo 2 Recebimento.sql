--BEGIN TRANSACTION
--ROLLBACK
--COMMIT

/*====================================================================================================================*/
/* VERSÃO        DATA ALTERAÇÃO    ALTERADO POR            DESCRIÇÃO                                                  */
/*====================================================================================================================*/
/* 0001          24/10/2022        JUNIOR OLIVEIRA         • INCLUSÃO DE VALIDAÇÃO QUE NÃO PERMITE LOJA DESTINO       */
/*                                                         DIFERENTE DO PASSO 1                                       */
/*                                                         • INCLUSÃO DE VALIDAÇÃO QUE NÃO PERMITE GRAVAR PRODUTOS    */
/*                                                         QUE NÃO CONTÉM NO PASSO 1                                  */
/*====================================================================================================================*/


DECLARE @CONFERENCIA_TRANSFERENCIA       NUMERIC(15) = :CONFERENCIA_TRANSFERENCIA
DECLARE @ESTOQUE_TRANSFERENCIA           NUMERIC(15) = :ESTOQUE_TRANSFERENCIA
DECLARE @CENTRO_ESTOQUE                  NUMERIC(15)   
DECLARE @TIPO_CONFERENCIA                NUMERIC(15) = :TIPO_CONFERENCIA

DECLARE @FORMULARIO_ORIGEM               NUMERIC(15) 
DECLARE @TAB_MASTER_ORIGEM               NUMERIC(15) 

DECLARE @REGISTRO_LOG_TEMPO              NUMERIC(15) 
DECLARE @EMPRESA_WMS                     VARCHAR(1)  
DECLARE @USUARIO_LOGADO                  NUMERIC(15) = :USUARIO_LOGADO

--PEGA AS ORIGENS--
SELECT @FORMULARIO_ORIGEM = A.FORMULARIO_ORIGEM,
       @TAB_MASTER_ORIGEM = A.TAB_MASTER_ORIGEM
  FROM CONFERENCIAS_ESTOQUE_TRANF A WITH(NOLOCK)
 WHERE A.CONFERENCIA_TRANSFERENCIA = @CONFERENCIA_TRANSFERENCIA

/*==========================================================================================*/
/*                   NÃO PERMITE LOJA DESTINDO DIFERENTE DO PASSO 1                         */
/*==========================================================================================*/

IF EXISTS(SELECT TOP 1 A.ESTOQUE_TRANSFERENCIA, A.EMPRESA, A.ENTIDADE
           FROM ESTOQUE_TRANSFERENCIAS    A WITH(NOLOCK)
          WHERE 1=1
            AND A.ESTOQUE_TRANSFERENCIA = @ESTOQUE_TRANSFERENCIA
            AND A.EMPRESA               = @EMPRESA
            AND A.ENTIDADE             <> @ENTIDADE)
    BEGIN 
          RAISERROR('A empresa destino(Passo 2) difere da empresa destino(Passo 1)', 16, 1)
    END 

/*==========================================================================================*/
/*                   CONFERE SE PRODUTOS NO PASSO 2 SÃO SOLICITADOS NO PASSO 1                         */
/*==========================================================================================*/

IF EXISTS(SELECT
              PRODUTO
              ,CODIGO_BARRAS
              ,A.ESTOQUE_TRANSFERENCIA
          FROM CONFERENCIAS_ESTOQUE_TRANF           A WITH(NOLOCK)
          LEFT
          JOIN CONFERENCIAS_ESTOQUE_TRANF_MANUAL    B WITH(NOLOCK)ON B.CONFERENCIA_TRANSFERENCIA = A.CONFERENCIA_TRANSFERENCIA

        WHERE A.ESTOQUE_TRANSFERENCIA = @ESTOQUE_TRANSFERENCIA

        EXCEPT

        SELECT
               B.PRODUTO
              ,B.CODIGO_BARRA
              ,A.ESTOQUE_TRANSFERENCIA
          FROM ESTOQUE_TRANSFERENCIAS             A WITH(NOLOCK)
          LEFT
          JOIN ESTOQUE_TRANSFERENCIAS_PRODUTOS    B WITH(NOLOCK)ON A.ESTOQUE_TRANSFERENCIA = B.ESTOQUE_TRANSFERENCIA
        WHERE A.ESTOQUE_TRANSFERENCIA = @ESTOQUE_TRANSFERENCIA)
    BEGIN 
          RAISERROR('Os produtos lançados não conferem com os produtos do Passo 1.', 16, 1)
    END 
         


-------------------------------------------------------------
--GERACAO DE TABELAS TEMPORARIAS PARA O PROCESSOS
-------------------------------------------------------------

if object_id('tempdb..#PRODUTOS')         is not null DROP TABLE #PRODUTOS
if object_id('tempdb..#RESULTADOS')       is not null DROP TABLE #RESULTADOS
if object_id('tempdb..#RESULTADOS_FINAL') is not null DROP TABLE #RESULTADOS_FINAL

       

SELECT DISTINCT TMP.PRODUTO

INTO #PRODUTOS

FROM (
       SELECT DISTINCT A.PRODUTO
         FROM CONFERENCIAS_ESTOQUE_TRANF_COLETA A WITH(NOLOCK)
        WHERE A.CONFERENCIA_TRANSFERENCIA = @CONFERENCIA_TRANSFERENCIA 

        UNION ALL 

       SELECT DISTINCT A.PRODUTO
         FROM CONFERENCIAS_ESTOQUE_TRANF_COLETA_2 A WITH(NOLOCK)
        WHERE A.CONFERENCIA_TRANSFERENCIA = @CONFERENCIA_TRANSFERENCIA

        UNION ALL

       SELECT DISTINCT A.PRODUTO
         FROM CONFERENCIAS_ESTOQUE_TRANF_MANUAL A WITH(NOLOCK)
        WHERE A.CONFERENCIA_TRANSFERENCIA = @CONFERENCIA_TRANSFERENCIA 
     ) TMP


       
----------------------------------------------------
--PEGA OS PRODUTOS DA COLETA
----------------------------------------------------

  SELECT A.PRODUTO                                   AS PRODUTO,
         C.LOTE_VALIDADE                             AS LOTE_VALIDADE ,
         SUM(C.QUANTIDADE * C.QUANTIDADE_EMBALAGEM ) AS QUANTIDADE,
         SUM(C.QUANTIDADE_UNIT )                     AS QUANTIDADE_UNIT,       
         'S'                                         AS COLETOR
         
    INTO #RESULTADOS
         
    FROM PRODUTOS                          A WITH(NOLOCK)
    JOIN #PRODUTOS                         B WITH(NOLOCK) ON A.PRODUTO = B.PRODUTO
    JOIN CONFERENCIAS_ESTOQUE_TRANF_COLETA C WITH(NOLOCK) ON A.PRODUTO = C.PRODUTO
   
   WHERE C.CONFERENCIA_TRANSFERENCIA = @CONFERENCIA_TRANSFERENCIA

GROUP BY A.PRODUTO ,
         C.LOTE_VALIDADE

   UNION ALL

----------------------------------------------------
--PEGA OS PRODUTOS DA COLETA 2
----------------------------------------------------

  SELECT A.PRODUTO                                   AS PRODUTO,
         C.LOTE_VALIDADE                             AS LOTE_VALIDADE,
         SUM(C.QUANTIDADE * C.QUANTIDADE_EMBALAGEM ) AS QUANTIDADE,
         SUM(C.QUANTIDADE_UNIT )                     AS QUANTIDADE_UNIT,
         'S'                                         AS COLETOR
       
    FROM PRODUTOS                            A WITH(NOLOCK) 
    JOIN #PRODUTOS                           B WITH(NOLOCK) ON A.PRODUTO = B.PRODUTO
    JOIN CONFERENCIAS_ESTOQUE_TRANF_COLETA_2 C WITH(NOLOCK) ON A.PRODUTO = C.PRODUTO
 
   WHERE C.CONFERENCIA_TRANSFERENCIA =@CONFERENCIA_TRANSFERENCIA

GROUP BY A.PRODUTO ,
         C.LOTE_VALIDADE

   UNION ALL

----------------------------------------------------
--PEGA OS PRODUTOS MANUAIS
----------------------------------------------------

  SELECT A.PRODUTO                                   AS PRODUTO,
         B.LOTE_VALIDADE                             AS LOTE_VALIDADE,
         SUM(B.QUANTIDADE * B.QUANTIDADE_EMBALAGEM)  AS QUANTIDADE,
         SUM(B.QUANTIDADE_UNIT )                     AS QUANTIDADE_UNIT,       
         'N'                                         AS COLETOR       
        
    FROM PRODUTOS                          A WITH(NOLOCK) 
    JOIN CONFERENCIAS_ESTOQUE_TRANF_MANUAL B WITH(NOLOCK) ON A.PRODUTO = B.PRODUTO
 
   WHERE B.CONFERENCIA_TRANSFERENCIA = @CONFERENCIA_TRANSFERENCIA
   
GROUP BY A.PRODUTO ,
         B.LOTE_VALIDADE


   UNION ALL

--------------------------------------------------
--PEGA OS PRODUTOS ROMANEIO COMO CONFERIDO--
----------------------------------------------------

  SELECT A.PRODUTO                   AS PRODUTO,
         NULL                        AS LOTE_VALIDADE ,
         SUM(B.QUANTIDADE_UNITARIA ) AS QUANTIDADE,
         SUM(B.QUANTIDADE_UNITARIA ) AS QUANTIDADE_UNIT,       
         'N'                         AS COLETOR       
        
    FROM PRODUTOS                        A WITH(NOLOCK)
    JOIN ESTOQUE_TRANSFERENCIAS_PRODUTOS B WITH(NOLOCK) ON A.PRODUTO = B.PRODUTO
 
   WHERE B.ESTOQUE_TRANSFERENCIA = @ESTOQUE_TRANSFERENCIA
     AND @TIPO_CONFERENCIA = 2
   
GROUP BY A.PRODUTO 


   UNION ALL

--------------------------------------------------
--PEGA OS PRODUTOS FALTAS
----------------------------------------------------

  SELECT A.PRODUTO                     AS PRODUTO,
         NULL                          AS LOTE_VALIDADE ,
         SUM(B.QUANTIDADE_UNIT ) * - 1 AS QUANTIDADE,
         SUM(B.QUANTIDADE_UNIT ) * - 1 AS QUANTIDADE_UNIT,       
         'N'                           AS COLETOR       
        
    FROM PRODUTOS                          A WITH(NOLOCK)
    JOIN CONFERENCIAS_ESTOQUE_TRANF_FALTAS B WITH(NOLOCK) ON A.PRODUTO = B.PRODUTO
 
   WHERE B.CONFERENCIA_TRANSFERENCIA = @CONFERENCIA_TRANSFERENCIA
     AND @TIPO_CONFERENCIA = 2
   
GROUP BY A.PRODUTO 


--------------------------------------------------------
--RESULTADO FINAL--
--------------------------------------------------------
       
              
   SELECT A.PRODUTO,
          A.LOTE_VALIDADE,
          SUM(A.QUANTIDADE)      AS QUANTIDADE,
          SUM(A.QUANTIDADE_UNIT) AS QUANTIDADE_UNIT             

     INTO #RESULTADOS_FINAL
       
     FROM #RESULTADOS A
    
 GROUP BY A.PRODUTO, 
          A.LOTE_VALIDADE
 
    HAVING SUM(A.QUANTIDADE_UNIT) > 0


--------------------------------------------------------
--RESULTADO FINAL--
--------------------------------------------------------

if object_id('tempdb..#RESULTADOS_SEM_LOTE') is not null DROP TABLE #RESULTADOS_SEM_LOTE

   SELECT A.PRODUTO,
          SUM(A.QUANTIDADE)      AS QUANTIDADE,
          SUM(A.QUANTIDADE_UNIT) AS QUANTIDADE_UNIT             

     INTO #RESULTADOS_SEM_LOTE
       
     FROM #RESULTADOS_FINAL A
    WHERE A.LOTE_VALIDADE IS NULL
   GROUP BY A.PRODUTO
 
 
-----------------------------------------------------
--CARREGA CENTRO DE ESTOQUE --
-----------------------------------------------------

SELECT @CENTRO_ESTOQUE = A.CENTRO_ESTOQUE_ORIGEM
  FROM ESTOQUE_TRANSFERENCIAS A WITH(NOLOCK)
 WHERE A.ESTOQUE_TRANSFERENCIA = @ESTOQUE_TRANSFERENCIA

--------------------------------------------
-- CRIA #ESTOQUE_TRANSFERENCIAS_PENDENTES --
--------------------------------------------

if object_id('tempdb..#ESTOQUE_TRANSFERENCIAS_PENDENTES') is not null
   DROP TABLE #ESTOQUE_TRANSFERENCIAS_PENDENTES

  SELECT B.CENTRO_ESTOQUE_ORIGEM AS CENTRO_ESTOQUE,
         A.PRODUTO,
         A.LOTE_VALIDADE,
         SUM(A.QUANTIDADE) AS SALDO
         
    INTO #ESTOQUE_TRANSFERENCIAS_PENDENTES
       
    FROM ESTOQUE_TRANSFERENCIAS_LOTE_VALIDADE_PENDENTES   A WITH(NOLOCK)
    JOIN ESTOQUE_TRANSFERENCIAS                           B WITH(NOLOCK) ON A.ESTOQUE_TRANSFERENCIA = B.ESTOQUE_TRANSFERENCIA
	JOIN ( SELECT DISTINCT A.PRODUTO
	         FROM #RESULTADOS_SEM_LOTE A ) X ON X.PRODUTO = A.PRODUTO
   WHERE A.ESTOQUE_TRANSFERENCIA <> @ESTOQUE_TRANSFERENCIA
     AND B.CENTRO_ESTOQUE_ORIGEM = @CENTRO_ESTOQUE

GROUP BY B.CENTRO_ESTOQUE_ORIGEM,
         A.PRODUTO,
         A.LOTE_VALIDADE

---------------------------------------------
--PEGA O SALDO POR LOTE E VALIDADE
---------------------------------------------

if object_id('tempdb..#SALDO_LV') is not null
   DROP TABLE #SALDO_LV

-----------------------------------------------------
--PEGA O SALDO POR LOTE E VALIDADE DO PICKING
-----------------------------------------------------

if object_id('tempdb..#SALDO_LV') is not null
   DROP TABLE #SALDO_LV

CREATE TABLE [dbo].[#SALDO_LV] (
    [PRODUTO                   ] NUMERIC (15, 0),
    [CENTRO_ESTOQUE            ] NUMERIC (15, 0),
    [LOTE_VALIDADE             ] NUMERIC (15, 0),
    [VALIDADE                  ] DATETIME,
    [ESTOQUE_SALDO             ] NUMERIC (15, 2),
    [ACUMULADO                 ] NUMERIC (15, 2),
    [QTDE_CONSUMO              ] NUMERIC (15, 2),
    [QTDE_ALOCADA              ] NUMERIC (15, 2),
    [PROCESSADO                ] VARCHAR(1),
    [ID                        ] NUMERIC (15, 0),
)


INSERT INTO #SALDO_LV ( 
 
            PRODUTO,
            CENTRO_ESTOQUE,
            LOTE_VALIDADE,
            VALIDADE,
            ESTOQUE_SALDO,
            ACUMULADO,
            QTDE_CONSUMO,
            QTDE_ALOCADA,
            PROCESSADO, 
            ID )

SELECT A.PRODUTO,
       A.CENTRO_ESTOQUE,
       A.LOTE_VALIDADE,
       C.VALIDADE,
       CAST( ( A.ESTOQUE_SALDO - ISNULL(Z.SALDO,0) )  AS NUMERIC(15,4) ) 
	                            AS ESTOQUE_SALDO ,
       CAST(0 AS NUMERIC(15,4)) AS ACUMULADO,
       X.QUANTIDADE_REAL        AS QTDE_CONSUMO,
       CAST(0 AS NUMERIC(15,4)) AS QTDE_ALOCADA,
       'N'                      AS PROCESSADO,
       ROW_NUMBER( ) OVER ( ORDER BY A.PRODUTO, C.VALIDADE, A.ESTOQUE_SALDO ) AS ID


  FROM LOTE_VALIDADE_ATUAL        A WITH(NOLOCK)
  JOIN ( SELECT A.PRODUTO               AS PRODUTO,
                SUM(A.QUANTIDADE_UNIT)  AS QUANTIDADE_REAL
           FROM #RESULTADOS_SEM_LOTE A 
       GROUP BY A.PRODUTO )       X    ON X.PRODUTO        = A.PRODUTO

  JOIN PRODUTOS_LOTE_VALIDADE     C WITH(NOLOCK) ON C.PRODUTO        = A.PRODUTO
                                                AND C.LOTE_VALIDADE  = A.LOTE_VALIDADE


  LEFT JOIN #ESTOQUE_TRANSFERENCIAS_PENDENTES   Z ON Z.PRODUTO        = A.PRODUTO
                                                 AND Z.CENTRO_ESTOQUE = A.CENTRO_ESTOQUE
                                                 AND Z.LOTE_VALIDADE  = A.LOTE_VALIDADE

 WHERE A.ESTOQUE_SALDO > 0 
   AND A.CENTRO_ESTOQUE = @CENTRO_ESTOQUE

   ORDER BY PRODUTO, VALIDADE, ESTOQUE_SALDO 


   --TIRA PRODUTOS SEM SALDO--
   DELETE FROM #SALDO_LV WHERE ESTOQUE_SALDO < 0.00


    --=====================================--
    --ATUALIZA O VALOR ACUMULADO--
    --=====================================--
    UPDATE #SALDO_LV 
       SET ACUMULADO  = ( SELECT SUM ( A.ESTOQUE_SALDO ) 
                            FROM #SALDO_LV A 
                           WHERE A.ID     < = #SALDO_LV.ID 
                             AND A.PRODUTO  = #SALDO_LV.PRODUTO
                             )

    --RETIRA OS PRODUTOS COM SALDO > NECESSIDADE DE CONSUMO--

    DELETE #SALDO_LV
      FROM #SALDO_LV A 
      JOIN ( SELECT A.PRODUTO,
                    MIN(A.ID) AS ID           
               FROM #SALDO_LV A 
              WHERE A.ACUMULADO > A.QTDE_CONSUMO
           GROUP BY A.PRODUTO ) X ON X.PRODUTO = A.PRODUTO
                                 AND A.ID      > X.ID 
   

--********************************************************************************---
--WHILE PARA PROCESSAMENTO DOS SALDOS E ALOCAÇÃO DO CONSUMO POR LOTE E VALIDADE
--********************************************************************************---

--VARIAVEIS--
DECLARE @PRODUTO          NUMERIC
DECLARE @CONT_PRODUTO     INT
DECLARE @CONT_PROCESSADO  INT
DECLARE @ID               NUMERIC


--INICIO DO WHILE--
WHILE EXISTS ( SELECT TOP 1 1 
                 FROM #SALDO_LV A
                WHERE A.PROCESSADO = 'N') 
   
   BEGIN

        SELECT TOP 1 
               @PRODUTO = A.PRODUTO,
               @ID      = A.ID
          FROM #SALDO_LV A
         WHERE A.PROCESSADO = 'N'
         ORDER BY A.ID

         --ATUALIZA Q QUANTIDADE ALOCADA POR PRODUTO--         
         UPDATE #SALDO_LV 
   
            SET QTDE_ALOCADA = CASE WHEN X.QTDE_ALOCADA_ACUMULADO >= X.QTDE_CONSUMO
                                    THEN 0.00
                                    ELSE CASE WHEN A.ESTOQUE_SALDO <= ( X.QTDE_CONSUMO - X.QTDE_ALOCADA_ACUMULADO )
                                              THEN A.ESTOQUE_SALDO
                                              ELSE ( X.QTDE_CONSUMO - X.QTDE_ALOCADA_ACUMULADO )
                                         END 
                               END ,

                PROCESSADO = 'S'

           FROM #SALDO_LV A
           JOIN ( SELECT SUM(A.QTDE_ALOCADA) AS QTDE_ALOCADA_ACUMULADO,
                         MAX(A.QTDE_CONSUMO) AS QTDE_CONSUMO
                    FROM #SALDO_LV A 
                   WHERE A.PRODUTO = @PRODUTO) X ON 1 = 1 
           WHERE A.ID = @ID

    END --END WHILE


--COMPLEMENTA A TABELA DE SALDO COM O SALDO DE CONSUMO NÃO ALOCADO CASO NÃO HAJA SALDO EM ESTOQUE POR LOTE E VALIDADE--

INSERT INTO #SALDO_LV ( 
 
            PRODUTO,
            CENTRO_ESTOQUE,
            LOTE_VALIDADE,
            VALIDADE,
            ESTOQUE_SALDO,
            ACUMULADO,
            QTDE_CONSUMO,
            QTDE_ALOCADA,
            PROCESSADO, 
            ID )

SELECT A.PRODUTO,
       @CENTRO_ESTOQUE   AS CENTRO_ESTOQUE,
       Z.LOTE_VALIDADE   AS LOTE_VALIDADE,
       Z.VALIDADE        AS VALIDADE,
       0.0000            AS ESTOQUE_SALDO ,
       0.0000            AS ACUMULADO,
       0.0000            AS QTDE_CONSUMO,
       A.QUANTIDADE_UNIT - ISNULL(X.QTDE_ALOCADA,0) AS QTDE_ALOCADA,
       'S'               AS PROCESSADO,
       0                 AS ID

  FROM #RESULTADOS_SEM_LOTE A 

LEFT JOIN ( SELECT A.PRODUTO,
                   MAX(B.LOTE_VALIDADE) AS LOTE_VALIDADE
              FROM #RESULTADOS_SEM_LOTE      A WITH(NOLOCK)
			  JOIN PRODUTOS_LOTE_VALIDADE    B WITH(NOLOCK) ON B.PRODUTO = A.PRODUTO
            GROUP BY A.PRODUTO ) B ON B.PRODUTO = A.PRODUTO

LEFT JOIN ( SELECT A.PRODUTO,
                   SUM(A.QTDE_ALOCADA) AS QTDE_ALOCADA,
                   MAX(A.ID) AS ID
              FROM #SALDO_LV A 
            GROUP BY A.PRODUTO )  X ON X.PRODUTO = A.PRODUTO

LEFT  JOIN #SALDO_LV              Y ON Y.PRODUTO = X.PRODUTO
                                   AND Y.ID      = X.ID

LEFT  JOIN PRODUTOS_LOTE_VALIDADE Z WITH(NOLOCK) ON Z.LOTE_VALIDADE = ISNULL(Y.LOTE_VALIDADE, B.LOTE_VALIDADE )

WHERE( A.QUANTIDADE_UNIT - ISNULL(X.QTDE_ALOCADA,0) ) > 0 


--------------------------------------------------------
--ROTINA PARA GRAVAR O RESULTADO DA CONFERENCIA
--------------------------------------------------------

if object_id('tempdb..#TEMP_DELETE_01')         is not null DROP TABLE #TEMP_DELETE_01

SELECT A.CONFERENCIA_TRANSFERENCIA_ITEM

  INTO #TEMP_DELETE_01
 
  FROM CONFERENCIAS_ESTOQUE_TRANF_PRODUTOS A WITH(NOLOCK)
 WHERE A.CONFERENCIA_TRANSFERENCIA = @CONFERENCIA_TRANSFERENCIA 


--REALIZA O DELETE USANDO A PK--
DELETE CONFERENCIAS_ESTOQUE_TRANF_PRODUTOS
  FROM CONFERENCIAS_ESTOQUE_TRANF_PRODUTOS A WITH(NOLOCK)
  JOIN #TEMP_DELETE_01                    X ON X.CONFERENCIA_TRANSFERENCIA_ITEM = A.CONFERENCIA_TRANSFERENCIA_ITEM
  
--INSERE OS DADOS--  
INSERT INTO CONFERENCIAS_ESTOQUE_TRANF_PRODUTOS (

            CONFERENCIA_TRANSFERENCIA,
            PRODUTO,
            LOTE_VALIDADE,
            QUANTIDADE,
            QUANTIDADE_UNIT,
            COLETOR )

SELECT @CONFERENCIA_TRANSFERENCIA AS CONFERENCIA_TRANSFERENCIA,
       PRODUTO,
       LOTE_VALIDADE,
       QUANTIDADE,
       QUANTIDADE_UNIT,
       'X' AS COLETOR
       
  FROM #RESULTADOS_FINAL A 
 WHERE A.LOTE_VALIDADE IS NOT NULL

 UNION ALL

SELECT @CONFERENCIA_TRANSFERENCIA AS CONFERENCIA_TRANSFERENCIA,
       A.PRODUTO,
       A.LOTE_VALIDADE,
       A.QTDE_ALOCADA,
       A.QTDE_ALOCADA AS QUANTIDADE_UNIT,
       'X' AS COLETOR
       
  FROM #SALDO_LV A 
 
ORDER BY A.PRODUTO


--================================================================================--
--INSERCAO DA TABELA DE TRANSACOES
--================================================================================--
--================================================================================--
--INSERCAO DA TABELA DE TRANSACOES
--================================================================================--

DELETE ESTOQUE_TRANSFERENCIAS_TRANSACOES
  FROM ESTOQUE_TRANSFERENCIAS_TRANSACOES A WITH(NOLOCK)
  JOIN CONFERENCIAS_ESTOQUE_TRANF        B WITH(NOLOCK) ON B.FORMULARIO_ORIGEM     = A.FORMULARIO_ORIGEM
                                                       AND B.TAB_MASTER_ORIGEM     = A.TAB_MASTER_ORIGEM
													   AND B.CONFERENCIA_TRANSFERENCIA = A.REG_MASTER_ORIGEM
 WHERE B.CONFERENCIA_TRANSFERENCIA = @CONFERENCIA_TRANSFERENCIA

 --GERA TRANSACAÇÃO DE CONFERENCIA--
INSERT INTO ESTOQUE_TRANSFERENCIAS_TRANSACOES ( 
            FORMULARIO_ORIGEM ,
            TAB_MASTER_ORIGEM ,
            REG_MASTER_ORIGEM ,
            REGISTRO_CONTROLE ,
            REGISTRO_CONTROLE_II ,
            DATA ,
            ESTOQUE_TRANSFERENCIA ,
            PRODUTO ,
            LOTE_VALIDADE ,
            QTDE_ORIGINAL ,
            CONFERENCIA ,
            ACERTO_SOBRA ,
            ACERTO_FALTA ) 

SELECT B.FORMULARIO_ORIGEM      AS FORMULARIO_ORIGEM ,
       B.TAB_MASTER_ORIGEM      AS TAB_MASTER_ORIGEM ,
       B.CONFERENCIA_TRANSFERENCIA  AS REG_MASTER_ORIGEM ,
       A.PRODUTO                AS REGISTRO_CONTROLE ,
       NULL                     AS REGISTRO_CONTROLE_II ,
       CONVERT(VARCHAR(10),GETDATE(), 103) 
                                AS DATA,
       B.ESTOQUE_TRANSFERENCIA  AS ESTOQUE_TRANSFERENCIA,
       A.PRODUTO                AS PRODUTO,
       A.LOTE_VALIDADE          AS LOTE_VALIDADE ,
       0                        AS QTDE_ORIGINAL,      
       SUM(A.QUANTIDADE_UNIT)   AS CONFERENCIA ,
       0                        AS ACERTO_SOBRA ,
       0                        AS ACERTO_FALTA 
                   
  FROM CONFERENCIAS_ESTOQUE_TRANF_PRODUTOS A WITH(NOLOCK),
       CONFERENCIAS_ESTOQUE_TRANF          B WITH(NOLOCK)
       
 WHERE A.CONFERENCIA_TRANSFERENCIA = @CONFERENCIA_TRANSFERENCIA
   AND A.CONFERENCIA_TRANSFERENCIA = B.CONFERENCIA_TRANSFERENCIA

GROUP BY  B.FORMULARIO_ORIGEM      ,
          B.TAB_MASTER_ORIGEM       ,
          B.CONFERENCIA_TRANSFERENCIA   ,
          A.PRODUTO                 ,
          A.LOTE_VALIDADE ,
          B.ESTOQUE_TRANSFERENCIA              

ORDER BY ESTOQUE_TRANSFERENCIA
