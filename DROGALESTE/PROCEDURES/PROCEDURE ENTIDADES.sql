
--CREATE PROCEDURE USP_CLIENTES_OFFLINE ( @BUSCA VARCHAR(255)  , @TIPO VARCHAR(1) = '1' , @CONVENIO VARCHAR(255) = '' , @EMPRESA NUMERIC = 0 
--)  AS                                          
	BEGIN                                                           
    
	 DECLARE @BUSCA             VARCHAR(255) = '37420389829'    
	 DECLARE @TIPO              VARCHAR(1)   = '1'           
	 DECLARE @CONVENIO          VARCHAR(255) = ''            
	 DECLARE @EMPRESA           NUMERIC      = 0             
    
	 DECLARE @INSCRICAO_FEDERAL VARCHAR(20)                    
	 DECLARE @SO_NUMERO         VARCHAR(20)                    
	 DECLARE @LEN_ENTIDADE      INT                    
                     
    declare @inicio             datetime = getdate()                    
    declare @fim                datetime                    
    DECLARE @QTDE_TMP_ENTIDADES NUMERIC(15)    
    DECLARE @QTDE_TMP_ENTIDADES_LIMITE INT = 20    
    DECLARE @ID_LOG NUMERIC(15)    
    
	   /*SET NOCOUNT ON */                   
	   /*insert into log_consultas_clientes (busca, inicio, fim, TIPO, QTDE_TMP_ENTIDADES,  client_net_address) VALUES(@BUSCA, @inicio, @fim, @TIPO, @QTDE_TMP_ENTIDADES, try_convert(varchar(155),CONNECTIONPROPERTY('client_net_address')) ) */         

	   /*SET @ID_LOG = SCOPE_IDENTITY()   */ 
	   /*SET NOCOUNT OFF                  */  
    
                
	 SET @BUSCA = REPLACE(@BUSCA, '%', '')                    
	 SET @BUSCA = REPLACE(@BUSCA, 'INSCRICAO=', '')                 
	 SET @BUSCA = REPLACE(@BUSCA, 'ENTIDADE=', '')                 
                   
	 /* ATRIBUI ENTIDADE CONSUMIDOR FINAL*/      
	   IF @BUSCA = '0' /*SET @BUSCA = '944.195.163-30' --cpf do consumidor final*/                                
	       IF @TIPO = ''  SET @TIPO = 1                                    
	           IF @TIPO = '0' SET @TIPO = 1                                       
     
               
	  IF @BUSCA = '0'                    
                    
	 BEGIN                     
                    
	 SELECT 
       1575997.00                          AS CLIENTE                    
		,5                                   AS TIPO   
		,'CLIENTE CONSUMIDOR'                AS NOME                    
		,'1575997'                           AS CODIGO_CONVENIO                    
		,''                                  AS DESCRICAO                    
		,CAST(NULL AS VARCHAR)               AS CONVENIO_CARTAO                    
		,'1575997'                           AS CHAVE_PRINCIPAL                    
		,'1575997'                           AS CHAVE_ALTERNATIVA                    
		,''                                  AS MENSAGEM_1                    
		,''                                  AS MENSAGEM_2                    
		,'N'                                 AS CONVENIO                    
		,'N'                                 AS BOLETO                    
		,'N'                                 AS CHEQUE                    
		,'N'                                 AS CHEQUE_PRE                    
		,'S'                                 AS CARTAO_DEBITO                    
		,'S'                                 AS CARTAO_CREDITO                    
		,'N'                                 AS FIADO                    
		,'*'                                 AS RECEITA                    
		,'S'                                 AS DESCONTO_MAXIMO                    
		,0.00                                AS DESCONTO_VENDA                    
		,0.00                                AS PREDATADO_PARCELAS                    
		,0.00                                AS BOLETO_PARCELAS                
		,CAST(NULL AS VARCHAR)               AS TIPO_TELEFONE     
		,''                                  AS TELEFONE                    
		,'86870-000'                         AS CEP                    
		,'ESTOQUE_LANCAMENTOS'               AS TIPO_ENDERECO                    
		,'RESIDENCIAL IVAIPORA'              AS ENDERECO                    
		,1000.00                             AS NUMERO                    
		,'CASA'                              AS COMPLEMENTO                    
		,'IVAIPORA'                          AS BAIRRO                    
		,'IVAIPORA'                          AS CIDADE                    
		,'PR'                                AS ESTADO                    
		,''                                  AS COBR_CEP      
		,''                                  AS COBR_TIPO_ENDERECO      
		,''                                  AS COBR_ENDERECO                    
		,0.00                                AS COBR_NUMERO                    
		,''                                  AS COBR_COMPLEMENTO                    
		,''                                  AS COBR_BAIRRO                    
		,''                                  AS COBR_CIDADE                    
		,''                                  AS COBR_ESTADO                    
		,''                                  AS ENTR_CEP                    
		,''                                  AS ENTR_TIPO_ENDERECO                    
		,''                                  AS ENTR_ENDERECO                    
		,0.00                                AS ENTR_NUMERO     
		,''                                  AS ENTR_COMPLEMENTO                    
		,''                                  AS ENTR_BAIRRO                    
		,''                                  AS ENTR_CIDADE                    
		,''                                  AS ENTR_ESTADO                    
		,99.00                               AS PARCELAS                    
		,0.00                                AS VALOR_MINIMO                    
		,1.00                                AS STATUS                    
		,0.00                                AS LIMITE_MENSAL                    
		,'944.195.163-30'                    AS INSCRICAO_FEDERAL                    
		,''                                  AS CARTAO_FIDELIDADE                    
		,0.00                                AS CODIGO_DEPARA                    
	   ,0.00                                AS CARGO_CONVENIO_CARTAO                    
		,''                                  AS CEP_CONVENIO                    
		,0.00                                AS TIPO_CARTAO                    
		,''                                  AS OBSERVACAO                    
	   ,'N'                                 AS FIDELIZE                    
		,'N'                                 AS SOLICITAR_CRM_CONVENIO 
		,0.00                                AS DEPENDENTE                    
		,'T'                                 AS TIPO_CONVENIADO                    
		,'T'                                 AS SOLICITAR_BIOMETRIA                    
		,'944.195.163-30'                    AS INSCRICAO_FEDERAL_CLIENTE                    
		,'N'                                 AS RECEITA_AMBOS                    
		,'N'                                 AS ENVIAR_CUPOM                    
		,'N'                                 AS TIPO_COMPRA_CONVENIO                    
		,'N'                                 AS TIPO_COMPRA_CONVENIO_CODIGO                    
		,'N'                                 AS CARTAO_LINX             
		,'N'                                 AS CONVENIO_PROMOCIONAL    
                    
	 RETURN                    
                    
	 END                     
                   
	 SET @SO_NUMERO = REPLACE(REPLACE(REPLACE(@BUSCA,'.',''),'/',''),'-','')       
                    
	 /* CRIA TEMP */      
	 IF OBJECT_ID('TEMPDB..#TMP_ENTIDADES') IS NOT NULL DROP TABLE #TMP_ENTIDADES                         
	 CREATE TABLE #TMP_ENTIDADES (
                                 ENTIDADE          NUMERIC(15) NOT NULL  
                                ,CONVENIO_CARTAO   NUMERIC(15)     NULL                    
			                       )                    
                    
	 /* BUSCA POR CHAVE NUMERICA */      
	 IF ISNUMERIC(@SO_NUMERO)= 1                   
             
       
	 BEGIN                     
                
	 /* MASCARA INCRICAO FEDERAL */      
	 SELECT @INSCRICAO_FEDERAL = CASE WHEN LEN(@SO_NUMERO) = 11                       
			                            THEN DBO.FN_MASCARA_CPF  ( CAST( DBO.NUMERICO_NULL (@SO_NUMERO ) AS NUMERIC ) )                    
			                            WHEN LEN(@SO_NUMERO) = 14                       
			                            THEN DBO.FN_MASCARA_CNPJ ( CAST( DBO.NUMERICO_NULL (@SO_NUMERO ) AS NUMERIC ) )                    
			                       ELSE NULL                    
			                       END                     
     
               
	 /* PEGA O LEN DO CODIGO DA ENTIDADE */      
	 SET @LEN_ENTIDADE = (SELECT LEN(MAX(ENTIDADE)) FROM ENTIDADES WITH(NOLOCK))                    
                    
	 /* REALIZA O INSERT NA TEMP */      
	 INSERT INTO #TMP_ENTIDADES (                   
			                       ENTIDADE         
		                         ,CONVENIO_CARTAO                    
			                      )            

	 SELECT 
           A.ENTIDADE                  AS ENTIDADE                    
	       ,NULL                        AS CONVENIO_CARTAO                    
	   FROM ENTIDADES                        A WITH(NOLOCK)   
	  WHERE A.INSCRICAO_FEDERAL = @INSCRICAO_FEDERAL                    
                    
	 UNION                    
                    
	 SELECT 
           A.ENTIDADE                  AS ENTIDADE                    
	       ,A.CONVENIO_CARTAO           AS CONVENIO_CARTAO          
	   FROM ENTIDADES_CONVENIOS_CARTOES      A WITH(NOLOCK)            
	  WHERE A.INSCRICAO_FEDERAL = @INSCRICAO_FEDERAL                    
                    
	 UNION 
                    
	 SELECT 
          A.ENTIDADE                   AS ENTIDADE                  
	      ,NULL                         AS CONVENIO_CARTAO                    
	   FROM ENTIDADES                        A WITH(NOLOCK)                    
	  WHERE A.ENTIDADE = @SO_NUMERO                    
		 AND @INSCRICAO_FEDERAL IS NULL                    
		 AND LEN(@SO_NUMERO) <= @LEN_ENTIDADE                
                    
	 UNION                     
                    
	 SELECT 
            A.ENTIDADE                 AS ENTIDADE                    
	        ,A.CONVENIO_CARTAO          AS CONVENIO_CARTAO                    
	   FROM ENTIDADES_CONVENIOS_CARTOES      A WITH(NOLOCK)                    
	  WHERE A.CONVENIO_CARTAO = @SO_NUMERO               
		 AND @INSCRICAO_FEDERAL IS NULL                
                    
	  UNION  
                    
	 SELECT 
            A.ENTIDADE                 AS ENTIDADE                    
	        ,A.CONVENIO_CARTAO          AS CONVENIO_CARTAO                    
	   FROM ENTIDADES_CONVENIOS_CARTOES       A WITH(NOLOCK)                    
	  WHERE A.CHAVE_PRINCIPAL = DBO.ZEROS(@SO_NUMERO,11)                
                    
	 UNION                     
                    
	 SELECT 
             A.ENTIDADE                AS ENTIDADE                    
	         ,A.CONVENIO_CARTAO         AS CONVENIO_CARTAO                    
	   FROM ENTIDADES_CONVENIOS_CARTOES       A WITH(NOLOCK)                    
	  WHERE A.INSCRICAO_FEDERAL = @SO_NUMERO                
                    
	 UNION                     
                    
	 SELECT 
             A.ENTIDADE                AS ENTIDADE                    
	         ,A.CONVENIO_CARTAO         AS CONVENIO_CARTAO 
	   FROM ENTIDADES_CONVENIOS_CARTOES       A WITH(NOLOCK)                    
	  WHERE A.CHAVE_PRINCIPAL = @SO_NUMERO                
                    
	 UNION                     
           
	 SELECT 
             A.ENTIDADE                AS ENTIDADE 
	         ,A.CONVENIO_CARTAO         AS CONVENIO_CARTAO                    
	   FROM ENTIDADES_CONVENIOS_CARTOES       A WITH(NOLOCK)                    
	  WHERE A.CHAVE_PRINCIPAL = @INSCRICAO_FEDERAL                
     
		SET @QTDE_TMP_ENTIDADES = @@ROWCOUNT  
    
	  IF LEN(@SO_NUMERO) <= 9    
	  BEGIN 

	   INSERT INTO #TMP_ENTIDADES (                    
		                             ENTIDADE                    
		                            ,CONVENIO_CARTAO                    
			                        )  

	   SELECT 
          A.ENTIDADE                AS ENTIDADE                    
	      ,NULL                      AS CONVENIO_CARTAO                    
	     FROM TELEFONES          A WITH(NOLOCK)                    
	    WHERE A.NUMERO           = @SO_NUMERO                    
	      AND @INSCRICAO_FEDERAL IS NULL        
    
		 SET @QTDE_TMP_ENTIDADES = @QTDE_TMP_ENTIDADES + @@ROWCOUNT                           
    
	  END               
          
	 END                    
	 ELSE                    
	 BEGIN                     

      
	 DECLARE @MENSAGEM VARCHAR(200)                                                     
    
	 END                     
                    
	   SELECT DISTINCT       
		      A.ENTIDADE                                          AS CLIENTE ,                                                                 
		      CASE 
                WHEN B.ENTIDADE IS NULL                                                                    
                THEN 5 
            ELSE 3                             
		      END                                                 AS TIPO ,                                    
		A.NOME                                                    AS NOME ,                 
		CAST (A.ENTIDADE AS VARCHAR(15))                          AS CODIGO_CONVENIO ,       
		CASE 
          WHEN B.ENTIDADE IS NULL                                                                            
		    THEN NULL 
      ELSE CAST(T.DESCRICAO AS VARCHAR(255))      
		END                                                       AS DESCRICAO ,                                                                  
		CAST(NULL AS VARCHAR(15))                                 AS CONVENIO_CARTAO ,  
		CAST(A.ENTIDADE AS VARCHAR(15))                           AS CHAVE_PRINCIPAL ,                                                                 
		CAST(A.ENTIDADE AS VARCHAR(15))                           AS CHAVE_ALTERNATIVA ,                                  
		CAST('' AS VARCHAR(255))                                  AS MENSAGEM_1 ,                                                                
		CAST('' AS VARCHAR(255))                                  AS MENSAGEM_2 ,                                                                  
		'N'                                                       AS CONVENIO ,                                                                 
		ISNULL(B.BOLETO, 'N')                                     AS BOLETO ,                
		ISNULL(B.PREDATADO , 'N')                                 AS CHEQUE ,  
		ISNULL(B.PREDATADO , 'N')                                 AS CHEQUE_PRE ,                                                      
		'S'                                                       AS CARTAO_DEBITO ,                                                                 
		'S'                                                       AS CARTAO_CREDITO ,                                                                  
		ISNULL(B.FIADO, 'N')                                      AS FIADO ,                                                
		'*'                                                       AS RECEITA ,          
		'S'                                                       AS DESCONTO_MAXIMO ,                                                                 
		0.00                                                      AS DESCONTO_VENDA ,                                                                  
		ISNULL(B.PREDATADO_PARCELAS, 0)                           AS PREDATADO_PARCELAS ,                                                      
		ISNULL(B.BOLETO_PARCELAS, 0)                              AS BOLETO_PARCELAS ,      
		D.DESCRICAO                                               AS TIPO_TELEFONE ,                                                                 
		LTRIM(RTRIM(STR(C.DDD))) + LTRIM(RTRIM(STR(C.NUMERO)))    AS TELEFONE ,                                                           
		E.CEP                                                     AS CEP ,     
		E.TIPO_ENDERECO                                           AS TIPO_ENDERECO ,  
		E.ENDERECO                                                AS ENDERECO ,                                                                 
		E.NUMERO                                                  AS NUMERO ,                        
		E.COMPLEMENTO                                             AS COMPLEMENTO ,                   
		E.BAIRRO                                                  AS BAIRRO ,                                                                 
		E.CIDADE                                                  AS CIDADE ,    
		E.ESTADO                                                  AS ESTADO ,                                                    
		F.CEP                                                     AS COBR_CEP ,                                                              
		F.TIPO_ENDERECO                                           AS COBR_TIPO_ENDERECO ,   
		F.ENDERECO                                                AS COBR_ENDERECO ,                                                                 
		F.NUMERO                                                  AS COBR_NUMERO ,       
		F.COMPLEMENTO                                             AS COBR_COMPLEMENTO ,                   
		F.BAIRRO                                                  AS COBR_BAIRRO ,      
		F.CIDADE                                                  AS COBR_CIDADE ,                                                                
		F.ESTADO                                                  AS COBR_ESTADO ,                                                                
		G.CEP                                                     AS ENTR_CEP ,                                                                 
		G.TIPO_ENDERECO                                           AS ENTR_TIPO_ENDERECO ,                                                                 
		G.ENDERECO                                                AS ENTR_ENDERECO ,                          
		G.NUMERO                                                  AS ENTR_NUMERO ,                                               
		G.COMPLEMENTO                                             AS ENTR_COMPLEMENTO ,   
		G.BAIRRO                                                  AS ENTR_BAIRRO ,                       
		G.CIDADE                                                  AS ENTR_CIDADE ,     
		G.ESTADO                                                  AS ENTR_ESTADO ,                                              
		99.00                                                     AS PARCELAS,                                              
		0.00                                                      AS VALOR_MINIMO ,   
		X.ESTADO_CARTAO                                           AS STATUS,                       
		0.00                                                      AS LIMITE_MENSAL ,                       
		A.INSCRICAO_FEDERAL                                       AS INSCRICAO_FEDERAL,                          
		CONVERT(VARCHAR(30), '')                                  AS CARTAO_FIDELIDADE,                                
		0.00                                                      AS CODIGO_DEPARA,                                
		0.00                                                      AS CARGO_CONVENIO_CARTAO,                                                  
		''                                                        AS CEP_CONVENIO,            
		0                                                         AS TIPO_CARTAO,                                
		CONVERT(VARCHAR(MAX), '')                                 AS OBSERVACAO,                                
		'N'                                                       AS SOLICITAR_BIOMETRIA    ,                      
		'N'                                                       AS SOLICITAR_CRM_CONVENIO  ,
		'N'                                                       AS FIDELIZE,  
		0.00                                                      AS DEPENDENTE,                
		A.INSCRICAO_FEDERAL                                       AS INSCRICAO_FEDERAL_CLIENTE,                    
		''                                                        AS RECEITA_AMBOS,                      
		NULL                                                      AS ENVIAR_CUPOM,       
		CONVERT(VARCHAR(50),NULL)                                 AS TIPO_COMPRA_CONVENIO,                                    
		CONVERT(int,NULL)                                         AS TIPO_COMPRA_CONVENIO_CODIGO ,                
		'T'                                                       AS TIPO_CONVENIADO,              
		A.CONVENIO_PROMOCIONAL                                    AS CONVENIO_PROMOCIONAL,                     
		ISNULL(T.TIPO, 1)                                         AS TIPO_CARTAO,
		''                                                        AS GERENCIAL_CONVENIO_VIA_UNICA,
		0.0                                                       AS CONVENIO_INTEGRACAO,
		''                                                        AS CARTAO_PESSOA_FISICA
	   FROM ENTIDADES                          A WITH(NOLOCK)                    
	   JOIN #TMP_ENTIDADES                     Z WITH(NOLOCK) ON Z.ENTIDADE        = A.ENTIDADE                    
				                                                AND Z.CONVENIO_CARTAO IS NULL                    
	   LEFT JOIN VAREJO_CONDICOES              B WITH(NOLOCK) ON B.ENTIDADE        = A.ENTIDADE                                                         
	   LEFT JOIN TELEFONES                     C WITH(NOLOCK) ON C.ENTIDADE        = A.ENTIDADE   
      LEFT 
      JOIN TIPOS_TELEFONE                     D WITH(NOLOCK) ON D.TIPO_TELEFONE   = C.TIPO_TELEFONE    
	   LEFT 
      JOIN (SELECT 
                   MAX(A.ENDERECO)          AS EBDERECO , 
                   MAX(A.ENTIDADE)          AS ENTIDADE,
                   MAX(A.CEP)               AS CEP ,       
                   MAX(A.TIPO_ENDERECO)     AS TIPO_ENDERECO ,
                   MAX(A.ENDERECO)          AS ENDERECO      ,
                   MAX(A.NUMERO)            AS NUMERO  ,    
                   MAX(A.COMPLEMENTO)       AS COMPLEMENTO   ,
                   MAX(A.BAIRRO)            AS BAIRRO        ,
                   MAX(A.CIDADE)            AS CIDADE        ,
                   MAX(A.ESTADO)            AS ESTADO        
				  FROM ENDERECOS           A WITH(NOLOCK)
	           JOIN #TMP_ENTIDADES      B ON B.ENTIDADE  = A.ENTIDADE
            )  E  ON E.ENTIDADE = A.ENTIDADE                                                                   
	   LEFT 
      JOIN ENDERECOS_COBRANCA                  F WITH(NOLOCK) ON F.ENTIDADE         = A.ENTIDADE     
	   LEFT                   
      JOIN ENDERECOS_ENTREGA                   G WITH(NOLOCK) ON G.ENTIDADE         = A.ENTIDADE                                          
	   LEFT                   
      JOIN CLIENTES_SALDOS                     X WITH(NOLOCK) ON X.CLIENTE          = A.ENTIDADE                                      
			                                                    AND X.TIPO             = CASE 
                                                                                          WHEN B.ENTIDADE IS NULL 
                                                                                          THEN 5 
                                                                                      ELSE 3 
                                                                                       END                                        
	   LEFT  
      JOIN PESSOAS_FISICAS                     Y WITH(NOLOCK) ON Y.ENTIDADE         = A.ENTIDADE                  
	   LEFT 
      JOIN ENTIDADES_CONVENIOS_CARTOES         Q WITH(NOLOCK) ON Q.ENTIDADE         = A.ENTIDADE                
	   LEFT 
      JOIN CONVENIOS_CARTOES                   T WITH(NOLOCK) ON T.CONVENIO_CARTAO  = Q.CARTAO_CONVENIO     


		UNION   

                                                    
	   SELECT B.CONVENIO_CARTAO                       AS CLIENTE ,                                                     
		1                                              AS TIPO ,                                                     
		B.NOME                                         AS NOME ,                                                     
		CAST(A.ENTIDADE AS VARCHAR(15))             AS CODIGO_CONVENIO ,     
		A.NOME                                         AS DESCRICAO ,                                       
		CAST(B.CONVENIO_CARTAO AS VARCHAR(15))      AS CONVENIO_CARTAO ,                                           
		CAST(B.CHAVE_PRINCIPAL AS VARCHAR(15))     AS CHAVE_PRINCIPAL ,                                                     
		CAST(B.CHAVE_ALTERNATIVA AS VARCHAR(15))   AS CHAVE_ALTERNATIVA ,                                    
		CAST(B.OBSERVACAO AS VARCHAR(255)) + ' - Limite: ' + CAST( ISNULL(B.LIMITE,0) as VARCHAR(20))                              
					                                  AS MENSAGEM_1,                
		CAST(C.OBSERVACAO AS VARCHAR(255) )      AS MENSAGEM_2 ,                                                   
		'S'      
                                 AS CONVENIO ,                                                     
		'N'                                           AS BOLETO ,                                                     
		'N'                                     
      AS CHEQUE ,                           
		'N'                                           AS CHEQUE_PRE ,                                      
		'S'                                           AS CARTAO_DEBITO ,                      
		'S'              
                             AS CARTAO_CREDITO ,                                   
		'N'                                           AS FIADO ,                                            
		ISNULL(C.RECEITA, 'N')                        AS RECEITA ,        
                   
		/*'S'                                    AS DESCONTO_MAXIMO, --Permanente usa Fidelize, o desconto sempre será o da prevenda */    
		ISNULL(C.DESCONTO_MAXIMO, 'N')                AS DESCONTO_MAXIMO  ,    
		C.DESCONTO_VENDA         
                     AS DESCONTO_VENDA ,                                 
		1                                             AS PREDATADO_PARCELAS ,                                                     
		1                                             AS BOLETO_PARCELAS ,                                                     
		NULL                                          AS TIPO_TELEFONE ,                                                     
		NULL                                          AS TELEFONE ,        
                                             
		NULL                                          AS CEP ,                             
		NULL                                          AS TIPO_ENDERECO ,                                                
		NULL  
                                        AS ENDERECO ,                                                     
		NULL                                          AS NUMERO ,                                            
		NULL                                      
    AS COMPLEMENTO ,                                                     
		NULL                                          AS BAIRRO ,                                                     
		NULL                                          AS CIDADE ,         
                           
		NULL                                          AS ESTADO ,                                                     
		NULL                                          AS COBR_CEP ,                                                     

		NULL                                          AS COBR_TIPO_ENDERECO ,                                                    
		NULL                                          AS COBR_ENDERECO ,                                                     
		NULL    
                                      AS COBR_NUMERO ,                       
		NULL                                          AS COBR_COMPLEMENTO ,                                                     
		NULL                                          AS COBR_BAIRRO ,                                                     
		NULL                                          AS COBR_CIDADE ,                                                     
		NULL                                          AS COBR_ESTADO ,   
		NULL                         AS ENTR_CEP ,                                                     
		NULL                                          AS ENTR_TIPO_ENDERECO ,                                                     
		NULL                               
           AS ENTR_ENDERECO ,                                                     
		NULL                                          AS ENTR_NUMERO ,                                                     
		NULL          AS ENTR_COMPLEMENTO ,                 
                                    
		NULL        AS ENTR_BAIRRO ,                                                     
		NULL                                          AS ENTR_CIDADE ,                                            
		NULL                   
                       AS ENTR_ESTADO,                                              
		ISNULL(V.QT_PARCELAS , C.PARCELAS)            AS PARCELAS,                    
		  C.VALOR_MINIMO                              AS VALOR_MINIMO,                         
             
		X.ESTADO_CARTAO                               AS STATUS,                                      
		0.00                                          AS LIMITE_MENSAL ,                 
		A.INSCRICAO_FEDERAL                           AS INSCRICAO_FEDERAL  ,                      
		CONVERT(VARCHAR(30), '')                      AS CARTAO_FIDELIDADE,                                
		0.00                                          AS CODIGO_DEPARA,     
		0.00                                          
