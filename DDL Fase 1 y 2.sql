--------------------------------------------------------------------
-- PRY2204 - EXP3 - SEMANA 9
-- Cristalería Andina S.A. – Asignación de Turnos y Mantenciones
--------------------------------------------------------------------

--------------------------------------------------------------------
-- LIMPIEZA (Drop en orden inverso de dependencias)
--------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ASIGNACION_TURNO CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE MANTENCION CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE JEFE_TURNO CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE OPERARIO CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE TECNICO_MANT CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE EMPLEADO CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE MAQUINA CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE TIPO_MAQUINA CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE TURNO CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE PLANTA CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE COMUNA CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE REGION CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE SALUD CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE AFP CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
--------------------------------------------------------------------
-- CASO 1: Tablas base y catálogos
--------------------------------------------------------------------

CREATE SEQUENCE SEQ_REGION START WITH 21 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_COMUNA START WITH 1050 INCREMENT BY 5 NOCACHE;

--------------------------------------------------------------------
-- REGION
--------------------------------------------------------------------
CREATE TABLE REGION (
  id_region     NUMBER(4)    NOT NULL,
  nombre_region VARCHAR2(60) NOT NULL,
  CONSTRAINT REGION_PK PRIMARY KEY (id_region),
  CONSTRAINT REGION_UN UNIQUE (nombre_region)
);

--------------------------------------------------------------------
-- COMUNA
--------------------------------------------------------------------
CREATE TABLE COMUNA (
  id_comuna        NUMBER(5) DEFAULT SEQ_COMUNA.NEXTVAL NOT NULL,
  nombre_comuna    VARCHAR2(80) NOT NULL,
  REGION_id_region NUMBER(4) NOT NULL,
  CONSTRAINT COMUNA_PK PRIMARY KEY (id_comuna),
  CONSTRAINT COMUNA_REGION_FK FOREIGN KEY (REGION_id_region)
    REFERENCES REGION(id_region)
);

--------------------------------------------------------------------
-- PLANTA
--------------------------------------------------------------------
CREATE TABLE PLANTA (
  id_planta        NUMBER(4) NOT NULL,
  nombre_planta    VARCHAR2(80) NOT NULL,
  direccion        VARCHAR2(150) NOT NULL,
  COMUNA_id_comuna NUMBER(5) NOT NULL,
  CONSTRAINT PLANTA_PK PRIMARY KEY (id_planta),
  CONSTRAINT PLANTA_COMUNA_FK FOREIGN KEY (COMUNA_id_comuna)
    REFERENCES COMUNA(id_comuna)
);

--------------------------------------------------------------------
-- AFP / SALUD
--------------------------------------------------------------------
CREATE TABLE AFP (
  id_afp NUMBER(4) NOT NULL,
  nombre_afp VARCHAR2(60) NOT NULL,
  CONSTRAINT AFP_PK PRIMARY KEY (id_afp),
  CONSTRAINT AFP_UN UNIQUE (nombre_afp)
);

CREATE TABLE SALUD (
  id_salud NUMBER(4) NOT NULL,
  nombre_salud VARCHAR2(60) NOT NULL,
  CONSTRAINT SALUD_PK PRIMARY KEY (id_salud),
  CONSTRAINT SALUD_UN UNIQUE (nombre_salud)
);

--------------------------------------------------------------------
-- TIPO_MAQUINA / MAQUINA
--------------------------------------------------------------------
CREATE TABLE TIPO_MAQUINA (
  id_tipo NUMBER(3) NOT NULL,
  nombre_tipo VARCHAR2(60) NOT NULL,
  CONSTRAINT TIPO_MAQUINA_PK PRIMARY KEY (id_tipo),
  CONSTRAINT TIPO_MAQUINA_UN UNIQUE (nombre_tipo)
);

CREATE TABLE MAQUINA (
  PLANTA_id_planta NUMBER(4) NOT NULL,
  num_maquina NUMBER(4) NOT NULL,
  nombre_maquina VARCHAR2(80) NOT NULL,
  activo CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N')),
  TIPO_MAQUINA_id_tipo NUMBER(3) NOT NULL,
  CONSTRAINT MAQUINA_PK PRIMARY KEY (PLANTA_id_planta, num_maquina),
  CONSTRAINT MAQUINA_PLANTA_FK FOREIGN KEY (PLANTA_id_planta)
     REFERENCES PLANTA(id_planta),
  CONSTRAINT MAQUINA_TIPO_FK FOREIGN KEY (TIPO_MAQUINA_id_tipo)
     REFERENCES TIPO_MAQUINA(id_tipo)
);

