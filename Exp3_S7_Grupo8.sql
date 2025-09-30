--------------------------------------------------------------------
-- LIMPIEZA
--------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE TITULACION CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE DOMINIO CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE PERSONAL CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE COMPANIA CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE COMUNA CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE REGION CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE ESTADO_CIVIL CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE GENERO CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE TITULO CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE IDIOMA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
--------------------------------------------------------------------
-- TABLAS BASE
--------------------------------------------------------------------
CREATE TABLE REGION (
  id_region      NUMBER(2) NOT NULL,
  nombre_region  VARCHAR2(25) NOT NULL,
  CONSTRAINT REGION_PK PRIMARY KEY (id_region)
);

CREATE TABLE COMUNA (
  id_comuna     NUMBER(5) NOT NULL,
  comuna_nombre VARCHAR2(25) NOT NULL,
  cod_region    NUMBER(2) NOT NULL,
  CONSTRAINT COMUNA_PK PRIMARY KEY (id_comuna, cod_region),
  CONSTRAINT COMUNA_FK_REGION FOREIGN KEY (cod_region)
    REFERENCES REGION(id_region)
);

CREATE TABLE ESTADO_CIVIL (
  id_estado_civil    VARCHAR2(2) NOT NULL,
  descripcion_est_civil VARCHAR2(25) NOT NULL,
  CONSTRAINT ESTADO_CIVIL_PK PRIMARY KEY (id_estado_civil)
);

CREATE TABLE GENERO (
  id_genero        VARCHAR2(3) NOT NULL,
  descripcion_genero VARCHAR2(25) NOT NULL,
  CONSTRAINT GENERO_PK PRIMARY KEY (id_genero)
);

CREATE TABLE TITULO (
  id_titulo        VARCHAR2(3) NOT NULL,
  descripcion_titulo VARCHAR2(60) NOT NULL,
  CONSTRAINT TITULO_PK PRIMARY KEY (id_titulo)
);

CREATE TABLE IDIOMA (
  id_idioma      NUMBER(3) NOT NULL,
  nombre_idioma  VARCHAR2(30) NOT NULL,
  CONSTRAINT IDIOMA_PK PRIMARY KEY (id_idioma)
);

--------------------------------------------------------------------
-- TABLAS PRINCIPALES
--------------------------------------------------------------------
CREATE TABLE COMPANIA (
  id_empresa      NUMBER(2) NOT NULL,
  nombre_empresa  VARCHAR2(25) NOT NULL,
  calle           VARCHAR2(50) NOT NULL,
  numeracion      NUMBER(5) NOT NULL,
  renta_promedio  NUMBER(10) NOT NULL,
  pct_aumento     NUMBER(4,3),
  cod_comuna      NUMBER(5) NOT NULL,
  cod_region      NUMBER(2) NOT NULL,
  CONSTRAINT COMPANIA_PK PRIMARY KEY (id_empresa),
  CONSTRAINT COMPANIA_UN_NOMBRE UNIQUE (nombre_empresa),
  CONSTRAINT COMPANIA_FK_COMUNA FOREIGN KEY (cod_comuna, cod_region)
    REFERENCES COMUNA(id_comuna, cod_region)
);

CREATE TABLE PERSONAL (
  rut_persona     NUMBER(8) NOT NULL,
  dv_persona      CHAR(1) NOT NULL,
  primer_nombre   VARCHAR2(25) NOT NULL,
  segundo_nombre  VARCHAR2(25),
  primer_apellido VARCHAR2(25) NOT NULL,
  segundo_apellido VARCHAR2(25) NOT NULL,
  fecha_contratacion DATE NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  email           VARCHAR2(100),
  calle           VARCHAR2(50) NOT NULL,
  numeracion      NUMBER(5) NOT NULL,
  sueldo          NUMBER(5) NOT NULL,
  cod_comuna      NUMBER(5) NOT NULL,
  cod_region      NUMBER(2) NOT NULL,
  cod_genero      VARCHAR2(3),
  cod_estado_civil VARCHAR2(2),
  cod_empresa     NUMBER(2) NOT NULL,
  encargado_rut   NUMBER(8),
  CONSTRAINT PERSONAL_PK PRIMARY KEY (rut_persona),
  CONSTRAINT PERSONAL_FK_COMPANIA FOREIGN KEY (cod_empresa)
    REFERENCES COMPANIA(id_empresa),
  CONSTRAINT PERSONAL_FK_COMUNA FOREIGN KEY (cod_comuna, cod_region)
    REFERENCES COMUNA(id_comuna, cod_region),
  CONSTRAINT PERSONAL_FK_ESTADO_CIVIL FOREIGN KEY (cod_estado_civil)
    REFERENCES ESTADO_CIVIL(id_estado_civil),
  CONSTRAINT PERSONAL_FK_GENERO FOREIGN KEY (cod_genero)
    REFERENCES GENERO(id_genero),
  CONSTRAINT PERSONAL_PERSONAL_FK FOREIGN KEY (encargado_rut)
    REFERENCES PERSONAL(rut_persona)
);

