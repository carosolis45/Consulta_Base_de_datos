//CASO1 - SYS-CREACION USUARIOS Y ROLES//

//crear usuarios y roles //

ALTER SESSION SET "_ORACLE_SCRIPT" = TRUE;

//1. crear usuarios//

CREATE USER PRY2205_USER1 IDENTIFIED BY "user1_pass"
DEFAULT TABLESPACE USERS
QUOTA UNLIMITED ON USERS;

CREATE USER PRY2205_USER2 IDENTIFIED BY "user2_pass"
DEFAULT TABLESPACE USERS
QUOTA UNLIMITED ON USERS;

//2. conexion para usuarios//

GRANT CREATE SESSION TO PRY2205_USER1;
GRANT CREATE SESSION TO PRY2205_USER2;

//3. crear roles// 

CREATE ROLE PRY2205_ROL_D;  -- Rol Dueño/Desarrollador
CREATE ROLE PRY2205_ROL_P;  -- Rol Público/Consulta

//4. se van asignar privilegios a los roles//

//Rol D (Dueño) - Permisos completos crear tablas, indices, vistas, sinonimos//

GRANT CREATE TABLE TO PRY2205_ROL_D;
GRANT CREATE SEQUENCE TO PRY2205_ROL_D; 
GRANT CREATE VIEW TO PRY2205_ROL_D;
GRANT CREATE SYNONYM TO PRY2205_ROL_D;
GRANT CREATE PUBLIC SYNONYM TO PRY2205_ROL_D;

//-- Rol P (Consulta) - Permisos limitados//

GRANT CREATE TABLE TO PRY2205_ROL_P;
GRANT CREATE SEQUENCE TO PRY2205_ROL_P;
GRANT CREATE TRIGGER TO PRY2205_ROL_P;

//5 Asignar roles a los usuarios//

GRANT PRY2205_ROL_D TO PRY2205_USER1;
GRANT PRY2205_ROL_P TO PRY2205_USER2;

//6 Otros privilegios necesarios//

GRANT UNLIMITED TABLESPACE TO PRY2205_USER1;
GRANT UNLIMITED TABLESPACE TO PRY2205_USER2;


SELECT username, account_status, created 
FROM dba_users 
WHERE username LIKE 'PRY2205_%'
ORDER BY username;


//Dar permisos SELECT a PRY2205_USER2//

// con las tablas ya creadas en el PRY2205_USER1, Dar permisos SELECT sobre las tablas //

GRANT SELECT ON PRY2205_USER1.LIBRO TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.EJEMPLAR TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.PRESTAMO TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.EMPLEADO TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.ALUMNO TO PRY2205_USER2;


GRANT CREATE PROCEDURE TO PRY2205_USER2;



//Verificar permisos dados//
SELECT grantee, table_name, privilege, grantor
FROM dba_tab_privs
WHERE owner = 'PRY2205_USER1'
  AND grantee = 'PRY2205_USER2'
ORDER BY table_name;

//Ver los roles asignados al usuario//
SELECT * FROM USER_ROLE_PRIVS;

//Ver los privilegios de sistema otorgados por rol//
SELECT * FROM USER_SYS_PRIVS;




//CASO2//

//POBLACION TABLAS, SE CREA ESQUEMA POBLADO, SE CREAN SINONIMOS PARA USER2//

//USER1//

//CONEXION A PRY2205_USER1//

//formato de fecha//
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY'

//Crear sinónimos públicos para que pueda acceder USER2//

CREATE PUBLIC SYNONYM LIBRO FOR PRY2205_USER1.LIBRO;
CREATE PUBLIC SYNONYM EJEMPLAR FOR PRY2205_USER1.EJEMPLAR;
CREATE PUBLIC SYNONYM PRESTAMO FOR PRY2205_USER1.PRESTAMO;
CREATE PUBLIC SYNONYM EMPLEADO FOR PRY2205_USER1.EMPLEADO;
CREATE PUBLIC SYNONYM ALUMNO FOR PRY2205_USER1.ALUMNO;


-- Verificar sinónimos creados
SELECT synonym_name, table_owner, table_name
FROM user_synonyms
ORDER BY synonym_name;


//PRY2205_USER2-CREACION DEL INFORME//

//SE REALIZA CONEXION AL USUARIO 2//

//SE REALIZA INFORME CONTROL STOCK//

// Crear tabla para el informe//

DROP TABLE CONTROL_STOCK_LIBROS;
DROP SEQUENCE SEQ_CONTROL_STOCK;

CREATE TABLE CONTROL_STOCK_LIBROS (
    ID_CONTROL           NUMBER PRIMARY KEY,
    LIBRO_ID             NUMBER,
    NOMBRE_LIBRO         VARCHAR2(500),
    TOTAL_EJEMPLARES     NUMBER,
    EN_PRESTAMO          NUMBER,
    DISPONIBLES          NUMBER,
    PORCENTAJE_PRESTAMO  NUMBER,
    STOCK_CRITICO        CHAR(1)
);



