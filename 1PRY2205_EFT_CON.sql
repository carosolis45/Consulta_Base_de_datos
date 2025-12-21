--El usuario  PRY2205_EFT_CON va revisar si tiene acceso 
--  ejecuta: Las primeras 5 filas con todas las columnas

SELECT COUNT(*) FROM PRY2205_EFT_DES.CARTOLA;
SELECT * FROM PRY2205_EFT_DES.CARTOLA WHERE ROWNUM <= 5;

-- En PRY2205_EFT_CON conectando se ejecuta:

-- Usando nombre completo
SELECT COUNT(*) FROM PRY2205_EFT.VW_EMPRESAS_ASESORADAS;

-- Ver datos, que nos muestre 3 datos
SELECT * FROM PRY2205_EFT.VW_EMPRESAS_ASESORADAS WHERE ROWNUM <= 3;