--------------------------------------------------------------------
-- RELACIONES MUCHOS A MUCHOS
--------------------------------------------------------------------
-- TITULACION (relación Persona ↔ Titulo)
CREATE TABLE TITULACION (
  cod_titulo      VARCHAR2(3) NOT NULL,
  persona_rut     NUMBER(8) NOT NULL,
  fecha_titulacion DATE NOT NULL,
  CONSTRAINT TITULACION_PK PRIMARY KEY (cod_titulo, persona_rut),
  CONSTRAINT TITULACION_FK_PERSONAL FOREIGN KEY (persona_rut)
    REFERENCES PERSONAL(rut_persona),
  CONSTRAINT TITULACION_FK_TITULO FOREIGN KEY (cod_titulo)
    REFERENCES TITULO(id_titulo)
);

-- DOMINIO (relación Persona ↔ Idioma con nivel)
CREATE TABLE DOMINIO (
  id_idioma   NUMBER(3) NOT NULL,
  persona_rut NUMBER(8) NOT NULL,
  nivel       VARCHAR2(25),
  CONSTRAINT DOMINIO_PK PRIMARY KEY (id_idioma, persona_rut),
  CONSTRAINT DOMINIO_FK_IDIOMA FOREIGN KEY (id_idioma)
    REFERENCES IDIOMA(id_idioma),
  CONSTRAINT DOMINIO_FK_PERSONAL FOREIGN KEY (persona_rut)
    REFERENCES PERSONAL(rut_persona)
);

commit;



--------------------------------------------------------------------
-- CASO 2: Reglas de negocio adicionales
--------------------------------------------------------------------

-- 1. Email de PERSONAL es opcional pero no debe repetirse
ALTER TABLE PERSONAL
  ADD CONSTRAINT UN_PERSONAL_EMAIL UNIQUE (email);

-- 2. Dígito verificador (dv_persona) debe estar en {0-9, K}
ALTER TABLE PERSONAL
  ADD CONSTRAINT CK_PERSONAL_DV
  CHECK (REGEXP_LIKE(dv_persona, '^[0-9K]$'));

-- 3. Sueldo mínimo de 450.000 pesos
ALTER TABLE PERSONAL
  ADD CONSTRAINT CK_PERSONAL_SUELDO
  CHECK (sueldo >= 450000);
  
  
--------------------------------------------------------------------
-- CASO 3: Poblamiento de Modelo
--------------------------------------------------------------------

-- 1. Secuencia para COMUNA
CREATE SEQUENCE SEQ_COMUNA
  START WITH 1101
  INCREMENT BY 6
  NOCACHE;

-- 2. Secuencia para COMPANIA
CREATE SEQUENCE SEQ_COMPANIA
  START WITH 10
  INCREMENT BY 5
  NOCACHE;

--------------------------------------------------------------------
-- Insertando datos en REGION
--------------------------------------------------------------------
INSERT INTO REGION (id_region, nombre_region) VALUES (7, 'ARICA Y PARINACOTA');
INSERT INTO REGION (id_region, nombre_region) VALUES (9, 'METROPOLITANA');
INSERT INTO REGION (id_region, nombre_region) VALUES (11, 'LA ARAUCANIA');

--------------------------------------------------------------------
-- Insertando datos en COMUNA
--------------------------------------------------------------------
INSERT INTO COMUNA (id_comuna, comuna_nombre, cod_region)
VALUES (1101, 'Arica', 7);

INSERT INTO COMUNA (id_comuna, comuna_nombre, cod_region)
VALUES (1107, 'Santiago', 9);

INSERT INTO COMUNA (id_comuna, comuna_nombre, cod_region)
VALUES (1113, 'Temuco', 11);

--------------------------------------------------------------------
-- Insertando datos en IDIOMA
--------------------------------------------------------------------
INSERT INTO IDIOMA (id_idioma, nombre_idioma) VALUES (25, 'Ingles');
INSERT INTO IDIOMA (id_idioma, nombre_idioma) VALUES (28, 'Chino');
INSERT INTO IDIOMA (id_idioma, nombre_idioma) VALUES (31, 'Aleman');
INSERT INTO IDIOMA (id_idioma, nombre_idioma) VALUES (34, 'Espanol');
INSERT INTO IDIOMA (id_idioma, nombre_idioma) VALUES (37, 'Frances');

--------------------------------------------------------------------
-- Insertando datos en COMPANIA
--------------------------------------------------------------------
INSERT INTO COMPANIA (id_empresa, nombre_empresa, calle, numeracion,
                      renta_promedio, pct_aumento, cod_comuna, cod_region)
