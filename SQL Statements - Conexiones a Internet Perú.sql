--DATA MODELING:Departamento,Empresa,Total de conexiones fijas y wifi separado por tipo de red
WITH
  wifi AS(
    SELECT
      TRIM(Region) AS Region,Empresa_Operadora,
      SUM(_2G) AS _2G,
      SUM(_3G) AS _3G,
      SUM(_4G) AS _4G,
      SUM(_5G) AS _5G
    FROM `conexion-internet-peru.OSIPTEL.wifi_estaciones`
    GROUP BY Region,Empresa_Operadora
    ORDER BY Region
  )
SELECT
  conFijas.Departamento,
  conFijas.Empresa,
  SUM(conFijas.Conexiones) AS TotalConexiones,
  SUM(wifi._2G) AS Total2G,
  SUM(wifi._3G) AS Total3G,
  SUM(wifi._4G) AS Total4G,
  SUM(wifi._5G) AS Total5G
FROM `conexion-internet-peru.OSIPTEL.conexiones_fijas` AS conFijas
FULL JOIN wifi
  ON wifi.Region = UPPER(conFijas.Departamento)
  AND wifi.Empresa_Operadora = conFijas.Empresa
WHERE
  Mes BETWEEN '2022-01-01' AND '2022-12-31'
  AND Segmento = 'Residencial'
GROUP BY Departamento, Empresa
ORDER BY Departamento, TotalConexiones DESC;


-- ANÁLISIS 1:
-- PORCENTAJE DE VIVIENDAS QUE TIENEN ACCESO A INTERNET EN LAS DISTINTAS REGIONES DEL PERÚ
-- AL PRIMER TRIMESTRE DEL 2022 EN EL SEGMENTO RESIDENCIAL
WITH
  ConexionDepartamento AS(
    SELECT
      CASE
        WHEN Departamento LIKE '%á%' THEN REPLACE(Departamento,'á','a')
        WHEN Departamento LIKE '%í%' THEN REPLACE(Departamento,'í','i')
        ELSE Departamento
      END AS Departamento,
      SUM(Conexiones) AS Conexiones
    FROM `conexion-internet-peru.OSIPTEL.conexiones_fijas`
    WHERE
      Mes BETWEEN '2022-01-01' AND '2022-03-31'
      AND Segmento = 'Residencial'
    GROUP BY Departamento
    ORDER BY Departamento,Conexiones DESC
  ),

  Viviendas_2022 AS(
    SELECT
      DEPARTAMENTO,
      VIVIENDAS_2017 + (INCREMENTO_ANUAL * 4) AS VIVIENDAS_2022
    FROM `conexion-internet-peru.INEI.viviendas_peru`
  )
SELECT
  cD.Departamento,
  cD.Conexiones,
  viviendas.VIVIENDAS_2022,
  ROUND((cD.Conexiones / viviendas.VIVIENDAS_2022) * 100,2) AS Porcentaje
FROM ConexionDepartamento AS cD
FULL JOIN Viviendas_2022 AS viviendas
  ON viviendas.DEPARTAMENTO = UPPER(cD.Departamento)
ORDER BY Porcentaje DESC;


-- ANÁLISIS 2:
--LAS 3 PRINCIPALES EMPRESAS QUE BRINDAN SERVICIO DE INTERNET EN EL PERÚ
--AL PRIMER TRIMESTRE DEL 2022 EN EL SEGMENTO RESIDENCIAL
WITH empresasConexiones AS (
  SELECT Empresa, SUM(Conexiones) AS Conexiones
  FROM `conexion-internet-peru.OSIPTEL.conexiones_fijas`
  WHERE
    Mes BETWEEN '2022-01-01' AND '2022-03-31'
    AND Segmento = 'Residencial'
  GROUP BY Empresa
)
SELECT
  Empresa,
  Conexiones,
  ROUND(Conexiones / SUM(Conexiones) OVER() * 100,2) AS Porcentaje
FROM empresasConexiones
ORDER BY Conexiones DESC
LIMIT 3;


-- ANÁLISIS 3:
--TECNOLOGÍA DE ACCESO A INTERNET MÁS USADA EN EL PERÚ
--EN EL PRIMER TRIMESTRE DEL 2022 EN EL SEGMENTO RESIDENCIAL
WITH conTec AS (
  SELECT Tecnologia,SUM(Conexiones) AS Conexiones
  FROM `conexion-internet-peru.OSIPTEL.conexiones_fijas`
  WHERE
    Mes BETWEEN '2022-01-01' AND '2022-03-31'
    AND Segmento = 'Residencial'
  GROUP BY Tecnologia
)
SELECT
  Tecnologia,
  Conexiones,
  ROUND(Conexiones/SUM(Conexiones) OVER() * 100,2) AS Porcentaje
FROM conTec
ORDER BY Conexiones DESC;


-- ANÁLISIS 4:
--RELACIÓN ENTRE EL NÚMERO DE CONEXIONES FIJAS A INTERNET Y LA CANTIDAD DE 
--ESTACIONES BASE PARA TECNOLOGÍA WIFI EN LAS DISTINTAS REGIONES DEL PERÚ
WITH
  wifi AS(
    SELECT
      TRIM(Region) AS Region,
      SUM(IFNULL(_2G,0)) AS _2G,
      SUM(IFNULL(_3G,0)) AS _3G,
      SUM(IFNULL(_4G,0)) AS _4G,
      SUM(IFNULL(_5G,0)) AS _5G
    FROM `conexion-internet-peru.OSIPTEL.wifi_estaciones`
    GROUP BY Region
    ORDER BY Region
  ),
  fijas AS(
    SELECT
      CASE
        WHEN Departamento LIKE '%á%' THEN REPLACE(Departamento,'á','a')
        WHEN Departamento LIKE '%í%' THEN REPLACE(Departamento,'í','i')
        ELSE Departamento
      END AS Departamento,
      SUM(Conexiones) AS Conexiones
    FROM `conexion-internet-peru.OSIPTEL.conexiones_fijas`
    WHERE
      Mes BETWEEN '2022-01-01' AND '2022-03-31'
      AND Segmento = 'Residencial'
    GROUP BY Departamento
  )
SELECT
  Departamento,
  Conexiones,
  (wifi._2G + wifi._3G + wifi._4G + wifi._5G) AS Total_Estaciones
FROM fijas
FULL JOIN wifi
  ON wifi.Region = UPPER(fijas.Departamento)
ORDER BY Conexiones DESC;
