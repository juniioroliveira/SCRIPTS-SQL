


ALTER PROCEDURE [dbo].[USP_SNGPC] (   
                                    @DATA_INICIAL      DATE                                                    
                                   ,@DATA_FINAL        DATE                                                    
                                   ,@EMPRESA           NUMERIC(15)                                      
                                   ,@GRAVACAO_FINAL    VARCHAR(1)                                       
                                   ,@INVENTARIO        VARCHAR(1)                                      
                                   ,@SNGPC             NUMERIC(15)                                      
                                   ,@FECHAR_MOVIMENTO  VARCHAR(1)                                      
                                  )                                       
                                                    
/*====================================================================================================================*/
/* VERSÃO        DATA ALTERAÇÃO    ALTERADO POR            DESCRIÇÃO                                                  */
/*====================================================================================================================*/
/* 0001          11/09/2020        BRUNO COLMENERO         CRIAÇÃO PROCEDURE                                          */
/* 0002          02/09/2022        BRUNO SANTANA           ALTERAÇÃO DATA COMPRA , DATA VENDA NAS TEMPS DE DEVOLUCOES */
/* 0003          02/09/2022        BRUNO SANTANA           IDENTAÇÃO E PADRONIZAÇÃO DE CODIGO PARA FACILIAR SUPORTE   */
/*====================================================================================================================*/

/*-------------------------*/
/*   DECLARAÇÃO VARIAVEL   */
/*-------------------------*/
                                                    
AS  


--DECLARE @SNGPC   NUMERIC (15) = 22868
--DECLARE @EMPRESA NUMERIC (15) = 68
--DECLARE @FECHAR_MOVIMENTO  VARCHAR(1) = 'S'                                      
 
      
if object_id('tempdb..#ULTIMO_FECHAR_MOVIMENTO') is not null    
   DROP TABLE #ULTIMO_FECHAR_MOVIMENTO   

SELECT TOP 1 A.SNGPC            AS SNGPC 
            ,A.FECHAR_MOVIMENTO AS FECHAR_MOVIMENTO
            ,A.EMPRESA          AS EMPRESA
        INTO #ULTIMO_FECHAR_MOVIMENTO 
        FROM SNGPC A  WITH(NOLOCK)
       WHERE A.EMPRESA =  @EMPRESA 
         AND A.SNGPC  <>  @SNGPC 
         AND A.SNGPC  <   @SNGPC 
    ORDER BY A.SNGPC DESC 
    
      

DECLARE @ULTIMO_FECHAR_MOVIMENTO VARCHAR (1) 

SELECT @ULTIMO_FECHAR_MOVIMENTO = A.FECHAR_MOVIMENTO FROM #ULTIMO_FECHAR_MOVIMENTO A  WHERE 1=1 AND A.EMPRESA = @EMPRESA AND A.SNGPC <> @SNGPC AND A.SNGPC < @SNGPC

 IF @ULTIMO_FECHAR_MOVIMENTO = 'N' AND @FECHAR_MOVIMENTO = 'S' AND @INVENTARIO = 'N'

 BEGIN  
      DECLARE @MSG_ERRO       VARCHAR(MAX)  
  
      SET @MSG_ERRO = 'Atenção: Ultimo registro SNGPC para a empresa '+CONVERT (VARCHAR (30),@EMPRESA)+' não esta com  movimento fechado. Favor verifique!!!'   
  
  
      RAISERROR ( @MSG_ERRO ,15,-1)  
      RETURN
    
 END  

 
                                                    
BEGIN                                          
                                      
SET DATEFORMAT DMY                                      
                                      
--BEGIN TRAN                                      
--ROLLBACK                                      
--COMMIT                                      
                                      
DECLARE @FORMULARIO_ORIGEM NUMERIC(6)  = (SELECT NUMID FROM FORMULARIOS WHERE FORMULARIO = 'SNGPC')                                      
       ,@TAB_MASTER_ORIGEM NUMERIC(6)  = (SELECT NUMID FROM TABELAS     WHERE TABELA     = 'SNGPC')                                      
     --,@DATA_INICIAL      DATE        = '19/05/2021'  
     --,@DATA_FINAL        DATE        = '21/05/2021'  
     --,@EMPRESA           NUMERIC(15) = 53  
     --,@GRAVACAO_FINAL    VARCHAR(1)  = 'N'  
     --,@INVENTARIO        VARCHAR(1)  = 'N'  
     --,@SNGPC             NUMERIC(15) = 10304  
     --,@FECHAR_MOVIMENTO  VARCHAR(1)  = 'N'                                       
   
/*--------------------------------------*/                   
/*-- DELETE LOTE_VALIDADE_LANCAMENTOS --*/                                      
/*--------------------------------------*/                                      
                                      
IF OBJECT_ID('TEMPDB..#DELETE_LV_LANCAMENTOS') IS NOT NULL                                      
 DROP TABLE #DELETE_LV_LANCAMENTOS                                      
                                      
     SELECT A.REGISTRO                                      
       INTO #DELETE_LV_LANCAMENTOS                                      
       FROM LOTE_VALIDADE_LANCAMENTOS  A WITH(NOLOCK)                                      
       JOIN SNGPC                      B WITH(NOLOCK) ON B.FORMULARIO_ORIGEM = A.FORMULARIO_ORIGEM                                      
                                                     AND B.TAB_MASTER_ORIGEM = A.TAB_MASTER_ORIGEM                   
                                                     AND B.SNGPC             = A.REG_MASTER_ORIGEM                                      
      WHERE B.SNGPC = @SNGPC  
                                   
      DELETE A                                      
        FROM LOTE_VALIDADE_LANCAMENTOS A WITH(NOLOCK)                                      
        JOIN #DELETE_LV_LANCAMENTOS    B ON B.REGISTRO = A.REGISTRO       
     
  
IF (@INVENTARIO = 'N')                                      
BEGIN                                      
                                      
/*--------------------------------------------------------*/                                      
/*-- DELETE DE CUPONS QUE ESTÃO COM CONFERIDO = 'N'     --*/                         
/*-- OU FORA DO RANGE DE DATA DA MASTER PARA REINSERÇÃO --*/                                      
/*--------------------------------------------------------*/                                      
                                      
if object_id('tempdb..#DELETE_RECEITA') is not null                                      
DROP TABLE #DELETE_RECEITA                                      
                                      
if object_id('tempdb..#DEL_PDV') is not null                                      
DROP TABLE #DEL_PDV                                      
                                      
CREATE TABLE #DELETE_RECEITA (SNGPC_RECEITA NUMERIC(15))                                      
CREATE TABLE #DEL_PDV        (SNGPC_PDV     NUMERIC(15))                                      
                                      
INSERT INTO #DEL_PDV (SNGPC_PDV)                                      
                                      
   SELECT B.SNGPC_PDV                                      
     FROM SNGPC_RECEITAS            A WITH(NOLOCK)                                      
     JOIN SNGPC_PDV                 B WITH(NOLOCK) ON B.SNGPC         = A.SNGPC                                      
                                                  AND B.MOVIMENTO     = A.MOVIMENTO                                      
                                                  AND B.VENDA         = A.VENDA                                      
                                                  AND B.CAIXA         = A.CAIXA                                      
                                                  AND B.LOJA          = A.LOJA                                      
                                                  AND B.PREVENDA      = A.PREVENDA                           
LEFT JOIN SNGPC_VENDAS_MANUTENCOES  C WITH(NOLOCK) ON C.SNGPC         = B.SNGPC                                      
                                                  AND C.MOVIMENTO     = B.MOVIMENTO                                      
                                       AND C.VENDA         = B.VENDA                                      
                                                  AND C.CAIXA         = B.CAIXA                                      
                                                  AND C.LOJA         = B.LOJA             
 WHERE A.CONFERIDO = 'N'  
   AND A.SNGPC = @SNGPC  
   AND C.SNGPC_VENDA_MANUTENCAO IS NULL  
                                      
UNION                                      
                                      
SELECT A.SNGPC_PDV                                      
  FROM SNGPC_PDV A (NOLOCK)                                      
                                        
 WHERE A.SNGPC = @SNGPC                                      
   AND A.MOVIMENTO NOT BETWEEN @DATA_INICIAL AND @DATA_FINAL                                      
                                      
                                      
INSERT INTO #DELETE_RECEITA (SNGPC_RECEITA)                                     
                                      
     SELECT A.SNGPC_RECEITA                                      
       FROM SNGPC_RECEITAS            A WITH(NOLOCK)        
  LEFT JOIN SNGPC_VENDAS_MANUTENCOES  B WITH(NOLOCK) ON B.SNGPC         = A.SNGPC                        
                                                    AND B.MOVIMENTO     = A.MOVIMENTO                                      
                                                    AND B.VENDA         = A.VENDA                                      
                                                    AND B.CAIXA         = A.CAIXA                                      
                                                    AND B.LOJA          = A.LOJA                                       
   
 WHERE A.CONFERIDO = 'N'                                       
   AND A.SNGPC = @SNGPC                          
   AND B.SNGPC_VENDA_MANUTENCAO IS NULL                                    
                                      
UNION                            
                                      
SELECT A.SNGPC_RECEITA                                      
  FROM SNGPC_RECEITAS   A (NOLOCK)                                      
                                        
 WHERE A.SNGPC = @SNGPC                     
   AND A.MOVIMENTO NOT BETWEEN @DATA_INICIAL AND @DATA_FINAL                                      
                                      
                                      
DELETE B                                      
  FROM #DEL_PDV   A                             JOIN SNGPC_PDV  B WITH(NOLOCK) ON B.SNGPC_PDV = A.SNGPC_PDV                                        
DELETE B                                      
  FROM #DELETE_RECEITA  A                                      
  JOIN SNGPC_RECEITAS   B WITH(NOLOCK) ON B.SNGPC_RECEITA = A.SNGPC_RECEITA                                 
                                      
/*---------------------------------------------*/                                      
/*-- DELETE DE NOTAS QUE ESTÃO FORA DO RANGE --*/                                      
/*-- DE DATA DA MASTER PARA REINSERÇÃO       --*/                                      
/*---------------------------------------------*/                                      
                                      
if object_id('tempdb..#DELETE_SNGPC_NFE') IS NOT NULL                                      
DROP TABLE #DELETE_SNGPC_NFE                                      
                                      
if object_id('tempdb..#DEL_NFE_ITENS')    IS NOT NULL                                
DROP TABLE #DEL_NFE_ITENS                                      
                                      
CREATE TABLE #DELETE_SNGPC_NFE (SNGPC_NFE NUMERIC(15))                                      
CREATE TABLE #DEL_NFE_ITENS    (SNGPC_NFE_ITEM NUMERIC(15))                                      
                                      
INSERT INTO #DEL_NFE_ITENS (SNGPC_NFE_ITEM)                                      
                                         
SELECT C.SNGPC_NFE_ITEM                                        
  FROM SNGPC              A (NOLOCK)                                      
  JOIN SNGPC_NFE          B (NOLOCK) ON B.SNGPC      =  A.SNGPC                                      
  JOIN SNGPC_NFE_ITENS    C (NOLOCK) ON C.SNGPC      =  B.SNGPC                             
                                    AND C.SNGPC_NFE  =  B.SNGPC_NFE                                      
                                        
 WHERE A.SNGPC = @SNGPC                                      
   AND B.MOVIMENTO NOT BETWEEN A.DATA_INICIAL AND A.DATA_FINAL                                      
                                      
INSERT INTO #DELETE_SNGPC_NFE (SNGPC_NFE)                                      
                                      
SELECT B.SNGPC_NFE                                        
  FROM SNGPC              A (NOLOCK)                                      
  JOIN SNGPC_NFE          B (NOLOCK) ON B.SNGPC      = A.SNGPC                                      
                                        
 WHERE A.SNGPC = @SNGPC                                      
   AND B.MOVIMENTO NOT BETWEEN A.DATA_INICIAL AND A.DATA_FINAL       
                                      
               
DELETE B                                       
  FROM #DEL_NFE_ITENS     A                                   
  JOIN SNGPC_NFE_ITENS    B WITH(NOLOCK) ON B.SNGPC_NFE_ITEM = A.SNGPC_NFE_ITEM                                      
           
DELETE B                                      
  FROM #DELETE_SNGPC_NFE  A                                      
  JOIN SNGPC_NFE          B WITH(NOLOCK) ON B.SNGPC_NFE = A.SNGPC_NFE                                      
                                      
/*--------------------------------------*/                                      
/*--  CRIAÇÃO DE TABELAS TEMPORÁRIAS  --*/                                      
/*--              GERAL               --*/                                      
/*--------------------------------------*/ 

IF OBJECT_ID ('TEMPDB..#PRODUTOS_FARMACIA')    IS NOT NULL                          
DROP TABLE #PRODUTOS_FARMACIA                                         
                                               
IF OBJECT_ID ('TEMPDB..#OPERACOES_FISCAIS')    IS NOT NULL                                       
DROP TABLE #OPERACOES_FISCAIS                                      
                                      
IF OBJECT_ID ('TEMPDB..#PRODUTOS_REGISTRO_MS') IS NOT NULL                            
DROP TABLE #PRODUTOS_REGISTRO_MS                                      
                                      
CREATE TABLE #PRODUTOS_FARMACIA       (
                                       PRODUTO_FARMACIA            NUMERIC(15)                                      
                                      ,PRODUTO                     NUMERIC(15)                                      
                                      ,RETENCAO_RECEITA            VARCHAR(1)                                         
                                      ,VENDA_CONTROLADA            VARCHAR(1)                                         
                                      ,ENVIA_SNGPC                 VARCHAR(1)                                         
                                      ,USO_CONTINUO                VARCHAR(1)                                         
                                      ,LISTA_PNU                   NUMERIC(5)                                         
                                      ,REGISTRO_MS                 VARCHAR(20)                                        
                                      ,TIPO                        NUMERIC(5)                                         
                                      ,FARMACIA_POPULAR            VARCHAR(1)                                         
                                      ,CONTROLE_ESPECIAL           VARCHAR(1)                                         
                                      ,REGISTRO_MS_ANTERIOR        VARCHAR(13)                                        
                                      ,UNIDADE_FARMACOTECNICA      VARCHAR(15)                                        
                                      ,CONTROLE_RASTREABILIDADE    VARCHAR(1)                                        
                                      ,PRINCIPIO_ATIVO             NUMERIC(15)                                  
                                      ,DOSAGEM_DESCRICAO           VARCHAR(50)                                        
                                      ,NOME_COMERCIAL              VARCHAR(50)                                        
                                      ,UNIDADE_APRESENTACAO        VARCHAR(3)                                       
                                      ,QUANTIDADE_APRESENTACAO     NUMERIC(5)                                         
                                      ,CLASSE_TERAPEUTICA          NUMERIC(5)                                         
                                      ,USO_PROLONGADO              VARCHAR(1)                                        
                                      ,PRODUTO_MANIPULADO          VARCHAR(1)                                        
                                      ,PRODUTO_PBM                 VARCHAR(1)                                       
                                      ,QUANTIDADE_FP               NUMERIC(15,2)                   
                                      ,PMC_FPOPULAR                NUMERIC(15,2)                    
                                      ,PERIODO_DISPENSACAO_FP      NUMERIC(15)                                      
                                      ,DATA_INICIO_CONTROLADO      DATETIME          
                                      ,DATA_FINAL_CONTROLADO       DATETIME                                      
                                      )                                       
                                      
CREATE TABLE #OPERACOES_FISCAIS       (
                                       OPERACAO_FISCAL             NUMERIC(5)                                        
                                      ,DESCRICAO_OPERACAO_FISCAL   VARCHAR(255)                                      
                                      ,TIPO_OPERACAO               NUMERIC(5)                                      
                                      ,DESCRICAO_TIPO_OPERACAO     VARCHAR(60)                                      
                                      ,NFE_TIPO_OPERACAO           VARCHAR(1)                                      
                                      ,DESCRICAO_NFE_TIPO_OPERACAO VARCHAR(60)                                      
                                      ,TRANSFERENCIA_ENTRADA       NUMERIC(5)  
                                      )                                      
         
CREATE TABLE #PRODUTOS_REGISTRO_MS    (
                                       PRODUTO                     NUMERIC(15)                                      
                                      ,REGISTRO_MS                 VARCHAR(20)  
                                      )  
                                      
                                      
/*--------------------------------------*/                                      
/*--  INSERT NAS TABELAS TEMPORÁRIAS  --*/                                      
/*--              GERAL               --*/                                      
/*--------------------------------------*/                                      
  
DECLARE @SNGPC_MOVIMENTACAO_COMPLETA VARCHAR (1) = (SELECT SNGPC_MOVIMENTACAO_COMPLETA FROM EMPRESAS_USUARIAS WITH(NOLOCK) WHERE EMPRESA_USUARIA = @EMPRESA)  
  
IF @SNGPC_MOVIMENTACAO_COMPLETA = 'S'  
  
INSERT INTO #PRODUTOS_FARMACIA        ( 
                                       PRODUTO_FARMACIA                                               
                                      ,PRODUTO                                                       
                                      ,RETENCAO_RECEITA                                              
                                      ,VENDA_CONTROLADA                                         
                                      ,ENVIA_SNGPC                                                   
                                      ,USO_CONTINUO                                                  
                                      ,LISTA_PNU                                                     
                                      ,REGISTRO_MS                                                   
                                      ,TIPO                              
                                      ,FARMACIA_POPULAR                                              
                                      ,CONTROLE_ESPECIAL                                             
                                      ,REGISTRO_MS_ANTERIOR                                          
                                      ,UNIDADE_FARMACOTECNICA                                  
                                      ,CONTROLE_RASTREABILIDADE                                      
                                      ,PRINCIPIO_ATIVO                                               
                                      ,DOSAGEM_DESCRICAO                                             
                                      ,NOME_COMERCIAL                                                
                                      ,UNIDADE_APRESENTACAO                                          
                                      ,QUANTIDADE_APRESENTACAO                                       
                                      ,CLASSE_TERAPEUTICA                                            
                                      ,USO_PROLONGADO                                                
                                      ,PRODUTO_MANIPULADO                                    
                                      ,PRODUTO_PBM                                                   
                                      ,QUANTIDADE_FP                                                 
                                      ,PMC_FPOPULAR          
                                      ,PERIODO_DISPENSACAO_FP                                        
                                      ,DATA_INICIO_CONTROLADO      
                                      ,DATA_FINAL_CONTROLADO  
                                      )                                              
                                              
SELECT A.PRODUTO_FARMACIA                                           AS PRODUTO_FARMACIA                    
      ,A.PRODUTO                                                    AS PRODUTO                                                     
      ,A.RETENCAO_RECEITA                                           AS RETENCAO_RECEITA                                            
      ,A.VENDA_CONTROLADA                                           AS VENDA_CONTROLADA                                            
      ,A.ENVIA_SNGPC                                                AS ENVIA_SNGPC                                       
      ,A.USO_CONTINUO                                               AS USO_CONTINUO                             
      ,A.LISTA_PNU                                                  AS LISTA_PNU                                                   
      ,A.REGISTRO_MS                                                AS REGISTRO_MS                                 
      ,A.TIPO                                                       AS TIPO                                                        
      ,A.FARMACIA_POPULAR                                           AS FARMACIA_POPULAR                                            
      ,A.CONTROLE_ESPECIAL                                          AS CONTROLE_ESPECIAL                                           
      ,A.REGISTRO_MS_ANTERIOR                                       AS REGISTRO_MS_ANTERIOR                                        
      ,A.UNIDADE_FARMACOTECNICA                                     AS UNIDADE_FARMACOTECNICA                                      
      ,A.CONTROLE_RASTREABILIDADE                                   AS CONTROLE_RASTREABILIDADE                                    
      ,A.PRINCIPIO_ATIVO                                            AS PRINCIPIO_ATIVO                                             
      ,A.DOSAGEM_DESCRICAO                                          AS DOSAGEM_DESCRICAO                     
      ,A.NOME_COMERCIAL                                             AS NOME_COMERCIAL                                              
      ,A.UNIDADE_APRESENTACAO                                       AS UNIDADE_APRESENTACAO                                        
      ,A.QUANTIDADE_APRESENTACAO                                    AS QUANTIDADE_APRESENTACAO                                     
      ,A.CLASSE_TERAPEUTICA                                         AS CLASSE_TERAPEUTICA                                          
      ,A.USO_PROLONGADO                                             AS USO_PROLONGADO                                              
      ,A.PRODUTO_MANIPULADO                                         AS PRODUTO_MANIPULADO                                          
      ,A.PRODUTO_PBM                                                AS PRODUTO_PBM                                                 
      ,A.QUANTIDADE_FP                                              AS QUANTIDADE_FP                                               
      ,A.PMC_FPOPULAR                                               AS PMC_FPOPULAR                                                
      ,A.PERIODO_DISPENSACAO_FP                                     AS PERIODO_DISPENSACAO_FP                                       
      ,ISNULL(A.DATA_INICIO_CONTROLADO, '01/01/2011')               AS DATA_INICIO_CONTROLADO        
      ,ISNULL(A.DATA_FINAL_CONTROLADO, DATEADD(DAY, 1, GETDATE()))  AS DATA_FINAL_CONTROLADO                                   
                                             
  FROM PRODUTOS_FARMACIA   A WITH(NOLOCK)                                       
 WHERE A.VENDA_CONTROLADA = 'S'                                      
   AND A.ENVIA_SNGPC      = 'N'        
     