AS CARGO_CONVENIO_CARTAO,                  
	   ''                                             AS CEP_CONVENIO,   
		0                                             AS TIPO_CARTAO,                                
		NULL                                      
    AS OBERVACAO,                                         
		'N'                                           AS SOLICITAR_BIOMETRIA    ,                      
		'N'                                           AS SOLICITAR_CRM_CONVENIO ,                       
  
		'S'                                           AS FIDELIZE, /*Todos o convênios são Fidelize*/      
		0.00                                          AS DEPENDENTE,             
	    /*NULL                                        AS TIPO_CONVENIADO   , 
*/      
		B.INSCRICAO_FEDERAL                           AS INSCRICAO_FEDERAL_CLIENTE ,                    
		''                                            AS RECEITA_AMBOS,                  
		C.ENVIAR_CUPOM                                AS ENVIAR_CUPOM
,                  
		W.DESCRICAO                                   AS TIPO_COMPRA_CONVENIO,                  
		CONVERT(INTEGER, W.TIPO_COMPRA_CONVENIO)      AS TIPO_COMPRA_CONVENIO_CODIGO ,                
		'T'                                          
 AS TIPO_CONVENIADO,              
		A.CONVENIO_PROMOCIONAL                        AS CONVENIO_PROMOCIONAL,
		1                                             AS TIPO_CARTAO,
		''                                            AS GERENCIAL_CONVENIO_VIA_UNICA,
		
