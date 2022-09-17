DECLARE @CONFERENCIA_ESTOQUE  NUMERIC(15) = :CONFERENCIA_ESTOQUE
DECLARE @EMPRESA              NUMERIC(15) = :EMPRESA
DECLARE @DATA_INICIAL                DATE = :DATA_INICIAL
DECLARE @DATA_FINAL                  DATE = :DATA_FINAL

IF(
    SELECT TOP 1 
      CASE 
         WHEN CONVERT(DATE,DATEADD(DAY, 1, A.DATA_FINAL)) >= CONVERT(DATE,GETDATE())
            THEN CONVERT(DATE,GETDATE())
         ELSE CONVERT(DATE,DATEADD(DAY, 1, A.DATA_FINAL))
          END                                                 AS DATA_INICIAL
      FROM DL_CONFERENCIAS_ESTOQUES   A WITH(NOLOCK)
     WHERE 1=1
       AND A.EMPRESA             = @EMPRESA
       AND A.CONFERENCIA_ESTOQUE < @CONFERENCIA_ESTOQUE
     ORDER
        BY A.CONFERENCIA_ESTOQUE DESC
  ) IS NOT NULL

BEGIN 
    SELECT 'Não é possível alterar data inicial.'
     WHERE @DATA_INICIAL <> (
                              SELECT TOP 1
                                    CASE 
                                      WHEN CONVERT(DATE,DATEADD(DAY, 1, A.DATA_FINAL)) >= CONVERT(DATE,GETDATE())
                                      THEN CONVERT(DATE,GETDATE())
                                      ELSE CONVERT(DATE,DATEADD(DAY, 1, A.DATA_FINAL))
                                    END                                             AS DATA_INICIAL
                                FROM DL_CONFERENCIAS_ESTOQUES   A WITH(NOLOCK)
                               WHERE 1=1
                                 AND A.EMPRESA             = @EMPRESA
                                 AND A.CONFERENCIA_ESTOQUE < @CONFERENCIA_ESTOQUE
                               ORDER
                                  BY A.CONFERENCIA_ESTOQUE DESC
                            )

END
ELSE

  SELECT 'Data Inválida'
   WHERE @DATA_INICIAL > GETDATE() 
      OR @DATA_INICIAL < '01/01/2011'

  UNION ALL

  SELECT CONCAT('Não pode haver intervalo entre a data do último arquivo para essa empresa (', A.DATA_FINAL, ') e a data inicial (', @DATA_INICIAL, ').')
    FROM (
            SELECT TOP 1
                A.DATA_FINAL
              FROM DL_CONFERENCIAS_ESTOQUES   A 
             WHERE A.EMPRESA = @EMPRESA
             ORDER
                BY A.CONFERENCIA_ESTOQUE DESC
         ) X
  WHERE (X.DATA_INICIAL +1) <> @DATA_INICIAL