ELSE  
  
INSERT INTO #PRODUTOS_FARMACIA        (
                                       PRODUTO_FARMACIA                                               
                                      ,PRODUTO                                                       
                                      ,RETENCAO_RECEITA                                              
                                      ,VENDA_CONTROLADA       
                                      ,ENVIA_SNGPC                                                   
                                      ,USO_CONTINUO                                                  
                                      ,LISTA_PNU                                                     
                                      ,REGISTRO_MS                                                   
                                      ,TIPO                              
                                      ,FARMACIA_POPULAR                                              
                                      ,CONTROLE_ESPECIAL                                             
                                      ,REGISTRO_MS_ANTERIOR                                          
                                      ,UNIDADE_FARMACOTECNICA                                        
                                      ,CONTROLE_RASTREABILIDADE                                      
                                      ,PRINCIPIO_ATIVO                                               
                                      ,DOSAGEM_DESCRICAO                                             
                                      ,NOME_COMERCIAL                                                
                                      ,UNIDADE_APRESENTACAO                                          
                                      ,QUANTIDADE_APRESENTACAO                                       
                                      ,CLASSE_TERAPEUTICA                                            
                                      ,USO_PROLONGADO                                                
                                      ,PRODUTO_MANIPULADO                                    
                                      ,PRODUTO_PBM                              
                                      ,QUANTIDADE_FP                                                 
                                      ,PMC_FPOPULAR          
                                      ,PERIODO_DISPENSACAO_FP                                        
                                      ,DATA_INICIO_CONTROLADO      
                                      ,DATA_FINAL_CONTROLADO 
                                      )                                              
                                              
SELECT A.PRODUTO_FARMACIA             AS PRODUTO_FARMACIA                       
      ,A.PRODUTO                      AS PRODUTO                                                        
      ,A.RETENCAO_RECEITA             AS RETENCAO_RECEITA                                               
      ,A.VENDA_CONTROLADA             AS VENDA_CONTROLADA                                               
      ,A.ENVIA_SNGPC                  AS ENVIA_SNGPC                                          
      ,A.USO_CONTINUO                 AS USO_CONTINUO                                
      ,A.LISTA_PNU                    AS LISTA_PNU                                                      
      ,A.REGISTRO_MS                  AS REGISTRO_MS                                    
      ,A.TIPO                         AS TIPO                                                           
      ,A.FARMACIA_POPULAR             AS FARMACIA_POPULAR                                               
      ,A.CONTROLE_ESPECIAL            AS CONTROLE_ESPECIAL                                              
      ,A.REGISTRO_MS_ANTERIOR         AS REGISTRO_MS_ANTERIOR                                           
      ,A.UNIDADE_FARMACOTECNICA       AS UNIDADE_FARMACOTECNICA                                         
      ,A.CONTROLE_RASTREABILIDADE     AS CONTROLE_RASTREABILIDADE                                       
      ,A.PRINCIPIO_ATIVO              AS PRINCIPIO_ATIVO                                                
      ,A.DOSAGEM_DESCRICAO            AS DOSAGEM_DESCRICAO                        
      ,A.NOME_COMERCIAL               AS NOME_COMERCIAL                                                 
      ,A.UNIDADE_APRESENTACAO         AS UNIDADE_APRESENTACAO                                           
      ,A.QUANTIDADE_APRESENTACAO      AS QUANTIDADE_APRESENTACAO                                        
      ,A.CLASSE_TERAPEUTICA           AS CLASSE_TERAPEUTICA                                             
      ,A.USO_PROLONGADO               AS USO_PROLONGADO                                                 
      ,A.PRODUTO_MANIPULADO           AS PRODUTO_MANIPULADO                                             
      ,A.PRODUTO_PBM                  AS PRODUTO_PBM                                                    
      ,A.QUANTIDADE_FP                AS QUANTIDADE_FP                                                  
      ,A.PMC_FPOPULAR                 AS PMC_FPOPULAR                                                   
      ,A.PERIODO_DISPENSACAO_FP       AS PERIODO_DISPENSACAO_FP   
      ,ISNULL(A.DATA_INICIO_CONTROLADO, '01/01/2011')               AS  DATA_INICIO_CONTROLADO        
      ,ISNULL(A.DATA_FINAL_CONTROLADO, DATEADD(DAY, 1, GETDATE()))  AS DATA_FINAL_CONTROLADO                                   
                                             
  FROM PRODUTOS_FARMACIA   A WITH(NOLOCK)                                       
 WHERE A.VENDA_CONTROLADA = 'S'                                      
   AND A.ENVIA_SNGPC      = 'N'  
   AND A.CLASSE_TERAPEUTICA = 1  
     
                                                                        
INSERT INTO #OPERACOES_FISCAIS        (       
                                       OPERACAO_FISCAL                                                   
                                      ,DESCRICAO_OPERACAO_FISCAL                                         
                                      ,TIPO_OPERACAO                                                     
                                      ,DESCRICAO_TIPO_OPERACAO                                           
                                      ,NFE_TIPO_OPERACAO                                                 
                                      ,DESCRICAO_NFE_TIPO_OPERACAO                                       
                                      ,TRANSFERENCIA_ENTRADA                                      
                                      )                                      
                                            
SELECT A.OPERACAO_FISCAL              AS OPERACAO_FISCAL                                                   
      ,A.DESCRICAO                    AS DESCRICAO_OPERACAO_FISCAL                                         
      ,B.TIPO_OPERACAO                AS TIPO_OPERACAO                                                     
      ,B.DESCRICAO                    AS DESCRICAO_TIPO_OPERACAO                                           
      ,C.NFE_TIPO_OPERACAO            AS NFE_TIPO_OPERACAO                                                 
      ,C.DESCRICAO                    AS DESCRICAO_NFE_TIPO_OPERACAO                                       
      ,A.TRANSFERENCIA_ENTRADA        AS TRANSFERENCIA_ENTRADA                        
                                      
  FROM OPERACOES_FISCAIS     A WITH(NOLOCK)      
  JOIN TIPOS_OPERACOES       B WITH(NOLOCK) ON B.TIPO_OPERACAO     = A.TIPO_OPERACAO                                          
  JOIN NFE_TIPOS_OPERACOES   C WITH(NOLOCK) ON C.NFE_TIPO_OPERACAO = A.NFE_TIPO_OPERACAO                                         
            
                                      
 INSERT INTO #PRODUTOS_REGISTRO_MS    (
                                       PRODUTO                                      
                                      ,REGISTRO_MS
                                      )                                      
                                      
SELECT X.PRODUTO                                      
      ,Y.REGISTRO_MS    
  FROM (SELECT A.PRODUTO                    AS PRODUTO   
              ,MAX(A.PRODUTO_REGISTRO_MS)   AS PRODUTO_REGISTRO_MS                                      
                          
       FROM PRODUTOS_REGISTROS_MS  A WITH(NOLOCK)                                      
      GROUP BY A.PRODUTO )    X                                       
  JOIN PRODUTOS_REGISTROS_MS  Y WITH(NOLOCK) ON Y.PRODUTO_REGISTRO_MS = X.PRODUTO_REGISTRO_MS                                      
 WHERE Y.REGISTRO_MS IS NOT NULL                                      
                                      
                                      
/*--------------------------------------*/                                      
/*--  CRIAÇÃO DE TABELAS TEMPORÁRIAS  --*/                                      
/*--              NOTAS               --*/                             
/*--------------------------------------*/                                      
                     
IF OBJECT_ID ('TEMPDB..#RETORNO_NOTAS')          IS NOT NULL                                      
DROP TABLE #RETORNO_NOTAS                                      
                                      
IF OBJECT_ID ('TEMPDB..#NF_COMPRA')              IS NOT NULL                                      
DROP TABLE #NF_COMPRA                    
     
IF OBJECT_ID ('TEMPDB..#NF_COMPRA_FINAL')        IS NOT NULL                                      
DROP TABLE #NF_COMPRA_FINAL                                      
                                      
IF OBJECT_ID ('TEMPDB..#NF_COMPRA_RECEBIMENTOS') IS NOT NULL                                      
DROP TABLE #NF_COMPRA_RECEBIMENTOS                           
                                      
IF OBJECT_ID ('TEMPDB..#RECEBIMENTOS_VOLUMES')   IS NOT NULL                                      
DROP TABLE #RECEBIMENTOS_VOLUMES                                      
                                      
IF OBJECT_ID ('TEMPDB..#NF_FATURAMENTO')         IS NOT NULL                                      
DROP TABLE #NF_FATURAMENTO                                      
                                                   
CREATE TABLE #RETORNO_NOTAS           ( 
                                       FORMULARIO_ORIGEM      NUMERIC(6)                                                    
                                      ,TAB_MASTER_ORIGEM      NUMERIC(6)                                                    
                                      ,REG_MASTER_ORIGEM      NUMERIC(15)                                                    
                                      ,CHAVE_NFE              VARCHAR(50)                                                    
                                      ,EMPRESA                NUMERIC(15)                                            
                                      ,ENTIDADE               NUMERIC(15)                                                    
                                      ,NF_NUMERO              NUMERIC(15)                                                    
                                      ,NF_SERIE               VARCHAR(3)                                                    
                                      ,NF_ESPECIE             VARCHAR(3)                                                    
                                      ,MOVIMENTO              DATETIME     
                                      ,PRODUTO                NUMERIC(15)                             
                                      ,QUANTIDADE             NUMERIC(15)                         
                                      ,LOTE                   VARCHAR(20)                                                    
                                      ,VALIDADE_DIGITACAO     VARCHAR(7)                                                    
                                      ,VALIDADE               DATETIME                                                    
                                      ,NFE_TIPO_OPERACAO      INT                                                    
                                      ,OPERACAO_TIPO          VARCHAR(30)                      
                                      ,TIPO_NF_CANCELAMENTO   INT                                                    
                                      ,OPERACAO_FISCAL        NUMERIC(15)                                              
                                      ,MOTIVO_PERDA           NUMERIC(15)                                                    
                                      ,QUANTIDADE_NOTA        NUMERIC(15)                                                    
                                      )                                                                              
                                      
CREATE TABLE #NF_COMPRA               ( 
                                       FORMULARIO_ORIGEM      NUMERIC(6)                                                    
                                      ,TAB_MASTER_ORIGEM      NUMERIC(6)                                                    
                                      ,REG_MASTER_ORIGEM      NUMERIC(15)                                                    
                                      ,NF_COMPRA              NUMERIC(15)                                                    
                                      ,CHAVE_NFE              VARCHAR(44)                                                    
                                      ,EMPRESA                NUMERIC(15)                            
                                      ,ENTIDADE               NUMERIC(15)                                                    
                                      ,NF_NUMERO              NUMERIC(10)      
                                      ,NF_SERIE               VARCHAR(3)   
                                      ,NF_ESPECIE             VARCHAR(3)                                                    
                                      ,MOVIMENTO              DATETIME                                                    
                                      ,OPERACAO_FISCAL        NUMERIC(15)                                                    
                                      ,PRODUTO                NUMERIC(15)                    
                                      ,QUANTIDADE             NUMERIC(15)                                                    
                                      ,LOTE                   VARCHAR(20)                                                    
                                      ,VALIDADE_DIGITACAO     VARCHAR(7)                                                    
                                      ,VALIDADE               DATETIME                                                    
                                      ,RECEBIMENTO            NUMERIC(15)                                                    
                                      ,RECEBIMENTO_LANCAMENTO NUMERIC(15)                                             
                                      )                                           
                                              
CREATE TABLE #NF_COMPRA_FINAL         ( 
                                       FORMULARIO_ORIGEM      NUMERIC(6)                                                  
                                      ,TAB_MASTER_ORIGEM      NUMERIC(6)                                                          
                                      ,REG_MASTER_ORIGEM      NUMERIC(15)                 
                                      ,NF_COMPRA              NUMERIC(15)                                                          
                                      ,CHAVE_NFE              VARCHAR(44)       
                                      ,EMPRESA                NUMERIC(15)                                                          
                                      ,ENTIDADE               NUMERIC(15)                   
                                      ,NF_NUMERO              NUMERIC(10)                                                          
                                      ,NF_SERIE               VARCHAR(3)                        
                                      ,NF_ESPECIE             VARCHAR(3)                                                          
                                      ,MOVIMENTO              DATETIME                                                          
                                      ,OPERACAO_FISCAL        NUMERIC(15)                                                          
                                      ,PRODUTO                NUMERIC(15)                                     
                                      ,QUANTIDADE             NUMERIC(15)                
                                      ,LOTE                   VARCHAR(20)               
                                      ,VALIDADE_DIGITACAO     VARCHAR(7)                                                          
                                      ,VALIDADE               DATETIME                                                          
                                      ,RECEBIMENTO            NUMERIC(15)                                                          
                                      ,RECEBIMENTO_LANCAMENTO NUMERIC(15)                                                          
                                      )                                                       
                                          
CREATE TABLE #NF_COMPRA_RECEBIMENTOS  (
                                       NF_COMPRA              NUMERIC(15)                                               
                                      ,RECEBIMENTO_LANCAMENTO NUMERIC(15)                                          
                                      ,RECEBIMENTO            NUMERIC(15)                                          
                                      )                                               
                                       
CREATE TABLE #RECEBIMENTOS_VOLUMES    ( 
                                       NF_COMPRA              NUMERIC(15)                                                  
                                      ,PRODUTO                NUMERIC(15)                                                    
                                      ,QUANTIDADE             NUMERIC(15)                                                    
                                      ,LOTE                   VARCHAR(20)                                                     
                                      ,VALIDADE_DIGITACAO     VARCHAR(7)                                                     
                                      )                                                    
                                      
CREATE TABLE #NF_FATURAMENTO          (
                                       FORMULARIO_ORIGEM       NUMERIC(6)                              
                                      ,TAB_MASTER_ORIGEM       NUMERIC(6)                                      
                                      ,NF_FATURAMENTO          NUMERIC(15)                                      
                                      ,EMPRESA                 NUMERIC(15)                                      
                                      ,ENTIDADE                NUMERIC(15)                                      
                                      ,NF_NUMERO               NUMERIC(6)                                       
                                      ,NF_SERIE                VARCHAR(3)                                       
                                      ,NF_ESPECIE              VARCHAR(3)                                      
                                      ,MOVIMENTO               DATETIME                                           
                                      ,PRODUTO                 NUMERIC(15)                                        
                                      ,QUANTIDADE_ESTOQUE      NUMERIC(15,2)                                      
                                      ,LOTE                    VARCHAR(20)                       
                                      ,VALIDADE_DIGITACAO      VARCHAR(7)                                          
                                      ,VALIDADE                DATETIME              
                                      ,OPERACAO_FISCAL         NUMERIC(5)                        
                                      ,MOTIVO_PERDA            NUMERIC(15)                                      
                                      )                                  
                                      
/*--------------------------------------*/                                      
/*--  INSERT NAS TABELAS TEMPORÁRIAS  --*/                                      
/*--     NOTAS                        --*/                                      
/*--------------------------------------*/                                      
                                      
INSERT INTO #NF_COMPRA                ( 
                                       FORMULARIO_ORIGEM                                              
                                      ,TAB_MASTER_ORIGEM                                                        
                                      ,REG_MASTER_ORIGEM                                                        
                                      ,NF_COMPRA                                                 
                                      ,CHAVE_NFE                                                                
                                      ,EMPRESA                                                                
                                      ,ENTIDADE                                          
                                      ,NF_NUMERO                                                      
                                      ,NF_SERIE                                                                
                                      ,NF_ESPECIE                                                                
                                      ,MOVIMENTO                                                                
                                      ,OPERACAO_FISCAL                                                        
                                      ,PRODUTO                         
                                      ,QUANTIDADE                                                      
                                      ,LOTE                                                                    
                                      ,VALIDADE_DIGITACAO                                                        
                                      ,VALIDADE                                                                
                                      ,RECEBIMENTO                        
                                      ,RECEBIMENTO_LANCAMENTO                                                    
                                      )                                                    
                                                    
   SELECT A.FORMULARIO_ORIGEM                                           AS FORMULARIO_ORIGEM  
         ,A.TAB_MASTER_ORIGEM                                           AS TAB_MASTER_ORIGEM  
         ,A.NF_COMPRA                                                   AS REG_MASTER_ORIGEM  
         ,A.NF_COMPRA                                                   AS NF_COMPRA  
         ,A.CHAVE_NFE                                                   AS CHAVE_NFE  
         ,A.EMPRESA                                                     AS EMPRESA  
         ,A.ENTIDADE                                                    AS ENTIDADE  
         ,A.NF_NUMERO                                                   AS NF_NUMERO  
         ,A.NF_SERIE                                                    AS NF_SERIE  
         ,A.NF_ESPECIE                                                  AS NF_ESPECIE  
         ,A.MOVIMENTO                                                   AS MOVIMENTO  
         ,MIN(B.OPERACAO_FISCAL)                                        AS OPERACAO_FISCAL  
         ,B.PRODUTO                                                     AS PRODUTO  
         ,SUM(B.QUANTIDADE_ESTOQUE)                                     AS QUANTIDADE                            
         ,CONVERT(VARCHAR(20),B.LOTE)                                   AS LOTE                                                              
         ,CONVERT(VARCHAR(07),B.VALIDADE_DIGITACAO)                     AS VALIDADE_DIGITACAO  
         ,CONVERT(DATETIME,DBO.DEFINI_VALIDADE(B.VALIDADE_DIGITACAO))   AS VALIDADE  
         ,A.RECEBIMENTO                                                 AS RECEBIMENTO  
         ,E.RECEBIMENTO_LANCAMENTO                                      AS RECEBIMENTO_LANCAMENTO  
     FROM NF_COMPRA                               A WITH(NOLOCK)                                        
     JOIN NF_COMPRA_PRODUTOS                      B WITH(NOLOCK) ON B.NF_COMPRA               = A.NF_COMPRA  
     JOIN #PRODUTOS_FARMACIA                      C WITH(NOLOCK) ON C.PRODUTO                 = B.PRODUTO  
                                                                AND CAST(A.MOVIMENTO AS DATE) 
                                                            BETWEEN C.DATA_INICIO_CONTROLADO AND C.DATA_FINAL_CONTROLADO  
     JOIN (SELECT A.RECEBIMENTO                                        
             FROM APROVACOES_RECEB_VOLUMES_ITENS  A WITH(NOLOCK)                    
             JOIN RECEBIMENTOS_VOLUMES            B WITH(NOLOCK) ON B.RECEBIMENTO = A.RECEBIMENTO  
                                                                AND B.MOVIMENTO 
                                                            BETWEEN @DATA_INICIAL AND @DATA_FINAL              
                                                                AND B.EMPRESA     = @EMPRESA                           
            UNION                                         
                                           
           SELECT A.RECEBIMENTO  
             FROM RECEBIMENTOS_VOLUMES  A WITH(NOLOCK)  
            WHERE ISNULL(A.FINALIZAR,'N') = 'S'  
              AND A.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL  
              AND A.EMPRESA   = @EMPRESA  
           )                                       D              ON D.RECEBIMENTO      = A.RECEBIMENTO  
LEFT JOIN RECEBIMENTOS_FISICOS_LANCAMENTOS         E WITH(NOLOCK) ON E.RECEBIMENTO      = A.RECEBIMENTO  
    WHERE A.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL                                                    
      AND A.EMPRESA = @EMPRESA                                               
                                                       
 GROUP BY A.FORMULARIO_ORIGEM                     
         ,A.TAB_MASTER_ORIGEM                                                
         ,A.NF_COMPRA                     
         ,A.CHAVE_NFE                                                     
         ,A.EMPRESA                                                              
         ,A.ENTIDADE                                
         ,A.NF_NUMERO                                                            
         ,A.NF_SERIE                           
         ,A.NF_ESPECIE                                      
         ,A.MOVIMENTO                                                                          
         ,B.PRODUTO                                              
         ,B.LOTE                                          
         ,B.VALIDADE_DIGITACAO                                          
         ,A.RECEBIMENTO                                                    
         ,E.RECEBIMENTO_LANCAMENTO                                                    
                                                                
                                                    
 INSERT INTO #NF_COMPRA_RECEBIMENTOS  ( 
                                       NF_COMPRA  
                                      ,RECEBIMENTO_LANCAMENTO  
                                      ,RECEBIMENTO  
                                      )                                              
 SELECT DISTINCT 
        NF_COMPRA                     AS NF_COMPRA  
       ,RECEBIMENTO_LANCAMENTO        AS RECEBIMENTO_LANCAMENTO 
       ,RECEBIMENTO                   AS RECEBIMENTO  
                                       
   FROM #NF_COMPRA  
                                                            
             
 INSERT INTO #RECEBIMENTOS_VOLUMES    (
                                       NF_COMPRA                                                                     
                                      ,PRODUTO                                                                  
                                      ,QUANTIDADE                                                                    
                                      ,LOTE                                                                           
                                      ,VALIDADE_DIGITACAO                                       
                                      )                                
                                                                     
  SELECT A.NF_COMPRA                  AS NF_COMPRA                                                              
        ,B.PRODUTO                    AS PRODUTO                   
        ,SUM(B.QUANTIDADE_UNIT)       AS QUANTIDADE                        
        ,B.LOTE                       AS LOTE                                             
        ,B.VALIDADE_DIGITACAO         AS VALIDADE_DIGITACAO                                                          
         
    FROM #NF_COMPRA_RECEBIMENTOS                 A                                                            
    JOIN RECEBIMENTOS_FISICOS_LANCAMENTOS_ITENS  B WITH(NOLOCK) ON B.RECEBIMENTO_LANCAMENTO = A.RECEBIMENTO_LANCAMENTO                                        
                                                   
