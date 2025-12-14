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

//Probar acceso a la vista//
SELECT "ID_PRESTAMO", "NOMBRE_ALUMNO", "DIAS_ATRASO", "MULTA_CON_REBAJA"
FROM PRY2205_USER1.VW_DETALLE_MULTAS 
WHERE ROWNUM <= 3;

//Verificar que se puede ver REBAJA_MULTA//
SELECT * FROM PRY2205_USER1.REBAJA_MULTA;


    








