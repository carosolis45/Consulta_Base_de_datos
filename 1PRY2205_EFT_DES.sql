//verificaR que se acceder a los sinónimos públicos//

DESC SIN_PROFESIONAL;  -- Debería mostrar la estructura
SELECT COUNT(*) FROM SIN_PROFESIONAL;  -- va a mostrar el número de registros de la tabla profesional

SELECT * FROM PROFESIONAL;  -- Sinónimo público
SELECT * FROM SIN_PROFESIONAL;  -- Sinónimo privado

-- En PRY2205_EFT_DES, primero eliminar sinónimos existentes si hay problemas
BEGIN
    FOR syn IN (SELECT SYNONYM_NAME FROM USER_SYNONYMS WHERE SYNONYM_NAME IN (
        'PROFESIONAL', 'EMPRESA', 'ASESORIA', 'CARTOLA',
        'PROFESION', 'ISAPRE', 'TIPO_CONTRATO', 'RANGOS_SUELDOS'
    ))
    LOOP
        EXECUTE IMMEDIATE 'DROP SYNONYM ' || syn.SYNONYM_NAME;
    END LOOP;
END;
/

-- Crear sinónimos privados
CREATE SYNONYM PROFESIONAL FOR SIN_PROFESIONAL;
CREATE SYNONYM EMPRESA FOR SIN_EMPRESA;
CREATE SYNONYM ASESORIA FOR SIN_ASESORIA;
CREATE SYNONYM CARTOLA FOR SIN_CARTOLA;
CREATE SYNONYM PROFESION FOR SIN_PROFESION;
CREATE SYNONYM ISAPRE FOR SIN_ISAPRE;
CREATE SYNONYM TIPO_CONTRATO FOR SIN_TIPO_CONTRATO;
CREATE SYNONYM RANGOS_SUELDOS FOR SIN_RANGOS_SUELDOS;


-- VERIFICAR sinónimos privados
SELECT synonym_name, table_name FROM user_synonyms;

-- Probar consulta con sinónimos privados
SELECT COUNT(*) FROM PROFESIONAL;      -- Va a mostrar número de profesionales de la tabla
SELECT COUNT(*) FROM ASESORIA;         -- va mostrar número de asesorías de la tabla

-- En PRY2205_EFT_DES, vamos a  verificar los acceso a los sinónimos públicos

SELECT * FROM ALL_SYNONYMS 
WHERE OWNER = 'PUBLIC' 
AND SYNONYM_NAME IN (
    'SIN_PROFESIONAL', 'SIN_EMPRESA', 'SIN_ASESORIA', 'SIN_CARTOLA',
    'SIN_PROFESION', 'SIN_ISAPRE', 'SIN_TIPO_CONTRATO', 'SIN_RANGOS_SUELDOS'
);



//CASO 2 , con nuestro Usuario PRY2205_EFT_DES se ejecuta esta consulta para generar y almacenar el informe//

--Muestra la estructura de la tabla CARTOLA--

   
DESC CARTOLA;

INSERT INTO CARTOLA
SELECT 
    P.RUTPROF AS RUT_PROFESIONAL,
    SUBSTR(P.NOMPRO || ' ' || P.APPPRO || ' ' || P.APMPRO, 1, 50) AS NOMBRE_PROFESIONAL,
    SUBSTR(PR.NOMPROFESION, 1, 25) AS PROFESION,
    SUBSTR(I.NOMISAPRE, 1, 25) AS ISAPRE,
    LEAST(P.SUELDO, 99999999) AS SUELDO_BASE,  -- Limita a 8 dígitos
    NVL(P.COMISION, 0) AS PORC_COMISION_PROFESIONAL,
    LEAST(NVL(P.SUELDO * NVL(P.COMISION, 0), 0), 99999999) AS VALOR_TOTAL_COMISION,
    CASE
        WHEN P.SUELDO BETWEEN RS.S_MIN AND RS.S_MAX THEN LEAST(RS.HONOR_PCT, 99999999)
        ELSE 0
    END AS PORCENTATE_HONORARIO,
    CASE TC.NOMTCONTRATO
        WHEN 'Indefinido Jornada Completa' THEN 150000
        WHEN 'Indefinido Jornada Parcial' THEN 120000
        WHEN 'Plazo fijo' THEN 60000
        WHEN 'Honorarios' THEN 50000
        ELSE 0
    END AS BONO_MOVILIZACION,
    LEAST(
        P.SUELDO + 
        NVL(P.SUELDO * NVL(P.COMISION, 0), 0) + 
        CASE
            WHEN P.SUELDO BETWEEN RS.S_MIN AND RS.S_MAX THEN (P.SUELDO * RS.HONOR_PCT / 100)
            ELSE 0
        END +
        CASE TC.NOMTCONTRATO
            WHEN 'Indefinido Jornada Completa' THEN 150000
            WHEN 'Indefinido Jornada Parcial' THEN 120000
            WHEN 'Plazo fijo' THEN 60000
            WHEN 'Honorarios' THEN 50000
            ELSE 0
        END,
        99999999
    ) AS TOTAL_PAGAR
FROM PROFESIONAL P
INNER JOIN PROFESION PR ON P.IDPROFESION = PR.IDPROFESION
INNER JOIN ISAPRE I ON P.IDISAPRE = I.IDISAPRE
INNER JOIN TIPO_CONTRATO TC ON P.IDTCONTRATO = TC.IDTCONTRATO
LEFT JOIN RANGOS_SUELDOS RS ON P.SUELDO BETWEEN RS.S_MIN AND RS.S_MAX
ORDER BY 
    PR.NOMPROFESION,
    P.SUELDO DESC,
    NVL(P.COMISION, 0),
    P.RUTPROF;


-- Verificar que se insertaron todas las filas
SELECT COUNT(*) FROM CARTOLA;

-- Ver todos los datos 
SELECT * FROM CARTOLA ORDER BY RUT_PROFESIONAL;

GRANT SELECT ON CARTOLA TO PRY2205_EFT_CON;


--  Verificar que la vista se creó
SELECT VIEW_NAME, TEXT_LENGTH 
FROM USER_VIEWS 
WHERE VIEW_NAME = 'VW_EMPRESAS_ASESORADAS';

-- Probar la vista (primeras 5 filas)
SELECT * FROM VW_EMPRESAS_ASESORADAS WHERE ROWNUM <= 5;




















