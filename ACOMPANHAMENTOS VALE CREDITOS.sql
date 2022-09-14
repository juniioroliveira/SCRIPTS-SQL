
/*============================================================================================================== /    
/  VERSÃO        DATA ALTERAÇÃO      ALTERADO POR           DESCRIÇÃO                                            /     
/ ============================================================================================================== /     
/   0001         DATA 24/08/2022     JUNIOR OLIVEIRA        CONSULTA TRAVANDO E NÃO RETORNANDO STATUS PENDENTE   /    
/ ==============================================================================================================*/


/*------------------------- /
/ -- DECLARAÇÃO VARIAVEL -- /
/ -------------------------*/

-- DECLARE @MOVIMENTO_INI DATETIME    = '06/08/2022'
-- DECLARE @MOVIMENTO_FIM DATETIME    = '06/08/2022'
-- DECLARE @EMPRESA_CTB   NUMERIC(15) = NULL
-- DECLARE @EMPRESA_INI   NUMERIC(15) = 1 --NULL                 
-- DECLARE @EMPRESA_FIM   NUMERIC(15) = 107 --NULL                  
                                                   
DECLARE @MOVIMENTO_INI DATETIME    = :MOVIMENTO_INI
DECLARE @MOVIMENTO_FIM DATETIME    = :MOVIMENTO_FIM
DECLARE @EMPRESA_CTB   NUMERIC(15) = :EMPRESA_CTB
DECLARE @EMPRESA_INI   NUMERIC(15) = :EMPRESA_INI
DECLARE @EMPRESA_FIM   NUMERIC(15) = :EMPRESA_FIM

/*---------------- /
/ -- RESULTADOS -- /
/ ----------------*/

SELECT 
     A.CREDITO_CLIENTE                               AS CREDITO_CLIENTE               
    ,A.NUMERO_CREDITO                                AS NUMERO_CREDITO                
    ,A.TIPO_CREDITO                                  AS TIPO_CREDITO                  
    ,A.DESCRICAO                                     AS DESCRICAO                     
    ,C.LOJA_COMPRA                                   AS COMPRA_LOJA                   
    ,C.ECF_CAIXA                                     AS COMPRA_ECF_CAIXA              
    ,C.CUPOM                                         AS COMPRA_CUPOM                  
    ,C.DATA_COMPRA                                   AS COMPRA_DATA                   
    ,C.NF_NUMERO                                     AS NF_NUMERO_DEVOLUCAO           
    ,C.DEVOLUCAO_PRODUTO                             AS DEVOLUCAO_PRODUTO             
    ,C.EMPRESA                                       AS EMPRESA_DEVOLUCAO             
    ,C.MOVIMENTO                                     AS MOVIMENTO_DEVOLUCAO           
    ,A.DATA_HORA                                     AS DATA_HORA                     
    ,A.ENTIDADE                                      AS ENTIDADE                      
    ,E.NOME                                          AS ENTIDADE_NOME                 
    ,A.VALOR                                         AS VALOR_VALE_CREDITO            
    ,B.DATA_HORA                                     AS USADO_DATA_HORA               
    ,B.VALOR                                         AS USADO_VALOR                   
    ,ISNULL(B.ENCERRAMENTO_AUTOMATICO,'N')           AS USADO_ENCERRAMENTO_AUTOMATICO 
    ,G.LOJA                                          AS USADO_LOJA                    
    ,G.CAIXA                                         AS USADO_CAIXA                   
    ,G.ABERTURA                                      AS USADO_ABERTURA                
    ,G.OPERADOR                                      AS USADO_OPERADOR                
    ,H.NOME                                          AS USADO_OPERADOR_NOME           
    ,G.MOVIMENTO                                     AS USADO_MOVIMENTO               
    ,G.VENDA                                         AS USADO_VENDA                   
    ,G.ECF_CUPOM                                     AS USADO_ECF_CUPOM               
    ,CASE WHEN CREDITO_CLIENTE_USADO IS NOT NULL 
         THEN 'Utilizado'
         ELSE 'Pendente'
     END                                             AS STATUS                        
    ,A.FORMULARIO_ORIGEM                             AS FORMULARIO_ORIGEM             
    ,A.TAB_MASTER_ORIGEM                             AS TAB_MASTER_ORIGEM             
    ,A.REG_MASTER_ORIGEM                             AS REG_MASTER_ORIGEM
  FROM      CREDITOS_CLIENTES                       A WITH(NOLOCK)            
  LEFT          
  JOIN CREDITOS_CLIENTES_USADOS                     B WITH(NOLOCK)ON B.CREDITO_CLIENTE   = A.CREDITO_CLIENTE
  LEFT          
  JOIN DEV_PRODUTOS_CAIXAS                          C WITH(NOLOCK)ON C.FORMULARIO_ORIGEM = A.FORMULARIO_ORIGEM
                                                                 AND C.TAB_MASTER_ORIGEM = A.TAB_MASTER_ORIGEM
                                                                 AND C.DEVOLUCAO_PRODUTO = A.REG_MASTER_ORIGEM
  JOIN ENTIDADES                                    E WITH(NOLOCK)ON E.ENTIDADE          = A.ENTIDADE

  LEFT          
  JOIN PDV_FINALIZADORAS_STATUS                     G WITH(NOLOCK)ON 1=1
                                                              AND G.MOVIMENTO	        BETWEEN @MOVIMENTO_INI  AND @MOVIMENTO_FIM
                                                              AND G.LOJA                BETWEEN @EMPRESA_INI    AND @EMPRESA_FIM
                                                              AND G.VALE_CREDITO        = A.CREDITO_CLIENTE
                                                              AND G.STATUS              = 'A'
  JOIN DBO.FN_EMPRESAS_USUARIAS ( @EMPRESA_INI , -- FILTRO PARA EMPRESA CONTÁBIL E EMPRESAS USUÁRIAS
                                  @EMPRESA_FIM , 
                                  @EMPRESA_CTB )    X             ON X.EMPRESA_USUARIA  = C.EMPRESA
  LEFT
  JOIN OPERADORES                                   J WITH(NOLOCK)ON J.OPERADOR         = G.OPERADOR
  LEFT
  JOIN VENDEDORES                                   H WITH(NOLOCK)ON J.VENDEDOR         = H.VENDEDOR


 WHERE C.MOVIMENTO BETWEEN @MOVIMENTO_INI AND @MOVIMENTO_FIM