0.0                                           AS CONVENIO_INTEGRACAO,
		''                                            AS CARTAO_PESSOA_FISICA    
		 FROM ENTIDADES                                 A WITH(NOLOCK)                    
		 JOIN #TMP_ENTIDADES  
                          Z WITH(NOLOCK) ON Z.ENTIDADE             = A.ENTIDADE                    
		 JOIN VW_CONVENIADOS_DEPENDENTES_RESUMO         B WITH(NOLOCK) ON B.ENTIDADE             = A.ENTIDADE                    
					                          
                        AND B.CONVENIO_CARTAO      = Z.CONVENIO_CARTAO                                                     
		 JOIN ENTIDADES_CONVENIOS_REGRAS                C WITH(NOLOCK) ON C.ENTIDADE             = A.ENTIDADE                            
                 
		 LEFT JOIN ENTIDADES_CONVENIOS_EMPRESAS         D WITH(NOLOCK) ON D.ENTIDADE            = A.ENTIDADE                           
					                                                 AND D.EMPRESA_USUARIA      = @EMPRESA                
                                 
		 LEFT JOIN VW_CLIENTES_STATUS                   X WITH(NOLOCK) ON X.CONVENIO_CARTAO      = B.CONVENIO_CARTAO                                      
					                                                  AND X.TIPO       
          = 1                          
					                                                 AND ISNULL(X.CONVENIO_CARTAO_DEPENDENTE,0) = B.DEPENDENTE   /* 18/09/2018 WILLYAN - MATHIAS FICOU DE VALIDAR SE ESSA É A MELHOR SOLUÇÃO */      
					           
                                       AND X.TIPO_CONVENIADO      = B.TIPO_CONVENIADO                   
		 LEFT JOIN PESSOAS_FISICAS                      Y WITH(NOLOCK) ON Y.ENTIDADE             = B.PESSOA_FISICA                  
		 LEFT JOIN TIPOS_COMPRAS_CONVENIOS              W WITH(NOLOCK) ON W.TIPO_COMPRA_CONVENIO = C.TIPO_COMPRA_CONVENIO             
		 LEFT JOIN CONVENIOS_AUTORIZACOES_PARCELAMENTOS V WITH(NOLOCK) ON V.CONVENIO_CARTAO      = B.CONVENIO_CARTAO                
					                 
                                 AND V.STATUS               = 1                
		 AND V.VALIDADE            >= CONVERT(DATE,GETDATE())               
                  
		WHERE @TIPO IN ('1','2','3')                     
	  /* AND D.EMPRESA_USUARIA IS NU
LL*/      
                                              
		UNION                    
                                              
	   SELECT B.CONVENIO_CARTAO                                AS CLIENTE ,                                                  
     
	  2                                                        AS TIPO ,                                                       
		B.NOME                                                 AS NOME ,             
		CAST ( A.ENTIDADE AS VARCHAR(15) )        
             AS CODIGO_CONVENIO ,                                                       
		CASE WHEN B.CARTAO_CONVENIO IS NULL                               
		  THEN A.NOME                				           
		  WHEN B.CARTAO_CONVENIO IS NOT NULL            
         
		  THEN D.DESCRICAO                			           
		END                                                    AS DESCRICAO ,                                                       
		CAST ( B.CARTAO_CONVENIO AS VARCHAR(15) )              AS CONVENIO_CARTAO ,                  
		CAST ( B.CHAVE_PRINCIPAL AS VARCHAR(15) )              AS CHAVE_PRINCIPAL ,                                                     
		CAST ( B.CHAVE_ALTERNATIVA AS VARCHAR(15) )            AS CHAVE_ALTERNATIVA ,                
  
		CAST ( B.OBSERVACAO AS VARCHAR(255) )                  AS MENSAGEM_1 ,                                          
		CAST ( '' AS VARCHAR(255) )                            AS MENSAGEM_2 ,                         
		'S'                                  
                  AS CONVENIO ,                                 
		'N'                                                    AS BOLETO ,                                
		'N'                                                    AS CHEQUE ,                     
               
		'N'                                                    AS CHEQUE_PRE ,                                                       
		'S'                                                    AS CARTAO_DEBITO ,                                    
                   
	    'S'                                                    AS CARTAO_CREDITO ,                                                       
		'N'                                                    AS FIADO ,                               
	
	ISNULL(C.RECEITA, 'N')                                 AS RECEITA ,                                                       
		COALESCE(C.DESCONTO_MAXIMO,D.DESCONTO_MAXIMO, 'N')     AS DESCONTO_MAXIMO ,      
		ISNULL(D.DESCONTO_VENDA,0)          AS DESCONTO_VENDA ,                                                  
		0                                                      AS PREDATADO_PARCELAS ,                                                       
		0                                                      AS BOLETO_PARCELAS ,                                                       
		F.DESCRICAO                                            AS TIPO_TELEFONE ,                                                
		LTRIM ( RTRIM ( STR ( E.DDD ) ) ) +                   
       
		LTRIM ( RTRIM ( STR ( E.NUMERO ) ) )                   AS TELEFONE ,                
		G.CEP              AS CEP ,                 
		G.TIPO_ENDERECO                                        AS TIPO_ENDERECO ,                                      
                 
		G.ENDERECO                                             AS ENDERECO ,                
		G.NUMERO                                               AS NUMERO ,                                      
		G.COMPLEMENTO                            
              AS COMPLEMENTO ,                                                     
	    G.BAIRRO                                               AS BAIRRO ,                                                       
		G.CIDADE                                  
             AS CIDADE ,                                                     
		G.ESTADO                                               AS ESTADO ,                                                       
		H.CEP                                              
    AS COBR_CEP ,                                                       
		H.TIPO_ENDERECO                                        AS COBR_TIPO_ENDERECO ,                                               
		H.ENDERECO                                          
   AS COBR_ENDERECO ,                               
		H.NUMERO                                               AS COBR_NUMERO ,                                                       
		H.COMPLEMENTO                                          AS COBR_COMPLENTO ,                                                       
		H.BAIRRO                                               AS COBR_BAIRRO ,                       
		H.CIDADE                                               AS COBR_CIDADE ,                        
                        
		H.ESTADO                                               AS COBR_ESTADO ,                                                
		I.CEP                                                  AS ENTR_CEP ,                                      
               
		I.TIPO_ENDERECO                                        AS ENTR_TIPO_ENDERECO ,                             
		I.ENDERECO                                             AS ENTR_ENDERECO ,                      
		I.NUMERO                     
                          AS ENTR_NUMERO ,                                                       
		I.COMPLEMENTO                                          AS ENTR_COMPLEMENTO ,                      
	    I.BAIRRO                                           
    AS ENTR_BAIRRO ,     
		I.CIDADE                                               AS ENTR_CIDADE ,                                                       
		I.ESTADO                                               AS ENTR_ESTADO ,                           
                   
		9.00                                                   AS PARCELAS    ,                                
		0.00                                                   AS VALOR_MINIMO,                    
		X.ESTADO_CARTAO                  
                      AS STATUS      ,                                
		0.00                                                   AS LIMITE_MENSAL ,                                
		A.INSCRICAO_FEDERAL                                    AS INSCRICAO_FEDERAL   ,                                
		''  AS CARTAO_FIDELIDADE,                          
		0.00                                                   AS CODIGO_DEPARA,                                
		0.00                                                   AS CARGO_CONVENIO_CARTAO,                              
		''                                                     AS CEP_CONVENIO,                      
		X.TIPO              AS TIPO_CARTAO,                                
		NULL                          
                         AS OBERVACAO,       
		'N'                                                    AS SOLICITAR_BIOMETRIA    ,                      
		'N'                                                    AS SOLICITAR_CRM_CONVENIO     ,              
              
		'N'                                                  AS FIDELIZE,                 
		0.00                                                   AS DEPENDENTE ,                            
	    /*'T'                                            
      AS TIPO_CONVENIADO   ,*/      
                
		CASE WHEN B.INSCRICAO_FEDERAL IS NULL                 
		  THEN A.INSCRICAO_FEDERAL                
		  ELSE B.INSCRICAO_FEDERAL                
		 END                                                
   AS INSCRICAO_FEDERAL_CLIENTE,                  
		''                                                     AS RECEITA_AMBOS,                  
		C.ENVIAR_CUPOM                                         AS ENVIAR_CUPOM,                  
		CONVERT(VARCHAR(50),NULL)                              AS TIPO_COMPRA_CONVENIO,                  
		CONVERT(int,NULL)                                      AS TIPO_COMPRA_CONVENIO_CODIGO ,                
		'T'                                                    AS TIPO_CONVENIADO,              
		A.CONVENIO_PROMOCIONAL                                 AS CONVENIO_PROMOCIONAL,    
		ISNULL(D.TIPO, 1)                                      AS TIPO_CARTAO,
		''                                                     AS GERENCIAL_CONVENIO_VIA_UNICA,
		0.0                                                    AS CONVENIO_INTEGRACAO,
		''                                                     AS CARTAO_PESSOA_FISICA                                          
		 FROM ENTIDADES                 
        A WITH(NOLOCK)                   
		 JOIN #TMP_ENTIDADES                    Z WITH(NOLOCK) ON Z.ENTIDADE        = A.ENTIDADE                    
		 JOIN ENTIDADES_CONVENIOS_CARTOES       B WITH(NOLOCK) ON B.ENTIDADE        = A.ENTIDADE            
        
					                                          AND B.CONVENIO_CARTAO = Z.CONVENIO_CARTAO                    
					                                          AND B.CARTAO_CONVENIO > 0                    
		 LEFT JOIN ENTIDADES_CONVENIOS_REGRAS   C 