GROUP BY A.NF_COMPRA                                                              
        ,B.PRODUTO                                           
        ,B.LOTE                                                              
        ,B.VALIDADE_DIGITACAO                                                            
                                        
   UNION    
                           
  SELECT A.NF_COMPRA                                                              
        ,B.PRODUTO                                                               
        ,SUM(B.QUANTIDADE_UNIT)       AS QUANTIDADE                                                              
        ,B.LOTE                       AS LOTE             
        ,B.VALIDADE_DIGITACAO         AS VALIDADE_DIGITACAO                                       
                                            
    FROM #NF_COMPRA_RECEBIMENTOS       A                                             
    JOIN RECEBIMENTOS_VOLUMES_FISICOS  B WITH(NOLOCK) ON B.RECEBIMENTO = A.RECEBIMENTO                                       
           
GROUP BY A.NF_COMPRA                                                              
        ,B.PRODUTO                                                               
        ,B.LOTE                                                              
        ,B.VALIDADE_DIGITACAO                                                            
                    
                                                  
INSERT INTO #NF_COMPRA_FINAL          ( 
                                       FORMULARIO_ORIGEM                                                             
                                      ,TAB_MASTER_ORIGEM                                                              
                                      ,REG_MASTER_ORIGEM                                                              
                                      ,NF_COMPRA                              
                                      ,CHAVE_NFE                                                                      
                                      ,EMPRESA                                                                      
                                      ,ENTIDADE                                                                      
                                      ,NF_NUMERO                                                            
                                      ,NF_SERIE                                                                      
                                      ,NF_ESPECIE                                                               
                                      ,MOVIMENTO                                                                      
                                      ,OPERACAO_FISCAL                      
                                      ,PRODUTO                                                                      
                                      ,QUANTIDADE                                                                      
                                      ,LOTE                                                                          
                                      ,VALIDADE_DIGITACAO                                                              
                                      ,VALIDADE                                                              
                                      ,RECEBIMENTO                                                                  
                                      ,RECEBIMENTO_LANCAMENTO                                                          
                                      )                       
                                                             
   SELECT A.FORMULARIO_ORIGEM                                                       AS FORMULARIO_ORIGEM  
         ,A.TAB_MASTER_ORIGEM                                                       AS TAB_MASTER_ORIGEM  
         ,A.REG_MASTER_ORIGEM                                                       AS REG_MASTER_ORIGEM  
         ,A.NF_COMPRA                                                               AS NF_COMPRA  
         ,A.CHAVE_NFE                                                               AS CHAVE_NFE  
         ,A.EMPRESA                                                                 AS EMPRESA  
         ,A.ENTIDADE                                                                AS ENTIDADE  
         ,A.NF_NUMERO                                                               AS NF_NUMERO  
         ,A.NF_SERIE                                                                AS NF_SERIE  
         ,A.NF_ESPECIE                                                              AS NF_ESPECIE  
         ,A.MOVIMENTO                                                               AS MOVIMENTO  
         ,A.OPERACAO_FISCAL                                                         AS OPERACAO_FISCAL  
         ,A.PRODUTO                                                                 AS PRODUTO  
         ,ISNULL(A.QUANTIDADE,B.QUANTIDADE)                                         AS QUANTIDADE  
         ,ISNULL(A.LOTE,B.LOTE)                                                     AS LOTE  
         ,ISNULL(A.VALIDADE_DIGITACAO, B.VALIDADE_DIGITACAO)                        AS VALIDADE_DIGITACAO  
         ,DBO.DEFINI_VALIDADE(ISNULL(A.VALIDADE_DIGITACAO,B.VALIDADE_DIGITACAO))    AS VALIDADE  
         ,A.RECEBIMENTO                                                             AS RECEBIMENTO  
         ,A.RECEBIMENTO_LANCAMENTO                                                  AS RECEBIMENTO_LANCAMENTO  
     FROM #NF_COMPRA             A                                       
LEFT JOIN #RECEBIMENTOS_VOLUMES  B  ON B.NF_COMPRA = A.NF_COMPRA                      
                                   AND B.PRODUTO   = A.PRODUTO  
     JOIN #PRODUTOS_FARMACIA     C  ON C.PRODUTO   = A.PRODUTO  
                                   AND CAST(A.MOVIMENTO AS DATE) BETWEEN C.DATA_INICIO_CONTROLADO  
                                   AND C.DATA_FINAL_CONTROLADO  
                                                      
GROUP BY A.FORMULARIO_ORIGEM                                              
        ,A.TAB_MASTER_ORIGEM                                                              
        ,A.REG_MASTER_ORIGEM                                                              
        ,A.NF_COMPRA                                                       
        ,A.CHAVE_NFE     
        ,A.EMPRESA                                                                      
        ,A.ENTIDADE                                 
        ,A.NF_NUMERO                                                            
        ,A.NF_SERIE                                               
        ,A.NF_ESPECIE                                                                      
        ,A.MOVIMENTO                                                                      
        ,A.OPERACAO_FISCAL                                                              
        ,A.PRODUTO                                                                      
        ,ISNULL(A.QUANTIDADE, B.QUANTIDADE)  
        ,ISNULL(A.LOTE, B.LOTE)  
        ,ISNULL(A.VALIDADE_DIGITACAO, B.VALIDADE_DIGITACAO)  
        ,DBO.DEFINI_VALIDADE (ISNULL(A.VALIDADE_DIGITACAO, B.VALIDADE_DIGITACAO))  
        ,A.RECEBIMENTO                                                                  
        ,A.RECEBIMENTO_LANCAMENTO                                                      
                      
                                      
INSERT INTO #NF_FATURAMENTO           ( 
                                       FORMULARIO_ORIGEM                                       
                                      ,TAB_MASTER_ORIGEM                                       
                                      ,NF_FATURAMENTO                                       
                                      ,EMPRESA                                                 
                                      ,ENTIDADE      
                                      ,NF_NUMERO                                               
                                      ,NF_SERIE                                            
                                      ,NF_ESPECIE                                              
                                      ,MOVIMENTO                                               
                                      ,PRODUTO                                                 
                                      ,QUANTIDADE_ESTOQUE                                      
                                      ,LOTE                           
                                      ,VALIDADE_DIGITACAO                                      
                                      ,VALIDADE                                          
                                      ,OPERACAO_FISCAL                                         
                                      ,MOTIVO_PERDA                                
                                      )        
                                      
   SELECT A.FORMULARIO_ORIGEM         AS FORMULARIO_ORIGEM                                       
         ,A.TAB_MASTER_ORIGEM         AS TAB_MASTER_ORIGEM                                       
         ,A.NF_FATURAMENTO            AS NF_FATURAMENTO                                          
         ,A.EMPRESA                   AS EMPRESA                                                 
         ,A.ENTIDADE                  AS ENTIDADE                                                
         ,A.NF_NUMERO                 AS NF_NUMERO                                               
         ,A.NF_SERIE                  AS NF_SERIE      
         ,A.NF_ESPECIE                AS NF_ESPECIE                                              
         ,A.MOVIMENTO                 AS MOVIMENTO               
         ,B.PRODUTO                   AS PRODUTO                                                 
         ,SUM(B.QUANTIDADE_ESTOQUE)   AS QUANTIDADE_ESTOQUE                                      
         ,B.LOTE                      AS LOTE                                                  
         ,B.VALIDADE_DIGITACAO        AS VALIDADE_DIGITACAO                                      
         ,B.VALIDADE                  AS VALIDADE                                               
         ,B.OPERACAO_FISCAL           AS OPERACAO_FISCAL                                         
         ,B.MOTIVO_PERDA              AS MOTIVO_PERDA     
     FROM NF_FATURAMENTO                       A WITH(NOLOCK)                                      
     JOIN NF_FATURAMENTO_PRODUTOS              B WITH(NOLOCK) ON B.NF_FATURAMENTO  = A.NF_FATURAMENTO                                      
                                        
   WHERE A.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL                                                    
      AND A.EMPRESA = @EMPRESA                                          
                                          
 GROUP BY A.FORMULARIO_ORIGEM                                                              
         ,A.TAB_MASTER_ORIGEM                                                                    
         ,A.NF_FATURAMENTO                                                                                   
         ,A.EMPRESA                      
         ,A.ENTIDADE                                                                             
         ,A.NF_NUMERO                                                 
         ,A.NF_SERIE                                                                             
         ,A.NF_ESPECIE                       
         ,A.MOVIMENTO                                                                    
         ,B.PRODUTO                                                               
         ,B.LOTE     
         ,B.VALIDADE_DIGITACAO                                                           
         ,B.VALIDADE                                                      
         ,B.OPERACAO_FISCAL                                      
         ,B.MOTIVO_PERDA                                                  
   
INSERT INTO #RETORNO_NOTAS            (          
                                       FORMULARIO_ORIGEM                                         
                                      ,TAB_MASTER_ORIGEM                                                    
                                      ,REG_MASTER_ORIGEM                                                      
                                      ,CHAVE_NFE                     
                                      ,EMPRESA                                                                  
                                      ,ENTIDADE                        
                                      ,NF_NUMERO                                                                  
                                      ,NF_SERIE                                                                  
                                      ,NF_ESPECIE                                                              
                                      ,MOVIMENTO                                                                  
                                      ,PRODUTO                                                                  
                                      ,QUANTIDADE                                                                 
                                      ,LOTE                                                                      
                                      ,VALIDADE_DIGITACAO                                                      
                                      ,VALIDADE                                                                  
                                      ,NFE_TIPO_OPERACAO    
                                      ,OPERACAO_TIPO  
                                      ,TIPO_NF_CANCELAMENTO                                                      
                                      ,OPERACAO_FISCAL  
                                      ,MOTIVO_PERDA                                     
                                      ,QUANTIDADE_NOTA
                                      )   
                                      
                                                 
/*-- COMPRA --*/                                                    
   SELECT A.FORMULARIO_ORIGEM         AS FORMULARIO_ORIGEM                                                        
         ,A.TAB_MASTER_ORIGEM         AS TAB_MASTER_ORIGEM                                                        
         ,A.NF_COMPRA                 AS REG_MASTER_ORIGEM                                  
         ,A.CHAVE_NFE                 AS CHAVE_NFE                                                      
         ,A.EMPRESA                   AS EMPRESA                                                        
         ,A.ENTIDADE                  AS ENTIDADE                                                           
         ,A.NF_NUMERO                 AS NF_NUMERO                                                      
         ,A.NF_SERIE                  AS NF_SERIE                                                       
         ,A.NF_ESPECIE                AS NF_ESPECIE                                                      
         ,A.MOVIMENTO                 AS MOVIMENTO                                                      
         ,A.PRODUTO                   AS PRODUTO                                                      
         ,A.QUANTIDADE                AS QUANTIDADE                                                
         ,A.LOTE                      AS LOTE                                                      
         ,A.VALIDADE_DIGITACAO        AS VALIDADE_DIGITACAO                                                      
         ,A.VALIDADE                  AS VALIDADE                                                      
         ,B.NFE_TIPO_OPERACAO         AS NFE_TIPO_OPERACAO                                                      
         ,'ENTRADA - COMPRAS'         AS OPERACAO_TIPO                                                    
         ,5                           AS TIPO_NF_CANCELAMENTO                                                      
         ,A.OPERACAO_FISCAL           AS OPERACAO_FISCAL                                                  
         ,NULL                        AS MOTIVO_PERDA                                                    
         ,A.QUANTIDADE                AS QUANTIDADE_NOTA -- Quantidade aberta por produto, usada na validação do Conferido  
     FROM #NF_COMPRA_FINAL                 A                                                    
     JOIN #OPERACOES_FISCAIS               B ON B.OPERACAO_FISCAL = A.OPERACAO_FISCAL                                     
                                            AND B.TIPO_OPERACAO   IN (1,10) --COMPRA/BONIFICACAO  
  
   UNION                                                      
                                          
/*-- TRANSFERENCIA DE SAIDA --*/

  SELECT A.FORMULARIO_ORIGEM                                                                    AS FORMULARIO_ORIGEM  
        ,A.TAB_MASTER_ORIGEM                                                                    AS TAB_MASTER_ORIGEM                             
        ,A.NF_FATURAMENTO                                                                       AS REG_MASTER_ORIGEM                           
        ,D.CHAVE_NFE                                                                            AS CHAVE_NFE                   
        ,A.EMPRESA                                                                              AS EMPRESA                   
        ,A.ENTIDADE                                                                             AS ENTIDADE                  
        ,A.NF_NUMERO                                                                            AS NF_NUMERO  
        ,A.NF_SERIE                                                                             AS NF_SERIE                   
        ,A.NF_ESPECIE                                                                           AS NF_ESPECIE                    
        ,A.MOVIMENTO                                                                            AS MOVIMENTO 
        ,A.PRODUTO                                                                              AS PRODUTO                 
        ,A.QUANTIDADE_ESTOQUE                                                                   AS QUANTIDADE                    
        ,A.LOTE                                                                                 AS LOTE              
        ,A.VALIDADE_DIGITACAO                                                                   AS VALIDADE_DIGITACAO          
        ,A.VALIDADE                                                                             AS VALIDADE                  
        ,C.NFE_TIPO_OPERACAO                                                                    AS NFE_TIPO_OPERACAO                           
        ,CAST(C.DESCRICAO_NFE_TIPO_OPERACAO + ' - ' + C.DESCRICAO_TIPO_OPERACAO AS VARCHAR(30)) AS OPERACAO_TIPO  
        ,1                                                                                      AS TIPO_NF_CANCELAMENTO  
        ,C.OPERACAO_FISCAL                                                                      AS OPERACAO_FISCAL  
        ,NULL                                                                                   AS MOTIVO_PERDA  
        ,A.QUANTIDADE_ESTOQUE                                                                   AS QUANTIDADE_NOTA  
    FROM #NF_FATURAMENTO               A  
    JOIN #PRODUTOS_FARMACIA            B              ON B.PRODUTO                 = A.PRODUTO  
                                                     AND CAST(A.MOVIMENTO AS DATE) BETWEEN B.DATA_INICIO_CONTROLADO AND B.DATA_FINAL_CONTROLADO  
    JOIN #OPERACOES_FISCAIS            C              ON C.OPERACAO_FISCAL         = A.OPERACAO_FISCAL  
                                                     AND C.TIPO_OPERACAO           = 9 --TRANSFERENCIA  
    JOIN NFE_CABECALHO                 D WITH(NOLOCK) ON D.FORMULARIO_ORIGEM       = A.FORMULARIO_ORIGEM  
              AND D.TAB_MASTER_ORIGEM    = A.TAB_MASTER_ORIGEM  
              AND D.REG_MASTER_ORIGEM       = A.NF_FATURAMENTO  
              AND D.STATUS                  = 4  
  
   UNION                                                      
                                                  
/*-- TRANSFERENCIA DE ENTRADA --*/                                                     
  SELECT D.FORMULARIO_ORIGEM                                           AS FORMULARIO_ORIGEM                                                        
        ,D.TAB_MASTER_ORIGEM                                           AS TAB_MASTER_ORIGEM                          
        ,D.ESTOQUE_RECEBIMENTO                                         AS REG_MASTER_ORIGEM                                                      
        ,F.CHAVE_NFE                                                   AS CHAVE_NFE                                                      
        ,D.EMPRESA                                                     AS EMPRESA                                                        
        ,E.ENTIDADE                                                    AS ENTIDADE                                                      
        ,A.NF_NUMERO                                                   AS NF_NUMERO                                                      
        ,A.NF_SERIE                                                    AS NF_SERIE                                                       
        ,A.NF_ESPECIE                                                  AS NF_ESPECIE                                                      
        ,D.MOVIMENTO                                                   AS MOVIMENTO                                                      
        ,X.PRODUTO                                                     AS PRODUTO                                                      
        ,SUM(X.QUANTIDADE_ESTOQUE)                                     AS QUANTIDADE                                                      
        ,X.LOTE                                                        AS LOTE          
        ,X.VALIDADE_DIGITACAO                                          AS VALIDADE_DIGITACAO                        
        ,X.VALIDADE                                                    AS VALIDADE                                                      
        ,0                                                             AS NFE_TIPO_OPERACAO                                                      
        ,CAST('ENTRADA - '+C.DESCRICAO_TIPO_OPERACAO AS VARCHAR(30))   AS OPERACAO_TIPO                                                      
        ,1                                                             AS TIPO_NF_CANCELAMENTO                                                      
        ,C.TRANSFERENCIA_ENTRADA                                       AS OPERACAO_FISCAL                                                      
        ,NULL                                                          AS MOTIVO_PERDA                                                      
        ,SUM(X.QUANTIDADE_ESTOQUE)                                     AS QUANTIDADE_NOTA     
                          
    FROM NF_FATURAMENTO                       A WITH(NOLOCK)                
    JOIN NF_FATURAMENTO_PRODUTOS              X WITH(NOLOCK) ON X.NF_FATURAMENTO          = A.NF_FATURAMENTO     
    JOIN #PRODUTOS_FARMACIA                   B              ON B.PRODUTO                 = X.PRODUTO  
                                                            AND CAST(A.MOVIMENTO AS DATE) BETWEEN B.DATA_INICIO_CONTROLADO  
                                                            AND B.DATA_FINAL_CONTROLADO  
    JOIN #OPERACOES_FISCAIS                   C              ON C.OPERACAO_FISCAL         = X.OPERACAO_FISCAL  
                                                            AND C.TIPO_OPERACAO           = 9 --TRANSFERENCIA  
    JOIN ESTOQUE_TRANSFERENCIAS_RECEBIMENTOS  D WITH(NOLOCK) ON D.NF_FATURAMENTO          = A.NF_FATURAMENTO  
    JOIN EMPRESAS_USUARIAS                    E WITH(NOLOCK) ON E.EMPRESA_USUARIA         = D.EMPRESA_ORIGEM                   
    JOIN NFE_CABECALHO                        F WITH(NOLOCK) ON F.FORMULARIO_ORIGEM       = A.FORMULARIO_ORIGEM                      
                                                            AND F.TAB_MASTER_ORIGEM       = A.TAB_MASTER_ORIGEM                      
                                                            AND F.REG_MASTER_ORIGEM       = A.NF_FATURAMENTO                   
                                                            AND F.STATUS                  = 4  
                                                             
   WHERE D.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL                                                    
     AND D.EMPRESA = @EMPRESA                         
                      
GROUP BY D.FORMULARIO_ORIGEM                                                          
        ,D.TAB_MASTER_ORIGEM                                      
        ,D.ESTOQUE_RECEBIMENTO                                                        
        ,F.CHAVE_NFE                                                      
        ,D.EMPRESA                                                                   
        ,E.ENTIDADE                                                                  
        ,A.NF_NUMERO                                        
        ,A.NF_SERIE                           
        ,A.NF_ESPECIE                                                                
        ,D.MOVIMENTO                                                                 
        ,X.PRODUTO                                                                   
        ,X.LOTE                                                                      
        ,X.VALIDADE_DIGITACAO                                           
        ,X.VALIDADE                                                                                    
        ,CAST('ENTRADA - '+C.DESCRICAO_TIPO_OPERACAO AS VARCHAR(30))                                                    
        ,C.TRANSFERENCIA_ENTRADA        
                                                    
                                      
   UNION                                                      
            
