

DECLARE @DATA_INICIAL            DATE  = '01/08/1990' --:DATA_INICIAL
DECLARE @DATA_FINAL              DATE  = GETDATE()--:DATA_FINAL
DECLARE @EMPRESA          NUMERIC(15)  = null --:EMPRESA

IF(LEN(@EMPRESA) IS NOT NULL)
    SET @EMPRESA = CASE 
                   WHEN ISNUMERIC(@EMPRESA)=1 
                   THEN @EMPRESA 
                   ELSE NULL 
                    END

SELECT
     A.SUPRIMENTO                       AS SUPRIMENTO                                                 
    ,CONVERT(DATE, A.MOVIMENTO)         AS MOVIMENTO                      
    ,A.LOJA                             AS LOJA   
    ,B.NOME_FANTASIA                    AS NOME_FANTASIA               
    ,A.CAIXA                            AS CAIXA       
    ,A.ABERTURA                         AS ABERTURA     
    ,A.RESP_ENTREGA                     AS RESP_ENTREGA           
    ,C.NOME                             AS NOME_RESP_ENTREGA
    ,A.RESP_CAIXA                       AS RESP_CAIXA           
    ,D.NOME                             AS NOME_RESP_CAIXA           
    ,A.ECF_CUPOM                        AS ECF_CUPOM            
    ,A.VALOR                            AS VALOR        
    ,A.VALOR_CHEQUE                     AS VALOR_CHEQUE           
    ,A.VALOR_CHEQUE_PREDATADO           AS VALOR_CHEQUE_PREDATADO                       
    ,A.VALOR_CARTAO_TEF                 AS VALOR_CARTAO_TEF               
    ,A.VALOR_CARTAO_POS                 AS VALOR_CARTAO_POS               
  FROM PDV_SUPRIMENTOS              A WITH(NOLOCK)
  JOIN EMPRESAS_USUARIAS            B WITH(NOLOCK)ON B.EMPRESA_USUARIA  = A.LOJA
  JOIN VENDEDORES                   C WITH(NOLOCK)ON C.VENDEDOR         = A.RESP_ENTREGA
  JOIN VENDEDORES                   D WITH(NOLOCK)ON D.VENDEDOR         = A.RESP_CAIXA

WHERE CONVERT(DATE, A.MOVIMENTO) >= @DATA_INICIAL
  AND CONVERT(DATE, A.MOVIMENTO) <= @DATA_FINAL
  AND (A.LOJA = @EMPRESA OR @EMPRESA IS NULL) 

ORDER
   BY  A.LOJA
      ,A.MOVIMENTO
  