VALUES (10, 'CCyRojas', 'Amapolas', 506, 1857000, 0.5, 1101, 7);

INSERT INTO COMPANIA (id_empresa, nombre_empresa, calle, numeracion,
                      renta_promedio, pct_aumento, cod_comuna, cod_region)
VALUES (15, 'SenTTy', 'Los Alamos', 3490, 897000, 0.025, 1101, 7);

INSERT INTO COMPANIA (id_empresa, nombre_empresa, calle, numeracion,
                      renta_promedio, pct_aumento, cod_comuna, cod_region)
VALUES (20, 'Praxia LTDA', 'Las Camelias', 11098, 2157000, 0.035, 1107, 9);

INSERT INTO COMPANIA (id_empresa, nombre_empresa, calle, numeracion,
                      renta_promedio, pct_aumento, cod_comuna, cod_region)
VALUES (25, 'TIC spa', 'FLORES S.A.', 4357, 857000, NULL, 1107, 9);

INSERT INTO COMPANIA (id_empresa, nombre_empresa, calle, numeracion,
                      renta_promedio, pct_aumento, cod_comuna, cod_region)
VALUES (30, 'SANTANA LTDA', 'AVDA VIC. MACKENA', 106, 757000, 0.015, 1107, 9);

INSERT INTO COMPANIA (id_empresa, nombre_empresa, calle, numeracion,
                      renta_promedio, pct_aumento, cod_comuna, cod_region)
VALUES (35, 'FLORES Y ASOCIADOS', 'PEDRO LATORRE', 557, 589000, 0.015, 1107, 9);

INSERT INTO COMPANIA (id_empresa, nombre_empresa, calle, numeracion,
                      renta_promedio, pct_aumento, cod_comuna, cod_region)
VALUES (40, 'J.A. HOFFMAN', 'LATINA D.32', 509, 1857000, 0.025, 1113, 11);

INSERT INTO COMPANIA (id_empresa, nombre_empresa, calle, numeracion,
                      renta_promedio, pct_aumento, cod_comuna, cod_region)
VALUES (45, 'CAGLIARI D.', 'ALAMEDA', 206, 1857000, NULL, 1107, 9);

INSERT INTO COMPANIA (id_empresa, nombre_empresa, calle, numeracion,
                      renta_promedio, pct_aumento, cod_comuna, cod_region)
VALUES (50, 'Rojas HNOS LTDA', 'SUCRE', 106, 957000, 0.005, 1113, 11);

INSERT INTO COMPANIA (id_empresa, nombre_empresa, calle, numeracion,
                      renta_promedio, pct_aumento, cod_comuna, cod_region)
VALUES (55, 'FRIENDS P. S.A', 'SUECIA', 506, 857000, 0.015, 1113, 11);

COMMIT;

--------------------------------------------------------------------
-- CASO 4: Reportes
--------------------------------------------------------------------


  -- INFORME 1
-- Nombre empresa, dirección completa, renta promedio,
-- renta simulada con aumento.
-- Ordenar por renta promedio DESC y nombre ASC.
SELECT 
    c.nombre_empresa AS "Nombre Empresa",
    c.calle || ' ' || c.numeracion AS "Dirección",
 c.renta_promedio AS "Renta Promedio",
    CASE 
        WHEN (c.renta_promedio * (1 + NVL(c.pct_aumento,0))) = c.renta_promedio 
             THEN NULL
        ELSE (c.renta_promedio * (1 + NVL(c.pct_aumento,0)))
    END AS "Simulación de Renta"
FROM COMPANIA c
JOIN COMUNA cm 
     ON c.cod_comuna = cm.id_comuna 
    AND c.cod_region = cm.cod_region
JOIN REGION r 
     ON c.cod_region = r.id_region
ORDER BY "Renta Promedio" DESC, "Nombre Empresa" ASC;

-- INFORME 2
-- ID empresa, nombre, renta promedio actual,
-- porcentaje aumentado en 15%, renta incrementada.
-- Ordenar por renta actual ASC y nombre DESC.
SELECT 
    c.id_empresa     AS "Código",
    c.nombre_empresa AS "Empresa",
    c.renta_promedio AS "Prom Renta Actual",
    CASE
        WHEN (c.renta_promedio * (1 + NVL(c.pct_aumento,0))) = c.renta_promedio 
             THEN NULL
        ELSE (NVL(c.pct_aumento,0) + 0.15)
    END AS "Pct Aumentado en 15%",
    CASE
        WHEN (c.renta_promedio * (1 + NVL(c.pct_aumento,0))) = c.renta_promedio 
             THEN NULL
        ELSE (c.renta_promedio * (1 + (NVL(c.pct_aumento,0) + 0.15)))
    END AS "Renta Aumentada"
FROM COMPANIA c
ORDER BY "Prom Renta Actual" ASC, "Empresa" DESC;