--------------------------------------------------------------------
-- TURNO
--------------------------------------------------------------------
CREATE TABLE TURNO (
  id_turno CHAR(6) NOT NULL,
  nombre_turno VARCHAR2(30) NOT NULL,
  hora_inicio CHAR(5) NOT NULL,
  hora_termino CHAR(5) NOT NULL,
  CONSTRAINT TURNO_PK PRIMARY KEY (id_turno),
  CONSTRAINT TURNO_UN UNIQUE (nombre_turno)
);

--------------------------------------------------------------------
-- CASO 2: Empleados y subtipos
--------------------------------------------------------------------
CREATE TABLE EMPLEADO (
  id_empleado NUMBER NOT NULL,
  rut NUMBER(9) NOT NULL,
  dv CHAR(1) NOT NULL,
  nombres VARCHAR2(80) NOT NULL,
  apellidos VARCHAR2(80) NOT NULL,
  fecha_contratacion DATE NOT NULL,
  sueldo_base NUMBER(10) NOT NULL,
  activo CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N')),
  tipo_empleado CHAR(12) NOT NULL
     CHECK (tipo_empleado IN ('JEFE_TURNO','OPERARIO','TECNICO_MANT')),
  PLANTA_id_planta NUMBER NOT NULL,
  SALUD_id_salud NUMBER NOT NULL,
  AFP_id_afp NUMBER NOT NULL,
  JEFE_DIRECTO_id_empleado NUMBER,
  CONSTRAINT EMPLEADO_PK PRIMARY KEY (id_empleado),
  CONSTRAINT EMPLEADO_RUT_UN UNIQUE (rut),
  CONSTRAINT EMPLEADO_PLANTA_FK FOREIGN KEY (PLANTA_id_planta)
    REFERENCES PLANTA(id_planta),
  CONSTRAINT EMPLEADO_SALUD_FK FOREIGN KEY (SALUD_id_salud)
    REFERENCES SALUD(id_salud),
  CONSTRAINT EMPLEADO_AFP_FK FOREIGN KEY (AFP_id_afp)
    REFERENCES AFP(id_afp),
  CONSTRAINT EMPLEADO_JEFE_FK FOREIGN KEY (JEFE_DIRECTO_id_empleado)
    REFERENCES EMPLEADO(id_empleado),
  CONSTRAINT CK_SUELDO CHECK (sueldo_base > 0),
  CONSTRAINT CK_FECHA CHECK (fecha_contratacion <= SYSDATE)
);

CREATE TABLE JEFE_TURNO (
  id_empleado NUMBER NOT NULL,
  area_responsabilidad VARCHAR2(80) NOT NULL,
  max_operarios NUMBER(3) NOT NULL,
  CONSTRAINT JEFE_TURNO_PK PRIMARY KEY (id_empleado),
  CONSTRAINT JEFE_TURNO_FK FOREIGN KEY (id_empleado)
    REFERENCES EMPLEADO(id_empleado)
);

CREATE TABLE OPERARIO (
  id_empleado NUMBER NOT NULL,
  categoria_proceso VARCHAR2(30) NOT NULL,
  certificacion VARCHAR2(80),
  horas_std_turno NUMBER(4,1) DEFAULT 8 NOT NULL,
  CONSTRAINT OPERARIO_PK PRIMARY KEY (id_empleado),
  CONSTRAINT OPERARIO_FK FOREIGN KEY (id_empleado)
    REFERENCES EMPLEADO(id_empleado)
);

CREATE TABLE TECNICO_MANT (
  id_empleado NUMBER NOT NULL,
  especialidad VARCHAR2(30) NOT NULL,
  nivel_certificacion VARCHAR2(40),
  tiempo_respuesta_estd NUMBER(5) NOT NULL,
  CONSTRAINT TECNICO_MANT_PK PRIMARY KEY (id_empleado),
  CONSTRAINT TECNICO_MANT_FK FOREIGN KEY (id_empleado)
    REFERENCES EMPLEADO(id_empleado)
);

