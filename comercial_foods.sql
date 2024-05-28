-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 23-05-2024 a las 16:57:49
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.1.25

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `comercial_foods`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `abono_factura` (IN `valor` DECIMAL(10,0), IN `nfact` INT)   BEGIN 
UPDATE cartera SET abonos=abonos+valor
WHERE cod_factura=nfact;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `actualiza_credito` ()   BEGIN
    UPDATE cartera SET pagada = 'S'
    WHERE saldo<= 0;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `actualiza_entrada` ()   BEGIN
DECLARE var_producod int;
DECLARE var_cantidad int;
DECLARE var_final int DEFAULT 0;
DECLARE c1 CURSOR FOR SELECT producto_cod, cantidad FROM entrada_detalle;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET var_final=1;
OPEN c1;
bucle: LOOP
	FETCH c1 INTO var_producod, var_cantidad; -- empieza desde 1er registro de consulta factura_detalle
    IF var_final=1 THEN
    LEAVE bucle;
    END if; 
    UPDATE productos SET existencia=existencia+var_cantidad
    WHERE cod_producto=var_producod;
   END LOOP bucle;
   SELECT cod_producto, existencia FROM productos;
CLOSE c1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `actualiza_salida` ()   BEGIN 
DECLARE var_producod int;
DECLARE var_cantidad int;
DECLARE var_final int DEFAULT 0;
DECLARE c1 CURSOR FOR SELECT producto_cod,cantidad FROM factura_detalle;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET var_final=1;
OPEN c1;
bucle:LOOP
FETCH c1 INTO var_producod, var_cantidad; -- empieza desde 1er registro de consulta factura_detalle
IF var_final=1 THEN
LEAVE bucle;
END IF;
UPDATE productos SET existencia=existencia-var_cantidad
WHERE cod_producto=var_producod;
END LOOP bucle;
SELECT cod_producto, existencia FROM productos;
CLOSE c1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `calcula_nomina` (IN `fechanom` DATE, IN `cod_emp` INT, IN `salario` DECIMAL(10,0), IN `diastb` INT, IN `nhrn` INT, IN `presta` DECIMAL(10,0))   BEGIN
    DECLARE smiv DECIMAL(10,0);
    DECLARE auxtte DECIMAL(10,0);
    DECLARE subtte DECIMAL(10,0);
    SET smiv = 1300000; -- Corregido el valor del salario mínimo legal vigente
    SET auxtte = 162000;
    
    IF salario <= 2 * smiv THEN
        SET subtte = auxtte / 30 * diastb;
    ELSE
        SET subtte = 0;
    END IF;
    
    INSERT INTO nomina (fecha_nomina, empleado_cod, salario_base, dias_trabajados, auxilio_transporte, no_hrecargo, prestamos)
    VALUES (fechanom, cod_emp, salario, diastb, subtte, nhrn, presta);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `consulta_ventaciudad` (IN `dato` VARCHAR(50))   BEGIN
SELECT * FROM cliente
WHERE ciudad=dato ;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `contar_productos` (IN `dato` VARCHAR(50), OUT `total` INT UNSIGNED)   BEGIN
   SET total=(
       SELECT COUNT(*)
       FROM productos
       WHERE productos.proveedor_cod=dato);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `inactiva_cliente` ()   BEGIN 
DECLARE var_codcli int;
DECLARE var_saldo decimal(10,0);
DECLARE var_dias int;
DECLARE var_final int DEFAULT 0;
DECLARE c1 CURSOR FOR SELECT cliente_cod, dias_mora, saldo FROM cartera;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET var_final=1;
OPEN c1;
bucle: LOOP
FETCH c1 INTO var_codcli, var_dias,var_saldo;
IF var_final=1 THEN
LEAVE bucle;
END IF;
-- instrucciones a realizar en el procedimiento
IF var_dias>0 AND var_saldo>0 THEN
UPDATE cliente SET activo="I"
WHERE cod_cliente=var_codcli;
END IF;
END LOOP bucle;
-- consultar tabla cliente para verificar y reactivacion
SELECT cod_cliente, activo FROM cliente 
WHERE activo="I";
CLOSE c1;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `promedad` () RETURNS INT(11)  BEGIN
DECLARE suma int;
DECLARE total int;
DECLARE edadp int;
DECLARE i int;
-- secciond de creacion de nombre del cursor 
DECLARE c1 CURSOR FOR SELECT edad FROM cliente;
-- seccion de asignacion de valores a variables
SET suma=0; -- acumulador de edad
SET i=1; -- contador ciclo whil
SET total=0; -- contador de cantidad de clientes en tabla
SELECT COUNT(*) INTO total FROM cliente; -- para hallar los registros en tabla
-- apertura del cursor
OPEN c1;
-- secciondel ciclo while
WHILE i<=total DO
	FETCH c1 INTO edadp; -- revisar cada fila de la consulta de conteo de registro
    SET suma= suma*edadp; -- totalizador de edades
    SET i=i+1; -- contador de edad 
END WHILE; 
-- cierre del cursor
CLOSE c1;
RETURN suma/total; -- para generar promedio de edad
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `salario_mayor2` () RETURNS VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_general_ci  BEGIN
DECLARE var_codemp int;
DECLARE var_nombre varchar(25);
DECLARE var_apellido varchar(25);
DECLARE var_netop decimal(10,0);
DECLARE mayor decimal(10,0);
DECLARE total int;
DECLARE i int;
DECLARE resultado varchar(100);
-- seccion de creacion de cursos para consulta select
DECLARE c1 CURSOR FOR SELECT t1.empleado_cod,t2.nombre1,t2.apellido1,t1.neto_pagar
FROM nomina t1 INNER JOIN empleado t2 ON t1.empleado_cod=t2.cod_empleado;
Set mayor=0;
set i=1;
SET total=0;
-- conteo de registros en tala nomina 
SELECT COUNT(*) INTO total FROM nomina;
-- apertura cursor
OPEN c1;
WHILE i<=total DO 
   FETCH c1 INTO var_codemp,var_nombre,var_apellido,var_netop;
   IF var_netop>mayor THEN 
   set resultado=concat(var_codemp,' ',var_nombre,' ',var_apellido,' ',var_neto);
   set mayor=var_netop;
   END IF;
   set i=i+1; -- contador
END WHILE;
CLOSE c1;
RETURN resultado;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cargo`
--

CREATE TABLE `cargo` (
  `cod_cargo` int(11) NOT NULL,
  `nombre_cargo` varchar(25) NOT NULL,
  `salario` decimal(10,0) NOT NULL CHECK (`salario` >= 900000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `cargo`
--

INSERT INTO `cargo` (`cod_cargo`, `nombre_cargo`, `salario`) VALUES
(1, 'Administrador', 2200000),
(2, 'Vendedor', 1800000),
(3, 'Contador', 2500000),
(4, 'Facturador', 1200000);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cartera`
--

