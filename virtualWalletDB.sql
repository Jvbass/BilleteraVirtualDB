										/*Evaluacion Integradora Modulo 3 SQL*/
										-- Autor: Juan V. Pino C.

-- Creamos la base de datos
CREATE DATABASE IF NOT EXISTS VirtualWallet;
USE VirtualWallet;

-- Creamos tablas
CREATE TABLE IF NOT EXISTS usuarios(
	user_id INT AUTO_INCREMENT PRIMARY KEY, -- En MySQL al usar AUTO INCREMENT se asigna como NOT NULL, lo mismo cuando se usa NOT NULL.
	nombre VARCHAR(50) NOT NULL, -- VARCHAR(50) Permite hasta 50 caracteres
	correo_electronico VARCHAR (100) NOT NULL,
	contrasena VARCHAR(100) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Ingresa automaticamente la fecha y hora actual.
);

CREATE TABLE IF NOT EXISTS monedas( 
	currency_id INT AUTO_INCREMENT PRIMARY KEY,
    currency_name ENUM("USD", "EUR", "YEN") NOT NULL, -- con ENUM definimos valores específicos que pueden ser ingresados en este campo .
    currency_symbol VARCHAR(5) NOT NULL
);

CREATE TABLE IF NOT EXISTS cuentas (
	cuenta_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    currency_id INT NOT NULL,
    saldo DECIMAL(10,2) NOT NULL, -- DECIMAL (10,2), permite 10 digitos antes de la coma y 2 decimales
	CONSTRAINT unique_usuario_moneda UNIQUE (user_id, currency_id), -- Con CONSTRAINT definimos la restriccion UNIQUE donde la combinacion entre user_id y currency_id son unicas y no se pueden repetir
    FOREIGN KEY (user_id) REFERENCES usuarios(user_id),-- Se asignan las claves foraneas haciendo referencia a la tabla que provienen
    FOREIGN KEY (currency_id) REFERENCES monedas(currency_id)
);

CREATE TABLE IF NOT EXISTS transacciones(
	transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_cuenta_id INT NOT NULL,
    receiver_cuenta_id INT NOT NULL,
    importe DECIMAL(10,2) NOT NULL,
    currency_id INT NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(sender_cuenta_id) REFERENCES cuentas(cuenta_id),
    FOREIGN KEY(receiver_cuenta_id) REFERENCES cuentas(cuenta_id)
);
	
-- Insertamos datos en usuarios
INSERT INTO usuarios (nombre, correo_electronico, contrasena)
VALUES
('Juan Pérez', 'juan@example.com', sha2('contraseña123',256)),
('María González', 'maria@example.com', sha2('segura456',256)),
('Pedro Ramirez', 'pedro@example.com', sha2('clave789',256));

-- Insertamos datos en monedas
INSERT INTO monedas (currency_name, currency_symbol)
VALUES
('USD', '$'),
('EUR', '€'),
('YEN', '¥');

-- Insertamos datos en cuentas
INSERT INTO cuentas (user_id, currency_id, saldo)
VALUES
(1, 1, 1000.0),
(1, 2, 1000.0),
(1, 3, 1000.0),
(2, 1, 1000.0),
(2, 2, 1000.0),
(2, 3, 1000.0),
(3, 1, 1000.0),
(3, 2, 1000.0),
(3, 3, 1000.0);


-- Realizamos transacciones entre cuentas usando procedimiento TRANSACTION
/* Este PROCEDURE recibe como parametros sender_cuenta_id, receiver_cuenta_id, monto y currency_id.*/
DROP PROCEDURE IF EXISTS `Transaccion`;
-- Creamos el delimitador // en reemplazo de ; para poder realizar los procedimientos de la TRANSACTION
DELIMITER // 
-- Crea el PROCEDURE Transaction() que recibe por parametros el la id de la cuenta de origen y de destino, el monto y la id de la moneda utilizada
CREATE PROCEDURE Transaccion(IN sender_cuenta_id INT, IN receiver_cuenta_id INT, IN monto DECIMAL(10,2), IN tipo_moneda_sender INT)
BEGIN
-- Declaramos las variables saldo_cuenta_origen, tipo_moneda_sender y tipo_moneda_receiver para mas adelante validar la transaccion
    DECLARE saldo_cuenta_origen DECIMAL(10,2);
    DECLARE tipo_moneda_receiver INT;
    
    START TRANSACTION;
    -- Restamos el monto a la cuenta origen
    UPDATE cuentas
    SET saldo = saldo - monto
    WHERE cuenta_id = sender_cuenta_id;

    -- Sumamos el monto a la cuenta destino
    UPDATE cuentas
    SET saldo = saldo + monto
    WHERE cuenta_id = receiver_cuenta_id;

    -- Asignamos los valores de la tabla cuentas a saldo_cuenta_origen y tipo_moneda_sender segun el parametro recibido como sender_cuenta_id
    SELECT saldo, currency_id INTO saldo_cuenta_origen, tipo_moneda_sender
    FROM cuentas
    WHERE cuenta_id = sender_cuenta_id;

    -- Asignamos los datos de la tabla cuentas a tipo_moneda_receiver segun el parametro recibido como receiver_cuenta_id
    SELECT currency_id INTO tipo_moneda_receiver
    FROM cuentas
    WHERE cuenta_id = receiver_cuenta_id;

	-- Validamos que el saldo de la cuenta origen tenga suficiente monto para realizar la transferencia
    IF saldo_cuenta_origen < monto THEN
        ROLLBACK; -- Con rollback cancelamos toda la operacion realizada anteriormente y termina el PROCEDURE
        SELECT 'Transacción rechazada, saldo insuficiente en cuenta origen' AS Mensaje; -- Enviamos mensaje con detalle del error
	END IF;
    -- Validamos que el tipo de moneda de ambas cuentas coincidan    
	IF tipo_moneda_sender != tipo_moneda_receiver THEN
        ROLLBACK;
        SELECT 'Transacción rechazada, el tipo de moneda no coincide' AS Mensaje; 
    ELSE
        -- Si la cuenta origen tiene saldo suficiente y los tipos de moneda coincide guardamos la transaccion en la tabla transacciones
        INSERT INTO transacciones (sender_cuenta_id, receiver_cuenta_id, importe, currency_id)
        VALUES (sender_cuenta_id, receiver_cuenta_id, monto, currency_id);

        COMMIT; -- Con commit confirmamos la transaccion y se realizan los cambios en todas las tablas (UPDATE en cuentas e INSERT en transacciones)
        SELECT 'Transferencia realizada con éxito' AS Mensaje;
    END IF;
END // -- Fin del PROCEDURE
-- Reasignamo ; como delimitador.
DELIMITER ; 

-- Llamamos al Procedimiento Transaccion() con los valores deseados
CALL Transaccion(1, 7, 150.00, 1); -- Envio de 150.00 Dolares de la cuenta 1 a la cuenta 7
CALL Transaccion(2, 5, 100.00, 2); -- Envio de 100.00 Euro de la cuenta 2 a la cuenta 5
CALL Transaccion(3, 9, 50.00, 3); -- Envio de 50.00 Yen de la cuenta 3 a la cuenta 9
CALL Transaccion(4, 1, 250.00, 1);
CALL Transaccion(5, 2, 125.00, 2);
CALL Transaccion(6, 3, 300.00, 3);
CALL Transaccion(7, 1, 75.00, 1);
CALL Transaccion(8, 4, 450.00, 2);
CALL Transaccion(9, 6, 325.00, 3);
CALL Transaccion(7, 4, 235.00, 1);
CALL Transaccion(5, 8, 235.00, 2);