WITH(NOLOCK) ON C.ENTIDADE        = A.ENTIDADE                   
		 LEFT JOIN CONVENIOS_CARTOES            D WITH(NOLOCK) ON D.CONVENIO_CARTAO = B.CARTAO_CONVENIO                                                 
		 LEFT JOIN TELEFONES                    
E WITH(NOLOCK) ON E.ENTIDADE        = A.ENTIDADE                                   
		 LEFT JOIN TIPOS_TELEFONE               F WITH(NOLOCK) ON F.TIPO_TELEFONE   = E.TIPO_TELEFONE                                
		 LEFT JOIN ENDERECOS                    G
 WITH(NOLOCK) ON G.ENTIDADE        = A.ENTIDADE                                            
		 LEFT JOIN ENDERECOS_COBRANCA           H WITH(NOLOCK) ON H.ENTIDADE        = A.ENTIDADE                                                       
		 LEFT JOIN ENDERECOS_ENTREGA            I WITH(NOLOCK) ON I.ENTIDADE        = A.ENTIDADE           
		 LEFT JOIN VW_CLIENTES_STATUS           X WITH(NOLOCK) ON X.CONVENIO_CARTAO = B.CONVENIO_CARTAO                   
					AND X.TIPO            = 2       
		WHERE @TIPO IN ( '1','2')                                            
	   AND D.CATEGORIA_FIDELIDADE IS NULL                  
                                   
		UNION     

	   SELECT B.CONVENIO_CARTAO                             AS CLIENTE ,                      
                                 
		2                                                   AS TIPO ,                               
		B.NOME                                              AS NOME ,                
		CAST ( A.ENTIDADE AS VARCHAR(15) )          
        AS CODIGO_CONVENIO ,                                                       
		CASE WHEN B.CARTAO_CONVENIO IS NULL                  
		  THEN A.NOME                                             
		  WHEN B.CARTAO_CONVENIO IS NOT NULL                
 
		  THEN D.DESCRICAO                
		END                                                 AS DESCRICAO ,                                           
		CAST ( B.CARTAO_CONVENIO AS VARCHAR(15) )          AS CONVENIO_CARTAO ,                               
        
		CAST ( B.CHAVE_PRINCIPAL AS VARCHAR(15) )           AS CHAVE_PRINCIPAL ,                                                     
		CAST ( B.CHAVE_ALTERNATIVA AS VARCHAR(15) )         AS CHAVE_ALTERNATIVA ,                  
		CAST ( B.OBSERVACAO AS VARCHAR(255) )               AS MENSAGEM_1 ,                                      
		CAST ( '' AS VARCHAR(255) )                         AS MENSAGEM_2 ,                             
		'S'                                                 AS CONVENIO ,    
                                                   
		'N'                                                 AS BOLETO ,                                                       
		'N'                                                 AS CHEQUE ,                 
                                      
		'N'                                                 AS CHEQUE_PRE ,                                                       
		'S'                                                 AS CARTAO_DEBITO ,                   
    
		'S'                                                 AS CARTAO_CREDITO ,                                 
		'N'                                                 AS FIADO ,                               
		ISNULL(C.RECEITA, 'N')                       
       AS RECEITA ,                                                       
		COALESCE(C.DESCONTO_MAXIMO,D.DESCONTO_MAXIMO, 'N')  AS DESCONTO_MAXIMO ,                                                       
		ISNULL(D.DESCONTO_VENDA,0)                      
    AS DESCONTO_VENDA ,                                                       
		0                                                   AS PREDATADO_PARCELAS ,                                 
		0                                                   AS BOLETO_PARCELAS ,                    
		F.DESCRICAO                                         AS TIPO_TELEFONE ,             
		LTRIM ( RTRIM ( STR ( E.DDD ) ) ) +                                                       
		LTRIM ( RTRIM ( STR ( E.NUMERO ) ) )        
        AS TELEFONE ,                                                     
		G.CEP                                               AS CEP ,                                                       
		G.TIPO_ENDERECO                                     AS TIPO_ENDERECO ,                                                       
		G.ENDERECO                                          AS ENDERECO ,                           
		G.NUMERO                                            AS NUMERO ,                             
         
		G.COMPLEMENTO                                       AS COMPLEMENTO ,                                                     
		G.BAIRRO                                            AS BAIRRO ,                         
		G.CIDADE                                            AS CIDADE ,                        
		G.ESTADO                                            AS ESTADO ,                                                      
		H.CEP                                               AS COBR_CEP ,  
		H.TIPO_ENDERECO                                     AS COBR_TIPO_ENDERECO ,                                   
		H.ENDERECO                                          AS COBR_ENDERECO ,                                                       
		H.NUMERO                                            AS COBR_NUMERO ,                                                       
		H.COMPLEMENTO                                       AS COBR_COMPLEMENTO ,                                  
		H.BAIRRO                                            AS COBR_BAIRRO ,                       
		H.CIDADE                                            AS COBR_CIDADE ,                                                       
		H.ESTADO                                            AS COBR_ESTADO ,   
                                                    
		I.CEP                                               AS ENTR_CEP ,                                                     
		I.TIPO_ENDERECO                                     AS ENTR_TIPO_ENDERECO ,    
                   
		I.ENDERECO                                          AS ENTR_ENDERECO ,                                                       
		I.NUMERO                                            AS ENTR_NUMERO ,                                     
                  
		I.COMPLEMENTO                                       AS ENTR_COMPLEMENTO ,                
		I.BAIRRO                                            AS ENTR_BAIRRO ,                                                       
		I.CIDADE        AS ENTR_CIDADE ,                                                       
		I.ESTADO                                            AS ENTR_ESTADO ,                                  
		9.00                                    
            AS PARCELAS    ,                                
		0.00                                                AS VALOR_MINIMO,                                
		X.ESTADO_CARTAO                                     AS STATUS      ,                     
           
		0.00                                                AS LIMITE_MENSAL ,                                
		A.INSCRICAO_FEDERAL                                 AS INSCRICAO_FEDERAL   ,                                
		''                       
                           AS CARTAO_FIDELIDADE,                                
		0.00                                                AS CODIGO_DEPARA,                                
		0.00                                                AS CARGO_CONVENIO_CARTAO,                              
		''                                                  AS CEP_CONVENIO,                      
		X.TIPO                                              AS TIPO_CARTAO,                                
		NULL              
                                  AS OBERVACAO,                                
		'N'                                                 AS SOLICITAR_BIOMETRIA    ,                      
		'N'                                                 AS SOLICITAR_CRM_CONVENIO     ,                            
		'N'                                                 AS FIDELIZE,                               
		0.00                                                AS DEPENDENTE ,                            
	    /* 'T'     
                                         AS TIPO_CONVENIADO,*/      
                
		CASE WHEN B.INSCRICAO_FEDERAL IS NULL                 
		  THEN A.INSCRICAO_FEDERAL                
		  ELSE B.INSCRICAO_FEDERAL                
		 END                
                                AS INSCRICAO_FEDERAL_CLIENTE,                    
		''                                                  AS RECEITA_AMBOS,                  
		C.ENVIAR_CUPOM                                      AS ENVIAR_CUPOM,             
     
		CONVERT(VARCHAR(50),NULL)                           AS TIPO_COMPRA_CONVENIO,                  
		CONVERT(int,NULL)                              AS TIPO_COMPRA_CONVENIO_CODIGO ,                
		'T'                                               AS TIPO_CONVENIADO,              
		A.CONVENIO_PROMOCIONAL                              AS CONVENIO_PROMOCIONAL,    
		ISNULL(D.TIPO, 1)                AS TIPO_CARTAO,
		''                                                  AS GERENCIAL_CONVENIO_VIA_UNICA,
		0.0                                                 AS CONVENIO_INTEGRACAO,
		''            AS CARTAO_PESSOA_FISICA
		 FROM ENTIDADES                       A WITH(NOLOCK)                
		 JOIN #TMP_ENTIDADES                  Z WITH(NOLOCK) ON Z.ENTIDADE
        = A.ENTIDADE                
                                                            AND Z.CONVENIO_CARTAO IS NULL                                       
		 JOIN ENTIDADES_CONVENIOS_CARTOES     B WITH(NOLOCK) ON B.ENTIDADE        = Z.ENTIDADE 
                   
                                              AND B.CARTAO_CONVENIO > 0                    
		 LEFT JOIN ENTIDADES_CONVENIOS_REGRAS C WITH(NOLOCK) ON C.ENTIDADE        = A.ENTIDADE                                             
		 LEFT JOIN CONVENIOS_CARTOES          D WITH(NOLOCK) ON D.CONVENIO_CARTAO = B.CARTAO_CONVENIO                                                 
		 LEFT JOIN TELEFONES                  E WITH(NOLOCK) ON E.ENTIDADE        = A.ENTIDADE                               
    
		 LEFT JOIN TIPOS_TELEFONE             F WITH(NOLOCK) ON F.TIPO_TELEFONE   = E.TIPO_TELEFONE                                      
		 LEFT JOIN ENDERECOS                  G WITH(NOLOCK) ON G.ENTIDADE        = A.ENTIDADE                              
              
	     LEFT JOIN ENDERECOS_COBRANCA         H WITH(NOLOCK) ON H.ENTIDADE        = A.ENTIDADE                                                       
		 LEFT JOIN ENDERECOS_ENTREGA          I WITH(NOLOCK) ON I.ENTIDADE        = A.ENTIDADE     
                                           
		 LEFT JOIN VW_CLIENTES_STATUS         X WITH(NOLOCK) ON X.CONVENIO_CARTAO = B.CONVENIO_CARTAO                                
					                                        AND X.TIPO            = 2             
                   
		WHERE @TIPO IN ( '1','2')                 
	   AND D.CATEGORIA_FIDELIDADE IS NULL                  
                                           
		ORDER BY 2                            
    
    
    
		/*SET NOCOUNT ON               
                    */
		/*UPDATE LOG_CONSULTAS_CLIENTES                    */
		/*   SET FIM                = GETDATE(),           */
		/*       QTDE_TMP_ENTIDADES = @QTDE_TMP_ENTIDADES  */   
		/* WHERE ID = @ID_LOG                              */
		/*S
ET NOCOUNT OFF                                  */
       
                    
	 END