--------------------------------------------------------------------
-- CASO 3: Asignaciones y Mantenciones
--------------------------------------------------------------------
CREATE TABLE ASIGNACION_TURNO (
  id_asig NUMBER NOT NULL,
  fecha DATE NOT NULL,
  rol VARCHAR2(40),
  EMPLEADO_id_empleado NUMBER NOT NULL,
  TURNO_id_turno CHAR(6) NOT NULL,
  MAQUINA_PLANTA_id_planta NUMBER NOT NULL,
  MAQUINA_num_maquina NUMBER NOT NULL,
  CONSTRAINT ASIGNACION_TURNO_PK PRIMARY KEY (id_asig),
  CONSTRAINT ASIGNACION_TURNO_UN UNIQUE (fecha, EMPLEADO_id_empleado),
  CONSTRAINT ASIGNACION_EMPLEADO_FK FOREIGN KEY (EMPLEADO_id_empleado)
     REFERENCES EMPLEADO(id_empleado),
  CONSTRAINT ASIGNACION_TURNO_FK FOREIGN KEY (TURNO_id_turno)
     REFERENCES TURNO(id_turno),
  CONSTRAINT ASIGNACION_MAQUINA_FK FOREIGN KEY 
     (MAQUINA_PLANTA_id_planta, MAQUINA_num_maquina)
     REFERENCES MAQUINA(PLANTA_id_planta, num_maquina)
);

CREATE TABLE MANTENCION (
  id_om NUMBER NOT NULL,
  fecha_programada DATE NOT NULL,
  fecha_ejecucion DATE,
  descripcion VARCHAR2(400),
  MAQUINA_PLANTA_id_planta NUMBER NOT NULL,
  MAQUINA_num_maquina NUMBER NOT NULL,
  TECNICO_MANT_id_empleado NUMBER NOT NULL,
  CONSTRAINT MANTENCION_PK PRIMARY KEY (id_om),
  CONSTRAINT MANTENCION_FK_MAQUINA FOREIGN KEY 
     (MAQUINA_PLANTA_id_planta, MAQUINA_num_maquina)
     REFERENCES MAQUINA(PLANTA_id_planta, num_maquina),
  CONSTRAINT MANTENCION_FK_TECNICO FOREIGN KEY (TECNICO_MANT_id_empleado)
     REFERENCES TECNICO_MANT(id_empleado),
  CONSTRAINT CK_MANTENCION_FECHAS CHECK (fecha_ejecucion >= fecha_programada)
);

--------------------------------------------------------------------
-- CASO 4: Poblamiento del modelo
--------------------------------------------------------------------

-- REGIÓN
INSERT INTO REGION VALUES (21,'Región de Valparaíso');
INSERT INTO REGION VALUES (22,'Región Metropolitana');

-- COMUNA
INSERT INTO COMUNA (id_comuna,nombre_comuna,REGION_id_region)
VALUES (1050,'Quilpué',21);
INSERT INTO COMUNA (id_comuna,nombre_comuna,REGION_id_region)
VALUES (1055,'Maipú',22);

-- PLANTA
INSERT INTO PLANTA VALUES (45,'Planta Oriente','Camino Industrial 1234',1050);
INSERT INTO PLANTA VALUES (46,'Planta Costa','Av. Vidrieras 890',1055);

-- AFP / SALUD
INSERT INTO AFP VALUES (1,'Provida');
INSERT INTO AFP VALUES (2,'Cuprum');
INSERT INTO SALUD VALUES (1,'Fonasa');
INSERT INTO SALUD VALUES (2,'Isapre Colmena');

-- TIPO_MAQUINA y MAQUINA
INSERT INTO TIPO_MAQUINA VALUES (1,'Línea IS');
INSERT INTO TIPO_MAQUINA VALUES (2,'Equipo de Empaque');
INSERT INTO TIPO_MAQUINA VALUES (3,'Horno de Fusión');

INSERT INTO MAQUINA VALUES (45,100,'Línea IS 01','S',1);
INSERT INTO MAQUINA VALUES (45,200,'Horno 01','S',3);
INSERT INTO MAQUINA VALUES (46,300,'Empacadora 02','S',2);