/*-- NOTA DE PERDA --*/                                     
  SELECT A.FORMULARIO_ORIGEM                                                                    AS FORMULARIO_ORIGEM  
        ,A.TAB_MASTER_ORIGEM                                                                    AS TAB_MASTER_ORIGEM  
        ,A.NF_FATURAMENTO                                                                       AS REG_MASTER_ORIGEM  
        ,D.CHAVE_NFE                                                                            AS CHAVE_NFE  
        ,A.EMPRESA                                                                              AS EMPRESA  
        ,A.ENTIDADE                                                                             AS ENTIDADE  
        ,A.NF_NUMERO                                                                            AS NF_NUMERO  
        ,A.NF_SERIE                                                                             AS NF_SERIE  
        ,A.NF_ESPECIE                                                                           AS NF_ESPECIE  
        ,A.MOVIMENTO                                                                            AS MOVIMENTO  
        ,A.PRODUTO                                                                              AS PRODUTO  
        ,A.QUANTIDADE_ESTOQUE                                                                   AS QUANTIDADE  
        ,A.LOTE                                                                                 AS LOTE  
        ,A.VALIDADE_DIGITACAO                                                                   AS VALIDADE_DIGITACAO  
        ,A.VALIDADE                                                                             AS VALIDADE  
        ,C.NFE_TIPO_OPERACAO                                                                    AS NFE_TIPO_OPERACAO  
        ,CAST(C.DESCRICAO_NFE_TIPO_OPERACAO + ' - ' + C.DESCRICAO_TIPO_OPERACAO AS VARCHAR(30)) AS OPERACAO_TIPO  
        ,1                                                                                      AS TIPO_NF_CANCELAMENTO  
        ,C.OPERACAO_FISCAL                                                                      AS OPERACAO_FISCAL  
        ,A.MOTIVO_PERDA                                                                         AS MOTIVO_PERDA  
        ,A.QUANTIDADE_ESTOQUE                                                                   AS QUANTIDADE_NOTA        
    FROM #NF_FATURAMENTO                A                                                                                  
    JOIN #PRODUTOS_FARMACIA             B              ON B.PRODUTO                 = A.PRODUTO             
                                                      AND CAST(A.MOVIMENTO AS DATE) BETWEEN B.DATA_INICIO_CONTROLADO   
                                                      AND B.DATA_FINAL_CONTROLADO                        
    JOIN #OPERACOES_FISCAIS             C              ON C.OPERACAO_FISCAL         = A.OPERACAO_FISCAL              
                                                      AND C.TIPO_OPERACAO           = 18 --PERDA/VENCIMENTO/ROUBO/DETERIORAÇÃO  
    JOIN NFE_CABECALHO                  D WITH(NOLOCK) ON D.FORMULARIO_ORIGEM       = A.FORMULARIO_ORIGEM  
                                                      AND D.TAB_MASTER_ORIGEM       = A.TAB_MASTER_ORIGEM  
                                                      AND D.REG_MASTER_ORIGEM       = A.NF_FATURAMENTO  
                                                      AND D.STATUS                  = 4  
                                                    
   UNION                               
                                                      
/*-- DEVOLUCAO DE COMPRAS --*/                                                      
  SELECT A.FORMULARIO_ORIGEM                                                                    AS FORMULARIO_ORIGEM  
        ,A.TAB_MASTER_ORIGEM                                                                    AS TAB_MASTER_ORIGEM  
        ,A.NF_COMPRA_DEVOLUCAO                                                                  AS REG_MASTER_ORIGEM  
        ,E.CHAVE_NFE                                                                            AS CHAVE_NFE                                                                            
        ,A.EMPRESA                                                                              AS EMPRESA  
        ,A.ENTIDADE                                                                             AS ENTIDADE  
        ,A.NF_NUMERO                                                                            AS NF_NUMERO  
        ,A.NF_SERIE                                                                             AS NF_SERIE  
        ,A.NF_ESPECIE                                                                           AS NF_ESPECIE  
        ,A.MOVIMENTO                                                                            AS MOVIMENTO  
        ,B.PRODUTO                                                                              AS PRODUTO  
        ,SUM(B.QUANTIDADE_ESTOQUE)                                                              AS QUANTIDADE  
        ,B.LOTE                                                                                 AS LOTE  
        ,B.VALIDADE_DIGITACAO                                                                   AS VALIDADE_DIGITACAO  
        ,B.VALIDADE                                                                             AS VALIDADE  
        ,D.NFE_TIPO_OPERACAO                                                                    AS NFE_TIPO_OPERACAO  
        ,CAST(D.DESCRICAO_NFE_TIPO_OPERACAO + ' - ' + D.DESCRICAO_TIPO_OPERACAO AS VARCHAR(30)) AS OPERACAO_TIPO  
        ,2                                                                                      AS TIPO_NF_CANCELAMENTO  
        ,D.OPERACAO_FISCAL                                                                      AS OPERACAO_FISCAL  
        ,9                                                                                      AS MOTIVO_PERDA  
        ,SUM(B.QUANTIDADE_ESTOQUE)                                                              AS QUANTIDADE_NOTA  
    FROM NF_COMPRA_DEVOLUCOES           A WITH(NOLOCK)  
    JOIN NF_COMPRA_DEVOLUCOES_PRODUTOS  B WITH(NOLOCK) ON B.NF_COMPRA_DEVOLUCAO           = A.NF_COMPRA_DEVOLUCAO  
    JOIN #PRODUTOS_FARMACIA             C              ON C.PRODUTO                       = B.PRODUTO  
                                                      AND CAST(A.MOVIMENTO AS DATE) BETWEEN C.DATA_INICIO_CONTROLADO  
                                                      AND C.DATA_FINAL_CONTROLADO  
    JOIN #OPERACOES_FISCAIS             D              ON D.OPERACAO_FISCAL               = B.OPERACAO_FISCAL  
                                                      AND D.TIPO_OPERACAO                 = 2 --DEVOLUÇÃO DE COMPRAS  
    JOIN NFE_CABECALHO                  E WITH(NOLOCK) ON E.FORMULARIO_ORIGEM             = A.FORMULARIO_ORIGEM  
                                                      AND E.TAB_MASTER_ORIGEM             = A.TAB_MASTER_ORIGEM  
                                                      AND E.REG_MASTER_ORIGEM             = A.NF_COMPRA_DEVOLUCAO  
                                                      AND E.STATUS                        = 4  
                                                           
   WHERE A.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL                                                    
     AND A.EMPRESA = @EMPRESA                                  
                                                    
GROUP BY A.FORMULARIO_ORIGEM               
        ,A.TAB_MASTER_ORIGEM                                     
        ,A.NF_COMPRA_DEVOLUCAO                                                       
        ,E.CHAVE_NFE                                             
        ,A.EMPRESA                                                                   
        ,A.ENTIDADE                                                                  
        ,A.NF_NUMERO                                                                 
        ,A.NF_SERIE                                                        
        ,A.NF_ESPECIE                                         
        ,A.MOVIMENTO                                                                 
        ,B.PRODUTO                                                                   
        ,B.LOTE                               
        ,B.VALIDADE_DIGITACAO                                                        
        ,B.VALIDADE                                                      
        ,D.NFE_TIPO_OPERACAO             
        ,CAST(D.DESCRICAO_NFE_TIPO_OPERACAO+' - '+D.DESCRICAO_TIPO_OPERACAO AS VARCHAR(30))                           
        ,D.OPERACAO_FISCAL                                                                
                                                      
   UNION                                                      
                                                      
/*-- VENDA --*/                  
  SELECT A.FORMULARIO_ORIGEM                                                                    AS FORMULARIO_ORIGEM  
        ,A.TAB_MASTER_ORIGEM                                                                    AS TAB_MASTER_ORIGEM  
        ,A.NF_FATURAMENTO                                                                       AS REG_MASTER_ORIGEM  
        ,D.CHAVE_NFE                                                                            AS CHAVE_NFE  
        ,A.EMPRESA                                                                              AS EMPRESA  
        ,A.ENTIDADE                                                                             AS ENTIDADE  
        ,A.NF_NUMERO                                                                            AS NF_NUMERO  
        ,A.NF_SERIE                                                                             AS NF_SERIE  
        ,A.NF_ESPECIE                                                                           AS NF_ESPECIE  
        ,A.MOVIMENTO                                                                            AS MOVIMENTO  
        ,A.PRODUTO                                                                              AS PRODUTO  
        ,A.QUANTIDADE_ESTOQUE                                                                   AS QUANTIDADE  
        ,A.LOTE                                                                                 AS LOTE  
        ,A.VALIDADE_DIGITACAO                                                                   AS VALIDADE_DIGITACAO  
        ,A.VALIDADE                                                                             AS VALIDADE  
        ,C.NFE_TIPO_OPERACAO                                                                    AS NFE_TIPO_OPERACAO  
        ,CAST(C.DESCRICAO_NFE_TIPO_OPERACAO + ' - ' + C.DESCRICAO_TIPO_OPERACAO AS VARCHAR(30)) AS OPERACAO_TIPO  
        ,1                                                                                      AS TIPO_NF_CANCELAMENTO  
        ,C.OPERACAO_FISCAL                                                                      AS OPERACAO_FISCAL  
        ,NULL                                                                                   AS MOTIVO_PERDA  
        ,A.QUANTIDADE_ESTOQUE                                                                   AS QUANTIDADE_NOTA  
    FROM #NF_FATURAMENTO       A                                                                                   
    JOIN #PRODUTOS_FARMACIA    B              ON B.PRODUTO                       = A.PRODUTO                                                    
                                             AND CAST(A.MOVIMENTO AS DATE) BETWEEN B.DATA_INICIO_CONTROLADO AND B.DATA_FINAL_CONTROLADO  
    JOIN #OPERACOES_FISCAIS    C              ON C.OPERACAO_FISCAL               = A.OPERACAO_FISCAL  
                                             AND C.TIPO_OPERACAO                 = 3 --VENDA  
    JOIN NFE_CABECALHO         D WITH(NOLOCK) ON D.FORMULARIO_ORIGEM             = A.FORMULARIO_ORIGEM  
                                             AND D.TAB_MASTER_ORIGEM             = A.TAB_MASTER_ORIGEM  
                                             AND D.REG_MASTER_ORIGEM             = A.NF_FATURAMENTO  
                                             AND D.STATUS                        = 4  
                                            
  UNION                                              
   
/*-- ESTORNO --*/ 

  SELECT A.FORMULARIO_ORIGEM                                                   AS FORMULARIO_ORIGEM  
        ,A.TAB_MASTER_ORIGEM                                                   AS TAB_MASTER_ORIGEM  
        ,A.NF_ESTORNO                                                          AS REG_MASTER_ORIGEM  
        ,E.CHAVE_NFE                                                           AS CHAVE_NFE  
        ,A.EMPRESA                                                             AS EMPRESA  
        ,A.ENTIDADE                                                            AS ENTIDADE  
        ,A.NF_NUMERO                                                           AS NF_NUMERO  
        ,A.NF_SERIE                                                            AS NF_SERIE  
        ,A.NF_ESPECIE                                                          AS NF_ESPECIE  
        ,A.MOVIMENTO                                                           AS MOVIMENTO  
        ,B.PRODUTO                                                             AS PRODUTO  
        ,SUM(B.QUANTIDADE_ESTOQUE)                                             AS QUANTIDADE  
        ,B.LOTE                                                                AS LOTE  
        ,B.VALIDADE_DIGITACAO                                                  AS VALIDADE_DIGITACAO  
        ,B.VALIDADE                                                            AS VALIDADE  
        ,D.NFE_TIPO_OPERACAO                                                   AS NFE_TIPO_OPERACAO  
        ,CAST(D.DESCRICAO_NFE_TIPO_OPERACAO+ ' - ' + 'ESTORNO' AS VARCHAR(30)) AS OPERACAO_TIPO  
        ,6                                                                     AS TIPO_NF_CANCELAMENTO  
        ,D.OPERACAO_FISCAL                                                     AS OPERACAO_FISCAL  
        ,NULL                                                                  AS MOTIVO_PERDA  
        ,SUM(B.QUANTIDADE_ESTOQUE)                                             AS QUANTIDADE_NOTA  
    FROM NF_ESTORNO               A WITH(NOLOCK)                                                        
    JOIN NF_ESTORNO_PRODUTOS      B WITH(NOLOCK) ON B.NF_ESTORNO              = A.NF_ESTORNO     
    JOIN #PRODUTOS_FARMACIA       C              ON C.PRODUTO                 = B.PRODUTO  
                                                AND CAST(A.MOVIMENTO AS DATE) BETWEEN C.DATA_INICIO_CONTROLADO AND C.DATA_FINAL_CONTROLADO  
    JOIN #OPERACOES_FISCAIS       D              ON D.OPERACAO_FISCAL         = B.OPERACAO_FISCAL  
    JOIN NFE_CABECALHO            E WITH(NOLOCK) ON E.FORMULARIO_ORIGEM       = A.FORMULARIO_ORIGEM  
                                                AND E.TAB_MASTER_ORIGEM       = A.TAB_MASTER_ORIGEM  
                                                AND E.REG_MASTER_ORIGEM       = A.NF_ESTORNO  
                                                AND E.STATUS                  = 4  
                                                         
   WHERE A.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL                                                      
     AND A.EMPRESA = @EMPRESA                                                      
                                          
GROUP BY A.FORMULARIO_ORIGEM                                                                
        ,A.TAB_MASTER_ORIGEM                                                                    
        ,A.NF_ESTORNO                                                                        
        ,E.CHAVE_NFE                                                     
        ,A.EMPRESA                                                                   
        ,A.ENTIDADE                                    
        ,A.NF_NUMERO                                        
        ,A.NF_SERIE                                                
        ,A.NF_ESPECIE                      
        ,A.MOVIMENTO                                                                      
        ,B.PRODUTO                                                                      
        ,B.LOTE                                                                           
        ,B.VALIDADE_DIGITACAO                             
        ,B.VALIDADE                                                        
        ,D.NFE_TIPO_OPERACAO                            
        ,CAST(D.DESCRICAO_NFE_TIPO_OPERACAO+' - '+'ESTORNO' AS VARCHAR(30))    
        ,D.OPERACAO_FISCAL                                                     
                                      
/*--------------------------------------*/                     
/*--  CRIAÇÃO DE TABELAS TEMPORÁRIAS  --*/                                      
/*--            RECEITAS              --*/ 
/*--------------------------------------*/                                      
                                                    
IF OBJECT_ID ('TEMPDB..#RETORNO_RECEITAS')          IS NOT NULL                                      
DROP TABLE #RETORNO_RECEITAS                                      
                                      
IF OBJECT_ID ('TEMPDB..#PDV_ITENS_ANTECESSOR_NULL') IS NOT NULL                                      
DROP TABLE #PDV_ITENS_ANTECESSOR_NULL                                      
       
IF OBJECT_ID ('TEMPDB..#DEVOLUCOES')                IS NOT NULL                                      
DROP TABLE #DEVOLUCOES                                                  
                                                    
IF OBJECT_ID ('TEMPDB..#DEV_PRODUTOS')              IS NOT NULL                                      
DROP TABLE #DEV_PRODUTOS                                               
                                                    
IF OBJECT_ID ('TEMPDB..#PDV_VENDAS')                IS NOT NULL                                 
DROP TABLE #PDV_VENDAS                                      
                                      
IF OBJECT_ID ('TEMPDB..#PREVENDAS_CONTROLADOS')     IS NOT NULL                                      
DROP TABLE #PREVENDAS_CONTROLADOS                                      
                                      
CREATE TABLE #RETORNO_RECEITAS        ( 
                                       MOVIMENTO               DATE      
                                      ,VENDA                   NUMERIC(15)                                                  
                                      ,CAIXA                   NUMERIC(6)                                                  
                                      ,LOJA                    NUMERIC(15)                                                  
                                      ,ECF_CUPOM               NUMERIC(10)  
                                      ,PREVENDA                NUMERIC(15)                                                  
                                      ,NUMERO_RECEITA          NUMERIC(20)                    
                                      ,DATA_RECEITA            DATE                                                  
                                      ,NOME_COMPRADOR          VARCHAR(60)                                                  
                                      ,ORGAO_EMISSOR_COMPRADOR VARCHAR(41)                                             
                                      ,UF_COMPRADOR            VARCHAR(2)                                                  
                                      ,TIPO_DOCUMENTO          VARCHAR(41)                                                  
                                      ,DOCUMENTO               VARCHAR(20)                                                  
                                      ,TELEFONE_COMPRADOR      VARCHAR(41)                                             
                                      ,CR_PRESCRITOR           VARCHAR(20)                                                  
                                      ,MEDICO                  NUMERIC(15)                                                  
                                      ,NOME_PRESCRITOR         VARCHAR(60)                                                  
                                      ,CODIGO_CR_PRESCRITOR    NUMERIC(15)                                                  
                                      ,UF_PRESCRITOR           VARCHAR(2)                                                  
                                      ,NOME_PACIENTE           VARCHAR(60)                                                  
                                      ,IDADE_PACIENTE          INT                                                  
                                      ,UNIDADE_IDADE           NUMERIC(1)                                 
                                      ,SEXO                    VARCHAR(1)                                                  
                                      ,CID                     VARCHAR(4)                           
                                      ,VENDEDOR                NUMERIC(15)                                     
                                      )       
                                              
CREATE TABLE #PDV_ITENS_ANTECESSOR_NULL ( 
                                         ANTECESSOR            NUMERIC(15)                                                  
                                        ,LOJA                  NUMERIC(15)                                      
                                        ,ITEM                  NUMERIC(15)                                                  
                                        ,CAIXA                 NUMERIC(6)                                                  
                                        ,PRODUTO               NUMERIC(15)                                                  
                                        ,MOVIMENTO             DATE                                       
                                        )                                       
                                      
CREATE TABLE #DEVOLUCOES              (
                                       LOJA                    NUMERIC(15)                                                  
                                      ,MOVIMENTO               DATE       
                                      ,PRODUTO                 NUMERIC(15)  
                                      ,ECF_CUPOM               NUMERIC(10)  
                                      ,CAIXA                   NUMERIC(6)  
                                      ,VENDA                   NUMERIC(15)  
                                      ,MOVIMENTO_VENDA         DATE
                                      )                                       
                                             
CREATE TABLE #PDV_VENDAS              ( 
                                       PREVENDA                NUMERIC(15)                                                  
                                      ,MOVIMENTO               DATE                                                  
                                      ,LOJA                    NUMERIC(15)                                                  
                                      ,VENDA                   NUMERIC(15)                                                  
                                      ,CAIXA                   NUMERIC(6)                                                  
                                      ,ECF_CUPOM               NUMERIC(10)                                                  
                                      ,PRODUTO                 NUMERIC(15)                           
                                      ,VENDEDOR                NUMERIC(15)                               
                                      )                                       
                                      
CREATE TABLE #DEV_PRODUTOS            (
                                       CUPOM                   NUMERIC(10)                                      
                                      ,PRODUTO                 NUMERIC(15)                                      
                                      ,EMPRESA                 NUMERIC(15)                                      
                                      ,MOVIMENTO               DATETIME
                                      )                                
                                              
CREATE TABLE #PREVENDAS_CONTROLADOS   ( 
                                       PRODUTO                 NUMERIC(15)  
                                      ,NUMERO_RECEITA          NUMERIC(20)  
                                      ,DATA_RECEITA            DATE                                               
                                      ,NOME_COMPRADOR          VARCHAR(60)                                        
                                      ,ORGAO_EMISSOR_COMPRADOR VARCHAR(41)                                        
                                      ,UF_COMPRADOR            VARCHAR(2)                                         
                                      ,TIPO_DOCUMENTO          VARCHAR(41)                                        
                                      ,DOCUMENTO               VARCHAR(20)                                        
                                      ,TELEFONE_COMPRADOR      VARCHAR(41)                                        
                                      ,CR_PRESCRITOR           VARCHAR(20)                                       
                                      ,MEDICO                  NUMERIC(15)                                        
                                      ,NOME_PRESCRITOR         VARCHAR(60)                                        
                                      ,CODIGO_CR_PRESCRITOR    NUMERIC(15)                                        
                                      ,UF_PRESCRITOR           VARCHAR(2)                                             
                                      ,ECF_CUPOM               NUMERIC(10)                                        
                                      ,NOME_PACIENTE           VARCHAR(60)                                        
                                      ,IDADE_PACIENTE          INT                      
                                      ,UNIDADE_IDADE           NUMERIC(1)                                         
                                      ,SEXO                    VARCHAR(1)                                         
                                      ,CID                     VARCHAR(4)                        
                                      ,VENDA                   NUMERIC(15)                                        
                                      ,CAIXA                   NUMERIC(6)                               
                                      ,MOVIMENTO               DATE                                               
                                      ,LOJA                    NUMERIC(15)                                        
                                      ,PREVENDA                NUMERIC(15)                          
                                      ,VENDEDOR                NUMERIC(15)                                      
                                      )                                        
                                             
                                                            
/*--------------------------------------*/                                      
/*--  INSERT NAS TABELAS TEMPORÁRIAS  --*/                                      
/*--            RECEITAS              --*/            
/*--------------------------------------*/                                      
                                      
 INSERT INTO #PDV_ITENS_ANTECESSOR_NULL ( 
                                         ANTECESSOR                                                  
                                        ,LOJA                                                  
                                        ,ITEM                                                  
                                        ,CAIXA                                                  
                                        ,PRODUTO                                                  
                                        ,MOVIMENTO 
                                        )  
                                        
SELECT  A.ANTECESSOR                    AS ANTECESSOR                                 
       ,A.LOJA                          AS LOJA                              
       ,A.ITEM                          AS ITEM                                 
       ,A.CAIXA                         AS CAIXA                                      
       ,A.PRODUTO                       AS PRODUTO                                 
       ,A.MOVIMENTO                     AS MOVIMENTO                                                   
                                                  
  FROM PDV_ITENS A WITH(NOLOCK)                 
                                                   
 WHERE 1=1                 
   AND A.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL                                                  
   AND A.LOJA = @EMPRESA                                     
                                        
                            
 INSERT INTO #DEVOLUCOES              ( 
                                       LOJA                                                  
                                      ,MOVIMENTO                                                  
                                      ,PRODUTO  
                                      ,ECF_CUPOM  
                                      ,CAIXA  
                                      ,VENDA 
                                      ,MOVIMENTO_VENDA 
                                      )                                                  
          