//Crear secuencia para el correlativo//

CREATE SEQUENCE SEQ_CONTROL_STOCK
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

//Procedimiento para generar el informe//

CREATE OR REPLACE PROCEDURE GENERAR_INFORME_CONTROL_STOCK AS
    v_fecha DATE;
    v_id_control NUMBER := 0;
BEGIN
    -- Usar el último mes con CUALQUIER préstamo
    SELECT TRUNC(MAX(fecha_inicio), 'MM') INTO v_fecha
    FROM PRESTAMO;
    
    -- Si no hay préstamos, usar mes actual
    IF v_fecha IS NULL THEN
        v_fecha := TRUNC(SYSDATE, 'MM');
    END IF;
    
    -- Limpiar tabla
    DELETE FROM CONTROL_STOCK_LIBROS;
    
    -- Insertar usando un cursor explícito
    FOR rec IN (
        SELECT
            l.libroid,
            l.nombre_libro,
            NVL(ce.total_ejemplares, 0) as total_ejemplares,
            NVL(cp.prestamos_mes, 0) as prestamos_mes
        FROM LIBRO l
        INNER JOIN (
            SELECT libroid, COUNT(*) as total_ejemplares
            FROM EJEMPLAR
            GROUP BY libroid
        ) ce ON l.libroid = ce.libroid
        LEFT JOIN (
            SELECT 
                e.libroid,
                COUNT(*) as prestamos_mes
            FROM PRESTAMO p
            JOIN EJEMPLAR e ON p.ejemplarid = e.ejemplarid
            WHERE TRUNC(p.fecha_inicio, 'MM') = v_fecha
            GROUP BY e.libroid
        ) cp ON l.libroid = cp.libroid
        ORDER BY l.libroid
    ) LOOP
        v_id_control := v_id_control + 1;
        
        INSERT INTO CONTROL_STOCK_LIBROS (
            ID_CONTROL,
            LIBRO_ID,
            NOMBRE_LIBRO,
            TOTAL_EJEMPLARES,
            EN_PRESTAMO,
            DISPONIBLES,
            PORCENTAJE_PRESTAMO,
            STOCK_CRITICO
        ) VALUES (
            v_id_control,
            rec.libroid,
            rec.nombre_libro,
            rec.total_ejemplares,
            rec.prestamos_mes,
            rec.total_ejemplares - rec.prestamos_mes,
            CASE 
                WHEN rec.total_ejemplares = 0 THEN 0
                ELSE ROUND(rec.prestamos_mes * 100.0 / rec.total_ejemplares, 0)
            END,
            CASE
                WHEN (rec.total_ejemplares - rec.prestamos_mes) > 2 
                THEN 'S'
                ELSE 'N'
            END
        );
    END LOOP;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Fecha usada: ' || TO_CHAR(v_fecha, 'Month YYYY'));
    DBMS_OUTPUT.PUT_LINE('Registros insertados: ' || v_id_control);
    
END GENERAR_INFORME_CONTROL_STOCK;

//ejecutar el informe//

EXEC GENERAR_INFORME_CONTROL_STOCK;

SELECT * FROM CONTROL_STOCK_LIBROS;


//CASO3//

// DESDE LA CONEXION DE PRY2205_USER1 //

-- Crear sinónimos específicos para la vista 
CREATE OR REPLACE PUBLIC SYNONYM SYN_PRESTAMO FOR PRY2205_USER1.PRESTAMO;
CREATE OR REPLACE PUBLIC SYNONYM SYN_ALUMNO FOR PRY2205_USER1.ALUMNO;
-- Necesitamos también CARRERA, PRESTAMO_DETALLE y posiblemente otras tablas
CREATE OR REPLACE PUBLIC SYNONYM SYN_CARRERA FOR PRY2205_USER1.CARRERA;
CREATE OR REPLACE PUBLIC SYNONYM SYN_PRESTAMO_DETALLE FOR PRY2205_USER1.PRESTAMO_DETALLE;
CREATE OR REPLACE PUBLIC SYNONYM SYN_LIBRO FOR PRY2205_USER1.LIBRO;

-- Verificar que todas las tablas necesarias existen
SELECT table_name FROM user_tables 
WHERE table_name IN ('PRESTAMO', 'ALUMNO', 'CARRERA', 'PRESTAMO_DETALLE', 'LIBRO', 'EJEMPLAR', 'EMPLEADO');



