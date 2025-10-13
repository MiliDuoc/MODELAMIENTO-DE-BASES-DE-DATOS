--------------------------------------------------------------------
-- PRY2204 - EXP3 - SEMANA 9
-- Cristalería Andina S.A. – Asignación de Turnos y Mantenciones
--------------------------------------------------------------------

--------------------------------------------------------------------
-- LIMPIEZA (Drop en orden inverso de dependencias)
--------------------------------------------------------------------
BEGIN
  FOR rec IN (SELECT object_name, object_type
              FROM user_objects
              WHERE object_type IN ('TABLE','SEQUENCE')) LOOP
    BEGIN
      IF rec.object_type = 'TABLE' THEN
        EXECUTE IMMEDIATE 'DROP TABLE "' || rec.object_name || '" CASCADE CONSTRAINTS';
      ELSIF rec.object_type = 'SEQUENCE' THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE "' || rec.object_name || '"';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/

--------------------------------------------------------------------
-- CASO 1: Tablas base y catálogos
--------------------------------------------------------------------

-- SECUENCIAS
CREATE SEQUENCE SEQ_REGION START WITH 21 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_COMUNA START WITH 1050 INCREMENT BY 5 NOCACHE;

--------------------------------------------------------------------
-- REGION
--------------------------------------------------------------------
CREATE TABLE REGION (
  id_region     NUMBER(4)    NOT NULL,
  nombre_region VARCHAR2(60) NOT NULL,
  CONSTRAINT REGION_PK PRIMARY KEY (id_region),
  CONSTRAINT REGION_NOMBRE_UN UNIQUE (nombre_region)
);

--------------------------------------------------------------------
-- COMUNA
--------------------------------------------------------------------
CREATE TABLE COMUNA (
  id_comuna NUMBER(5) GENERATED ALWAYS AS IDENTITY (START WITH 1050 INCREMENT BY 5),
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
  CONSTRAINT CK_SUELDO CHECK (sueldo_base > 0)
);

CREATE OR REPLACE TRIGGER TRG_FECHA_CONTRATACION
BEFORE INSERT OR UPDATE ON EMPLEADO
FOR EACH ROW
BEGIN
  IF :NEW.fecha_contratacion > SYSDATE THEN
    RAISE_APPLICATION_ERROR(-20001, 'La fecha de contratacion no puede ser futura');
  END IF;
END;
/


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
INSERT INTO REGION VALUES (SEQ_REGION.NEXTVAL,'Región de Valparaíso');
INSERT INTO REGION VALUES (SEQ_REGION.NEXTVAL,'Región Metropolitana');

-- COMUNA
INSERT INTO COMUNA (nombre_comuna, REGION_id_region)
VALUES ('Quilpué', 21);
INSERT INTO COMUNA (nombre_comuna, REGION_id_region)
VALUES ('Maipú', 22);


-- PLANTA
INSERT INTO PLANTA VALUES (45,'Planta Oriente','Camino Industrial 1234',1050);
INSERT INTO PLANTA VALUES (46,'Planta Costa','Av. Vidrieras 890',1055);


-- TURNO
INSERT INTO TURNO VALUES ('M0715','Mañana','07:00','15:00');
INSERT INTO TURNO VALUES ('T1523','Tarde','15:00','23:00');
INSERT INTO TURNO VALUES ('N2307','Noche','23:00','07:00');

--------------------------------------------------------------------
-- CASO 5: Recuperación de Datos / Informes
--------------------------------------------------------------------

--------------------------------------------------------------------
-- INFORME 1: LISTADO DE TURNOS CON FORMATO "ID - NOMBRE"
--------------------------------------------------------------------
SELECT 
    id_turno || ' - ' || nombre_turno AS "TURNO",
    hora_inicio AS "ENTRADA",
    hora_termino AS "SALIDA"
FROM TURNO
WHERE hora_inicio>'20:00'
ORDER BY hora_inicio DESC;
--------------------------------------------------------------------
-- INFORME 2: Turnos diurnos (inicio entre 06:00 y 14:59)
-- Ordenado por hora de inicio ascendente
--------------------------------------------------------------------

SELECT 
    nombre_turno || ' (' || id_turno || ')' AS "TURNO",
    hora_inicio AS "ENTRADA",
    hora_termino AS "SALIDA"
FROM TURNO
WHERE hora_inicio BETWEEN '06:00' AND '14:59'
ORDER BY hora_inicio ASC;
COMMIT;