SELECT A.LOJA                         AS LOJA                               
      ,A.MOVIMENTO                    AS MOVIMENTO                                    
      ,A.PRODUTO                      AS PRODUTO  
      ,A.ECF_CUPOM                    AS ECF_CUPOM  
      ,A.CAIXA                        AS CAIXA  
      ,A.VENDA                        AS VENDA 
      ,A.MOVIMENTO_VENDA              AS MOVIMENTO_VENDA 
                       
  FROM PDV_DEVOLUCOES      A WITH(NOLOCK)                                                  
  JOIN #PRODUTOS_FARMACIA  B WITH(NOLOCK) ON B.PRODUTO = A.PRODUTO                                       
                                                            
 WHERE A.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL        
   AND A.LOJA      = @EMPRESA                                                   
                                      
GROUP BY A.LOJA,                                                  
         A.MOVIMENTO,                                                  
         A.PRODUTO,  
         A.ECF_CUPOM,  
         A.CAIXA,  
         A.VENDA,
         A.MOVIMENTO_VENDA
  
                                         
INSERT INTO #PDV_VENDAS               ( 
                                       PREVENDA                                                     
                                      ,MOVIMENTO                                                   
                                      ,LOJA             
                                      ,VENDA                                                       
                                      ,CAIXA                                                       
                                      ,ECF_CUPOM                                                   
                                      ,PRODUTO                          
                                      ,VENDEDOR 
                                      )                                                  
                                                  
   SELECT B.PREVENDA                  AS PREVENDA                                 
         ,B.MOVIMENTO                 AS MOVIMENTO                           
         ,B.LOJA                      AS LOJA                                 
         ,B.VENDA                     AS VENDA              
         ,B.CAIXA                     AS CAIXA                                     
         ,B.ECF_CUPOM                 AS ECF_CUPOM                                 
         ,A.PRODUTO                   AS PRODUTO          
         ,B.VENDEDOR                  AS VENDEDOR                                                 
                                                  
     FROM PDV_ITENS                   A WITH(NOLOCK)                                                  
LEFT JOIN #PDV_ITENS_ANTECESSOR_NULL  D              ON D.ANTECESSOR       = A.ITEM                                                  
                                                    AND D.LOJA             = A.LOJA                                                  
                                                    AND D.CAIXA            = A.CAIXA                                                  
                                                    AND D.PRODUTO          = A.PRODUTO                                                  
                                                    AND D.MOVIMENTO        = A.MOVIMENTO                                   
     JOIN PDV_VENDAS                  B WITH(NOLOCK) ON B.LOJA             = A.LOJA                                                  
                                                    AND B.CAIXA            = A.CAIXA                                                  
                                                    AND B.VENDA            = A.VENDA                                                  
                                                    AND B.MOVIMENTO        = A.MOVIMENTO     
LEFT JOIN #DEVOLUCOES                 X              ON X.LOJA             = A.LOJA                                                  
                                                    AND X.PRODUTO          = A.PRODUTO                                                  
                                                    AND X.MOVIMENTO_VENDA  = A.MOVIMENTO  /* ALTERACAO 002 */
                                                    --RAPHAEL SANSANA 08/06/2021 NÃO ESTAVA SUBINDO AS VENDAS DE PRODUTOS QUE TIVERAM DEVOLUÇÕES NO MESMO DIA  
                                                    AND X.ECF_CUPOM        = A.ECF_CUPOM  
                                                    AND X.CAIXA            = A.CAIXA  
                                                    AND X.VENDA            = A.VENDA  
                                                      
    WHERE 1=1    
      AND D.ITEM       IS NULL      
      AND A.ANTECESSOR IS NULL                                                  
      AND X.LOJA       IS NULL                                                  
      AND B.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL                                                  
      AND B.LOJA       = @EMPRESA                                                  
                   
 GROUP BY B.PREVENDA                                                  
         ,B.MOVIMENTO                                                  
         ,B.LOJA                                        
         ,B.VENDA                                           
         ,B.CAIXA                                                      
         ,B.ECF_CUPOM                                                  
         ,A.PRODUTO                            
         ,B.VENDEDOR                                                                    
                                      
INSERT INTO #PREVENDAS_CONTROLADOS    ( 
                                       PRODUTO                 
                                      ,NUMERO_RECEITA          
                                      ,DATA_RECEITA            
                                      ,NOME_COMPRADOR          
                                      ,ORGAO_EMISSOR_COMPRADOR 
                                      ,UF_COMPRADOR            
                                      ,TIPO_DOCUMENTO          
                                      ,DOCUMENTO               
                                      ,TELEFONE_COMPRADOR      
                                      ,CR_PRESCRITOR           
                                      ,MEDICO   
                                      ,NOME_PRESCRITOR         
                                      ,CODIGO_CR_PRESCRITOR    
                                      ,UF_PRESCRITOR           
                                      ,ECF_CUPOM               
                                      ,NOME_PACIENTE           
                                      ,IDADE_PACIENTE          
                                      ,UNIDADE_IDADE           
                                      ,SEXO                    
                                      ,CID                     
                                      ,VENDA                   
                                      ,CAIXA                   
                                      ,MOVIMENTO               
                                      ,LOJA                    
                                      ,PREVENDA               
                                      ,VENDEDOR
                                      )                        
                                                     
SELECT DISTINCT
       H.PRODUTO                                            AS PRODUTO                
      ,ISNULL(B.NUMERO_RECEITA,0)                           AS NUMERO_RECEITA         
      ,ISNULL(CAST(B.DATA_RECEITA AS DATE),'01/01/1900')    AS DATA_RECEITA           
      ,UPPER(DBO.SEM_CARACTER(B.NOME_COMPRADOR))            AS NOME_COMPRADOR   
      ,UPPER(F.SNGPC_ORGAO_EXPEDITOR)                       AS ORGAO_EMISSOR_COMPRADOR
      ,UPPER(K.ESTADO )                                     AS UF_COMPRADOR           
      ,UPPER(J.TIPO_DOCUMENTO)                              AS TIPO_DOCUMENTO         
      ,UPPER(B.DOCUMENTO)                                   AS DOCUMENTO              
      ,UPPER(B.TELEFONE_COMPRADOR)                          AS TELEFONE_COMPRADOR     
      ,B.CR_PRESCRITOR                                      AS CR_PRESCRITOR          
      ,Z.MEDICO                                             AS MEDICO                 
      ,UPPER(B.NOME_PRESCRITOR)                             AS NOME_PRESCRITOR        
      ,B.CODIGO_CR_PRESCRITOR                               AS CODIGO_CR_PRESCRITOR   
      ,UPPER(L.ESTADO )                                     AS UF_PRESCRITOR          
      ,H.ECF_CUPOM                                          AS ECF_CUPOM              
      ,UPPER(B.NOME_PACIENTE)                               AS NOME_PACIENTE          
      ,CASE WHEN LEN(B.PACIENTE_IDADE) > 3                                            
            THEN NULL                                                                 
            ELSE B.PACIENTE_IDADE                                                     
        END                                                 AS IDADE_PACIENTE         
      ,B.UNIDADE_IDADE                                      AS UNIDADE_IDADE          
      ,UPPER(B.SEXO_PACIENTE)                               AS SEXO                   
      ,B.CID                                                AS CID                    
      ,H.VENDA                                              AS VENDA                  
      ,H.CAIXA                                              AS CAIXA                  
      ,H.MOVIMENTO                                          AS MOVIMENTO              
      ,H.LOJA                                               AS LOJA                   
      ,CASE WHEN ISNULL(A.PREVENDA,0) =0       
            THEN H.VENDA*-1                                      
            ELSE A.PREVENDA                                      
        END                                                 AS PREVENDA               
      ,CASE WHEN H.VENDEDOR = 0                                  
            THEN ISNULL(A.VENDEDOR, 0)                                  
            ELSE H.VENDEDOR                                  
        END                                                 AS VENDEDOR               
           FROM #PDV_VENDAS            H                                                  
      LEFT JOIN PDV_PREVENDAS          A WITH(NOLOCK) ON A.PREVENDA              = H.PREVENDA  
                                                     AND A.LOJA                  = H.LOJA  
      LEFT JOIN PDV_PREVENDAS_ITENS    B WITH(NOLOCK) ON B.PREVENDA              = A.PREVENDA  
                                                     AND B.LOJA                  = A.LOJA  
                                                     AND B.PRODUTO               = H.PRODUTO  
      LEFT JOIN MEDICOS                Z WITH(NOLOCK) ON Z.CODIGO_CR             = B.CODIGO_CR_PRESCRITOR  
                                                     AND Z.CR                    = B.CR_PRESCRITOR  
                                                     AND Z.UF                    = B.UF_PRESCRITOR  
           JOIN PRODUTOS               C WITH(NOLOCK) ON C.PRODUTO               = H.PRODUTO  
           JOIN #PRODUTOS_FARMACIA     D WITH(NOLOCK) ON D.PRODUTO               = H.PRODUTO                              
                                                     AND CAST(H.MOVIMENTO AS DATE) BETWEEN D.DATA_INICIO_CONTROLADO AND D.DATA_FINAL_CONTROLADO  
      LEFT JOIN SNGPC_ORGAO_EXPEDITOR  F WITH(NOLOCK) ON F.SNGPC_ORGAO_EXPEDITOR = B.ORGAO_EMISSOR_COMPRADOR                                   
      LEFT JOIN TIPOS_DOCUMENTOS       J WITH(NOLOCK) ON J.TIPO_DOCUMENTO        = B.TIPO_DOCUMENTO            
      LEFT JOIN ESTADOS                K WITH(NOLOCK) ON K.ESTADO                = B.UF_COMPRADOR           
      LEFT JOIN ESTADOS                L WITH(NOLOCK) ON L.ESTADO                = B.UF_PRESCRITOR  
                           
/*-----------------------------------------------------*/                                                  
/*-- REMOVE LANCAMENTOS CUPONS COM STATUS CANCELADOS --*/                                             
/*-----------------------------------------------------*/                                                  
UPDATE A                                                   
   SET VENDA     = NULL                                                  
      ,LOJA      = NULL                                                  
      ,CAIXA     = NULL                                               
      ,MOVIMENTO = NULL                      
                                                  
  FROM #PREVENDAS_CONTROLADOS  A                                                   
  JOIN ( SELECT X.PREVENDA                                                  
               ,X.VENDA                                                  
               ,X.CAIXA             
               ,X.LOJA                                                  
               ,X.MOVIMENTO                                        
                                               
           FROM PDV_VENDAS A WITH(NOLOCK)                                                   
           JOIN ( SELECT DISTINCT A.PREVENDA                 
                                 ,A.CAIXA                                                  
                                 ,A.LOJA                                                  
                                 ,A.MOVIMENTO                                                 
                                 ,A.VENDA                                                 
                                      
                             FROM #PREVENDAS_CONTROLADOS A) X ON X.VENDA      = A.VENDA                                                  
                                                             AND X.CAIXA      = A.CAIXA                                           
                                                             AND X.LOJA       = A.LOJA                                                  
                                                             AND X.MOVIMENTO  = A.MOVIMENTO                                             
                                                   
          WHERE A.STATUS = 'C'                                          
                                          
       GROUP BY X.PREVENDA,                                                  
                X.VENDA,                                                  
                X.CAIXA,                                                  
                X.LOJA,                                                  
                X.MOVIMENTO  ) Z ON Z.VENDA     = A.VENDA                   
                                AND Z.CAIXA     = A.CAIXA                                                  
                                AND Z.LOJA      = A.LOJA                       
                                AND Z.MOVIMENTO = A.MOVIMENTO                                          
                                                
                                                  
/*-------------------------------------------------------*/                       
/*-- REMOVE LANCAMENTOS QUE POSSUEM DEVOLUCAO DE VENDA --*/                                                  
/*-------------------------------------------------------*/                                                  
                                      
INSERT INTO #DEV_PRODUTOS             ( 
                                       CUPOM
                                      ,PRODUTO
                                      ,EMPRESA
                                      ,MOVIMENTO 
                                      )
                                      
SELECT
    X.CUPOM                           AS CUPOM
   ,X.PRODUTO                         AS PRODUTO
   ,X.LOJA                            AS EMPRESA
   ,X.MOVIMENTO                       AS MOVIMENTO
FROM
    #PREVENDAS_CONTROLADOS   A
JOIN
(SELECT
     A.CUPOM                          AS CUPOM
    ,B.PRODUTO                        AS PRODUTO
    ,A.EMPRESA                        AS LOJA
  --,CAST(A.MOVIMENTO AS DATE)        AS MOVIMENTO
    ,CAST(A.DATA_COMPRA AS DATE)      AS MOVIMENTO   /* ALTERACAO 002 */
 FROM
     DEV_PRODUTOS_CAIXAS  A WITH(NOLOCK)
 JOIN
     DEV_PRODUTOS         B WITH(NOLOCK)ON B.DEVOLUCAO_PRODUTO = A.DEVOLUCAO_PRODUTO
 )                                    X ON X.CUPOM             = A.ECF_CUPOM
                                       AND X.LOJA              = A.LOJA
                                       AND X.PRODUTO           = A.PRODUTO
                                       AND X.MOVIMENTO         = A.MOVIMENTO
                                     
     UPDATE A                                                   
        SET VENDA     = NULL                                                  
           ,LOJA      = NULL                                                  
           ,CAIXA     = NULL                                                  
           ,MOVIMENTO = NULL                                       
                                                      
       FROM #PREVENDAS_CONTROLADOS   A                                                   
       JOIN #DEV_PRODUTOS            B ON B.CUPOM     = A.ECF_CUPOM                                                  
                                      AND B.EMPRESA   = A.LOJA                                               
                                      AND B.PRODUTO   = A.PRODUTO                                                  
                                      AND B.MOVIMENTO = A.MOVIMENTO                                                  
                                                 
                                                   
INSERT INTO #RETORNO_RECEITAS         ( 
                                       MOVIMENTO                                                  
                                      ,LOJA                                                  
                                      ,VENDA                                                  
                                      ,CAIXA                                                  
                                      ,ECF_CUPOM                                                  
                                      ,PREVENDA                                                  
                                      ,NUMERO_RECEITA                                              
                                      ,DATA_RECEITA    
                                      ,NOME_COMPRADOR    
                                      ,ORGAO_EMISSOR_COMPRADOR                                                  
                                      ,UF_COMPRADOR                  
                                      ,TIPO_DOCUMENTO                                                        
                                      ,DOCUMENTO                                                                
                                      ,TELEFONE_COMPRADOR                                                       
                                      ,CR_PRESCRITOR                                                            
                                      ,CODIGO_CR_PRESCRITOR                               
                                      ,MEDICO                                                  
                                      ,NOME_PRESCRITOR                                 
                                      ,UF_PRESCRITOR                                                  
                                      ,NOME_PACIENTE                             
                                      ,SEXO                                                  
                                      ,CID                                                  
                                      ,IDADE_PACIENTE                                                  
                                      ,UNIDADE_IDADE                           
                                      ,VENDEDOR
                                      )                              
                                                                
 SELECT MOVIMENTO                     AS MOVIMENTO                                                  
       ,LOJA                          AS LOJA                                                     
       ,VENDA                         AS VENDA                                                     
       ,CAIXA                         AS CAIXA                                                  
       ,ECF_CUPOM                     AS ECF_CUPOM                                                  
       ,PREVENDA                      AS PREVENDA                                                     
       ,NUMERO_RECEITA                AS NUMERO_RECEITA                                                  
       ,DATA_RECEITA                  AS DATA_RECEITA                                                  
       ,MAX(NOME_COMPRADOR)           AS NOME_COMPRADOR                                         
       ,MAX(ORGAO_EMISSOR_COMPRADOR)  AS ORGAO_EMISSOR_COMPRADOR                                                  
       ,MAX(UF_COMPRADOR)             AS UF_COMPRADOR                                                  
       ,MAX(TIPO_DOCUMENTO)           AS TIPO_DOCUMENTO                                                  
       ,MAX(DOCUMENTO)                AS DOCUMENTO                                                  
       ,MAX(TELEFONE_COMPRADOR)       AS TELEFONE_COMPRADOR                                                  
       ,MAX(CR_PRESCRITOR)            AS CR_PRESCRITOR                                                  
       ,MAX(CODIGO_CR_PRESCRITOR)     AS CODIGO_CR_PRESCRITOR                                                  
       ,MAX(MEDICO)                   AS MEDICO                                                  
       ,MAX(NOME_PRESCRITOR)          AS NOME_PRESCRITOR                                                  
       ,MAX(UF_PRESCRITOR)            AS UF_PRESCRITOR                                                  
       ,MAX(NOME_PACIENTE)            AS NOME_PACIENTE                                                  
       ,MAX(SEXO)                     AS SEXO                                                  
       ,MAX(CID)                      AS CID                                                  
       ,MAX(IDADE_PACIENTE)           AS IDADE_PACIENTE                         
       ,MAX(UNIDADE_IDADE)            AS UNIDADE_IDADE                            
       ,MAX(VENDEDOR)                 AS VENDEDOR                                                
                          
    FROM #PREVENDAS_CONTROLADOS                                    
   WHERE VENDA IS NOT NULL                                            
                                                  
GROUP BY MOVIMENTO                          
        ,LOJA                                                  
        ,VENDA               
        ,CAIXA                                                  
        ,ECF_CUPOM                                                  
        ,PREVENDA                                                  
        ,NUMERO_RECEITA  
        ,DATA_RECEITA  
        
ORDER BY MOVIMENTO, VENDA, CAIXA                                        
           
/*--------------------------------------*/                                      
/*--  CRIAÇÃO DE TABELAS TEMPORÁRIAS  --*/                                      
/*--         ITENS DA RECEITAS        --*/                                      
/*--------------------------------------*/           
IF OBJECT_ID ('TEMPDB..#RETORNO_PDV')             IS NOT NULL                                    
DROP TABLE #RETORNO_PDV                                        
                                                  
IF OBJECT_ID ('TEMPDB..#PDV_VENDAS_2')            IS NOT NULL                                    
DROP TABLE #PDV_VENDAS_2                                         
                                                  
IF OBJECT_ID ('TEMPDB..#PDV_ITENS')               IS NOT NULL                                    
DROP TABLE #PDV_ITENS                                        
                                                  
IF OBJECT_ID ('TEMPDB..#PDV_PREVENDAS_ITENS')     IS NOT NULL                                    
DROP TABLE #PDV_PREVENDAS_ITENS                                 
                        
IF OBJECT_ID ('TEMPDB..#PREVENDAS_CONTROLADOS_2') IS NOT NULL                                    
DROP TABLE #PREVENDAS_CONTROLADOS_2                                        
                                
          
CREATE TABLE #RETORNO_PDV             ( 
                                       MOVIMENTO               DATE                                              
                                      ,VENDA                   NUMERIC(15)                                                
                                      ,CAIXA                   NUMERIC(6)                                                
                                      ,LOJA                    NUMERIC(15)                                                
                                      ,PREVENDA                NUMERIC(15)                                                
                                      ,NUMERO_RECEITA          NUMERIC(15)                                                
                                      ,DATA_RECEITA            DATE                                                
                                      ,PRODUTO                 NUMERIC(15)                                                
                                      ,QUANTIDADE_PRESCRITA    NUMERIC(15)                                                
                                      ,QUANTIDADE              NUMERIC(15)                                                
                                      ,LOTE                    VARCHAR(20)                                                
                                      ,VALIDADE_DIGITACAO      VARCHAR(7)                                                     
                                      ,VALIDADE                DATE                                                
                                      ,REGISTRO_MS             VARCHAR(13)                                                
                                      ,USO_PROLONGADO          VARCHAR(1)   
                                      ,CLASSE_TERAPEUTICA      NUMERIC(15) 
                                      )                                        
                                          
CREATE TABLE #PDV_VENDAS_2            (
                                       MOVIMENTO  DATE                                                
                                      ,LOJA       NUMERIC(15)         
                                      ,VENDA      NUMERIC(15)              
                                      ,CAIXA      NUMERIC(6)                                          
                                      ,PREVENDA   NUMERIC(15)              
                                      ,ECF_CUPOM  VARCHAR(6) 
                                      )                                         
                                             
CREATE TABLE #PDV_ITENS               (
                                       PREVENDA           NUMERIC(15)                                                
                                      ,MOVIMENTO          DATE                                                
                                      ,LOJA               NUMERIC(15)                                             
                                      ,VENDA              NUMERIC(15)           
                                      ,CAIXA              NUMERIC(6)                       
                                      ,ECF_CUPOM          NUMERIC(10)                                                
                                      ,PRODUTO            NUMERIC(15)                                                
                                      ,QUANTIDADE         NUMERIC(15)                                          
                                      ,CLASSE_TERAPEUTICA NUMERIC(5)                                          
                                      ,ITEM               NUMERIC(15) 
                                      )                                         
                                          