CREATE TABLE `cartera` (
  `cod_factura` int(11) NOT NULL DEFAULT 0,
  `cliente_cod` int(11) NOT NULL,
  `fecha_factura` date NOT NULL,
  `forma_pago` enum('efectivo','nequi','credito') DEFAULT NULL,
  `total_neto` decimal(32,0) DEFAULT NULL,
  `fecha_vcto` date DEFAULT (`fecha_factura` + interval 30 day),
  `dias_mora` int(11) DEFAULT timestampdiff(DAY,`fecha_vcto`,curdate()),
  `abonos` decimal(10,0) DEFAULT 0,
  `saldo` decimal(10,0) GENERATED ALWAYS AS (`total_neto` - `abonos`) VIRTUAL,
  `pagada` varchar(5) DEFAULT 'N'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `cartera`
--

INSERT INTO `cartera` (`cod_factura`, `cliente_cod`, `fecha_factura`, `forma_pago`, `total_neto`, `fecha_vcto`, `dias_mora`, `abonos`, `pagada`) VALUES
(10, 9, '2023-08-08', 'credito', 281700, '2023-09-07', 231, 100000, 'N'),
(11, 9, '2023-08-08', 'credito', 523500, '2023-09-07', 231, 0, 'N'),
(12, 10, '2023-08-08', 'credito', 782000, '2023-09-07', 231, 0, 'N'),
(13, 10, '2023-08-09', 'credito', 570300, '2023-09-08', 230, 0, 'N'),
(19, 13, '2023-08-12', 'credito', 416250, '2023-09-11', 227, 0, 'N'),
(20, 14, '2023-08-13', 'credito', 841950, '2023-09-12', 226, 0, 'N'),
(30, 9, '2023-08-18', 'credito', 28000, '2023-09-17', 221, 0, 'N'),
(34, 8, '2023-08-19', 'credito', 285750, '2023-09-18', 220, 0, 'N'),
(39, 12, '2023-08-22', 'credito', 1046200, '2023-09-21', 217, 0, 'N'),
(41, 9, '2023-10-25', 'credito', NULL, '2023-11-24', 181, 0, 'N');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria`
--

CREATE TABLE `categoria` (
  `cod_categoria` int(11) NOT NULL,
  `nombre_categoria` varchar(50) NOT NULL,
  `observaciones` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `categoria`
--

INSERT INTO `categoria` (`cod_categoria`, `nombre_categoria`, `observaciones`) VALUES
(1, 'Lacteos', 'leche, yogurt y queso'),
(2, 'Panaderia', 'panes y repostería'),
(3, 'Galleteria', 'galletas saladas y dulces'),
(4, 'Golosinas', 'Chupetas, caramelos y bombones'),
(5, 'Salsas', 'salsa de tomate y aderezos'),
(6, 'Refrescos', 'Bebidas gaseosas y jugos'),
(7, 'Carnes Frías', 'Salchichas, mortadelas y jamones');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `cod_cliente` int(11) NOT NULL,
  `nombre1` varchar(25) NOT NULL,
  `nombre2` varchar(25) NOT NULL,
  `apellido1` varchar(25) NOT NULL,
  `apellido2` varchar(25) NOT NULL,
  `tipo_documento` enum('CC','CE','NIT','RUT') DEFAULT NULL,
  `no_documento` varchar(25) NOT NULL,
  `sexo` enum('masculino','femenino') DEFAULT NULL,
  `direccion` varchar(50) NOT NULL,
  `ciudad` varchar(20) NOT NULL,
  `fecha_ingreso` date DEFAULT curdate(),
  `edad` int(11) NOT NULL,
  `telefono` varchar(25) NOT NULL,
  `estado_civil` enum('soltero','casado','divorciado','union libre','viudo') DEFAULT NULL,
  `tipo_cliente` enum('detallista','mayorista','empresarial') DEFAULT NULL,
  `activo` varchar(4) NOT NULL DEFAULT 'A',
  `empleado_cod` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`cod_cliente`, `nombre1`, `nombre2`, `apellido1`, `apellido2`, `tipo_documento`, `no_documento`, `sexo`, `direccion`, `ciudad`, `fecha_ingreso`, `edad`, `telefono`, `estado_civil`, `tipo_cliente`, `activo`, `empleado_cod`) VALUES
(1, 'Mario', 'Alexis', 'Aroca', 'Martínez', 'CC', '1122239857', 'masculino', 'CALLE 40 SUR #96-16', 'Bogota', '2024-03-13', 38, '3158097309', 'soltero', 'mayorista', 'A', 3),
(2, 'Jerónimo', '', 'burgos', 'diez', 'CC', '10000459', 'masculino', 'CRA 98 # 58-90', 'Bogota', '2024-03-13', 40, '9015872', 'soltero', '', 'A', 3),
(3, 'Estefanía', 'Tatiana', 'Villegas', 'sierra', 'CC', '1023581203', 'masculino', 'TRV 110 #81-40', 'Bogota', '2024-03-13', 32, '6047599', 'casado', 'mayorista', 'A', 4),
(4, 'Guillermo', 'Mauricio', 'Fernandez', 'Vallejo', 'CC', '125692614', 'masculino', 'CALLE 75 #23SUR-40', 'Barranquilla', '2024-03-13', 43, '7057522', 'soltero', 'mayorista', 'A', 4),
(5, 'Eliana', 'Marcela', 'Ramírez', 'Guerrero', 'NIT', '1222333445', 'femenino', 'Calle 181 #2-45 ', 'Barranquilla', '2024-03-13', 50, '8019053', 'viudo', 'mayorista', 'A', 5),
(6, 'José', 'Gregorio', 'Carmona', 'Guerra', 'CC', '1091562345', 'masculino', 'Cra 3 A # 5-89', 'Barranquilla', '2024-03-13', 29, '3134409180', 'casado', 'detallista', 'A', 5),
(7, 'Marcela', 'Eliana', 'De santis', 'Rodríguez', 'CC', '1091562348', 'femenino', 'calle 9b # 4-20', 'Cali', '2024-03-13', 35, '3108156310', 'union libre', 'mayorista', 'A', 6),
(8, 'Daniela', '', 'Franco', 'Marulanda', 'CC', '1091562312', 'femenino', 'Carrera 56A No. 51 - 81', 'Cali', '2024-03-13', 45, '3212598228', 'union libre', 'mayorista', 'I', 6),
(9, 'Rafael', 'Fabian', 'Cortes', 'Palacio', 'CC', '1091562336', 'masculino', 'Calle 10 No. 9 - 78 Centro', 'Medellin', '2024-03-13', 48, '7586412', 'soltero', 'mayorista', 'I', 7),
(10, 'Camilo', 'Andres', 'Berrios', 'Bermudez', 'CC', '1091562314', 'masculino', 'Calle 24D #5676', 'Medellin', '2024-03-13', 36, '4341235', 'casado', 'mayorista', 'I', 7),
(11, 'Francisco', 'David', 'Arias', 'Toledo', 'CC', '1091562349', 'masculino', 'calle 5b #78c 05', 'Bogota', '2024-03-13', 27, '6018954', 'casado', 'empresarial', 'A', 8),
(12, 'Antonio', 'Giovanny', 'Merizalde', 'Arango', 'CC', '1091562103', 'masculino', 'Calle 23 #54-9', 'Barranquilla', '2024-03-13', 53, '3165846257', 'viudo', 'mayorista', 'I', 8),
(13, 'Karen', 'Rocio', 'Restrepo', 'Acevedo', 'CC', '1091562425', 'femenino', 'cra 7a # 34-89sur', 'Barranquilla', '2024-03-13', 43, '8017936', 'viudo', 'detallista', 'I', 9),
(14, 'David', 'Santiago', 'Lemus', 'Cock', 'NIT', '1112239564', 'masculino', 'cr 5a #20-34 sur', 'Bogota', '2024-03-13', 55, '3412658975', 'soltero', 'mayorista', 'I', 9),
(15, 'Javier', 'Mauricio', 'Santana', 'Casadiegos', 'CC', '1233669874', 'masculino', 'CALLE 27 #58-63', 'Cali', '2024-03-13', 40, '315648301', 'casado', 'mayorista', 'A', 10),
(16, 'Virginia', '', 'Saldarriaga', 'Salamanca', 'CC', '1556998745', 'femenino', 'cll 36 3 1-81 este', 'Medellin', '2024-03-13', 38, '4518992', 'casado', 'detallista', 'A', 10);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `contratista`
--

CREATE TABLE `contratista` (
  `cod_contratista` int(11) NOT NULL,
  `nombre1` varchar(25) NOT NULL,
  `nombre2` varchar(25) NOT NULL,
  `apellido1` varchar(25) NOT NULL,
  `apellido2` varchar(25) NOT NULL,
  `tipo_documento` enum('CC','CE','NIT','RUT') DEFAULT NULL,
  `sexo` enum('masculino','femenino') DEFAULT NULL,
  `direccion` varchar(50) NOT NULL,
  `telefono` varchar(25) NOT NULL,
  `camion` enum('camioneta','furgon','camion') DEFAULT NULL,
  `no_documento` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `contratista`
--

INSERT INTO `contratista` (`cod_contratista`, `nombre1`, `nombre2`, `apellido1`, `apellido2`, `tipo_documento`, `sexo`, `direccion`, `telefono`, `camion`, `no_documento`) VALUES
(1, 'Alberto', 'Alexis', 'Santos', 'Martínez', 'CC', 'masculino', 'CALLE 40 SUR #96-16', '3158097309', 'furgon', '1122239867'),
(2, 'Claudio', '', 'Berrio', 'Diem', 'CC', 'masculino', 'CRA 98 # 58-90', '9015872', 'camion', '10000457'),
(3, 'Sandra', 'Tatiana', 'Viloria', 'Sierra', 'CC', 'femenino', 'TRV 110 #81-40', '6047599', 'furgon', '1023581203'),
(4, 'Gustavo', 'Mauricio', 'Ferrer', 'Vallejo', 'CC', 'masculino', 'CALLE 75 #23SUR-40', '7057522', 'camion', '125692614'),
(5, 'Diana', 'Marcela', 'Ramírez', 'Guerrero', 'NIT', 'femenino', 'Calle 181 #2-45 ', '8019053', 'furgon', '1222333445'),
(6, 'José', 'Carlos', 'Calle', 'Guerra', 'CC', 'masculino', 'Cra 3A # 5-89', '3134409180', 'camion', '1091562345'),
(7, 'Marcela', 'Sofia', 'Castro', 'Rodríguez', 'CC', 'femenino', 'calle 9b # 4-20', '3108156310', 'furgon', '1091562348');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `despacho`
--

CREATE TABLE `despacho` (
  `cod_despacho` int(11) NOT NULL,
  `contratista_cod` int(11) NOT NULL,
  `factura_cod` int(11) NOT NULL,
  `fecha_recibo` date NOT NULL,
  `fecha_entrega` date NOT NULL,
  `valor_flete` decimal(10,0) NOT NULL DEFAULT 0,
  `entregado` varchar(1) NOT NULL,
  `observaciones` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `despacho`
--

INSERT INTO `despacho` (`cod_despacho`, `contratista_cod`, `factura_cod`, `fecha_recibo`, `fecha_entrega`, `valor_flete`, `entregado`, `observaciones`) VALUES
(1, 1, 1, '2023-08-06', '2023-08-07', 200000, 'n', 'Completo'),
(2, 1, 2, '2023-08-06', '2023-08-07', 200000, 's', 'Completo'),
(3, 2, 3, '2023-08-06', '2023-08-07', 200000, 's', 'Completo'),
(4, 2, 4, '2023-08-06', '2023-08-07', 200000, 's', 'Completo'),
(5, 3, 5, '2023-08-06', '2023-08-07', 200000, 's', 'Completo'),
(6, 3, 6, '2023-08-06', '2023-08-07', 200000, 's', 'Completo'),
(7, 4, 7, '2023-08-06', '2023-08-07', 100000, 's', 'Completo'),
(8, 3, 8, '2023-08-07', '2023-08-07', 340000, 's', 'Completo'),
(9, 4, 9, '2023-08-07', '2023-08-07', 250000, 's', 'Completo'),
(10, 5, 10, '2023-08-07', '2023-08-07', 270000, 's', 'Completo'),
(11, 6, 11, '2023-08-08', '2023-08-08', 320000, 's', 'Completo'),
(12, 7, 12, '2023-08-08', '2023-08-08', 220000, 's', 'Completo'),
(13, 1, 13, '2023-08-09', '2023-08-09', 350000, 's', 'Completo'),
(14, 2, 14, '2023-08-09', '2023-08-09', 280000, 's', 'Completo'),
(15, 3, 15, '2023-08-10', '2023-08-10', 330000, 's', 'Completo'),
(16, 4, 16, '2023-08-10', '2023-08-10', 265000, 's', 'Completo'),
(17, 5, 17, '2023-08-10', '2023-08-10', 320000, 's', 'Completo'),
(18, 6, 18, '2023-08-10', '2023-08-10', 280000, 's', 'Completo'),
(19, 7, 19, '2023-08-10', '2023-08-10', 260000, 's', 'Completo'),
(20, 1, 20, '2023-08-10', '2023-08-10', 370000, 's', 'Completo'),
(21, 2, 21, '2023-08-11', '2023-08-11', 230000, 's', 'Completo'),
(22, 3, 22, '2023-08-11', '2023-08-11', 240000, 's', 'Completo'),
(23, 4, 23, '2023-08-11', '2023-08-11', 270000, 's', 'Completo'),
(24, 5, 24, '2023-08-11', '2023-08-11', 240000, 's', 'Completo'),
(25, 6, 25, '2023-08-12', '2023-08-12', 250000, 's', 'Completo'),
(26, 7, 26, '2023-08-12', '2023-08-12', 260000, 's', 'Completo'),
(27, 1, 21, '2023-08-13', '2023-08-13', 320000, 's', 'Completo'),
(28, 2, 22, '2023-08-13', '2023-08-15', 300000, 's', 'Completo'),
(29, 3, 23, '2023-08-13', '2023-08-13', 310000, 's', 'Completo'),
(30, 4, 24, '2023-08-13', '2023-08-13', 310000, 's', 'Completo'),
(31, 5, 25, '2023-08-13', '2023-08-13', 230000, 's', 'Completo'),
(32, 6, 26, '2023-08-14', '2023-08-14', 250000, 's', 'Completo'),
(33, 7, 27, '2023-08-14', '2023-08-14', 260000, 's', 'Completo'),
(34, 1, 28, '2023-08-14', '2023-08-14', 270000, 's', 'Completo'),
(35, 2, 29, '2023-08-15', '2023-08-15', 290000, 's', 'Completo'),
(36, 3, 30, '2023-08-15', '2023-08-17', 300000, 's', 'Completo'),
(37, 4, 31, '2023-08-15', '2023-08-15', 320000, 's', 'Completo'),
(38, 5, 32, '2023-08-15', '2023-08-15', 280000, 's', 'Completo'),
(39, 6, 33, '2023-08-15', '2023-08-15', 350000, 's', 'Completo'),
(40, 7, 34, '2023-08-15', '2023-08-15', 260000, 's', 'Completo'),
(41, 1, 35, '2023-08-15', '2023-08-15', 320000, 's', 'Completo'),
(42, 2, 36, '2023-08-16', '2023-08-16', 350000, 's', 'Completo'),
(43, 3, 37, '2023-08-16', '2023-08-16', 400000, 's', 'Completo'),
(44, 4, 38, '2023-08-16', '2023-08-16', 350000, 's', 'Completo'),
(45, 5, 39, '2023-08-16', '2023-08-16', 320000, 's', 'Completo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empleado`
--

CREATE TABLE `empleado` (
  `cod_empleado` int(11) NOT NULL,
  `nombre1` varchar(25) NOT NULL,
  `nombre2` varchar(25) NOT NULL,
  `apellido1` varchar(25) NOT NULL,
  `apellido2` varchar(25) NOT NULL,
  `tipo_documento` enum('CC','CE','NIT','RUT') DEFAULT NULL,
  `no_documento` varchar(25) NOT NULL,
  `sexo` enum('masculino','femenino') DEFAULT NULL,
  `direccion` varchar(50) NOT NULL,
  `ciudad` varchar(20) NOT NULL,
  `edad` int(11) NOT NULL CHECK (`edad` >= 18),
  `telefono` varchar(25) NOT NULL,
  `fecha_ingreso` date DEFAULT curdate(),
  `estado_civil` enum('soltero','soltera','casado','casada','divociado','divorciada','union libre','viudo','viuda') DEFAULT NULL,
  `cargo_cod` int(11) NOT NULL,
  `nivel_estudios` enum('primaria','bachillerato','tecnico','tecnologo','profecional','otro') DEFAULT NULL,
  `eps` enum('sanitas','sura','capital salud','nueva eps','compesar','famisanar','aliansalud') DEFAULT NULL,
  `pensiones` enum('colfondos','proteccion','porvenir','skandia') DEFAULT NULL,
  `cesantias` enum('fna',' porvenir','colfondos','proteccion') DEFAULT NULL,
  `banco` enum('BBVA','davivienda','bancolombia','caja social','popular','las villas') DEFAULT NULL,
  `activo` varchar(4) NOT NULL DEFAULT 'A'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `empleado`
--

INSERT INTO `empleado` (`cod_empleado`, `nombre1`, `nombre2`, `apellido1`, `apellido2`, `tipo_documento`, `no_documento`, `sexo`, `direccion`, `ciudad`, `edad`, `telefono`, `fecha_ingreso`, `estado_civil`, `cargo_cod`, `nivel_estudios`, `eps`, `pensiones`, `cesantias`, `banco`, `activo`) VALUES
(1, 'Gonzalo', '', 'Betancur', 'Arroyave', 'CC', '80161094', 'masculino', 'cra 78c # 5c 48', 'bogota', 30, '3145778421', '2024-03-13', 'soltero', 1, '', 'sanitas', 'colfondos', 'fna', 'BBVA', 'A'),
(2, 'Santiago', '', 'Betancurt', 'Lemos', 'CC', '79843321', 'masculino', 'cra 71d # 7a 48', 'bogota', 32, '3202568945', '2024-03-13', 'casado', 1, 'tecnico', 'sura', 'proteccion', '', 'davivienda', 'A'),
(3, 'Isabella', '', 'Marquez', 'Jaramillo', 'CC', '52951079', 'femenino', 'CALLE 28 #58-69', 'barranquilla', 28, '3457634512', '2024-03-13', 'casada', 2, '', 'capital salud', 'colfondos', 'colfondos', '', 'A'),
(4, 'Karla', 'Maria', 'Molina', 'Lema', 'CC', '53456798', 'femenino', 'cra 78c # 5c 25', 'cali', 34, '3124772431', '2024-03-13', 'soltera', 2, 'tecnico', 'nueva eps', 'proteccion', 'fna', 'popular', 'A'),
(5, 'Hilda', '', 'Rodriguez', 'Caro', 'CC', '1020567980', 'femenino', 'Av 68 # 5a _45', 'bogota', 31, '3025975960', '2024-03-13', 'soltera', 2, '', 'sanitas', 'porvenir', 'proteccion', '', 'A'),
(6, 'Victoria', '', 'Hincapie', 'Vergara', 'CC', '19654789', 'femenino', 'Calle 10 # 5-51', 'medellin', 22, '3103336590', '2024-03-13', 'casada', 2, '', 'sura', 'porvenir', 'colfondos', 'popular', 'A'),
(7, 'Pablo', 'Santiago', 'Rojas', 'Duque', 'CC', '1018765324', 'masculino', 'Calle 100 # 11B-27 Bogotá', 'bogota', 25, '3456676895', '2024-03-13', 'soltero', 2, 'primaria', 'capital salud', 'colfondos', 'fna', 'davivienda', 'A'),
(8, 'Pamela', '', 'Serna', 'Muñoz', 'CC', '1010654382', 'femenino', 'Calle 53 No 10-60/46, Pis', 'barranquilla', 40, '3225986478', '2024-03-13', 'soltera', 2, 'tecnico', 'nueva eps', 'skandia', '', 'BBVA', 'A'),
(9, 'Stepania', '', 'Zapata', 'Pelaez', 'CC', '1014343567', 'femenino', 'Carrera 21 # 17 -63', 'cali', 25, '3028912345', '2024-03-13', 'soltera', 2, '', 'sanitas', 'porvenir', 'fna', 'davivienda', 'A'),
(10, 'Manuel', 'Andres', 'Toro', 'Sanchez', 'CC', '1013567900', 'masculino', 'Calle 24D #5676', 'medellin', 28, '3026598745', '2024-03-13', 'casado', 2, '', 'sura', 'skandia', 'colfondos', 'popular', 'A'),
(11, 'Barbara', '', 'Henao', 'Cano', 'CC', '51593856', 'femenino', 'CALLE 12#45-17', 'bogota', 35, '8018043009', '2024-03-13', 'soltera', 4, '', 'capital salud', 'colfondos', 'colfondos', '', 'A'),
(12, 'Leonardo', '', 'Vasquez', 'Uribe', 'CC', '79804568', 'masculino', 'Av 26 No 59-51 Edificio A', 'medellin', 24, '3201452698', '2024-03-13', 'union libre', 4, 'tecnico', 'nueva eps', 'proteccion', 'proteccion', '', 'A'),
(13, 'Juliana', '', 'Castrillón', 'Florez', 'CC', '1015678904', 'femenino', 'Av Boyaca #  2a 71', 'cali', 32, '3412589678', '2024-03-13', 'soltera', 3, '', 'sanitas', 'colfondos', 'colfondos', 'davivienda', 'A'),
(14, 'Rocio', '', 'Muñoz', 'Gutierrez', 'CC', '1015768903', 'femenino', 'CR 5B #50-49A SUR', 'barranquilla', 37, '3125847512', '2024-03-13', 'soltera', 3, 'tecnico', 'sura', 'porvenir', '', 'BBVA', 'A');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `entrada_cabeza`
--

CREATE TABLE `entrada_cabeza` (
  `cod_entrada` int(11) NOT NULL,
  `fecha_entrada` date NOT NULL,
  `proveedor_cod` int(11) NOT NULL,
  `empleado_cod` int(11) NOT NULL,
  `forma_pago` enum('efectivo','nequi','credito') DEFAULT NULL,
  `tipomov_cod` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `entrada_cabeza`
--

INSERT INTO `entrada_cabeza` (`cod_entrada`, `fecha_entrada`, `proveedor_cod`, `empleado_cod`, `forma_pago`, `tipomov_cod`) VALUES
(1, '2023-08-05', 2, 1, 'efectivo', 2),
(2, '2023-08-05', 2, 1, 'efectivo', 2),
(3, '2023-08-05', 3, 1, 'efectivo', 2),
(4, '2023-08-06', 3, 1, 'efectivo', 2),
(5, '2023-08-06', 4, 1, 'efectivo', 2),
(6, '2023-08-06', 4, 1, 'efectivo', 2),
(7, '2023-08-06', 5, 1, 'efectivo', 4),
(8, '2023-08-07', 7, 1, 'efectivo', 2),
(9, '2023-08-07', 2, 1, 'efectivo', 2),
(10, '2023-08-07', 3, 1, 'efectivo', 2),
(11, '2023-08-08', 4, 1, 'efectivo', 2),
(12, '2023-08-08', 3, 1, 'efectivo', 2),
(13, '2023-08-08', 6, 1, 'efectivo', 2),
(14, '2023-08-08', 1, 1, 'efectivo', 4),
(15, '2023-08-09', 1, 1, 'efectivo', 4),
(16, '2023-08-09', 8, 1, 'efectivo', 2),
(17, '2023-08-10', 1, 1, 'efectivo', 4),
(18, '2023-08-11', 1, 1, 'efectivo', 4),
(19, '2023-08-11', 7, 1, 'efectivo', 2),
(20, '2023-08-11', 5, 1, 'efectivo', 2),
(21, '2023-08-12', 2, 1, 'efectivo', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `entrada_detalle`
--

CREATE TABLE `entrada_detalle` (
  `cod_edetalle` int(11) NOT NULL,
  `entrada_cod` int(11) NOT NULL,
  `producto_cod` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `valor_compra` decimal(10,0) NOT NULL DEFAULT 0,
  `subtotal` decimal(10,0) GENERATED ALWAYS AS (`valor_compra` * `cantidad`) VIRTUAL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `entrada_detalle`
--

INSERT INTO `entrada_detalle` (`cod_edetalle`, `entrada_cod`, `producto_cod`, `cantidad`, `valor_compra`) VALUES
(1, 1, 1, 100, 2000),
(2, 1, 2, 500, 7000),
(3, 1, 3, 400, 2800),
(4, 2, 1, 100, 2000),
(5, 2, 2, 500, 7000),
(6, 2, 3, 400, 2800),
(7, 3, 4, 100, 4500),
(8, 3, 5, 600, 6500),
(9, 3, 8, 500, 5500),
(10, 4, 4, 100, 4500),
(11, 4, 5, 600, 6500),
(12, 4, 8, 500, 5500),
(13, 5, 10, 500, 6500),
(14, 5, 4, 700, 4500),
(15, 6, 8, 500, 5500),
(16, 6, 5, 100, 6500),
(17, 7, 2, 150, 5500),
(18, 8, 11, 200, 5500),
(19, 8, 12, 150, 5500),
(20, 8, 13, 120, 7500),
(21, 9, 14, 300, 9000),
(22, 9, 15, 500, 7200),
(23, 9, 16, 400, 8000),
(24, 10, 17, 180, 6300),
(25, 10, 18, 260, 5600),
(26, 10, 19, 400, 2800),
(27, 11, 23, 500, 2500),
(28, 11, 24, 300, 3400),
(29, 11, 25, 250, 4200),
(30, 12, 3, 170, 3000),
(31, 13, 26, 300, 1800),
(32, 13, 27, 250, 2500),
(33, 13, 28, 140, 6000),
(34, 14, 14, 4, 9000),
(35, 14, 15, 2, 7200),
(36, 14, 16, 5, 8000),
(37, 15, 12, 6, 5500),
(38, 15, 13, 3, 7500),
(39, 15, 14, 5, 9000),
(40, 16, 8, 300, 5500),
(41, 16, 9, 240, 7500),
(42, 16, 10, 220, 6500),
(43, 17, 5, 3, 6500),
(44, 18, 10, 4, 6500),
(45, 19, 11, 270, 5500),
(46, 20, 7, 140, 4500),
(47, 20, 20, 150, 6000),
(48, 20, 21, 200, 8000),
(49, 20, 22, 300, 2100),
(54, 21, 1, 100, 2000),
(55, 21, 2, 100, 7000),
(56, 21, 14, 100, 9000),
(57, 21, 16, 100, 8000);

--
-- Disparadores `entrada_detalle`
--
DELIMITER $$
CREATE TRIGGER `entrada_inventario` AFTER INSERT ON `entrada_detalle` FOR EACH ROW BEGIN
UPDATE productos SET existencia=productos.existencia+NEW.cantidad
    WHERE productos.cod_producto=NEW.producto_cod;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `factura_cabeza`
--

CREATE TABLE `factura_cabeza` (
  `cod_factura` int(11) NOT NULL,
  `fecha_factura` date NOT NULL,
  `cliente_cod` int(11) NOT NULL,
  `empleado_cod` int(11) NOT NULL,
  `forma_pago` enum('efectivo','nequi','credito') DEFAULT NULL,
  `tipomov_cod` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `factura_cabeza`
--

INSERT INTO `factura_cabeza` (`cod_factura`, `fecha_factura`, `cliente_cod`, `empleado_cod`, `forma_pago`, `tipomov_cod`) VALUES
(1, '2023-08-05', 4, 3, 'efectivo', 1),
(2, '2023-08-05', 7, 3, 'efectivo', 1),
(3, '2023-08-05', 5, 4, 'efectivo', 1),
(4, '2023-08-06', 3, 4, 'nequi', 1),
(5, '2023-08-06', 6, 5, 'nequi', 1),
(6, '2023-08-06', 7, 3, 'nequi', 1),
(7, '2023-08-06', 7, 3, 'efectivo', 3),
(8, '2023-08-07', 8, 5, 'nequi', 1),
(9, '2023-08-07', 8, 6, 'efectivo', 1),
(10, '2023-08-08', 9, 6, 'credito', 1),
(11, '2023-08-08', 9, 7, 'credito', 1),
(12, '2023-08-08', 10, 7, 'credito', 1),
(13, '2023-08-09', 10, 8, 'credito', 1),
(14, '2023-08-09', 11, 8, 'nequi', 1),
(15, '2023-08-10', 11, 9, 'nequi', 1),
(16, '2023-08-11', 12, 9, 'efectivo', 1),
(17, '2023-08-11', 12, 10, 'efectivo', 1),
(18, '2023-08-12', 13, 10, 'efectivo', 1),
(19, '2023-08-12', 13, 5, 'credito', 1),
(20, '2023-08-13', 14, 6, 'credito', 1),
(21, '2023-08-13', 14, 4, 'nequi', 1),
(22, '2023-08-14', 15, 8, 'nequi', 1),
(23, '2023-08-15', 16, 9, 'efectivo', 3),
(24, '2023-08-15', 10, 7, 'efectivo', 3),
(25, '2023-08-16', 3, 5, 'efectivo', 3),
(26, '2023-08-16', 5, 3, 'efectivo', 3),
(27, '2023-08-17', 8, 11, 'nequi', 1),
(28, '2023-08-17', 4, 10, 'nequi', 1),
(29, '2023-08-17', 8, 7, 'efectivo', 1),
(30, '2023-08-18', 9, 4, 'credito', 1),
(31, '2023-08-18', 2, 9, 'nequi', 1),
(32, '2023-08-18', 6, 7, 'nequi', 1),
(33, '2023-08-19', 13, 3, 'efectivo', 1),
(34, '2023-08-19', 8, 8, 'credito', 1),
(35, '2023-08-20', 14, 5, 'nequi', 1),
(36, '2023-08-20', 15, 3, 'efectivo', 1),
(37, '2023-08-21', 16, 6, 'nequi', 1),
(38, '2023-08-21', 11, 8, 'efectivo', 1),
(39, '2023-08-22', 12, 6, 'credito', 1),
(40, '2023-10-25', 8, 5, 'efectivo', 1),
(41, '2023-10-25', 9, 6, 'credito', 1);

--
-- Disparadores `factura_cabeza`
--
DELIMITER $$
CREATE TRIGGER `actualiza_cartera` AFTER INSERT ON `factura_cabeza` FOR EACH ROW BEGIN 
IF NEW.forma_pago="credito" AND NEW.tipomov_cod=1 THEN
INSERT INTO cartera(cod_factura, cliente_cod, fecha_factura, forma_pago)
VALUES(NEW.cod_factura, NEW.cliente_cod,NEW.fecha_factura,NEW.forma_pago);
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `factura_detalle`
--

CREATE TABLE `factura_detalle` (
  `cod_facdetalle` int(11) NOT NULL,
  `factura_cod` int(11) NOT NULL,
  `producto_cod` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `valor_venta` decimal(10,0) NOT NULL DEFAULT 0,
  `subtotal` decimal(10,0) GENERATED ALWAYS AS (`valor_venta` * `cantidad`) VIRTUAL,
  `descuento` decimal(10,2) NOT NULL DEFAULT 0.00,
  `neto` decimal(10,0) GENERATED ALWAYS AS (`subtotal` * (1 - `descuento`)) VIRTUAL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `factura_detalle`
--

INSERT INTO `factura_detalle` (`cod_facdetalle`, `factura_cod`, `producto_cod`, `cantidad`, `valor_venta`, `descuento`) VALUES
(1, 1, 1, 10, 3000, 0.00),
(2, 1, 2, 5, 8000, 0.00),
(3, 1, 3, 4, 3000, 0.00),
(4, 2, 1, 10, 3000, 0.00),
(5, 2, 2, 5, 8000, 0.00),
(6, 2, 3, 4, 3800, 0.00),
(7, 3, 4, 10, 5500, 0.10),
(8, 3, 5, 6, 7500, 0.10),
(9, 3, 8, 5, 6500, 0.10),
(10, 4, 4, 10, 5500, 0.10),
(11, 4, 5, 6, 7500, 0.10),
(12, 4, 8, 5, 6500, 0.10),
(13, 5, 10, 5, 7500, 0.10),
(14, 5, 4, 7, 5500, 0.10),
(15, 6, 8, 5, 6500, 0.10),
(16, 6, 5, 10, 7500, 0.10),
(17, 7, 2, 15, 6500, 0.00),
(18, 8, 7, 20, 5500, 0.05),
(19, 8, 9, 18, 8500, 0.05),
(20, 9, 12, 13, 6500, 0.00),
(21, 9, 13, 30, 8500, 0.00),
(22, 9, 14, 23, 10000, 0.00),
(23, 10, 11, 7, 6500, 0.10),
(24, 10, 10, 13, 7500, 0.10),
(25, 10, 13, 20, 8500, 0.10),
(26, 11, 14, 15, 10000, 0.00),
(27, 11, 15, 30, 8200, 0.00),
(28, 11, 5, 17, 7500, 0.00),
(29, 12, 16, 30, 9000, 0.15),
(30, 12, 15, 50, 8200, 0.15),
(31, 12, 14, 24, 10000, 0.15),
(32, 13, 17, 30, 7300, 0.00),
(33, 13, 18, 40, 6600, 0.00),
(34, 13, 19, 25, 3880, 0.10),
(35, 14, 20, 15, 7000, 0.05),
(36, 14, 21, 10, 9000, 0.05),
(37, 15, 22, 34, 3100, 0.05),
(38, 15, 23, 55, 3500, 0.05),
(39, 16, 24, 43, 4400, 0.10),
(40, 16, 25, 32, 5200, 0.10),
(41, 17, 26, 28, 2800, 0.00),
(42, 17, 27, 16, 3500, 0.00),
(43, 18, 28, 26, 7000, 0.00),
(44, 19, 10, 40, 7500, 0.10),
(45, 19, 11, 25, 6500, 0.10),
(46, 20, 12, 17, 6500, 0.10),
(47, 20, 13, 50, 8500, 0.10),
(48, 20, 14, 36, 10000, 0.00),
(49, 21, 4, 30, 5500, 0.10),
(50, 21, 5, 26, 7500, 0.05),
(51, 22, 7, 30, 5500, 0.05),
(52, 22, 8, 16, 6500, 0.05),
(53, 23, 9, 20, 8500, 0.10),
(54, 23, 10, 30, 7500, 0.10),
(55, 24, 11, 50, 6500, 0.10),
(56, 24, 12, 28, 6500, 0.05),
(57, 24, 13, 16, 8500, 0.05),
(58, 25, 14, 12, 10000, 0.05),
(59, 25, 15, 10, 8200, 0.10),
(60, 26, 16, 30, 9000, 0.05),
(61, 26, 17, 20, 7300, 0.05),
(62, 27, 18, 15, 6600, 0.10),
(63, 27, 19, 22, 3880, 0.10),
(64, 27, 20, 13, 7000, 0.10),
(65, 28, 21, 25, 9000, 0.00),
(66, 28, 22, 15, 3100, 0.00),
(67, 28, 23, 7, 3500, 0.00),
(68, 29, 24, 11, 4400, 0.00),
(69, 29, 25, 4, 5200, 0.00),
(70, 30, 26, 10, 2800, 0.00),
(71, 31, 27, 14, 3500, 0.10),
(72, 31, 28, 12, 7000, 0.05),
(73, 32, 4, 20, 5500, 0.10),
(74, 32, 5, 15, 7500, 0.10),
(75, 33, 6, 20, 3500, 0.00),
(76, 33, 7, 16, 5500, 0.00),
(77, 34, 8, 24, 6500, 0.10),
(78, 34, 9, 18, 8500, 0.05),
(79, 35, 10, 30, 7500, 0.00),
(80, 35, 11, 23, 6500, 0.10),
(81, 36, 12, 37, 6500, 0.05),
(82, 36, 13, 26, 8500, 0.10),
(83, 37, 14, 22, 10000, 0.10),
(84, 37, 15, 31, 8200, 0.10),
(85, 38, 16, 15, 9000, 0.00),
(86, 38, 17, 29, 7300, 0.00),
(87, 38, 18, 30, 6600, 0.00),
(88, 38, 19, 25, 3880, 0.00),
(89, 39, 20, 40, 7000, 0.00),
(90, 39, 22, 28, 3100, 0.00),
(91, 39, 21, 37, 9000, 0.00),
(92, 39, 24, 24, 4400, 0.00),
(93, 39, 26, 10, 2800, 0.00),
(94, 39, 25, 14, 5200, 0.00),
(95, 39, 28, 20, 7000, 0.00),
(96, 40, 1, 50, 3000, 0.10),
(97, 40, 1, 50, 3000, 0.10),
(98, 40, 2, 50, 8000, 0.10),
(99, 40, 3, 50, 3800, 0.10),
(100, 40, 4, 50, 3000, 0.10);

--
-- Disparadores `factura_detalle`
--
DELIMITER $$
CREATE TRIGGER `salida_inventario` AFTER INSERT ON `factura_detalle` FOR EACH ROW BEGIN 
UPDATE productos SET existencia=productos.existencia-NEW.cantidad
    WHERE productos.cod_producto=NEW.producto_cod;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `nomina`
--

CREATE TABLE `nomina` (
  `cod_nomina` int(11) NOT NULL,
  `fecha_nomina` date NOT NULL,
  `empleado_cod` varchar(25) NOT NULL,
  `salario_base` decimal(10,0) NOT NULL DEFAULT 0,
  `dias_trabajados` int(11) NOT NULL,
  `salario` decimal(10,0) GENERATED ALWAYS AS (`salario_base` / 30 * `dias_trabajados`) VIRTUAL,
  `auxilio_transporte` decimal(10,0) NOT NULL DEFAULT 0,
  `no_hrecargo` int(11) DEFAULT 0,
  `recargo_noche` decimal(10,0) GENERATED ALWAYS AS (`salario_base` / 240 * `no_hrecargo` * 1.35) VIRTUAL,
  `total_devengado` decimal(10,0) GENERATED ALWAYS AS (`salario` + `auxilio_transporte` + `recargo_noche`) VIRTUAL,
  `salud` decimal(10,0) GENERATED ALWAYS AS (`total_devengado` * 0.04) VIRTUAL,
  `pension` decimal(10,0) GENERATED ALWAYS AS (`total_devengado` * 0.04) VIRTUAL,
  `prestamos` decimal(10,0) NOT NULL DEFAULT 0,
  `total_deducido` decimal(10,0) GENERATED ALWAYS AS (`salud` + `pension` + `prestamos`) VIRTUAL,
  `neto_pagar` decimal(10,0) GENERATED ALWAYS AS (`total_devengado` - `total_deducido`) VIRTUAL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `nomina`
--

INSERT INTO `nomina` (`cod_nomina`, `fecha_nomina`, `empleado_cod`, `salario_base`, `dias_trabajados`, `auxilio_transporte`, `no_hrecargo`, `prestamos`) VALUES
(1, '2024-05-02', '1', 1300000, 30, 162000, 5, 110000),
(2, '2024-05-02', '2', 1500000, 20, 108000, 10, 120000),
(3, '2024-05-02', '3', 1200000, 25, 135000, 10, 90000),
(4, '2024-05-02', '4', 1800000, 23, 124200, 8, 140000);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `cod_producto` int(11) NOT NULL,
  `descripcion` varchar(50) NOT NULL,
  `valor_compra` decimal(10,0) NOT NULL DEFAULT 0,
  `valor_venta` decimal(10,0) NOT NULL DEFAULT 0,
  `existencia` bigint(20) NOT NULL CHECK (`existencia` >= 0),
  `nro_lote` int(11) NOT NULL,
  `fecha_fabricacion` date NOT NULL,
  `fecha_vencimiento` date NOT NULL,
  `categoria_cod` int(11) NOT NULL,
  `proveedor_cod` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`cod_producto`, `descripcion`, `valor_compra`, `valor_venta`, `existencia`, `nro_lote`, `fecha_fabricacion`, `fecha_vencimiento`, `categoria_cod`, `proveedor_cod`) VALUES
(1, 'Galletas Festival Bsax12', 2000, 3000, 4180, 4089, '2023-04-01', '2024-04-01', 3, 2),
(2, 'Galletas Ducales taco', 7000, 8000, 6175, 4088, '2023-04-01', '2024-04-01', 3, 2),
(3, 'Bom bom bum barrax50', 3000, 3800, 4412, 4081, '2023-05-01', '2024-05-01', 4, 3),
(4, 'Pan Blanco tajado', 4500, 5500, 6273, 4080, '2023-02-01', '2024-02-01', 2, 4),
(5, 'Salsa de tomate frasco', 7150, 7500, 7223, 4084, '2023-06-01', '2024-06-01', 5, 7),
(6, 'Jugo Fresa frasco', 2500, 3500, 6480, 4086, '2023-03-01', '2024-03-01', 6, 6),
(7, 'Leche pasteurizada bsa', 4500, 5500, 7574, 4080, '2023-03-01', '2024-03-01', 1, 5),
(8, 'Ranchera', 5500, 7150, 10245, 4070, '2023-08-30', '2023-09-20', 7, 8),
(9, 'Ranchera', 7500, 9350, 9684, 4071, '2023-08-30', '2023-09-20', 7, 8),
(10, 'Ranchera', 6500, 8250, 9106, 4072, '2023-08-30', '2023-09-20', 7, 8),
(11, 'Salsa de soya frasco', 6050, 6500, 6865, 4079, '2023-08-20', '2024-09-20', 5, 7),
(12, 'Salsa mayonesa frasco', 6050, 6500, 8061, 4079, '2023-08-20', '2024-09-20', 5, 7),
(13, 'Salsa rosada frasco', 8250, 8500, 7581, 4079, '2023-08-20', '2024-09-20', 5, 7),
(14, 'Galletas Recreo bsa', 9000, 10000, 8477, 4077, '2023-08-20', '2024-08-20', 3, 2),
(15, 'Galletas Ducales taco', 7200, 8200, 9381, 4077, '2023-08-20', '2024-08-20', 3, 2),
(16, 'Galletas Saltin taco', 8000, 9000, 10430, 4077, '2023-08-20', '2024-08-20', 3, 2),
(17, 'Menta Helada Bsa', 6300, 7300, 5601, 4076, '2023-09-10', '2024-09-10', 4, 3),
(18, 'Confites Choco Bsa', 5600, 6600, 3875, 4076, '2023-09-10', '2024-09-10', 4, 3),
(19, 'Arequipe mum tarro', 2800, 3880, 4828, 4076, '2023-09-10', '2024-09-10', 4, 3),
(20, 'Queso Costeño pq', 6000, 7000, 3082, 4075, '2023-09-10', '2024-09-10', 1, 5),
(21, 'Leche Entera bsa', 8000, 9000, 5128, 4075, '2023-09-10', '2024-09-10', 1, 5),
(22, 'Yogurt Dulce tarro', 2100, 3100, 6223, 4075, '2023-09-10', '2024-09-10', 1, 5),
(23, 'Pan mogolla x 10 bsa', 2500, 3500, 5438, 4074, '2023-09-10', '2024-09-10', 2, 4),
(24, 'Ponque Bimbox5 bsa', 3400, 4400, 3722, 4074, '2023-09-10', '2024-09-10', 2, 4),
(25, 'Brownie x 5 bsa', 4200, 5200, 7200, 4074, '2023-09-10', '2024-09-10', 2, 4),
(26, 'Agua Cristal bote', 1800, 2800, 8752, 4073, '2023-09-10', '2024-09-10', 6, 6),
(27, 'Jugo Mora Frasco', 2500, 3500, 6520, 4073, '2023-09-10', '2024-09-10', 6, 6),
(28, 'Pony Malta litro', 6000, 7000, 8482, 4073, '2023-09-10', '2024-09-10', 6, 6);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedor`
--

CREATE TABLE `proveedor` (
  `cod_proveedor` int(11) NOT NULL,
  `razon_social` varchar(50) NOT NULL,
  `tipo_documento` enum('NIT','RUT','CC') DEFAULT NULL,
  `direccion` varchar(50) NOT NULL,
  `ciudad` varchar(20) NOT NULL,
  `telefono` varchar(25) NOT NULL,
  `e_mail` varchar(50) NOT NULL,
  `asesor_comercial` varchar(50) NOT NULL,
  `telefono_asesor` varchar(25) NOT NULL,
  `e_mail_asesor` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `proveedor`
--

INSERT INTO `proveedor` (`cod_proveedor`, `razon_social`, `tipo_documento`, `direccion`, `ciudad`, `telefono`, `e_mail`, `asesor_comercial`, `telefono_asesor`, `e_mail_asesor`) VALUES
(1, 'Devolución Buena', '', 'N/A', 'BOGOTA', 'N/A', 'N/A', 'N/A', 'N/A', 'N/A'),
(2, 'GALLETAS POLLY', 'NIT', 'CRA 41B NO.9-65', 'BOGOTA', '3701266', 'servicioproveedor@pull.co', 'RODRIGO TORRES', '319423218', 'rodrigotorres@pull.co'),
(3, 'DULCES SUGAR', 'NIT', 'CRA 29B No.18A-61 SUR', 'BOGOTA', '7133907', 'clientes@dulsugar.co', 'SANDRA VALBUENA', '314763218', 'sandra.valbunea@dulsugar.co'),
(4, 'PAN MIMOS', 'NIT', 'CRA 31A No.10-78', 'BUCARAMANGA', '2084765', 'atencioncliente@mimos.co', 'ROCIO MORENO', '3134487965', 'carlos.moreno@mimos.co'),
(5, 'LACTEOS VAQUERIA', 'NIT', 'CRA 20 No.22-48', 'MEDELLIN', '76712474', 'serviciocliente@vaqueria.co', 'AMAYA', '3108156311', 'ramayacalinca@vaqueria.co'),
(6, 'BEBIDAS YAYOS', 'NIT', 'CRA 24 NO.54-32', 'BARRANQUILLA', '68856743', 'clientes@yayos.co', 'FREDY CARDENAS', '3124512107', 'fredy.cardenas@yayos.co'),
(7, 'SALSAS PIRRY', 'NIT', 'CLL 12A No.37-122', 'CALI', '24457740', ' servicioalcliente@pirry.com', 'SONIA VIVAS', '3194321290', 'soniavivas@pirry.com'),
(8, 'CARNICOS COWS', 'NIT', 'CLL 220A No.7-122', 'BOGOTA', '24457735', ' servicioalcliente@cows.com', 'BARTIMEO RIOS', '3194321298', 'Bartimeo rios@cows.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipomov`
--

CREATE TABLE `tipomov` (
  `cod_tipomov` int(11) NOT NULL,
  `nombre_mov` varchar(25) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipomov`
--

INSERT INTO `tipomov` (`cod_tipomov`, `nombre_mov`) VALUES
(1, 'Venta'),
(2, 'Compra'),
(3, 'Salida V'),
(4, 'Devolucion V'),
(5, 'Venta'),
(6, 'Compra'),
(7, 'Salida V'),
(8, 'Devolucion V');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_cargo_empleado`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_cargo_empleado` (
`cod_cargo` int(11)
,`nombre_cargo` varchar(25)
,`salario` decimal(10,0)
,`cod_empleado` int(11)
,`nombre1` varchar(25)
,`apellido1` varchar(25)
,`fecha_ingreso` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_categoria_producto`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_categoria_producto` (
`razon_social` varchar(50)
,`direccion` varchar(50)
,`descripcion` varchar(50)
,`valor_venta` decimal(10,0)
,`valor_compra` decimal(10,0)
,`existencia` bigint(20)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_empleado_cliente`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_empleado_cliente` (
`empleado` varchar(50)
,`cliente` varchar(50)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_proveedor_producto`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_proveedor_producto` (
`razon_social` varchar(50)
,`ciudad` varchar(20)
,`descripcion` varchar(50)
,`valor_compra` decimal(10,0)
,`valor_venta` decimal(10,0)
,`existencia` bigint(20)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_tipomov_entrada`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_tipomov_entrada` (
`cod_tipomov` int(11)
,`nombre_mov` varchar(25)
,`cod_entrada` int(11)
,`fecha_entrada` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_tipomov_factura`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_tipomov_factura` (
`cod_tipomov` int(11)
,`nombre_mov` varchar(25)
,`cod_factura` int(11)
,`fecha_factura` date
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_cargo_empleado`
--
DROP TABLE IF EXISTS `vista_cargo_empleado`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_cargo_empleado`  AS SELECT `t1`.`cod_cargo` AS `cod_cargo`, `t1`.`nombre_cargo` AS `nombre_cargo`, `t1`.`salario` AS `salario`, `t2`.`cod_empleado` AS `cod_empleado`, `t2`.`nombre1` AS `nombre1`, `t2`.`apellido1` AS `apellido1`, `t2`.`fecha_ingreso` AS `fecha_ingreso` FROM (`cargo` `t1` join `empleado` `t2`) WHERE `t1`.`cod_cargo` = `t2`.`cargo_cod` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_categoria_producto`
--
DROP TABLE IF EXISTS `vista_categoria_producto`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_categoria_producto`  AS SELECT `t1`.`razon_social` AS `razon_social`, `t1`.`direccion` AS `direccion`, `t2`.`descripcion` AS `descripcion`, `t2`.`valor_venta` AS `valor_venta`, `t2`.`valor_compra` AS `valor_compra`, `t2`.`existencia` AS `existencia` FROM (`proveedor` `t1` join `productos` `t2`) WHERE `t1`.`cod_proveedor` = `t2`.`proveedor_cod` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_empleado_cliente`
--
DROP TABLE IF EXISTS `vista_empleado_cliente`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_empleado_cliente`  AS SELECT concat(`t1`.`nombre1`,`t1`.`apellido1`) AS `empleado`, concat(`t2`.`nombre1`,`t2`.`apellido1`) AS `cliente` FROM (`empleado` `t1` join `cliente` `t2`) WHERE `t1`.`cod_empleado` = `t2`.`cod_cliente` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_proveedor_producto`
--
DROP TABLE IF EXISTS `vista_proveedor_producto`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_proveedor_producto`  AS SELECT `t1`.`razon_social` AS `razon_social`, `t1`.`ciudad` AS `ciudad`, `t2`.`descripcion` AS `descripcion`, `t2`.`valor_compra` AS `valor_compra`, `t2`.`valor_venta` AS `valor_venta`, `t2`.`existencia` AS `existencia` FROM (`proveedor` `t1` join `productos` `t2`) WHERE `t1`.`cod_proveedor` = `t2`.`proveedor_cod` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_tipomov_entrada`
--
DROP TABLE IF EXISTS `vista_tipomov_entrada`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_tipomov_entrada`  AS SELECT `t1`.`cod_tipomov` AS `cod_tipomov`, `t1`.`nombre_mov` AS `nombre_mov`, `t2`.`cod_entrada` AS `cod_entrada`, `t2`.`fecha_entrada` AS `fecha_entrada` FROM (`tipomov` `t1` join `entrada_cabeza` `t2`) WHERE `t1`.`cod_tipomov` = `t2`.`tipomov_cod` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_tipomov_factura`
--
DROP TABLE IF EXISTS `vista_tipomov_factura`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_tipomov_factura`  AS SELECT `t1`.`cod_tipomov` AS `cod_tipomov`, `t1`.`nombre_mov` AS `nombre_mov`, `t2`.`cod_factura` AS `cod_factura`, `t2`.`fecha_factura` AS `fecha_factura` FROM (`tipomov` `t1` join `factura_cabeza` `t2`) WHERE `t1`.`cod_tipomov` = `t2`.`tipomov_cod` ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `cargo`
--
ALTER TABLE `cargo`
  ADD PRIMARY KEY (`cod_cargo`),
  ADD KEY `nombre_cargo` (`nombre_cargo`);

--
-- Indices de la tabla `cartera`
--
ALTER TABLE `cartera`
  ADD PRIMARY KEY (`cod_factura`),
  ADD KEY `fkcodcliente` (`cliente_cod`);

--
-- Indices de la tabla `categoria`
--
ALTER TABLE `categoria`
  ADD PRIMARY KEY (`cod_categoria`),
  ADD KEY `nombre_categoria` (`nombre_categoria`);

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`cod_cliente`),
  ADD KEY `nombre1` (`nombre1`,`apellido1`),
  ADD KEY `empleado_cod` (`empleado_cod`);

--
-- Indices de la tabla `contratista`
--
ALTER TABLE `contratista`
  ADD PRIMARY KEY (`cod_contratista`);

--
-- Indices de la tabla `despacho`
--
ALTER TABLE `despacho`
  ADD PRIMARY KEY (`cod_despacho`),
  ADD KEY `fecha_entrega` (`fecha_entrega`,`entregado`),
  ADD KEY `contratista_cod` (`contratista_cod`),
  ADD KEY `factura_cod` (`factura_cod`);

--
-- Indices de la tabla `empleado`
--
ALTER TABLE `empleado`
  ADD PRIMARY KEY (`cod_empleado`),
  ADD KEY `nombre1` (`nombre1`),
  ADD KEY `cargo_cod` (`cargo_cod`);

--
-- Indices de la tabla `entrada_cabeza`
--
ALTER TABLE `entrada_cabeza`
  ADD PRIMARY KEY (`cod_entrada`),
  ADD KEY `proveedor_cod` (`proveedor_cod`),
  ADD KEY `empleado_cod` (`empleado_cod`),
  ADD KEY `fk_tipomove` (`tipomov_cod`);

--
-- Indices de la tabla `entrada_detalle`
--
ALTER TABLE `entrada_detalle`
  ADD PRIMARY KEY (`cod_edetalle`),
  ADD KEY `entrada_cod` (`entrada_cod`),
  ADD KEY `producto_cod` (`producto_cod`);

--
-- Indices de la tabla `factura_cabeza`
--
ALTER TABLE `factura_cabeza`
  ADD PRIMARY KEY (`cod_factura`),
  ADD KEY `cliente_cod` (`cliente_cod`),
  ADD KEY `empleado_cod` (`empleado_cod`),
  ADD KEY `fk_tipomovf` (`tipomov_cod`);

--
-- Indices de la tabla `factura_detalle`
--
ALTER TABLE `factura_detalle`
  ADD PRIMARY KEY (`cod_facdetalle`),
  ADD KEY `factura_cod` (`factura_cod`),
  ADD KEY `producto_cod` (`producto_cod`);

--
-- Indices de la tabla `nomina`
--
ALTER TABLE `nomina`
  ADD PRIMARY KEY (`cod_nomina`),
  ADD KEY `fecha_nomina` (`fecha_nomina`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`cod_producto`),
  ADD KEY `descripcion` (`descripcion`),
  ADD KEY `categoria_cod` (`categoria_cod`),
  ADD KEY `proveedor_cod` (`proveedor_cod`);

--
-- Indices de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD PRIMARY KEY (`cod_proveedor`),
  ADD KEY `razon_social` (`razon_social`);

--
-- Indices de la tabla `tipomov`
--
ALTER TABLE `tipomov`
  ADD PRIMARY KEY (`cod_tipomov`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `cargo`
--
ALTER TABLE `cargo`
  MODIFY `cod_cargo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `categoria`
--
ALTER TABLE `categoria`
  MODIFY `cod_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `cod_cliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `contratista`
--
ALTER TABLE `contratista`
  MODIFY `cod_contratista` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `despacho`
--
ALTER TABLE `despacho`
  MODIFY `cod_despacho` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT de la tabla `empleado`
--
ALTER TABLE `empleado`
  MODIFY `cod_empleado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `entrada_cabeza`
--
ALTER TABLE `entrada_cabeza`
  MODIFY `cod_entrada` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT de la tabla `entrada_detalle`
--
ALTER TABLE `entrada_detalle`
  MODIFY `cod_edetalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT de la tabla `factura_cabeza`
--
ALTER TABLE `factura_cabeza`
  MODIFY `cod_factura` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT de la tabla `factura_detalle`
--
ALTER TABLE `factura_detalle`
  MODIFY `cod_facdetalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=101;

--
-- AUTO_INCREMENT de la tabla `nomina`
--
ALTER TABLE `nomina`
  MODIFY `cod_nomina` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `cod_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  MODIFY `cod_proveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `tipomov`
--
ALTER TABLE `tipomov`
  MODIFY `cod_tipomov` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cartera`
--
ALTER TABLE `cartera`
  ADD CONSTRAINT `fkcodcliente` FOREIGN KEY (`cliente_cod`) REFERENCES `cliente` (`cod_cliente`),
  ADD CONSTRAINT `fkcodfactura` FOREIGN KEY (`cod_factura`) REFERENCES `factura_cabeza` (`cod_factura`);

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `cliente_ibfk_1` FOREIGN KEY (`empleado_cod`) REFERENCES `empleado` (`cod_empleado`);

--
-- Filtros para la tabla `despacho`
--
ALTER TABLE `despacho`
  ADD CONSTRAINT `despacho_ibfk_1` FOREIGN KEY (`contratista_cod`) REFERENCES `contratista` (`cod_contratista`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `despacho_ibfk_2` FOREIGN KEY (`factura_cod`) REFERENCES `factura_cabeza` (`cod_factura`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `empleado`
--
ALTER TABLE `empleado`
  ADD CONSTRAINT `empleado_ibfk_1` FOREIGN KEY (`cargo_cod`) REFERENCES `cargo` (`cod_cargo`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `entrada_cabeza`
--
ALTER TABLE `entrada_cabeza`
  ADD CONSTRAINT `entrada_cabeza_ibfk_1` FOREIGN KEY (`proveedor_cod`) REFERENCES `proveedor` (`cod_proveedor`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `entrada_cabeza_ibfk_2` FOREIGN KEY (`empleado_cod`) REFERENCES `empleado` (`cod_empleado`),
  ADD CONSTRAINT `fk_tipomove` FOREIGN KEY (`tipomov_cod`) REFERENCES `tipomov` (`cod_tipomov`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `entrada_detalle`
--
ALTER TABLE `entrada_detalle`
  ADD CONSTRAINT `entrada_detalle_ibfk_1` FOREIGN KEY (`entrada_cod`) REFERENCES `entrada_cabeza` (`cod_entrada`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `entrada_detalle_ibfk_2` FOREIGN KEY (`producto_cod`) REFERENCES `productos` (`cod_producto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `factura_cabeza`
--
ALTER TABLE `factura_cabeza`
  ADD CONSTRAINT `factura_cabeza_ibfk_1` FOREIGN KEY (`cliente_cod`) REFERENCES `cliente` (`cod_cliente`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `factura_cabeza_ibfk_2` FOREIGN KEY (`empleado_cod`) REFERENCES `empleado` (`cod_empleado`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_tipomovf` FOREIGN KEY (`tipomov_cod`) REFERENCES `tipomov` (`cod_tipomov`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `factura_detalle`
--
ALTER TABLE `factura_detalle`
  ADD CONSTRAINT `factura_detalle_ibfk_1` FOREIGN KEY (`factura_cod`) REFERENCES `factura_cabeza` (`cod_factura`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `factura_detalle_ibfk_2` FOREIGN KEY (`producto_cod`) REFERENCES `productos` (`cod_producto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `productos_ibfk_1` FOREIGN KEY (`categoria_cod`) REFERENCES `categoria` (`cod_categoria`),
  ADD CONSTRAINT `productos_ibfk_2` FOREIGN KEY (`proveedor_cod`) REFERENCES `proveedor` (`cod_proveedor`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
