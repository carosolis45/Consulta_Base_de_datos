//CASO 1//

SELECT 
    c.numrut_cli || '-' || c.dvrut_cli AS "RUT Cliente",
    INITCAP(c.nombre_cli) || ' ' || INITCAP(c.appaterno_cli) || ' ' || INITCAP(c.apmaterno_cli) AS "Nombre Completo Cliente",
    c.direccion_cli AS "Dirección Cliente",
    TO_CHAR(c.renta_cli, 'FM$999,999,999') AS "Renta Cliente",
    CASE 
        WHEN c.celular_cli IS NOT NULL THEN
            SUBSTR(TO_CHAR(c.celular_cli), 1, 2) || '-' || 
            SUBSTR(TO_CHAR(c.celular_cli), 3, 3) || '-' || 
            SUBSTR(TO_CHAR(c.celular_cli), 6, 3)
        ELSE 'SIN CELULAR'
    END AS "Celular Cliente",
    CASE 
        WHEN c.renta_cli > 500000 THEN 'TRAMO 1'
        WHEN c.renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
        WHEN c.renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
        ELSE 'TRAMO 4'
    END AS "Tramo Renta Cliente"
FROM cliente c
WHERE c.renta_cli BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
    AND c.celular_cli IS NOT NULL
ORDER BY INITCAP(c.nombre_cli) || ' ' || INITCAP(c.appaterno_cli) || ' ' || INITCAP(c.apmaterno_cli) ASC;


//CASO 2//

SELECT 
    ce.id_categoria_emp AS "CODIGO_CATEGORIA",
    ce.desc_categoria_emp AS "DESCRIPCION_CATEGORIA",
    COUNT(e.numrut_emp) AS "CANTIDAD_EMPLEADOS",
    s.desc_sucursal AS "SUCURSAL",
    TO_CHAR(ROUND(AVG(e.sueldo_emp)), 'FM$999,999,999') AS "SUELDO_PROMEDIO"
FROM empleado e
JOIN categoria_empleado ce ON e.id_categoria_emp = ce.id_categoria_emp
JOIN sucursal s ON e.id_sucursal = s.id_sucursal
GROUP BY ce.id_categoria_emp, ce.desc_categoria_emp, s.id_sucursal, s.desc_sucursal
HAVING AVG(e.sueldo_emp) > &SUELDO_PROMEDIO_MINIMO
ORDER BY AVG(e.sueldo_emp) DESC;


//CASO 3 //

SELECT 
    tp.id_tipo_propiedad AS "CODIGO_TIPO",
    tp.id_tipo_propiedad || ' ' || tp.desc_tipo_propiedad AS "DESCRIPCION_TIPO",
    COUNT(p.nro_propiedad) AS "TOTAL_PROPIEDADES",
    TO_CHAR(ROUND(AVG(p.valor_arriendo)), 'FM$999,999,999') AS "PROMEDIO_ARRIENDO",
    TO_CHAR(AVG(p.superficie), 'FM999,999.00') AS "PROMEDIO_SUPERFICIE",
    TO_CHAR(ROUND(AVG(p.valor_arriendo / p.superficie)), 'FM$999,999') AS "VALOR_ARRIENDO_M2",
    CASE 
        WHEN AVG(p.valor_arriendo / p.superficie) < 5000 THEN 'Económico'
        WHEN AVG(p.valor_arriendo / p.superficie) BETWEEN 5000 AND 10000 THEN 'Medio'
        ELSE 'Alto'
    END AS "CLASIFICACION"
FROM propiedad p
JOIN tipo_propiedad tp ON p.id_tipo_propiedad = tp.id_tipo_propiedad
GROUP BY tp.id_tipo_propiedad, tp.desc_tipo_propiedad
HAVING AVG(p.valor_arriendo / p.superficie) > 1000
ORDER BY AVG(p.valor_arriendo / p.superficie) DESC;