CREATE TABLE #PDV_PREVENDAS_ITENS     ( 
                                       PREVENDA            NUMERIC(15)                                                
                                      ,LOJA                NUMERIC(15)                                             
                                      ,PRODUTO             NUMERIC(15)                 
                                      ,QUANTIDADE          NUMERIC(15)              
                                      ,LOTE                VARCHAR(20)                                          
                                      ,VALIDADE_DIGITACAO  VARCHAR(7)                                           
                                      ,NUMERO_RECEITA      NUMERIC(20)                                          
                                      ,DATA_RECEITA        DATE                                          
                                      ,USO_PROLONGADO      VARCHAR(1)                                          
                                      ,VALIDADE            VARCHAR(10)                                          
                                      ,ITEM                NUMERIC(15)
                                      )                                         
                                      
CREATE TABLE #PREVENDAS_CONTROLADOS_2 ( 
                                       PRODUTO                 NUMERIC(15)                                                
                                      ,DESCRICAO               VARCHAR(40)                                                 
                                      ,LOTE                    VARCHAR(20)                                                 
                                      ,REGISTRO_MS             VARCHAR(13)                                                 
                                      ,VALIDADE_DIGITACAO      VARCHAR(7)                                                  
                                      ,VALIDADE                DATE                                                
                                      ,QUANTIDADE_PRESCRITA    INT                                                
                                      ,QUANTIDADE              NUMERIC(15)                                                
                                      ,NUMERO_RECEITA          NUMERIC(20)                                                
                                      ,DATA_RECEITA            DATE                                                
                                      ,ECF_CUPOM               NUMERIC(10)                                      
                                      ,USO_PROLONGADO          VARCHAR(1)                                                
                                      ,VENDA                   NUMERIC(15)                                                
                                      ,CAIXA                   NUMERIC(6)                                           
                                      ,MOVIMENTO               DATE                 
                                      ,LOJA                    NUMERIC(15)                                                
                                      ,PREVENDA                NUMERIC(15)                                                
                                      ,CLASSE_TERAPEUTICA      NUMERIC(15)
                                      )                                      
                                                  
                                                         
/*--------------------------------------*/                                      
/*--  INSERT NAS TABELAS TEMPORÁRIAS  --*/                                      
/*--       ITENS DA RECEITAS          --*/                                      
/*--------------------------------------*/                                      
                                      
INSERT INTO #PDV_VENDAS_2             (
                                       MOVIMENTO                                          
                                      ,LOJA                              
                                      ,VENDA                                                   
                                      ,CAIXA         
                                      ,PREVENDA                                          
                                      ,ECF_CUPOM 
                                      )                          
                                          
SELECT A.MOVIMENTO                    AS MOVIMENTO                      
      ,A.LOJA                         AS LOJA                               
      ,A.VENDA                        AS VENDA                                 
      ,A.CAIXA                        AS CAIXA                       
      ,A.PREVENDA                     AS PREVENDA                       
      ,A.ECF_CUPOM                    AS ECF_CUPOM                  
                                          
  FROM PDV_VENDAS  A WITH(NOLOCK)                                          
 WHERE 1=1                                          
   AND A.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL                                                
   AND A.LOJA      = @EMPRESA                                             
                    
                                      
INSERT INTO #PDV_ITENS              ( 
                                     PREVENDA                                                   
                                    ,MOVIMENTO                                                 
                                    ,LOJA                                                      
                                    ,VENDA                                                     
                                    ,CAIXA                                      
                                    ,ECF_CUPOM                                                 
                                    ,PRODUTO                                                   
                                    ,QUANTIDADE                    
                                    ,CLASSE_TERAPEUTICA                                          
                                    ,ITEM
                                    )                                                
                                                
   SELECT B.PREVENDA                AS PREVENDA                                 
         ,A.MOVIMENTO               AS MOVIMENTO                                 
         ,A.LOJA                    AS LOJA                                 
         ,A.VENDA                   AS VENDA                      
         ,A.CAIXA                   AS CAIXA                                     
         ,A.ECF_CUPOM               AS ECF_CUPOM                                 
         ,A.PRODUTO                 AS PRODUTO                                                
         ,1                         AS QUANTIDADE                                          
         ,E.CLASSE_TERAPEUTICA                                         
         ,ROW_NUMBER() OVER(PARTITION BY A.VENDA                                          
                                        ,A.LOJA                                          
                                        ,A.CAIXA                                          
                                        ,A.MOVIMENTO                                          
                                        ,A.PRODUTO      
       ORDER BY A.ITEM)             AS ITEM                                          
                     
     FROM PDV_ITENS      A WITH(NOLOCK)  
LEFT JOIN #DEVOLUCOES                X              ON X.LOJA                    = A.LOJA  
                                                   AND X.PRODUTO                 = A.PRODUTO  
                                                   AND X.MOVIMENTO_VENDA         = A.MOVIMENTO  
                                               --  RAPHAEL SANSANA 08/06/2021 NÃO ESTAVA SUBINDO AS VENDAS DE PRODUTOS QUE TIVERAM DEVOLUÇÕES NO MESMO DIA  
                                                   AND X.ECF_CUPOM               = A.ECF_CUPOM  
                                                   AND X.CAIXA                   = A.CAIXA  
                                                   AND X.VENDA                   = A.VENDA  
LEFT JOIN #PDV_ITENS_ANTECESSOR_NULL D              ON D.ANTECESSOR              = A.ITEM  
                          AND D.LOJA                    = A.LOJA  
                                                   AND D.CAIXA                   = A.CAIXA  
                                                   AND D.PRODUTO                 = A.PRODUTO  
                                                   AND D.MOVIMENTO               = A.MOVIMENTO  
     JOIN #PDV_VENDAS_2              B              ON B.LOJA                    = A.LOJA  
                                                   AND B.CAIXA                   = A.CAIXA  
                                                   AND B.VENDA                   = A.VENDA  
                                                   AND B.MOVIMENTO               = A.MOVIMENTO  
     JOIN VEZES                      C WITH(NOLOCK) ON C.SEQUENCIA              <= A.QUANTIDADE  
     JOIN #PRODUTOS_FARMACIA         E              ON E.PRODUTO                 = A.PRODUTO  
                                                   AND CAST(A.MOVIMENTO AS DATE) BETWEEN E.DATA_INICIO_CONTROLADO AND E.DATA_FINAL_CONTROLADO  
    WHERE 1=1                                                
      AND D.ITEM IS NULL                                                
      AND A.ANTECESSOR IS NULL                                                
      AND X.LOJA IS NULL                                          
                                      
                                      
INSERT INTO #PDV_PREVENDAS_ITENS    (   
                                     PREVENDA                               
                                    ,LOJA                                                        
                                    ,PRODUTO                                                    
                                    ,QUANTIDADE                                                  
                                    ,LOTE                                                        
                                    ,VALIDADE_DIGITACAO                                          
                                    ,NUMERO_RECEITA                                              
                                    ,DATA_RECEITA                                            
                                    ,USO_PROLONGADO               
                                    ,VALIDADE                                               
                                    ,ITEM 
                                    )                                          
                                          
   SELECT A.PREVENDA                                         AS PREVENDA                                          
         ,A.LOJA                                             AS LOJA                                          
         ,B.PRODUTO                                          AS PRODUTO                                       
         ,1                                                  AS QUANTIDADE                                          
         ,ISNULL(UPPER(B.LOTE),'NÃO INFORMADO')              AS LOTE                                          
         ,CASE WHEN LEN(ISNULL(B.VALIDADE,'01/1900'))>7                                    
               THEN SUBSTRING(B.VALIDADE, 4, 10)                              
               ELSE ISNULL(B.VALIDADE,'01/1900')                              
          END                                                AS VALIDADE_DIGITACAO                                              
         ,ISNULL(B.NUMERO_RECEITA,0)                         AS NUMERO_RECEITA                                          
         ,ISNULL(CAST(B.DATA_RECEITA AS DATE),'01/01/1900')  AS DATA_RECEITA             
         ,UPPER(B.USO_PROLONGADO)                            AS USO_PROLONGADO   
         ,B.VALIDADE                                         AS VALIDADE                                          
         ,ROW_NUMBER() OVER(PARTITION BY A.PREVENDA  
                                        ,A.LOJA  
                                        ,B.PRODUTO   
                                ORDER BY B.PREVENDA_ITEM)    AS ITEM  
            
     FROM #PDV_VENDAS_2       A                                           
     JOIN PDV_PREVENDAS_ITENS B WITH(NOLOCK) ON B.PREVENDA   = A.PREVENDA                                          
                                            AND B.LOJA       = A.LOJA                                          
     JOIN VEZES               C WITH(NOLOCK) ON C.SEQUENCIA <= B.QUANTIDADE  
                  
INSERT INTO #PREVENDAS_CONTROLADOS_2 ( 
                                      PRODUTO                                                
                                     ,LOTE                                                                     
                                     ,REGISTRO_MS                  
                                     ,VALIDADE_DIGITACAO                                                
                                     ,VALIDADE                                                
                                     ,QUANTIDADE_PRESCRITA                                                    
                                     ,QUANTIDADE                                                              
                                     ,NUMERO_RECEITA                                              
                                     ,DATA_RECEITA                                                            
                                     ,ECF_CUPOM                                                            
                                     ,USO_PROLONGADO                                                          
                                     ,VENDA                                                                   
                                     ,CAIXA                                                                 
                                     ,MOVIMENTO                                                               
                                     ,LOJA                                                                
                                     ,PREVENDA                                                
                                     ,CLASSE_TERAPEUTICA                                           
                                     )                                          
                                          
   SELECT A.PRODUTO                                          AS PRODUTO  
         ,ISNULL(UPPER(B.LOTE),'NÃO INFORMADO')              AS LOTE  
         ,ISNULL(C.REGISTRO_MS, 'NÃO INFORMADO')             AS REGISTRO_MS  
         ,ISNULL(B.VALIDADE_DIGITACAO,'01/1900')             AS VALIDADE_DIGITACAO  
         ,ISNULL(C.VALIDADE,'01/01/1900')                    AS VALIDADE  
         ,0                                                  AS QUANTIDADE_PRESCRITA  
         ,SUM(A.QUANTIDADE)                                  AS QUANTIDADE  
         ,ISNULL(B.NUMERO_RECEITA,0)                         AS NUMERO_RECEITA  
         ,ISNULL(CAST(B.DATA_RECEITA AS DATE),'01/01/1900')  AS DATA_RECEITA  
         ,A.ECF_CUPOM                                        AS ECF_CUPOM  
         ,UPPER(B.USO_PROLONGADO)                            AS USO_PROLONGADO                                         
         ,A.VENDA                                            AS VENDA  
         ,A.CAIXA                                            AS CAIXA  
         ,A.MOVIMENTO                                        AS MOVIMENTO  
         ,A.LOJA                                             AS LOJA  
       --,A.PREVENDA                                         AS PREVENDA  
         ,CASE WHEN A.PREVENDA = 0  
               THEN A.VENDA * -1  
               ELSE A.PREVENDA 
           END                                               AS PREVENDA  --Alterado Por Ruan Rufino em 20/10/2020 - Tickets 135542 e 163098  
         ,A.CLASSE_TERAPEUTICA                               AS CLASSE_TERAPEUTICA  
     FROM #PDV_ITENS              A                                           
LEFT JOIN #PDV_PREVENDAS_ITENS    B              ON B.PREVENDA              = A.PREVENDA                                          
                                                AND B.LOJA                  = A.LOJA                                          
                                                AND B.PRODUTO               = A.PRODUTO                                          
                                                AND B.ITEM                  = A.ITEM                                          
LEFT JOIN PRODUTOS_LOTE_VALIDADE  C WITH(NOLOCK) ON C.LOTE                  = B.LOTE                       
                                                AND C.VALIDADE_DIGITACAO    = B.VALIDADE                                                
                                                AND C.PRODUTO               = B.PRODUTO                                          
GROUP BY  A.PRODUTO                                                                                  
         ,ISNULL(UPPER(B.LOTE),'NÃO INFORMADO')                                                      
         ,ISNULL(C.REGISTRO_MS, 'NÃO INFORMADO')                                          
         ,ISNULL(B.VALIDADE_DIGITACAO,'01/1900')                                                         
         ,ISNULL(C.VALIDADE,'01/01/1900')                                          
         ,ISNULL(B.NUMERO_RECEITA,0)                        
         ,ISNULL(CAST(B.DATA_RECEITA AS DATE),'01/01/1900')                                          
         ,A.ECF_CUPOM                                                    
         ,UPPER(B.USO_PROLONGADO)                                                                    
         ,A.VENDA                                                                                    
         ,A.CAIXA                                                                                    
         ,A.MOVIMENTO                                                                                
         ,A.LOJA                            
         ,A.PREVENDA                                                                                 
         ,A.CLASSE_TERAPEUTICA                                          
                                      
/*--------------------------------------------------------------------*/                                                
/*--  PEGA ULTIMO REGISTRO MS QUE ENTROU NA PRODUTOS_REGISTROS_MS,  --*/                                                 
/*--      CASO NÃO EXISTA REGISTRO MS NA PRODUTOS_LOTE_VALIDADE     --*/                                        
/*--------------------------------------------------------------------*/                                      
UPDATE A                                                
   SET A.REGISTRO_MS = B.REGISTRO_MS             
                                                  
  FROM #PREVENDAS_CONTROLADOS_2   A                                                
  JOIN #PRODUTOS_REGISTRO_MS      B ON B.PRODUTO = A.PRODUTO                                                
 WHERE A.REGISTRO_MS IS NULL                                        
                                      
/*---------------------------------------------*/                                      
/*-- RETIRA OS PRODUTOS QUE FORAM DEVOLVIDOS --*/                                      
/*---------------------------------------------*/                                      
                                      
UPDATE A                                                   
   SET VENDA     = NULL  
      ,LOJA      = NULL  
      ,CAIXA     = NULL  
      ,MOVIMENTO = NULL                
                              
  FROM #PREVENDAS_CONTROLADOS_2   A     
  JOIN #DEV_PRODUTOS              B ON B.CUPOM     = A.ECF_CUPOM                                                  
                                   AND B.EMPRESA   = A.LOJA                 
                                   AND B.PRODUTO   = A.PRODUTO                                                  
                                   AND B.MOVIMENTO = A.MOVIMENTO                                        
                                                 
                     
INSERT INTO #RETORNO_PDV             ( 
                                      MOVIMENTO                                               
                                     ,LOJA                                                
                                     ,VENDA                                                
                                     ,CAIXA                                      
                                     ,PREVENDA                          
                                     ,NUMERO_RECEITA                                          
                                     ,DATA_RECEITA                                          
                                     ,PRODUTO                                          
                                     ,QUANTIDADE_PRESCRITA                                                 
                                     ,QUANTIDADE                                                
                                     ,LOTE                                     
                                     ,VALIDADE_DIGITACAO                                                
                                     ,VALIDADE                          
                                     ,REGISTRO_MS                    
                                     ,USO_PROLONGADO                                                
                                     ,CLASSE_TERAPEUTICA                                                
                                     )                                        
                                          
  SELECT A.MOVIMENTO                 AS MOVIMENTO                                           
        ,A.LOJA                      AS LOJA                                           
        ,A.VENDA                     AS VENDA                                    
        ,A.CAIXA                     AS CAIXA                 
        ,A.PREVENDA                  AS PREVENDA                                           
        ,A.NUMERO_RECEITA            AS NUMERO_RECEITA                                           
        ,A.DATA_RECEITA              AS DATA_RECEITA                                           
        ,A.PRODUTO                   AS PRODUTO                                           
        ,A.QUANTIDADE_PRESCRITA      AS QUANTIDADE_PRESCRITA                                           
        ,A.QUANTIDADE                AS QUANTIDADE                               
        ,A.LOTE                      AS LOTE                                           
        ,A.VALIDADE_DIGITACAO        AS VALIDADE_DIGITACAO                                           
        ,A.VALIDADE                  AS VALIDADE                                           
        ,A.REGISTRO_MS               AS REGISTRO_MS                                           
        ,A.USO_PROLONGADO            AS USO_PROLONGADO                                           
        ,A.CLASSE_TERAPEUTICA        AS CLASSE_TERAPEUTICA                                       
    FROM #PREVENDAS_CONTROLADOS_2    A                                       
    JOIN #RETORNO_RECEITAS           B ON B.VENDA          = A.VENDA  
 -- RETIRA OS ITENS DOS CUPONS CANCELADOS, POIS NESSA TABELA ELES JÁ FORAM RETIRADOS                                      
                                      AND B.LOJA           = A.LOJA                                      
                                      AND B.CAIXA          = A.CAIXA                                      
                                      AND B.MOVIMENTO      = A.MOVIMENTO                             
                                      AND B.PREVENDA       = A.PREVENDA                            
                                      AND B.NUMERO_RECEITA = A.NUMERO_RECEITA                            
                                      AND B.DATA_RECEITA   = A.DATA_RECEITA                            
   WHERE A.VENDA IS NOT NULL                
                                     
ORDER BY A.MOVIMENTO  
        ,A.VENDA  
        ,A.CAIXA  
        ,A.PRODUTO  
                                      
                                      
/*------------------------*/                                     
/*-- INSERT NAS DETAILS --*/                                      
/*------------------------*/                                      
                                    
INSERT INTO SNGPC_RECEITAS          (
                                     FORMULARIO_ORIGEM                                      
                                    ,TAB_MASTER_ORIGEM                         
                                    ,REG_MASTER_ORIGEM                                      
                                    ,SNGPC                                      
                                    ,MOVIMENTO                                      
                                    ,LOJA       
                                    ,VENDA                                      
                                    ,CAIXA                                      
                                    ,ECF_CUPOM                                      
                                    ,MOVIMENTO_SNGPC                                      
                                    ,PREVENDA                                      
                                    ,NUMERO_RECEITA                                      
                                    ,DATA_RECEITA                
                                    ,NOME_COMPRADOR                                      
                                    ,ORGAO_EMISSOR_COMPRADOR                                      
                                    ,UF_COMPRADOR                  
                                    ,TIPO_DOCUMENTO                                      
                                    ,DOCUMENTO                                  
                                    ,TELEFONE_COMPRADOR                                      
                                    ,CR_PRESCRITOR                                      
                                    ,CODIGO_CR_PRESCRITOR                                      
                                    ,MEDICO                                      
                                    ,NOME_PRESCRITOR                                      
                                    ,UF_PRESCRITOR                                      
                                    ,NOME_PACIENTE                                      
                                    ,SEXO                                      
                                    ,CID                                
                                    ,IDADE_PACIENTE                                      
                                    ,UNIDADE_IDADE                          
                                    ,VENDEDOR
                                    )                                      
                                       
SELECT @FORMULARIO_ORIGEM           AS FORMULARIO_ORIGEM                                      
      ,@TAB_MASTER_ORIGEM           AS TAB_MASTER_ORIGEM                                      
      ,@SNGPC                       AS REG_MASTER_ORIGEM                                      
      ,@SNGPC                       AS SNGPC                                      
      ,A.MOVIMENTO                  AS MOVIMENTO                                   
      ,A.LOJA                       AS LOJA                                   
      ,A.VENDA                      AS VENDA                                   
      ,A.CAIXA                      AS CAIXA                                   
      ,A.ECF_CUPOM                  AS ECF_CUPOM                                      
      ,A.MOVIMENTO                  AS MOVIMENTO_SNGPC                                       
      ,A.PREVENDA                   AS PREVENDA                                   
      ,A.NUMERO_RECEITA             AS NUMERO_RECEITA                                   
      ,A.DATA_RECEITA               AS DATA_RECEITA                                   
      ,A.NOME_COMPRADOR             AS NOME_COMPRADOR             
      ,A.ORGAO_EMISSOR_COMPRADOR    AS ORGAO_EMISSOR_COMPRADOR                                   
      ,A.UF_COMPRADOR               AS UF_COMPRADOR                                   
      ,A.TIPO_DOCUMENTO             AS TIPO_DOCUMENTO                                   
      ,A.DOCUMENTO                  AS DOCUMENTO           
      ,A.TELEFONE_COMPRADOR         AS TELEFONE_COMPRADOR                      
      ,A.CR_PRESCRITOR              AS CR_PRESCRITOR                                   
      ,A.CODIGO_CR_PRESCRITOR       AS CODIGO_CR_PRESCRITOR                                   
      ,A.MEDICO                     AS MEDICO                                   
      ,A.NOME_PRESCRITOR            AS NOME_PRESCRITOR                                   
      ,A.UF_PRESCRITOR              AS UF_PRESCRITOR                                   
      ,A.NOME_PACIENTE              AS NOME_PACIENTE                                   
      ,A.SEXO                       AS SEXO                                   
      ,A.CID                        AS CID                     
      ,A.IDADE_PACIENTE             AS IDADE_PACIENTE                                   
      ,A.UNIDADE_IDADE              AS UNIDADE_IDADE                          
      ,A.VENDEDOR                   AS VENDEDOR                                   
                                      
     FROM #RETORNO_RECEITAS  A  
