-- ============================================
-- SISTEMA DE GESTIÓN DE CRÉDITOS - CREDITFLOW
-- Base de datos SQLite optimizada
-- Versión 2.0
-- ============================================

PRAGMA foreign_keys=ON;
PRAGMA encoding='UTF-8';

-- ============================================
-- ELIMINAR TABLAS SI EXISTEN (para reinicio limpio)
-- ============================================
DROP TABLE IF EXISTS auditoria;
DROP TABLE IF EXISTS arqueos;
DROP TABLE IF EXISTS caja;
DROP TABLE IF EXISTS pagos;
DROP TABLE IF EXISTS creditos;
DROP TABLE IF EXISTS aprobaciones;
DROP TABLE IF EXISTS solicitudes;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS zonas;
DROP TABLE IF EXISTS configuracion;
DROP TABLE IF EXISTS productos;

-- ============================================
-- TABLA: ZONAS
-- ============================================
CREATE TABLE zonas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT UNIQUE NOT NULL,
    descripcion TEXT,
    activo INTEGER DEFAULT 1,
    fecha_creacion TEXT DEFAULT (datetime('now','localtime'))
);

-- ============================================
-- TABLA: USUARIOS (Optimizada)
-- ============================================
CREATE TABLE usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    rol TEXT NOT NULL CHECK(rol IN ('cliente','agente','gerente','admin')),
    telefono TEXT DEFAULT '',
    zona_id INTEGER REFERENCES zonas(id),
    creado_por INTEGER,
    activo INTEGER DEFAULT 1,
    bloqueado INTEGER DEFAULT 0,
    intentos_fallidos INTEGER DEFAULT 0,
    ultimo_login TEXT,
    fecha_alta TEXT DEFAULT (datetime('now','localtime')),
    fecha_modificacion TEXT DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (creado_por) REFERENCES usuarios(id)
);

-- ============================================
-- TABLA: CLIENTES (Optimizada)
-- ============================================
CREATE TABLE clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario INTEGER UNIQUE REFERENCES usuarios(id),
    
    -- Datos del titular
    titular_nombre TEXT, 
    titular_curp TEXT UNIQUE, 
    titular_direccion TEXT, 
    titular_telefono TEXT, 
    titular_fecha_nac TEXT,
    titular_rfc TEXT,
    titular_sexo TEXT CHECK(titular_sexo IN ('M','F')),
    
    -- Datos del aval
    aval_nombre TEXT, 
    aval_curp TEXT, 
    aval_direccion TEXT, 
    aval_telefono TEXT, 
    aval_parentesco TEXT,
    aval_rfc TEXT,
    
    -- Informacion laboral
    laboral_empresa TEXT, 
    laboral_puesto TEXT, 
    laboral_antiguedad INTEGER CHECK(laboral_antiguedad >= 0), 
    laboral_salario REAL CHECK(laboral_salario >= 0),
    laboral_direccion TEXT, 
    laboral_telefono TEXT,
    laboral_tipo TEXT CHECK(laboral_tipo IN ('formal','informal','independiente','jubilado')),
    
    -- Informacion economica
    eco_ingresos REAL CHECK(eco_ingresos >= 0), 
    eco_egresos REAL CHECK(eco_egresos >= 0), 
    eco_otros_ingresos REAL CHECK(eco_otros_ingresos >= 0),
    eco_capacidad_pago REAL GENERATED ALWAYS AS (eco_ingresos + eco_otros_ingresos - eco_egresos) STORED,
    
    -- Informacion financiera
    fin_banco TEXT, 
    fin_tarjeta TEXT, 
    fin_ref1 TEXT, 
    fin_ref2 TEXT,
    fin_buro_score INTEGER CHECK(fin_buro_score BETWEEN 0 AND 800),
    
    -- Control interno
    id_agente INTEGER REFERENCES usuarios(id),
    fecha_ingreso TEXT DEFAULT (datetime('now','localtime')),
    ciclos_concluidos INTEGER DEFAULT 0 CHECK(ciclos_concluidos >= 0),
    cumplimiento REAL DEFAULT 100.0 CHECK(cumplimiento BETWEEN 0 AND 100),
    calificacion REAL DEFAULT 0.0 CHECK(calificacion BETWEEN 0 AND 10),
    
    -- Estado
    estado TEXT DEFAULT 'activo' CHECK(estado IN ('activo','inactivo','bloqueado')),
    observaciones TEXT,
    fecha_ultima_actualizacion TEXT DEFAULT (datetime('now','localtime'))
);