CREATE OR REPLACE VIEW VW_DETALLE_MULTAS AS
SELECT 
    p.prestamoid AS "ID_PRESTAMO",
    INITCAP(a.nombre) || ' ' || INITCAP(a.apaterno) || ' ' || INITCAP(a.amaterno) AS "NOMBRE_ALUMNO",
    INITCAP(c.descripcion) AS "NOMBRE_CARRERA",
    l.libroid AS "COD_LIBRO",
    TO_CHAR(l.precio, '$999G999') AS "PRECIO_LIBRO",
    TO_CHAR(p.fecha_termino, 'DD/MM/YYYY') AS "FECHA_TERMINO",
    TO_CHAR(p.fecha_entrega, 'DD/MM/YYYY') AS "FECHA_ENTREGA",
    CASE 
        WHEN p.fecha_entrega > p.fecha_termino 
        THEN p.fecha_entrega - p.fecha_termino 
        ELSE 0 
    END AS "DIAS_ATRASO",
    CASE 
        WHEN p.fecha_entrega > p.fecha_termino 
        THEN TO_CHAR((p.fecha_entrega - p.fecha_termino) * (l.precio * 0.03), '$999G999')
        ELSE '$0' 
    END AS "MULTA_CALCULADA",
    COALESCE(TO_CHAR(rm.porc_rebaja_multa, '999'), '0') || '%' AS "PORCENTAJE_REBAJA",
    CASE 
        WHEN p.fecha_entrega > p.fecha_termino 
        THEN TO_CHAR(((p.fecha_entrega - p.fecha_termino) * (l.precio * 0.03)) * (1 - COALESCE(rm.porc_rebaja_multa, 0) / 100.0), '$999G999')
        ELSE '$0' 
    END AS "MULTA_CON_REBAJA"
FROM SYN_PRESTAMO p
INNER JOIN SYN_ALUMNO a ON p.alumnoid = a.alumnoid
INNER JOIN SYN_CARRERA c ON a.carreraid = c.carreraid
INNER JOIN SYN_LIBRO l ON p.libroid = l.libroid
LEFT JOIN REBAJA_MULTA rm ON c.carreraid = rm.carreraid
WHERE EXTRACT(YEAR FROM p.fecha_termino) = EXTRACT(YEAR FROM SYSDATE) - 2
    AND p.fecha_entrega > p.fecha_termino
    AND p.fecha_entrega IS NOT NULL
ORDER BY p.fecha_entrega DESC;

//ver si se creo //
SELECT 'Vista creada: ' || view_name 
FROM user_views 
WHERE view_name = 'VW_DETALLE_MULTAS';

DESC VW_DETALLE_MULTAS;


-- Probar consulta //
SELECT COUNT(*) AS "Total registros" FROM VW_DETALLE_MULTAS;


//Dar permiso SELECT en la vista user2//
GRANT SELECT ON VW_DETALLE_MULTAS TO PRY2205_USER2;

GRANT SELECT ON REBAJA_MULTA TO PRY2205_USER2;


//Verificar que se puede ver REBAJA_MULTA//
SELECT * FROM PRY2205_USER1.REBAJA_MULTA;



//Verificar permisos dados//
SELECT grantee, table_name, privilege, grantor
FROM user_tab_privs
WHERE grantee = 'PRY2205_USER2'
ORDER BY table_name;


//DESDE CONEXION DEL USUARIO PRY2205_USER2, SE REALIZA PRUEBAS PARA REVISAR PERMISO OTORGADO POR PRY2205_USER1//
//Probar acceso a la vista//
SELECT "ID_PRESTAMO", "NOMBRE_ALUMNO", "DIAS_ATRASO", "MULTA_CON_REBAJA"
FROM PRY2205_USER1.VW_DETALLE_MULTAS 
WHERE ROWNUM <= 3;


// EN CONEXION DESDE USUARIO PRY2205_USER1//
// ÍNDICE PRINCIPAL: Para el filtro WHERE por año y comparación de fechas//

CREATE INDEX idx_vw_multas_filtro_fechas ON PRESTAMO (
    EXTRACT(YEAR FROM fecha_termino),  -- Filtro por año
    fecha_entrega,                     -- Para ORDER BY y comparación
    fecha_termino                      -- Para comparación fecha_entrega > fecha_termino
);


//ÍNDICE para JOIN PRESTAMO-ALUMNO y ORDER BY//

CREATE INDEX idx_vw_multas_join_order ON PRESTAMO (
    alumnoid,                          -- JOIN con ALUMNO
    fecha_entrega DESC,                -- ORDER BY fecha_entrega DESC
    libroid                            -- JOIN con LIBRO
);

//ÍNDICE para JOIN ALUMNO-CARRERA-para optimizar acceso a carrera del alumno//

CREATE INDEX idx_vw_multas_alumno_carrera ON ALUMNO (
    carreraid,                         -- JOIN con CARRERA y REBAJA_MULTA
    alumnoid                           -- Para el JOIN con PRESTAMO
);



//ÍNDICE para cálculo de multas- acceso a precio del libro//
CREATE INDEX idx_vw_multas_libro_precio ON LIBRO (
    libroid,                           -- JOIN con PRESTAMO
    precio                             -- Para cálculo: precio * 0.03
);


//vamos a Verificar que todos los índices se crearon correctamente//
SELECT 
    index_name,
    table_name,
    uniqueness,
    status
FROM user_indexes 
WHERE index_name LIKE 'IDX_VW_%'
ORDER BY index_name;