LEFT JOIN SNGPC_RECEITAS     B WITH(NOLOCK) ON B.MOVIMENTO       = A.MOVIMENTO                                      
                                           AND B.VENDA           = A.VENDA                                      
                                           AND B.CAIXA           = A.CAIXA                                      
                                           AND B.LOJA            = A.LOJA                                      
                                           AND B.PREVENDA        = A.PREVENDA   
                                      
    WHERE B.NUMERO_RECEITA IS NULL   
        
 ORDER BY A.MOVIMENTO, A.VENDA, A.PREVENDA                                                
  
  
                                      
INSERT INTO SNGPC_PDV               (
                                     FORMULARIO_ORIGEM                                      
                                    ,TAB_MASTER_ORIGEM                    
                                    ,REG_MASTER_ORIGEM                                      
                                    ,SNGPC                                      
                                    ,MOVIMENTO                                      
                                    ,LOJA                                      
                                    ,VENDA                                      
                                    ,CAIXA                   
                                    ,PREVENDA                                      
                                    ,NUMERO_RECEITA                   
                                    ,DATA_RECEITA                                      
                                    ,PRODUTO                                      
                                    ,QUANTIDADE_PRESCRITA                                      
                                    ,QUANTIDADE                                      
                                    ,LOTE                                      
                                    ,VALIDADE_DIGITACAO                                      
                                    ,VALIDADE                                      
                                    ,REGISTRO_MS                                      
                                    ,USO_PROLONGADO                                      
                                    ,SNGPC_RECEITA
                                    )                                      
                                      
SELECT @FORMULARIO_ORIGEM                                             AS FORMULARIO_ORIGEM                 
      ,@TAB_MASTER_ORIGEM                                             AS TAB_MASTER_ORIGEM                                      
      ,@SNGPC                                                         AS REG_MASTER_ORIGEM                                      
      ,@SNGPC                                                         AS SNGPC                                      
      ,A.MOVIMENTO                                                    AS MOVIMENTO            
      ,A.LOJA                                                         AS LOJA                 
      ,A.VENDA                                                        AS VENDA                
      ,A.CAIXA                                                        AS CAIXA                
      ,A.PREVENDA                                                     AS PREVENDA             
      ,A.NUMERO_RECEITA                                               AS NUMERO_RECEITA       
      ,A.DATA_RECEITA                                                 AS DATA_RECEITA         
      ,A.PRODUTO                                                      AS PRODUTO             
      ,A.QUANTIDADE_PRESCRITA                                         AS QUANTIDADE_PRESCRITA 
      ,A.QUANTIDADE                                                   AS QUANTIDADE           
      ,A.LOTE                                                         AS LOTE                 
      ,A.VALIDADE_DIGITACAO                                           AS VALIDADE_DIGITACAO                                      
      ,ISNULL(DBO.DEFINI_VALIDADE(A.VALIDADE_DIGITACAO),'01/01/1900') AS VALIDADE                       
      ,A.REGISTRO_MS                                                  AS REGISTRO_MS   
      ,A.USO_PROLONGADO                                               AS USO_PROLONGADO
      ,C.SNGPC_RECEITA                                                AS SNGPC_RECEITA                     
                              
     FROM #RETORNO_PDV            A                                      
LEFT JOIN SNGPC_PDV               B WITH(NOLOCK) ON B.MOVIMENTO         = A.MOVIMENTO                                      
                                                AND B.VENDA             = A.VENDA                                      
                                                AND B.CAIXA             = A.CAIXA                                      
                                                AND B.LOJA              = A.LOJA             
                                                AND B.PREVENDA          = A.PREVENDA                                      
                                                AND B.PRODUTO           = A.PRODUTO                                      
     JOIN SNGPC_RECEITAS          C WITH(NOLOCK) ON C.MOVIMENTO         = A.MOVIMENTO               
                                                AND C.VENDA             = A.VENDA                                      
                                                AND C.CAIXA             = A.CAIXA                                      
                                                AND C.LOJA              = A.LOJA                                      
                                                AND C.PREVENDA          = A.PREVENDA                                      
                                                AND C.NUMERO_RECEITA    = A.NUMERO_RECEITA                                 
                                                AND C.DATA_RECEITA      = A.DATA_RECEITA                                      
                                      
    WHERE B.VENDA IS NULL                                      
                                      
 ORDER BY A.MOVIMENTO, A.VENDA, A.PREVENDA                                      
                                      
                                      
INSERT INTO SNGPC_NFE              (
                                    FORMULARIO_ORIGEM                                  
                                   ,TAB_MASTER_ORIGEM                                      
                                   ,REG_MASTER_ORIGEM                                      
                                   ,SNGPC                                      
                                   ,CHAVE_NFE                                      
                                   ,OPERACAO_TIPO                             
                                   ,NF_NUMERO                                      
                                   ,MOVIMENTO                                      
                                   ,MOVIMENTO_SNGPC                                      
                                   ,ENTIDADE                                      
                                   ,NF_COMPRA                                      
                                   ,NF_FATURAMENTO                                      
                                   ,ESTOQUE_RECEBIMENTO                                      
                                   ,NF_COMPRA_DEVOLUCAO                                      
                                   ,OPERACAO_FISCAL                                      
                                   ,MOTIVO_PERDA
                                   )                                      
                                      
SELECT @FORMULARIO_ORIGEM                                                                                    AS FORMULARIO_ORIGEM  
      ,@TAB_MASTER_ORIGEM                                                                                    AS TAB_MASTER_ORIGEM  
      ,@SNGPC                                                                                                AS REG_MASTER_ORIGEM  
      ,@SNGPC                                                                                                AS SNGPC  
      ,A.CHAVE_NFE                                                                                           AS CHAVE_NFE               
      ,A.OPERACAO_TIPO                                                                                       AS OPERACAO_TIPO               
      ,A.NF_NUMERO                                                                                           AS NF_NUMERO                                                                                                    
      ,CAST(A.MOVIMENTO AS DATE)                                                                             AS MOVIMENTO  
      ,CAST(A.MOVIMENTO AS DATE)                                                                             AS MOVIMENTO_SNGPC  
      ,A.ENTIDADE                                      
      ,CASE WHEN TIPO_NF_CANCELAMENTO = 5         THEN A.REG_MASTER_ORIGEM ELSE NULL END                     AS NF_COMPRA  
      ,CASE WHEN TIPO_NF_CANCELAMENTO = 1 AND A.NFE_TIPO_OPERACAO = 1 THEN A.REG_MASTER_ORIGEM ELSE NULL END AS NF_FATURAMENTO  
      ,CASE WHEN TIPO_NF_CANCELAMENTO = 1 AND A.NFE_TIPO_OPERACAO = 0 THEN A.REG_MASTER_ORIGEM ELSE NULL END AS ESTOQUE_RECEBIMENTO  
      ,CASE WHEN TIPO_NF_CANCELAMENTO = 2         THEN A.REG_MASTER_ORIGEM ELSE NULL END                     AS NF_COMPRA_DEVOLUCAO  
      ,MIN(A.OPERACAO_FISCAL)                                                                                AS OPERACAO_FISCAL  
      ,MIN(A.MOTIVO_PERDA)                                                                                   AS MOTIVO_PERDA  
       FROM #RETORNO_NOTAS               A WITH(NOLOCK)                                      
  LEFT JOIN CANCELAMENTOS_NOTAS_FISCAIS  B WITH(NOLOCK) ON B.TIPO                = A.TIPO_NF_CANCELAMENTO             
                                                       AND B.CHAVE               = A.REG_MASTER_ORIGEM  
                                                       AND B.ID_NOTA             = A.CHAVE_NFE -- RAPHAEL SANSANA 08/06/2021  
  LEFT JOIN SNGPC_NFE                    C WITH(NOLOCK) ON C.SNGPC               = @SNGPC                                      
                                                       AND C.CHAVE_NFE           = A.CHAVE_NFE  
      WHERE B.NF_CANCELAMENTO IS NULL                                      
        AND A.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL                                      
        AND A.EMPRESA = @EMPRESA                                      
        AND C.CHAVE_NFE IS NULL                                      
                                      
   GROUP BY A.FORMULARIO_ORIGEM  
           ,A.TAB_MASTER_ORIGEM  
           ,C.SNGPC  
           ,C.SNGPC  
           ,A.CHAVE_NFE  
           ,A.OPERACAO_TIPO  
           ,A.NF_NUMERO  
           ,A.MOVIMENTO  
           ,A.ENTIDADE  
           ,CASE WHEN TIPO_NF_CANCELAMENTO = 5                             THEN A.REG_MASTER_ORIGEM ELSE NULL END            
           ,CASE WHEN TIPO_NF_CANCELAMENTO = 1 AND A.NFE_TIPO_OPERACAO = 1 THEN A.REG_MASTER_ORIGEM ELSE NULL END            
           ,CASE WHEN TIPO_NF_CANCELAMENTO = 1 AND A.NFE_TIPO_OPERACAO = 0 THEN A.REG_MASTER_ORIGEM ELSE NULL END            
           ,CASE WHEN TIPO_NF_CANCELAMENTO = 2                             THEN A.REG_MASTER_ORIGEM ELSE NULL END  
          -- ,A.MOTIVO_PERDA              
                                                                     
   ORDER BY A.MOVIMENTO, A.CHAVE_NFE                                      
                                      
                                      
INSERT INTO SNGPC_NFE_ITENS       (
                                   FORMULARIO_ORIGEM                             
                                  ,TAB_MASTER_ORIGEM                                      
                                  ,REG_MASTER_ORIGEM                                      
                                  ,SNGPC                                      
                                  ,CHAVE_NFE        
                                  ,OPERACAO_TIPO                                      
                                  ,PRODUTO                                      
                                  ,QUANTIDADE                                      
                                  ,LOTE                                      
                                  ,VALIDADE_DIGITACAO                                      
                                  ,VALIDADE                                      
                                  ,REGISTRO_MS                                      
                                  ,SNGPC_NFE
                                  )                     
                                      
SELECT @FORMULARIO_ORIGEM                  AS FORMULARIO_ORIGEM  
      ,@TAB_MASTER_ORIGEM                  AS TAB_MASTER_ORIGEM  
      ,@SNGPC                              AS REG_MASTER_ORIGEM  
      ,@SNGPC                              AS SNGPC  
	  ,E.CHAVE_NFE                         AS CHAVE_NFE     /*005*/
	  ,E.OPERACAO_TIPO                     AS OPERACAO_TIPO /*005*/                                  
      ,A.PRODUTO                           AS PRODUTO                                    
      ,A.QUANTIDADE                        AS QUANTIDADE                                    
      ,A.LOTE                              AS LOTE                                    
      ,A.VALIDADE_DIGITACAO                AS VALIDADE_DIGITACAO          
      ,A.VALIDADE                          AS VALIDADE                                       
      ,ISNULL(G.REGISTRO_MS,C.REGISTRO_MS) AS REGISTRO_MS  
      ,E.SNGPC_NFE                                      
                                         
       FROM #RETORNO_NOTAS              A WITH(NOLOCK)                                      
  LEFT JOIN CANCELAMENTOS_NOTAS_FISCAIS B WITH(NOLOCK) ON B.TIPO                = A.TIPO_NF_CANCELAMENTO  
                                                      AND B.CHAVE               = A.REG_MASTER_ORIGEM  
                                                      AND B.ID_NOTA             = A.CHAVE_NFE -- RAPHAEL SANSANA 08/06/2021  
  LEFT JOIN #PRODUTOS_REGISTRO_MS       C              ON C.PRODUTO             = A.PRODUTO  
  LEFT JOIN SNGPC_NFE_ITENS             D WITH(NOLOCK) ON D.SNGPC               = @SNGPC  
                                                      AND D.CHAVE_NFE           = A.CHAVE_NFE  
                                                      AND D.PRODUTO             = A.PRODUTO  
       JOIN SNGPC_NFE                   E WITH(NOLOCK) ON E.SNGPC               = @SNGPC  
													  AND E.CHAVE_NFE           = A.CHAVE_NFE  
  LEFT JOIN PRODUTOS_LOTE_VALIDADE      G WITH(NOLOCK) ON G.PRODUTO             = A.PRODUTO  
                                                      AND G.LOTE                = A.LOTE  
                                                      AND G.VALIDADE_DIGITACAO  = A.VALIDADE_DIGITACAO  
      WHERE B.NF_CANCELAMENTO IS NULL                                      
        AND A.MOVIMENTO BETWEEN @DATA_INICIAL AND @DATA_FINAL                                      
        AND A.EMPRESA = @EMPRESA                                      
        AND D.CHAVE_NFE IS NULL                                      
                                      
   ORDER BY A.CHAVE_NFE, A.PRODUTO, A.LOTE                                      
                                          
IF @GRAVACAO_FINAL = 'S'                                      
                                    
BEGIN                                      
                                      
/*------------------------------------------------------*/                                      
/*-- GERACAO DA TABELA DE LOTE E VALIDADE POR PRODUTO --*/                            
/*------------------------------------------------------*/                                      
                 
INSERT INTO PRODUTOS_LOTE_VALIDADE ( 
                                    FORMULARIO_ORIGEM                                       
                                   ,TAB_MASTER_ORIGEM                                       
                                   ,REG_MASTER_ORIGEM                                       
                                   ,PRODUTO                                       
                                   ,LOTE                                      
                                   ,VALIDADE_DIGITACAO                                      
                                   ,VALIDADE                                      
                                   ,REGISTRO_MS
                                   )                                      
                                      
   SELECT DISTINCT 
          @FORMULARIO_ORIGEM       AS FORMULARIO_ORIGEM                                      
         ,@TAB_MASTER_ORIGEM       AS TAB_MASTER_ORIGEM                                      
         ,A.SNGPC                  AS REG_MASTER_ORIGEM                                      
         ,A.PRODUTO                AS PRODUTO                                                 
         ,A.LOTE                   AS LOTE                                                    
         ,A.VALIDADE_DIGITACAO     AS VALIDADE_DIGITACAO                                      
         ,A.VALIDADE               AS VALIDADE             
         ,A.REGISTRO_MS            AS REGISTRO_MS                                              
                                             
     FROM SNGPC_NFE_ITENS                 A WITH(NOLOCK)                                      
LEFT JOIN PRODUTOS_LOTE_VALIDADE          B WITH(NOLOCK) ON B.PRODUTO            = A.PRODUTO                                      
                                                        AND B.LOTE               = A.LOTE                                      
                                                        AND B.VALIDADE_DIGITACAO = A.VALIDADE_DIGITACAO  
      JOIN SNGPC                          C WITH(NOLOCK) ON C.SNGPC              = A.SNGPC                                      
      JOIN PARAMETROS_SNGPC               D WITH(NOLOCK) ON D.EMPRESA_USUARIA    = C.EMPRESA            
      JOIN SNGPC_NFE                      E WITH(NOLOCK) ON E.SNGPC_NFE          = A.SNGPC_NFE                                      
               
     WHERE C.SNGPC      = @SNGPC                                      
       AND E.MOVIMENTO >= D.DATA_INICIO                                      
       AND B.PRODUTO   IS NULL                                      
       AND A.VALIDADE  IS NOT NULL                                       
       AND E.NF_COMPRA IS NOT NULL                                      
                                      
/*---------------------------------------*/                                      
/*-- ATUALIZA O REGISTRO_MS SE EXISTIR --*/                               
/*---------------------------------------*/                                      
                                      
if object_id('tempdb..#UPDATE_PRODUTOS_LOTE_VALIDADE') is not null                                      
   DROP TABLE #UPDATE_PRODUTOS_LOTE_VALIDADE                                      
                                      
   SELECT B.LOTE_VALIDADE                                      
         ,REGISTRO_MS = ISNULL(A.REGISTRO_MS,C.REGISTRO_MS)                                      
  
     INTO #UPDATE_PRODUTOS_LOTE_VALIDADE                                      
                                          
     FROM SNGPC_NFE_ITENS             A WITH(NOLOCK)                                      
     JOIN PRODUTOS_LOTE_VALIDADE      B WITH(NOLOCK) ON B.PRODUTO            = A.PRODUTO                                      
                                                    AND B.LOTE               = A.LOTE  
                                                    AND B.VALIDADE_DIGITACAO = A.VALIDADE_DIGITACAO                                      
LEFT JOIN #PRODUTOS_REGISTRO_MS       C              ON C.PRODUTO            = B.PRODUTO                                    
     JOIN SNGPC_NFE                   D WITH(NOLOCK) ON D.SNGPC_NFE          = A.SNGPC_NFE                                       
                   
WHERE A.SNGPC        = @SNGPC                                      
  AND A.VALIDADE    IS NOT NULL                                      
  AND D.NF_COMPRA   IS NOT NULL                                      
  AND B.REGISTRO_MS IS NULL                                      
                                      
                                      
UPDATE B                                      
   SET REGISTRO_MS = A.REGISTRO_MS                                      
                                 
  FROM #UPDATE_PRODUTOS_LOTE_VALIDADE  A                                      
  JOIN PRODUTOS_LOTE_VALIDADE          B WITH(NOLOCK) ON B.LOTE_VALIDADE = A.LOTE_VALIDADE                                      
                                      
                                      
/*--------------------------------------*/                                      
/*--  CRIAÇÃO DE TABELAS TEMPORÁRIAS  --*/                                      
/*--              GERAL               --*/        
/*--------------------------------------*/                                      
                                      
IF OBJECT_ID ('TEMPDB..#PRODUTOS_LOTE_VALIDADE') IS NOT NULL                                       
DROP TABLE #PRODUTOS_LOTE_VALIDADE                                      
                                      
IF OBJECT_ID ('TEMPDB..#EMPRESAS_ESTOQUES')      IS NOT NULL                                       
DROP TABLE #EMPRESAS_ESTOQUES 
                                      
                                      
CREATE TABLE #PRODUTOS_LOTE_VALIDADE ( 
                                      LOTE_VALIDADE      NUMERIC(15)                                      
                                     ,PRODUTO            NUMERIC(15)                                      
                                     ,LOTE               VARCHAR(20)                                      
                                     ,VALIDADE_DIGITACAO VARCHAR(7)
                                     )                                    
                                      
CREATE TABLE #EMPRESAS_ESTOQUES      ( 
                                      EMPRESA_USUARIA    NUMERIC(15)      
                                     ,OBJETO_CONTROLE    NUMERIC(15)
                                     )                                      
                    
/*--------------------------------------*/                                      
/*-- INSERT NAS TABELAS TEMPORÁRIAS   --*/                                      
/*--              GERAL               --*/                                      
/*--------------------------------------*/                                      
                                      
INSERT INTO #PRODUTOS_LOTE_VALIDADE  (
                                      LOTE_VALIDADE                                            
                                     ,PRODUTO                                                  
                                     ,LOTE                                                     
                                     ,VALIDADE_DIGITACAO 
                                     )                                       
                                                 
SELECT LOTE_VALIDADE                 AS LOTE_VALIDADE                                
      ,PRODUTO                       AS PRODUTO                                      
      ,LOTE                          AS LOTE                                         
      ,VALIDADE_DIGITACAO            AS VALIDADE_DIGITACAO                                        
                      
  FROM PRODUTOS_LOTE_VALIDADE A WITH(NOLOCK)                                       
                                    
                                      
INSERT INTO #EMPRESAS_ESTOQUES       (
                                      EMPRESA_USUARIA                                      
                                     ,OBJETO_CONTROLE
                                     )                                      
                                      
SELECT A.EMPRESA_USUARIA             AS EMPRESA_USUARIA                                
      ,A.OBJETO_CONTROLE             AS OBJETO_CONTROLE                                 
                              
  FROM EMPRESAS_ESTOQUES   A WITH(NOLOCK)                                      
 WHERE A.TIPO_ESTOQUE = 2          
                                      