-- ============================================
-- TABLA: PRODUCTOS (NUEVA)
-- ============================================
CREATE TABLE productos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo TEXT UNIQUE NOT NULL,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    monto_minimo REAL CHECK(monto_minimo >= 0),
    monto_maximo REAL CHECK(monto_maximo >= 0),
    plazo_minimo INTEGER CHECK(plazo_minimo > 0),
    plazo_maximo INTEGER CHECK(plazo_maximo > 0),
    tasa_interes REAL CHECK(tasa_interes >= 0),
    tasa_moratoria REAL CHECK(tasa_moratoria >= 0),
    comision_apertura REAL DEFAULT 0,
    seguro REAL DEFAULT 0,
    activo INTEGER DEFAULT 1,
    fecha_creacion TEXT DEFAULT (datetime('now','localtime'))
);

-- ============================================
-- TABLA: SOLICITUDES (Optimizada)
-- ============================================
CREATE TABLE solicitudes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_cliente INTEGER REFERENCES usuarios(id),
    id_agente INTEGER REFERENCES usuarios(id),
    id_producto INTEGER REFERENCES productos(id),
    producto TEXT NOT NULL,
    monto REAL NOT NULL CHECK(monto > 0),
    plazo INTEGER NOT NULL CHECK(plazo > 0 AND plazo <= 60),
    cuota REAL CHECK(cuota > 0),
    total_pagar REAL CHECK(total_pagar > 0),
    tasa_interes REAL,
    tasa_moratoria REAL,
    estado TEXT DEFAULT 'pendiente_agente' CHECK(estado IN (
        'pendiente_agente', 
        'pendiente_gerente', 
        'pendiente_admin', 
        'aprobada', 
        'rechazada', 
        'desembolsada', 
        'cancelada'
    )),
    pdf_path TEXT DEFAULT '',
    fecha TEXT DEFAULT (datetime('now','localtime')),
    fecha_aprobacion TEXT,
    fecha_rechazo TEXT,
    motivo_rechazo TEXT,
    observaciones TEXT,
    FOREIGN KEY (id_producto) REFERENCES productos(id)
);

-- ============================================
-- TABLA: APROBACIONES (Optimizada)
-- ============================================
CREATE TABLE aprobaciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_solicitud INTEGER REFERENCES solicitudes(id),
    nivel TEXT NOT NULL CHECK(nivel IN ('agente','gerente','admin')),
    id_usuario INTEGER REFERENCES usuarios(id),
    decision TEXT CHECK(decision IN ('aprobado','rechazado','pendiente')),
    comentario TEXT,
    fecha TEXT DEFAULT (datetime('now','localtime')),
    ip_address TEXT,
    user_agent TEXT
);

-- ============================================
-- TABLA: CREDITOS (Optimizada)
-- ============================================
CREATE TABLE creditos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_solicitud INTEGER REFERENCES solicitudes(id),
    id_cliente INTEGER REFERENCES usuarios(id),
    id_agente INTEGER REFERENCES usuarios(id),
    id_zona INTEGER REFERENCES zonas(id),
    id_producto INTEGER REFERENCES productos(id),
    producto TEXT, 
    monto REAL CHECK(monto > 0), 
    plazo INTEGER CHECK(plazo > 0), 
    cuota REAL CHECK(cuota > 0), 
    total_pagar REAL CHECK(total_pagar > 0),
    saldo REAL CHECK(saldo >= 0),
    pagos_hechos INTEGER DEFAULT 0 CHECK(pagos_hechos >= 0),
    pagos_totales INTEGER DEFAULT 0,
    estado TEXT DEFAULT 'activo' CHECK(estado IN ('activo', 'concluido', 'moroso', 'cancelado', 'refinanciado')),
    fecha_desembolso TEXT DEFAULT (datetime('now','localtime')),
    fecha_ultimo_pago TEXT,
    fecha_proximo_pago TEXT,
    dias_mora INTEGER DEFAULT 0 CHECK(dias_mora >= 0),
    intereses_moratorios REAL DEFAULT 0,
    FOREIGN KEY (id_producto) REFERENCES productos(id)
);

