BEGIN TRAN--ROLLBACK
DECLARE @EMPRESA          NUMERIC(15) = 60
DECLARE @MOVIMENTO        DATE        = '26/09/2022'
DECLARE @CONFERENCIA      NUMERIC(15)  

IF EXISTS(SELECT PROCESSAR, EMPRESA, MOVIMENTO FROM CONFERENCIAS_FECHAMENTOS_CAIXAS WHERE EMPRESA = @EMPRESA AND MOVIMENTO = @MOVIMENTO AND PROCESSAR = 'S')
BEGIN

    SELECT @CONFERENCIA = CONFERENCIA_FECHAMENTO_CAIXA 
      FROM CONFERENCIAS_FECHAMENTOS_CAIXAS 
    WHERE EMPRESA = @EMPRESA 
      AND MOVIMENTO = @MOVIMENTO 
      AND PROCESSAR = 'S'

    PRINT CONCAT('CONFERENCIA DESPROCESSADA: ', @CONFERENCIA)

    BEGIN TRY

       UPDATE CONFERENCIAS_FECHAMENTOS_CAIXAS
          SET PROCESSAR = 'N'
        WHERE EMPRESA = @EMPRESA 
          AND MOVIMENTO = @MOVIMENTO 
          AND PROCESSAR = 'S'
    
       SELECT PROCESSAR, EMPRESA, MOVIMENTO
         FROM CONFERENCIAS_FECHAMENTOS_CAIXAS 
        WHERE 1=1
          AND EMPRESA = @EMPRESA
          AND MOVIMENTO = @MOVIMENTO  

          COMMIT

    END TRY
    BEGIN CATCH
         THROW 99001, 'ERRO AO DESPROCESSAR CONFERENCIA', 1
    END CATCH
    

END
ELSE IF EXISTS (SELECT PROCESSAR, EMPRESA, MOVIMENTO FROM CONFERENCIAS_FECHAMENTOS_CAIXAS WHERE EMPRESA = @EMPRESA AND MOVIMENTO = @MOVIMENTO AND PROCESSAR = 'N')
BEGIN

    ;THROW 99001, 'O PROCESSAR DESSA CONFERÊNCIA ESTÁ MARCADA COMO "N"', 1 

END