-- TURNO
INSERT INTO TURNO VALUES ('M0715','Mañana','07:00','15:00');
INSERT INTO TURNO VALUES ('T1523','Tarde','15:00','23:00');
INSERT INTO TURNO VALUES ('N2307','Noche','23:00','07:00');

-- EMPLEADOS Y SUBTIPOS
INSERT INTO EMPLEADO VALUES (1,12345678,'K','Carlos','Muñoz',DATE '2020-01-15',950000,'S','JEFE_TURNO',45,1,1,NULL);
INSERT INTO EMPLEADO VALUES (2,16789012,'3','María','López',DATE '2021-05-10',750000,'S','OPERARIO',45,2,2,1);
INSERT INTO EMPLEADO VALUES (3,18567234,'2','José','Ramírez',DATE '2022-03-05',820000,'S','TECNICO_MANT',46,1,1,1);

INSERT INTO JEFE_TURNO VALUES (1,'Líneas de Producción',10);
INSERT INTO OPERARIO VALUES (2,'Caliente','Certificación A1',8);
INSERT INTO TECNICO_MANT VALUES (3,'Mecánica','Nivel 2',60);

-- ASIGNACIÓN DE TURNOS
INSERT INTO ASIGNACION_TURNO VALUES (1,DATE '2025-10-10','Moldeador',2,'M0715',45,100);
INSERT INTO ASIGNACION_TURNO VALUES (2,DATE '2025-10-10','Técnico Mecánico',3,'T1523',46,300);

-- MANTENCIONES
INSERT INTO MANTENCION VALUES (1,DATE '2025-10-01',DATE '2025-10-02','Cambio de sello hidráulico en Horno 01',45,200,3);
INSERT INTO MANTENCION VALUES (2,DATE '2025-10-05',NULL,'Programación de mantenimiento preventivo IS 01',45,100,3);

COMMIT;

--------------------------------------------------------------------
-- CASO 5: Recuperación de Datos / Informes
--------------------------------------------------------------------

-- INFORME 1: Listado de empleados con su planta y tipo
SELECT 
  e.id_empleado AS "ID EMPLEADO",
  e.nombres || ' ' || e.apellidos AS "NOMBRE COMPLETO",
  e.tipo_empleado AS "CARGO",
  p.nombre_planta AS "PLANTA",
  e.sueldo_base AS "SUELDO"
FROM EMPLEADO e
JOIN PLANTA p ON e.PLANTA_id_planta = p.id_planta
ORDER BY e.tipo_empleado, e.sueldo_base DESC;

-- INFORME 2: Asignaciones del 10 de octubre de 2025
SELECT 
  a.id_asig AS "ID ASIGNACION",
  a.fecha AS "FECHA",
  e.nombres || ' ' || e.apellidos AS "EMPLEADO",
  a.rol AS "ROL EN TURNO",
  m.nombre_maquina AS "MAQUINA",
  t.nombre_turno AS "TURNO"
FROM ASIGNACION_TURNO a
JOIN EMPLEADO e ON a.EMPLEADO_id_empleado = e.id_empleado
JOIN MAQUINA m ON a.MAQUINA_PLANTA_id_planta = m.PLANTA_id_planta AND a.MAQUINA_num_maquina = m.num_maquina
JOIN TURNO t ON a.TURNO_id_turno = t.id_turno
WHERE a.fecha = DATE '2025-10-10'
ORDER BY e.nombres;

-- INFORME 3: Mantenciones realizadas y pendientes
SELECT 
  m.id_om AS "ID ORDEN",
  maq.nombre_maquina AS "MAQUINA",
  m.fecha_programada AS "FECHA PROGRAMADA",
  m.fecha_ejecucion AS "FECHA EJECUTADA",
  CASE 
    WHEN m.fecha_ejecucion IS NULL THEN 'Pendiente'
    ELSE 'Completada'
  END AS "ESTADO",
  t.nombres || ' ' || t.apellidos AS "TECNICO RESPONSABLE"
FROM MANTENCION m
JOIN MAQUINA maq ON m.MAQUINA_PLANTA_id_planta = maq.PLANTA_id_planta AND m.MAQUINA_num_maquina = maq.num_maquina
JOIN EMPLEADO t ON m.TECNICO_MANT_id_empleado = t.id_empleado
ORDER BY m.fecha_programada;

COMMIT;