-- ============================================
-- TABLA: PAGOS (Optimizada)
-- ============================================
CREATE TABLE pagos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_credito INTEGER REFERENCES creditos(id),
    numero INTEGER CHECK(numero > 0),
    monto REAL CHECK(monto > 0),
    monto_capital REAL,
    monto_interes REAL,
    fecha_programada TEXT,
    fecha_pago TEXT,
    estado TEXT DEFAULT 'pendiente' CHECK(estado IN ('pendiente', 'pagado', 'vencido', 'moratorio')),
    cobrado_por INTEGER REFERENCES usuarios(id),
    metodo TEXT DEFAULT 'efectivo' CHECK(metodo IN ('efectivo', 'transferencia', 'deposito', 'tarjeta', 'cheque')),
    folio TEXT DEFAULT '',
    referencia_pago TEXT,
    observaciones TEXT,
    fecha_registro TEXT DEFAULT (datetime('now','localtime'))
);

-- ============================================
-- TABLA: CAJA (Optimizada)
-- ============================================
CREATE TABLE caja (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT DEFAULT (datetime('now','localtime')),
    tipo TEXT CHECK(tipo IN ('ingreso', 'egreso')),
    monto REAL CHECK(monto > 0),
    concepto TEXT NOT NULL,
    referencia TEXT,
    id_usuario INTEGER REFERENCES usuarios(id),
    id_credito INTEGER REFERENCES creditos(id),
    id_pago INTEGER REFERENCES pagos(id),
    saldo_parcial REAL,
    comprobante_path TEXT,
    observaciones TEXT
);

-- ============================================
-- TABLA: ARQUEOS (Optimizada)
-- ============================================
CREATE TABLE arqueos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT DEFAULT (datetime('now','localtime')),
    fecha_inicio TEXT,
    fecha_fin TEXT,
    total_esperado REAL CHECK(total_esperado >= 0),
    total_contado REAL CHECK(total_contado >= 0),
    diferencia REAL,
    nota TEXT,
    id_usuario INTEGER REFERENCES usuarios(id),
    estado TEXT DEFAULT 'abierto' CHECK(estado IN ('abierto', 'cerrado', 'verificado'))
);

-- ============================================
-- TABLA: AUDITORIA (Optimizada)
-- ============================================
CREATE TABLE auditoria (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT DEFAULT (datetime('now','localtime')),
    id_usuario INTEGER REFERENCES usuarios(id),
    accion TEXT NOT NULL,
    tabla TEXT,
    id_registro INTEGER,
    detalle TEXT,
    ip_address TEXT,
    user_agent TEXT
);

-- ============================================
-- TABLA: SESIONES
-- ============================================
CREATE TABLE sesiones (
    token TEXT PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuarios(id),
    expira TEXT,
    ip_address TEXT,
    user_agent TEXT,
    fecha_creacion TEXT DEFAULT (datetime('now','localtime'))
);

-- ============================================
-- TABLA: CONFIGURACION (NUEVA)
-- ============================================
CREATE TABLE configuracion (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    clave TEXT UNIQUE NOT NULL,
    valor TEXT NOT NULL,
    descripcion TEXT,
    tipo TEXT CHECK(tipo IN ('texto', 'numero', 'booleano', 'json')),
    modificado_por INTEGER REFERENCES usuarios(id),
    fecha_modificacion TEXT DEFAULT (datetime('now','localtime'))
);

-- ============================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_rol ON usuarios(rol);
CREATE INDEX idx_usuarios_zona ON usuarios(zona_id);

CREATE INDEX idx_clients_agente ON clients(id_agente);
CREATE INDEX idx_clients_curp ON clients(titular_curp);
CREATE INDEX idx_clients_usuario ON clients(id_usuario);

CREATE INDEX idx_solicitudes_estado ON solicitudes(estado);
CREATE INDEX idx_solicitudes_cliente ON solicitudes(id_cliente);
CREATE INDEX idx_solicitudes_agente ON solicitudes(id_agente);
CREATE INDEX idx_solicitudes_fecha ON solicitudes(fecha);

CREATE INDEX idx_creditos_cliente ON creditos(id_cliente);
CREATE INDEX idx_creditos_agente ON creditos(id_agente);
CREATE INDEX idx_creditos_estado ON creditos(estado);
CREATE INDEX idx_creditos_saldo ON creditos(saldo);

CREATE INDEX idx_pagos_credito ON pagos(id_credito);
CREATE INDEX idx_pagos_estado_fecha ON pagos(estado, fecha_programada);
CREATE INDEX idx_pagos_fecha_pago ON pagos(fecha_pago);

