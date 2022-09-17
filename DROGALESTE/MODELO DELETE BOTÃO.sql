BEGIN TRAN

-- /*------------------------------*/
-- /*   DECLARAÇÃO DAS VARIAVEIS   */
-- /*------------------------------*/

DECLARE @DEPOSITO_LOJA              NUMERIC(15) = :DEPOSITO_LOJA
DECLARE @PERFIL_USUARIO             NUMERIC(15)   

SELECT                     
    @PERFIL_USUARIO = PERFIL_USUARIO
FROM
    USUARIOS   WITH(NOLOCK)
WHERE                  
    LOGIN = @LOGIN     

                         
/*---------------------------------*/
/*   VALIDAÇÃO DE USUÁRIO LOGADO   */ 
/*---------------------------------*/

IF @PERFIL_USUARIO NOT IN (1, 411, 1787, 1849)
  
BEGIN               

    RAISERROR('Usuário NÃO tem permissão para usar este botão!!!', 16, 1)
    RETURN      
         
END   

IF @PERFIL_USUARIO IN (1, 411, 1787, 1849)
   
BEGIN                                                              
  DELETE
    FROM DEPOSITOS_BANCARIOS_LOJAS_DINH_DETALHES 
   WHERE DEPOSITO_LOJA = @DEPOSITO_LOJA    
  END   

