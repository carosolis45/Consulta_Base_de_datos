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