CREATE INDEX idx_caja_fecha ON caja(fecha);
CREATE INDEX idx_caja_usuario ON caja(id_usuario);
CREATE INDEX idx_caja_tipo ON caja(tipo);

CREATE INDEX idx_auditoria_fecha ON auditoria(fecha);
CREATE INDEX idx_auditoria_usuario ON auditoria(id_usuario);
CREATE INDEX idx_auditoria_accion ON auditoria(accion);

-- ============================================
-- TRIGGERS PARA AUTOMATIZACIÓN
-- ============================================

-- Trigger: Actualizar saldo del crédito al registrar un pago
CREATE TRIGGER trg_actualizar_saldo_credito
AFTER INSERT ON pagos
WHEN NEW.estado = 'pagado'
BEGIN
    UPDATE creditos 
    SET 
        saldo = saldo - NEW.monto,
        pagos_hechos = pagos_hechos + 1,
        fecha_ultimo_pago = NEW.fecha_pago,
        fecha_proximo_pago = (
            SELECT fecha_programada 
            FROM pagos 
            WHERE id_credito = NEW.id_credito 
            AND estado = 'pendiente' 
            ORDER BY numero ASC 
            LIMIT 1
        )
    WHERE id = NEW.id_credito;
    
    -- Actualizar estado del crédito si saldo es 0
    UPDATE creditos 
    SET estado = 'concluido' 
    WHERE id = NEW.id_credito AND saldo <= 0;
END;

-- Trigger: Registrar en auditoría inserción de usuarios
CREATE TRIGGER trg_audit_usuarios_insert
AFTER INSERT ON usuarios
BEGIN
    INSERT INTO auditoria (id_usuario, accion, tabla, id_registro, detalle)
    VALUES (NEW.id, 'INSERT', 'usuarios', NEW.id, 'Usuario creado: ' || NEW.nombre);
END;

-- Trigger: Registrar en auditoría actualización de usuarios
CREATE TRIGGER trg_audit_usuarios_update
AFTER UPDATE ON usuarios
BEGIN
    INSERT INTO auditoria (id_usuario, accion, tabla, id_registro, detalle)
    VALUES (NEW.id, 'UPDATE', 'usuarios', NEW.id, 'Usuario actualizado: ' || NEW.nombre);
END;

-- Trigger: Actualizar fecha de modificación en usuarios
CREATE TRIGGER trg_usuarios_update_timestamp
AFTER UPDATE ON usuarios
BEGIN
    UPDATE usuarios SET fecha_modificacion = datetime('now','localtime')
    WHERE id = NEW.id;
END;

-- ============================================
-- DATOS DE PRUEBA (SEMILLA)
-- ============================================

-- Zonas
INSERT INTO zonas (id, nombre, descripcion) VALUES
(1, 'Norte', 'Zona norte del país'),
(2, 'Sur', 'Zona sur del país');

-- Usuarios
INSERT INTO usuarios (id, nombre, email, password_hash, rol, telefono, zona_id, activo) VALUES
(1, 'Director General', 'admin@creditflow.app', 'eca75d1f42cad46a$0ff268173fb3e7febcaf16bc5b063cb44555bf1ea18c3d539a9dc00c1e47e942', 'admin', '', NULL, 1),
(2, 'Gerente Regional', 'gerente@creditflow.app', '0a6c3438d28909b7$2cacc51e058dffff7568be6872ecf33242ca0c9eac4dddc7d937d58a0509435d', 'gerente', '', NULL, 1),
(3, 'Agente Carlos', 'agente1@creditflow.app', 'd7c080e99b0c80ca$b4a8fd468ea5f00828538fff61d50e8b6d061bded65b9c814789866ee62cb5e1', 'agente', '', 1, 1),
(4, 'Agente Maria', 'agente2@creditflow.app', 'af72f6b35392fa72$633f510ea29c163a6f6b5975671475b69595555714553ec1cec98dd069b1b37b', 'agente', '', 2, 1),
(5, 'Juan Perez', 'cliente1@correo.com', '044aef634e1eed76$e3ea5c0d1e7b138ef9390bbf3202ce625d746f6a52b9801a590d611209ab6bbd', 'cliente', '', 1, 1),
(6, 'Ana Lopez', 'cliente2@correo.com', 'e1b65b76b76e12e8$83f3906a0434f8c414ff986d9cdbc6718713f7aa71886c4eb21f30dec534a549', 'cliente', '', 2, 1);

