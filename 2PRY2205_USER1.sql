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



//Verificar permisos dados//
SELECT grantee, table_name, privilege, grantor
FROM user_tab_privs
WHERE grantee = 'PRY2205_USER2'
ORDER BY table_name;


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





