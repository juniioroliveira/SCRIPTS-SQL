-- SELECT
-- 	*	
--   FROM(
-- 	SELECT 																				    
-- 		* 																						
-- 	  FROM
-- 	  	(	 																					
-- 		  SELECT DISTINCT 																		
-- 			CONCAT(D.ORDENACAO, '(', B.FORMULARIO, ')')	            AS FORMULARIO  															
-- 			,ISNULL(D.DESCRICAO, '')								AS DESC_FORMULARIO 													
-- 			,A.NOME			            							AS PERFIL 															
-- 		    FROM USUARIOS				 	A WITH(NOLOCK) 										
-- 		    JOIN USUARIOS_FORMULARIOS		B WITH(NOLOCK)ON B.USUARIO = A.USUARIO 			
-- 		    JOIN MENU_FORMULARIOS			D WITH(NOLOCK)ON D.EXECUCAO = B.FORMULARIO 	
					
-- 		   WHERE A.NOME  LIKE '%PERFIL%' 															
-- 		)A

-- 	 PIVOT 																					
-- 		(MAX(DESC_FORMULARIO) 																	
-- 			FOR PERFIL IN 																		
-- 			( 			 																		
-- 			  [PERFIL - FISCAL]																	
-- 			 ,[PERFIL - CONTAS A PAGAR]															
-- 			 ,[PERFIL - COMPRAS]																
-- 			 ,[PERFIL - RECEBIMENTO]															
-- 			 ,[PERFIL - SEPARAÇÃO/ALOCAÇÃO/CHECKOUT]											
-- 			 ,[PERFIL - CONTAS RECEBER]															
-- 			 ,[PERFIL - CHECKOUT]																
-- 			 ,[PERFIL - SUPORTE ADMINISTRATIVO]													
-- 			 ,[PERFIL - DP]																		
-- 			 ,[PERFIL - FINANCEIRO]																
-- 			 ,[PERFIL - GERENTE COMPRAS]														
-- 			 ,[PERFIL - ASSISTENTE PRECIFICAÇÃO]												
-- 			 ,[PERFIL - RECEBIMENTO APROVAÇÃO]													
-- 			 ,[PERFIL - FARMACEUTICO LIDER]														
-- 			 ,[PERFIL - LIDER]																	
-- 			 ,[PERFIL - CONTAS A RECEBER LIDER]													
-- 			 ,[PERFIL - GERENTE (SANTIAGO)]														
-- 			 ,[PERFIL - GERENTE]																
-- 			 ,[PERFIL - GERENTE FARMACEUTICO]													
-- 			 ,[PERFIL - FARMACEUTICO]															
-- 			 ,[PERFIL - TESOURARIA CAIXA]														
-- 			 ,[PERFIL - DP ASSISTENTE]															
-- 			 ,[PERFIL - SNGPC]																	
-- 			 ,[PERFIL - ADM DROGALESTE]															
-- 			 ,[PERFIL - INVENTÁRIO]																
-- 			 ,[PERFIL - CONFERENCIA CAIXA]														
-- 			 ,[PERFIL - INATIVOS]																
-- 			 ,[PERFIL - CONFERÊNCIA DE NOTAS]													
-- 			 ,[PERFIL - DIRETORIA]																
-- 			 ,[PERFIL - SUPERVISOR LOJAS]														
-- 			 ,[PERFIL - SUPORTE DESENVOLVIMENTO]												
-- 			 ,[PERFIL - CONTAS A PAGAR E CONFERENCIA CAIXAS]										
-- 			 ,[PERFIL - ADMINISTRATIVO]															
-- 			 ,[PERFIL - ASSISTENTE QUALIDADE]													
-- 			 ,[PERFIL - SUPORTE TI]																
-- 			 ,[PERFIL - REGULATORIOS]															
-- 			 ,[PERFIL - CONTAS A PAGAR (MILTON)]												
-- 			 ,[PERFIL - CONSULTOR SAUDE E BELEZA]												
-- 			 ,[PERFIL - NOTAS]																	
-- 			 ,[PERFIL - TRADE]																	
-- 			 ,[PERFIL - MARKETING]																
-- 			 ,[PERFIL - DESENVOLVIMENTO]														
-- 			 ,[PERFIL - VALIDACAO PREMIACOES]													
-- 			 ,[PERFIL - TREINAMENTO SUPORTE]													
-- 			 ,[PERFIL - ASSISTENTE INVENTÁRIO]													
-- 			 ,[PERFIL - CONTAS A PAGAR LIDER]													
-- 			 )																					
-- 		 )A		
--     )A							