-- Productos
INSERT INTO productos (codigo, nombre, descripcion, monto_minimo, monto_maximo, plazo_minimo, plazo_maximo, tasa_interes, tasa_moratoria, comision_apertura, seguro) VALUES
('P1', 'Crédito Express', 'Crédito rápido para emergencias', 500, 5000, 10, 20, 0.05, 0.02, 50, 10),
('P2', 'Crédito Personal', 'Crédito personal para gastos varios', 1000, 10000, 15, 36, 0.04, 0.015, 100, 20),
('P3', 'Crédito Premium', 'Crédito para clientes VIP', 5000, 50000, 20, 48, 0.03, 0.01, 200, 50);

-- Clientes
INSERT INTO clients (id, id_usuario, titular_nombre, titular_curp, titular_direccion, titular_telefono, titular_fecha_nac, titular_rfc, titular_sexo, aval_nombre, aval_curp, aval_direccion, aval_telefono, aval_parentesco, aval_rfc, laboral_empresa, laboral_puesto, laboral_antiguedad, laboral_salario, laboral_direccion, laboral_telefono, laboral_tipo, eco_ingresos, eco_egresos, eco_otros_ingresos, fin_banco, fin_tarjeta, fin_ref1, fin_ref2, id_agente, ciclos_concluidos, cumplimiento) VALUES
(1, 5, 'Juan Perez Martinez', 'PEMJ900101HDFRRN04', 'Calle 5 de Mayo 123, Monterrey', '8112345678', '1990-01-01', 'PEMJ900101', 'M', 'Luis Perez', 'PELU650505HDFRRS02', 'Av. Juarez 45, Monterrey', '8118765432', 'Hermano', 'PELU650505', 'Maquilas del Norte', 'Operador', 3, 8500.0, 'Calle Industria 7', '8122223344', 'formal', 9500.0, 6200.0, 0.0, 'BBVA 0123', 'TDC Banorte 4567', 'Ref 1: Mario Diaz', 'Ref 2: Rosa Torres', 3, 0, 73.33),
(2, 6, 'Ana Lopez Garcia', 'LOGA950620MMCPRN05', 'Calle 16 de Septiembre 888, Merida', '9991234567', '1995-06-20', 'LOGA950620', 'F', 'Rosa Garcia', 'GACR700410MYNRRS03', 'Calle 60 #200, Merida', '9997654321', 'Madre', 'GACR700410', 'Servicios Turisticos Sur', 'Coordinadora', 2, 11000.0, 'Av. Colon 300', '9991112233', 'formal', 12500.0, 7800.0, 1500.0, 'Santander 7788', 'TDC HSBC 9900', 'Ref 1: Pedro Gil', 'Ref 2: Sofia Ruiz', 4, 2, 100.0);

-- Solicitudes
INSERT INTO solicitudes (id, id_cliente, id_agente, id_producto, producto, monto, plazo, cuota, total_pagar, estado, pdf_path) VALUES
(1, 5, 3, 1, 'P1', 1000.0, 15, 95.0, 1425.0, 'pendiente_agente', 'solicitud_1.pdf'),
(2, 6, 4, 2, 'P2', 3000.0, 23, 210.0, 4830.0, 'pendiente_gerente', 'solicitud_2.pdf');

-- Créditos
INSERT INTO creditos (id, id_solicitud, id_cliente, id_agente, id_zona, id_producto, producto, monto, plazo, cuota, total_pagar, saldo, pagos_hechos, pagos_totales, estado) VALUES
(1, NULL, 5, 3, 1, 1, 'P1', 1000.0, 15, 95.0, 1425.0, 380.0, 11, 15, 'activo');

