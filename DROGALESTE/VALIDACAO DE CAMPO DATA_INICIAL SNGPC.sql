IF (SELECT TOP 1
        CASE WHEN CONVERT(DATE,DATEADD(DAY, 1, A.DATA_FINAL)) >= CONVERT(DATE,GETDATE())
             THEN CONVERT(DATE,GETDATE())
             ELSE CONVERT(DATE,DATEADD(DAY, 1, A.DATA_FINAL))
        END             AS DATA_INICIAL
    FROM
        SNGPC A WITH(NOLOCK)
    WHERE
        1=1
    AND A.EMPRESA = :EMPRESA
    AND A.SNGPC   < :SNGPC
    ORDER BY
        SNGPC DESC ) IS NOT NULL

BEGIN 

    SELECT
        'Não é possivel alterar data inicial.'
    WHERE
        :DATA_INICIAL <> ( SELECT TOP 1
                               CASE WHEN CONVERT(DATE,DATEADD(DAY, 1, A.DATA_FINAL)) >= CONVERT(DATE,GETDATE())
                                    THEN CONVERT(DATE,GETDATE())
                                    ELSE CONVERT(DATE,DATEADD(DAY, 1, A.DATA_FINAL))
                               END             AS DATA_INICIAL
                           FROM
                               SNGPC A WITH(NOLOCK)
                           WHERE
                               1=1
                           AND A.EMPRESA = :EMPRESA
                           AND A.SNGPC   < :SNGPC
                           ORDER BY
                               SNGPC DESC )

END

ELSE

SELECT
    'Data Inválida.'
WHERE
    (:DATA_INICIAL > CONVERT(VARCHAR(10),GETDATE(),103)
 OR  :DATA_INICIAL < '01/01/2011')

UNION ALL

SELECT
    'Data Inválida. O dia atual só pode ser usado em caso de inventário.'
FROM
    SNGPC     A WITH(NOLOCK)
WHERE
    :INVENTARIO       = 'N'
AND :DATA_INICIAL     = CONVERT(VARCHAR(10),GETDATE(),103)
AND :FECHAR_MOVIMENTO = 'S'

    UNION ALL

SELECT TOP 1
    'Não pode haver intervalo entre a data do último arquivo para essa Empresa (' + CONVERT(VARCHAR,A.DATA_FINAL,103) + ') e a Data Inicial (' +  CONVERT(VARCHAR,:DATA_INICIAL,103) + ').'
FROM
(SELECT TOP 1
     DATA_FINAL
 FROM
     SNGPC
 WHERE
     EMPRESA = :EMPRESA
 ORDER BY
     SNGPC DESC) A
WHERE
    1=1
AND (A.DATA_FINAL + 1) <> :DATA_INICIAL
AND :INVENTARIO         = 'N'

--UNION  ALL

--SELECT 'Já existem envios confirmados para este período.' 
--  FROM SNGPC A WITH(NOLOCK)
--WHERE A.EMPRESA = :EMPRESA
--      AND A.CONFIRMADO = 'S'
--      HAVING(:DATA_INICIAL <= MAX(A.DATA_FINAL))