/*--------------------------------------------------------------------*/                                      
/*--GERACAO DA TABELA DE LANCAMENTOS DE LOTE E VALIDADE POR PRODUTO --*/                                      
/*--------------------------------------------------------------------*/                                      
             
 INSERT INTO LOTE_VALIDADE_LANCAMENTOS (
                                        FORMULARIO_ORIGEM                                       
                                       ,TAB_MASTER_ORIGEM                                       
                                       ,REG_MASTER_ORIGEM                                       
                                       ,REGISTRO_CONTROLE                                   
                                       ,REGISTRO_CONTROLE_II                                       
                                       ,DATA_HORA                                      
                                       ,DATA                                       
                                       ,LOTE_VALIDADE                                       
                                       ,PRODUTO                                       
                                       ,CENTRO_ESTOQUE                                      
                                       ,ENTRADA                                       
                                       ,SAIDA                                       
                                       ,TIPO_MOVIMENTO                                       
                                       ,DOCUMENTO
                                       )                                      
                                          
      SELECT @FORMULARIO_ORIGEM        AS FORMULARIO_ORIGEM                                      
            ,@TAB_MASTER_ORIGEM        AS TAB_MASTER_ORIGEM                                      
            ,A.SNGPC                   AS REG_MASTER_ORIGEM                                      
            ,B.VENDA                   AS REGISTRO_CONTROLE                                       
            ,C.SNGPC_PDV               AS REGISTRO_CONTROLE_II                                       
            ,GETDATE()                 AS DATA_HORA                                      
            ,B.MOVIMENTO_SNGPC         AS DATA                                      
            ,D.LOTE_VALIDADE           AS LOTE_VALIDADE                                      
            ,C.PRODUTO                 AS PRODUTO                                      
            ,E.OBJETO_CONTROLE         AS CENTRO_ESTOQUE                                      
            ,0                         AS ENTRADA 
            ,SUM(C.QUANTIDADE)         AS SAIDA                                    
            ,1                         AS TIPO_MOVIMENTO                                      
            ,B.ECF_CUPOM               AS DOCUMENTO  
  
        FROM SNGPC                               A WITH(NOLOCK)                                      
        JOIN SNGPC_RECEITAS                      B WITH(NOLOCK) ON B.SNGPC              = A.SNGPC                                      
                                                               AND B.CONFERIDO          = 'S'                                      
        JOIN SNGPC_PDV                           C WITH(NOLOCK) ON C.SNGPC_RECEITA      = B.SNGPC_RECEITA                                      
   LEFT JOIN #PRODUTOS_LOTE_VALIDADE             D WITH(NOLOCK) ON D.PRODUTO            = C.PRODUTO                                      
                                                               AND D.LOTE               = C.LOTE                     
                                                               AND D.VALIDADE_DIGITACAO = C.VALIDADE_DIGITACAO  
        JOIN #EMPRESAS_ESTOQUES                  E WITH(NOLOCK) ON E.EMPRESA_USUARIA    = A.EMPRESA  
       WHERE A.SNGPC = @SNGPC                                      
                      
    GROUP BY A.SNGPC                             
            ,B.VENDA                                
            ,C.SNGPC_PDV                                                            
            ,B.MOVIMENTO_SNGPC                                                            
            ,D.LOTE_VALIDADE                                  
            ,C.PRODUTO                                                              
            ,E.OBJETO_CONTROLE                                       
            ,B.ECF_CUPOM                                                     
                            
                                                                   
   UNION ALL                                      
                                                                               
                                         
      SELECT @FORMULARIO_ORIGEM        AS FORMULARIO_ORIGEM  
            ,@TAB_MASTER_ORIGEM        AS TAB_MASTER_ORIGEM  
            ,B.SNGPC                   AS REG_MASTER_ORIGEM  
            ,CASE 
                WHEN B.ESTOQUE_RECEBIMENTO IS NOT NULL   
                THEN B.ESTOQUE_RECEBIMENTO                                       
                WHEN B.NF_COMPRA           IS NOT NULL   
                THEN B.NF_COMPRA                                      
                WHEN B.NF_FATURAMENTO      IS NOT NULL  
                THEN B.NF_FATURAMENTO                                      
                WHEN B.NF_COMPRA_DEVOLUCAO IS NOT NULL  
                THEN B.NF_COMPRA_DEVOLUCAO  
                ELSE NULL                      
             END                       AS REGISTRO_CONTROLE  
            ,C.SNGPC_NFE_ITEM          AS REGISTRO_CONTROLE_II  
            ,GETDATE()                 AS DATA_HORA  
            ,B.MOVIMENTO_SNGPC         AS DATA  
            ,D.LOTE_VALIDADE           AS LOTE_VALIDADE  
            ,C.PRODUTO                 AS PRODUTO  
            ,E.OBJETO_CONTROLE         AS CENTRO_ESTOQUE  
            ,SUM(C.QUANTIDADE)         AS ENTRADA  
            ,0                         AS SAIDA  
            ,CASE WHEN F.TIPO_OPERACAO = 1   
                  THEN 2                                       
                  WHEN F.TIPO_OPERACAO = 9 AND B.ESTOQUE_RECEBIMENTO IS NOT NULL  
                  THEN 4                                      
                  WHEN F.TIPO_OPERACAO = 9 AND B.ESTOQUE_RECEBIMENTO IS NULL  
                  THEN 3                                       
                  WHEN F.TIPO_OPERACAO = 3   
                  THEN 1                              
                  WHEN F.TIPO_OPERACAO = 2   
                  THEN 12  
                  WHEN F.TIPO_OPERACAO = 18  
                  THEN 17     
                  WHEN F.TIPO_OPERACAO IN (10,7)   
                  THEN 6                      
                  ELSE NULL                                               
             END                       AS TIPO_MOVIMENTO  
            ,B.NF_NUMERO               AS DOCUMENTO  
        FROM SNGPC                               A WITH(NOLOCK)                                      
        JOIN SNGPC_NFE                           B WITH(NOLOCK) ON B.SNGPC              = A.SNGPC                                      
                                                               AND B.CONFERIDO          = 'S'                                      
        JOIN SNGPC_NFE_ITENS                     C WITH(NOLOCK) ON C.SNGPC_NFE          = B.SNGPC_NFE                             
        JOIN #PRODUTOS_LOTE_VALIDADE             D WITH(NOLOCK) ON D.PRODUTO            = C.PRODUTO                                      
                                                               AND D.LOTE               = C.LOTE                                      
                                                               AND D.VALIDADE_DIGITACAO = C.VALIDADE_DIGITACAO  
        JOIN #EMPRESAS_ESTOQUES                  E WITH(NOLOCK) ON E.EMPRESA_USUARIA    = A.EMPRESA                                      
        JOIN #OPERACOES_FISCAIS                  F WITH(NOLOCK) ON F.OPERACAO_FISCAL    = B.OPERACAO_FISCAL                                      
                                              
       WHERE A.SNGPC = @SNGPC                                      
         AND F.NFE_TIPO_OPERACAO = 0                                      
                                             
    GROUP BY B.SNGPC         
            ,CASE WHEN B.ESTOQUE_RECEBIMENTO IS NOT NULL THEN B.ESTOQUE_RECEBIMENTO                                       
                  WHEN B.NF_COMPRA           IS NOT NULL THEN B.NF_COMPRA                                      
                  WHEN B.NF_FATURAMENTO      IS NOT NULL THEN B.NF_FATURAMENTO                                      
                  WHEN B.NF_COMPRA_DEVOLUCAO IS NOT NULL THEN B.NF_COMPRA_DEVOLUCAO                                      
                  ELSE NULL                                      
              END                                                       
            ,C.SNGPC_NFE_ITEM                                      
            ,B.MOVIMENTO_SNGPC                                      
            ,D.LOTE_VALIDADE         
            ,C.PRODUTO                                      
            ,E.OBJETO_CONTROLE                                      
            ,CASE WHEN F.TIPO_OPERACAO = 1 THEN 2                                       
                  WHEN F.TIPO_OPERACAO = 9 AND B.ESTOQUE_RECEBIMENTO IS NOT NULL THEN 4                                      
                  WHEN F.TIPO_OPERACAO = 9 AND B.ESTOQUE_RECEBIMENTO IS NULL THEN 3             
                  WHEN F.TIPO_OPERACAO = 3 THEN 1                                      
                  WHEN F.TIPO_OPERACAO = 2 THEN 12    
                  WHEN F.TIPO_OPERACAO = 18 THEN 17     
                  WHEN F.TIPO_OPERACAO IN (10,7) THEN 6                                          
                  ELSE NULL                                               
               END                                      
             ,B.NF_NUMERO                                      
                                         
                                         
   UNION ALL      
                                         
                            
      SELECT @FORMULARIO_ORIGEM        AS FORMULARIO_ORIGEM  
            ,@TAB_MASTER_ORIGEM        AS TAB_MASTER_ORIGEM  
            ,B.SNGPC                   AS REG_MASTER_ORIGEM  
            ,CASE WHEN B.ESTOQUE_RECEBIMENTO IS NOT NULL   
                  THEN B.ESTOQUE_RECEBIMENTO   
                  WHEN B.NF_COMPRA           IS NOT NULL  
                  THEN B.NF_COMPRA                       
                  WHEN B.NF_FATURAMENTO      IS NOT NULL  
                  THEN B.NF_FATURAMENTO               
                  WHEN B.NF_COMPRA_DEVOLUCAO IS NOT NULL  
                  THEN B.NF_COMPRA_DEVOLUCAO                                      
                  ELSE NULL     
             END                      AS REGISTRO_CONTROLE  
            ,C.SNGPC_NFE_ITEM         AS REGISTRO_CONTROLE_II  
            ,GETDATE()                AS DATA_HORA  
            ,B.MOVIMENTO_SNGPC        AS DATA  
            ,D.LOTE_VALIDADE          AS LOTE_VALIDADE  
            ,C.PRODUTO                AS PRODUTO  
            ,E.OBJETO_CONTROLE        AS CENTRO_ESTOQUE  
            ,0                        AS ENTRADA  
            ,SUM(C.QUANTIDADE)  AS SAIDA  
            ,CASE WHEN F.TIPO_OPERACAO = 1   
                  THEN 2                                       
                  WHEN F.TIPO_OPERACAO = 9 AND B.ESTOQUE_RECEBIMENTO IS NOT NULL   
                  THEN 4                                      
                  WHEN F.TIPO_OPERACAO = 9 AND B.ESTOQUE_RECEBIMENTO IS NULL  
                  THEN 3                                       
                  WHEN F.TIPO_OPERACAO = 3   
                  THEN 1   
                  WHEN F.TIPO_OPERACAO = 2   
                  THEN 12   
                  WHEN F.TIPO_OPERACAO = 18  
                  THEN 17     
                  WHEN F.TIPO_OPERACAO IN (10,7)  
                  THEN 6            
                  ELSE NULL                      
             END                       AS TIPO_MOVIMENTO  
            ,B.NF_NUMERO               
        FROM SNGPC                      A WITH(NOLOCK)                                      
        JOIN SNGPC_NFE                  B WITH(NOLOCK) ON B.SNGPC              = A.SNGPC  
                                                      AND B.CONFERIDO          = 'S'  
        JOIN SNGPC_NFE_ITENS            C WITH(NOLOCK) ON C.SNGPC_NFE          = B.SNGPC_NFE  
        JOIN #PRODUTOS_LOTE_VALIDADE    D WITH(NOLOCK) ON D.PRODUTO            = C.PRODUTO  
                                                      AND D.LOTE               = C.LOTE  
                                                      AND D.VALIDADE_DIGITACAO = C.VALIDADE_DIGITACAO  
        JOIN #EMPRESAS_ESTOQUES         E WITH(NOLOCK) ON E.EMPRESA_USUARIA    = A.EMPRESA  
        JOIN #OPERACOES_FISCAIS         F WITH(NOLOCK) ON F.OPERACAO_FISCAL    = B.OPERACAO_FISCAL  
       WHERE A.SNGPC = @SNGPC  
         AND F.NFE_TIPO_OPERACAO = 1                                      
                
   GROUP BY B.SNGPC                                      
           ,CASE WHEN B.ESTOQUE_RECEBIMENTO IS NOT NULL THEN B.ESTOQUE_RECEBIMENTO                                       
                 WHEN B.NF_COMPRA           IS NOT NULL THEN B.NF_COMPRA                           
                 WHEN B.NF_FATURAMENTO      IS NOT NULL THEN B.NF_FATURAMENTO                                      
                 WHEN B.NF_COMPRA_DEVOLUCAO IS NOT NULL THEN B.NF_COMPRA_DEVOLUCAO                                      
                 ELSE NULL                                      
             END                                                       
           ,C.SNGPC_NFE_ITEM                                      
           ,B.MOVIMENTO_SNGPC                                      
           ,D.LOTE_VALIDADE                                      
           ,C.PRODUTO                                      
           ,E.OBJETO_CONTROLE                                      
           ,CASE WHEN F.TIPO_OPERACAO = 1 THEN 2                          
                 WHEN F.TIPO_OPERACAO = 9 AND B.ESTOQUE_RECEBIMENTO IS NOT NULL THEN 4                                      
                 WHEN F.TIPO_OPERACAO = 9 AND B.ESTOQUE_RECEBIMENTO IS NULL THEN 3                                       
                 WHEN F.TIPO_OPERACAO = 3 THEN 1                                      
                 WHEN F.TIPO_OPERACAO = 2 THEN 12     
                 WHEN F.TIPO_OPERACAO = 18 THEN 17     
                 WHEN F.TIPO_OPERACAO IN (10,7) THEN 6                                         
                 ELSE NULL                                      
             END                                       
           ,B.NF_NUMERO                                      
                                         
   ORDER BY LOTE_VALIDADE                                      
                
                                      
/*--------------------------------------------------------------------------------------*/                                      
/*-- VERIFICAR SE FORAM INSERIDAS TODAS AS MOVIMENTAÇÕES NA LOTE_VALIDADE_LANCAMENTOS --*/                                      
/*--------------------------------------------------------------------------------------*/                                    
DECLARE @MENSAGEM VARCHAR(100)                                     
                                      
IF EXISTS (--SELECT A.SNGPC                                      
           --      ,A.TAB_MASTER_ORIGEM                                      
           --      ,A.DATA_INICIAL                 
           --      ,A.DATA_FINAL                                      
           --      ,A.EMPRESA                                      
           --      ,B.MOVIMENTO                                      
           --      ,B.NF_COMPRA                                      
           --      ,B.CONFERIDO                                      
           --      ,C.PRODUTO                                      
           --      ,C.LOTE                                      
           --      ,C.VALIDADE_DIGITACAO                                      
           --      ,C.QUANTIDADE                                      
           --      ,D.LOTE_VALIDADE                    
             SELECT TOP 1 1                                      
               FROM SNGPC                       A WITH(NOLOCK)                                      
               JOIN SNGPC_NFE                   B WITH(NOLOCK) ON B.SNGPC              = A.SNGPC                                      
                                                              AND B.CONFERIDO          = 'S'                                    
               JOIN SNGPC_NFE_ITENS             C WITH(NOLOCK) ON C.SNGPC_NFE          = B.SNGPC_NFE                                      
               JOIN PRODUTOS_LOTE_VALIDADE      D WITH(NOLOCK) ON D.PRODUTO            = C.PRODUTO                  
                                                              AND D.LOTE               = C.LOTE                                      
                                                              AND D.VALIDADE_DIGITACAO = C.VALIDADE_DIGITACAO     
          LEFT JOIN LOTE_VALIDADE_LANCAMENTOS   E WITH(NOLOCK) ON E.FORMULARIO_ORIGEM  = A.FORMULARIO_ORIGEM   
                                                              AND E.TAB_MASTER_ORIGEM  = A.TAB_MASTER_ORIGEM   
                                                              AND E.REG_MASTER_ORIGEM  = A.SNGPC  
                                                              AND E.LOTE_VALIDADE      = D.LOTE_VALIDADE  
              WHERE E.REGISTRO IS NULL                                      
                AND A.SNGPC = @SNGPC            
                
    UNION ALL            
                
           --SELECT A.SNGPC                                      
           --      ,A.TAB_MASTER_ORIGEM                                      
           --      ,A.DATA_INICIAL                                      
           --      ,A.DATA_FINAL                                      
           --      ,A.EMPRESA             
           --      ,B.MOVIMENTO                                      
           --      ,B.VENDA                                    
           --      ,B.CONFERIDO                                      
           --      ,C.PRODUTO                                      
           --      ,C.LOTE                                      
           --      ,C.VALIDADE_DIGITACAO                                      
           --      ,C.QUANTIDADE                                      
           --      ,D.LOTE_VALIDADE                                      
             SELECT TOP 1 1                                      
               FROM SNGPC                       A WITH(NOLOCK)                                      
               JOIN SNGPC_RECEITAS              B WITH(NOLOCK) ON B.SNGPC              = A.SNGPC                  
                                                              AND B.CONFERIDO          = 'S'                                   
               JOIN SNGPC_PDV                   C WITH(NOLOCK) ON C.SNGPC_RECEITA      = B.SNGPC_RECEITA            
               JOIN PRODUTOS_LOTE_VALIDADE      D WITH(NOLOCK) ON D.PRODUTO            = C.PRODUTO                                      
                                                              AND D.LOTE               = C.LOTE                                      
                                                              AND D.VALIDADE_DIGITACAO = C.VALIDADE_DIGITACAO     
          LEFT JOIN LOTE_VALIDADE_LANCAMENTOS   E WITH(NOLOCK) ON E.FORMULARIO_ORIGEM  = A.FORMULARIO_ORIGEM  
                                                              AND E.TAB_MASTER_ORIGEM  = A.TAB_MASTER_ORIGEM   
                                                              AND E.REG_MASTER_ORIGEM  = A.SNGPC  
                                                              AND E.LOTE_VALIDADE      = D.LOTE_VALIDADE  
              WHERE E.REGISTRO IS NULL                                      
                AND A.SNGPC = @SNGPC            
    )                                      
                              
BEGIN                                       
                                      
SELECT @MENSAGEM = 'Erro na geração das movimentações de lote. Procure o suporte técnico'                                      
                                      
RAISERROR(@MENSAGEM,15,-1)                                  
RETURN                        
                                      
END -- IF EXISTS                                      
                                      
                                      
/*-------------------------------------------------------*/                                      
/*-- UPDATE LINHA DE PRODUTOS CRIADAS DIRETO NA DETAIL --*/                                   
/*-------------------------------------------------------*/                                      
IF OBJECT_ID('TEMPDB..#UPD_SNGPC_PDV') IS NOT NULL                       
     DROP TABLE #UPD_SNGPC_PDV                                      
                                      
IF OBJECT_ID('TEMPDB..#UPD_SNGPC_NFE') IS NOT NULL        
     DROP TABLE #UPD_SNGPC_NFE                                      
                                      
/*---------*/                                     
/*-- PDV --*/                                 
/*---------*/                                     
                                          
SELECT B.SNGPC_PDV                    AS SNGPC_PDV                                    
      ,A.MOVIMENTO                    AS MOVIMENTO                                     
      ,A.LOJA                         AS LOJA                                    
      ,A.VENDA                        AS VENDA                                     
      ,A.CAIXA                        AS CAIXA                                     
      ,A.PREVENDA                     AS PREVENDA                                    
      ,A.NUMERO_RECEITA               AS NUMERO_RECEITA          
      ,A.DATA_RECEITA                 AS DATA_RECEITA                                       
                                      
  INTO #UPD_SNGPC_PDV                                      
  FROM SNGPC_RECEITAS  A WITH(NOLOCK)                           
  JOIN SNGPC_PDV       B WITH(NOLOCK) ON B.SNGPC_RECEITA = A.SNGPC_RECEITA                                      
 WHERE 1=1                                      
   AND A.SNGPC          = @SNGPC                                      
   AND B.MOVIMENTO      IS NULL                                      
    OR B.LOJA           IS NULL                           
    OR B.VENDA          IS NULL                                      
    OR B.CAIXA          IS NULL                                      
    OR B.PREVENDA       IS NULL                                      
    OR B.NUMERO_RECEITA IS NULL                                      
    OR B.DATA_RECEITA   IS NULL                                              
UPDATE B     
   SET B.MOVIMENTO       = A.MOVIMENTO                                       
     ,B.LOJA            = A.LOJA                                      
      ,B.VENDA           = A.VENDA                                       
      ,B.CAIXA           = A.CAIXA                                       
      ,B.PREVENDA        = A.PREVENDA                                      
      ,B.NUMERO_RECEITA  = A.NUMERO_RECEITA                                      
      ,B.DATA_RECEITA    = A.DATA_RECEITA                                       
                                      
  FROM #UPD_SNGPC_PDV  A WITH(NOLOCK)                                      
  JOIN SNGPC_PDV       B WITH(NOLOCK) ON B.SNGPC_PDV = A.SNGPC_PDV                                      
 
 /*
----------                                      
--NFE                                       
----------                  
-- Trecho comentado por Artur Neto em 24/08/2022. A atualização dos campos será no Insert                                      
SELECT B.SNGPC_NFE_ITEM                                      
      ,A.CHAVE_NFE                                      
      ,A.OPERACAO_TIPO                                      
                                      
  INTO #UPD_SNGPC_NFE                                      
  FROM SNGPC_NFE         A WITH(NOLOCK)                                      
  JOIN SNGPC_NFE_ITENS   B WITH(NOLOCK) ON A.SNGPC_NFE   = B.SNGPC_NFE                                      
                                      
 WHERE 1=1                          
   AND A.SNGPC = @SNGPC                                      
   AND B.CHAVE_NFE     IS NULL                          
    OR B.OPERACAO_TIPO IS NULL                                        
                                      
UPDATE B                                      
   SET B.CHAVE_NFE     = A.CHAVE_NFE                                      
      ,B.OPERACAO_TIPO = A.OPERACAO_TIPO                                      
                                      
  FROM #UPD_SNGPC_NFE    A WITH(NOLOCK)                                      
  JOIN SNGPC_NFE_ITENS   B WITH(NOLOCK) ON A.SNGPC_NFE_ITEM  = B.SNGPC_NFE_ITEM         
  
  */
                    
END -- GRAVACAO FINAL = 'S'                      
                                   
END -- INVENTARIO = 'N'                    
             
-----------------------------------------                                      
--            INVENTÁRIO                                      
-----------------------------------------                                      
IF (@INVENTARIO = 'S' AND @FECHAR_MOVIMENTO = 'S' AND @GRAVACAO_FINAL = 'S')                                      
BEGIN                                      
                                      
 EXEC USP_SNGPC_INVENTARIO @SNGPC, @FORMULARIO_ORIGEM, @TAB_MASTER_ORIGEM                                      
                                      
END -- INVENTARIO = 'S'                                                                         
             
END -- PROC   