-- Pagos (11 pagos realizados, 4 pendientes)
INSERT INTO pagos (id, id_credito, numero, monto, fecha_programada, fecha_pago, estado, cobrado_por, metodo) VALUES
(1, 1, 1, 95.0, '2026-03-07', '2026-03-07', 'pagado', 3, 'efectivo'),
(2, 1, 2, 95.0, '2026-03-14', '2026-03-14', 'pagado', 3, 'efectivo'),
(3, 1, 3, 95.0, '2026-03-21', '2026-03-21', 'pagado', 3, 'efectivo'),
(4, 1, 4, 95.0, '2026-03-28', '2026-03-28', 'pagado', 3, 'efectivo'),
(5, 1, 5, 95.0, '2026-04-04', '2026-04-04', 'pagado', 3, 'efectivo'),
(6, 1, 6, 95.0, '2026-04-11', '2026-04-11', 'pagado', 3, 'efectivo'),
(7, 1, 7, 95.0, '2026-04-18', '2026-04-18', 'pagado', 3, 'efectivo'),
(8, 1, 8, 95.0, '2026-04-25', '2026-04-25', 'pagado', 3, 'efectivo'),
(9, 1, 9, 95.0, '2026-05-02', '2026-05-02', 'pagado', 3, 'efectivo'),
(10, 1, 10, 95.0, '2026-05-09', '2026-05-09', 'pagado', 3, 'efectivo'),
(11, 1, 11, 95.0, '2026-05-16', '2026-05-16', 'pagado', 3, 'efectivo'),
(12, 1, 12, 95.0, '2026-05-23', NULL, 'pendiente', NULL, 'efectivo'),
(13, 1, 13, 95.0, '2026-05-30', NULL, 'pendiente', NULL, 'efectivo'),
(14, 1, 14, 95.0, '2026-06-06', NULL, 'pendiente', NULL, 'efectivo'),
(15, 1, 15, 95.0, '2026-06-13', NULL, 'pendiente', NULL, 'efectivo');

-- Caja (movimientos de cobranza y desembolso)
INSERT INTO caja (fecha, tipo, monto, concepto, referencia, id_usuario, id_credito, id_pago) VALUES
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #1', 'pago_seed_1', 3, 1, 1),
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #2', 'pago_seed_2', 3, 1, 2),
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #3', 'pago_seed_3', 3, 1, 3),
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #4', 'pago_seed_4', 3, 1, 4),
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #5', 'pago_seed_5', 3, 1, 5),
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #6', 'pago_seed_6', 3, 1, 6),
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #7', 'pago_seed_7', 3, 1, 7),
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #8', 'pago_seed_8', 3, 1, 8),
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #9', 'pago_seed_9', 3, 1, 9),
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #10', 'pago_seed_10', 3, 1, 10),
('2026-08-27 22:48:08', 'ingreso', 95.0, 'COBRANZA credito 1 pago #11', 'pago_seed_11', 3, 1, 11),
('2026-08-27 22:48:08', 'egreso', 1000.0, 'DESEMBOLSO de credito de prueba', 'credito_1', 1, 1, NULL);

-- Arqueos
INSERT INTO arqueos (id, fecha, total_esperado, total_contado, diferencia, nota, id_usuario, estado) VALUES
(1, '2026-08-27 22:48:08', 45.0, 45.0, 0.0, 'Arqueo inicial semilla', 1, 'cerrado');

-- Auditoría
INSERT INTO auditoria (id, fecha, id_usuario, accion, tabla, id_registro, detalle) VALUES
(1, '2026-08-27 22:48:08', 1, 'seed', 'sistema', NULL, 'Carga de datos semilla optimizada');

-- Configuración inicial
INSERT INTO configuracion (clave, valor, descripcion, tipo) VALUES
('version', '2.0', 'Versión de la base de datos', 'texto'),
('fecha_instalacion', datetime('now','localtime'), 'Fecha de instalación', 'texto'),
('dias_mora_limite', '30', 'Días de mora para pasar a moroso', 'numero'),
('tasa_interes_default', '0.05', 'Tasa de interés por defecto', 'numero'),
('tasa_moratoria_default', '0.02', 'Tasa moratoria por defecto', 'numero');

-- ============================================
-- RESET SECUENCIAS
-- ============================================
DELETE FROM sqlite_sequence;
INSERT INTO sqlite_sequence VALUES('zonas',2);
INSERT INTO sqlite_sequence VALUES('usuarios',6);
INSERT INTO sqlite_sequence VALUES('clients',2);
INSERT INTO sqlite_sequence VALUES('solicitudes',2);
INSERT INTO sqlite_sequence VALUES('creditos',1);
INSERT INTO sqlite_sequence VALUES('pagos',15);
INSERT INTO sqlite_sequence VALUES('caja',12);
INSERT INTO sqlite_sequence VALUES('arqueos',1);
INSERT INTO sqlite_sequence VALUES('auditoria',1);
INSERT INTO sqlite_sequence VALUES('productos',3);
INSERT INTO sqlite_sequence VALUES('configuracion',5);

-- ============================================
-- FIN DEL ARCHIVO
-- ============================================