IF OBJECT_ID('TEMPDB..#MENU') IS NOT NULL
   DROP TABLE #MENU

   SELECT 
   		*
	INTO #MENU
	FROM MENU_FORMULARIOS
   WHERE REGISTRO IN(6682, 6702, 6715, 6719, 6722, 4896, 6722, 6691)

 --SELECT * FROM #MENU

IF OBJECT_ID('TEMPDB..#N1') IS NOT NULL
   DROP TABLE #N1

   SELECT 
   		*
	INTO #N1
	FROM MENU_FORMULARIOS
   WHERE TIPO IS NULL
	 AND EXECUCAO IS NULL
     AND ORDENACAO IS NOT NULL
     AND REGISTRO_PAI IN(4896)

	 
   --SELECT * FROM #N1

IF OBJECT_ID('TEMPDB..#N2') IS NOT NULL
   DROP TABLE #N2

   SELECT 
   		*
	INTO #N2
	FROM MENU_FORMULARIOS
   WHERE REGISTRO_PAI IN(4897, 6474, 6478)
	 AND EXECUCAO IS NULL

   --SELECT * FROM #N2

IF OBJECT_ID('TEMPDB..#N3') IS NOT NULL
   DROP TABLE #N3

   SELECT 
   		*
	INTO #N3
	FROM MENU_FORMULARIOS
   WHERE REGISTRO_PAI IN((SELECT REGISTRO FROM #N2))
	 AND EXECUCAO IS NULL

   --SELECT * FROM #N3

IF OBJECT_ID('TEMPDB..#N4') IS NOT NULL
   DROP TABLE #N4

   SELECT 
   		*
	INTO #N4
	FROM MENU_FORMULARIOS
   WHERE REGISTRO_PAI IN((SELECT REGISTRO FROM #N3))
	 AND EXECUCAO IS NULL

   --SELECT * FROM #N4

IF OBJECT_ID('TEMPDB..#N5') IS NOT NULL
   DROP TABLE #N5

   SELECT 
   		*
	INTO #N5
	FROM MENU_FORMULARIOS
   WHERE REGISTRO_PAI IN((SELECT REGISTRO FROM #N4))
	 AND EXECUCAO IS NULL

   --SELECT * FROM #N5

IF OBJECT_ID('TEMPDB..#N6') IS NOT NULL
   DROP TABLE #N6

   SELECT 
   		*
	INTO #N6
	FROM MENU_FORMULARIOS
   WHERE REGISTRO_PAI IN((SELECT REGISTRO FROM #N5))
	 AND EXECUCAO IS NULL

   --SELECT * FROM #N6


   SELECT 
		 Y.DESCRICAO		AS MENU
		--  A.REGISTRO			AS REGISTO_N1
		,A.DESCRICAO		AS DESCRICAO_N1
		-- ,B.REGISTRO			AS REGISTO_N2
		,B.DESCRICAO		AS DESCRICAO_N2
		-- ,C.REGISTRO			AS REGISTO_N3
		,C.DESCRICAO		AS DESCRICAO_N3
		-- ,D.REGISTRO			AS REGISTO_N4
		,D.DESCRICAO		AS DESCRICAO_N4
		-- ,E.REGISTRO			AS REGISTO_N5
		,E.DESCRICAO		AS DESCRICAO_N5
		-- ,F.REGISTRO			AS REGISTO_N6
		,F.DESCRICAO		AS DESCRICAO_N6
	 FROM #MENU		Y WITH(NOLOCK)
	 LEFT
	 JOIN #N1		A WITH(NOLOCK)ON A.REGISTRO_PAI = Y.REGISTRO
	 LEFT
	 JOIN #N2		B WITH(NOLOCK)ON B.REGISTRO_PAI = A.REGISTRO
	 LEFT
	 JOIN #N3		C WITH(NOLOCK)ON C.REGISTRO_PAI = B.REGISTRO
	 LEFT
	 JOIN #N4		D WITH(NOLOCK)ON D.REGISTRO_PAI = C.REGISTRO
	 LEFT
	 JOIN #N5		E WITH(NOLOCK)ON E.REGISTRO_PAI = D.REGISTRO
	 LEFT
	 JOIN #N6		F WITH(NOLOCK)ON F.REGISTRO_PAI = E.REGISTRO

	 ORDER BY 
	 	 Y.DESCRICAO
		,A.DESCRICAO
		,B.DESCRICAO
		,C.DESCRICAO
		,D.DESCRICAO
		,E.DESCRICAO
		,F.DESCRICAO

