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
  fecha_alta TEXT DEFAULT (datetime('now','localtime'))
);

CREATE TABLE solicitudes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  id_cliente INTEGER REFERENCES usuarios(id),
  id_agente INTEGER REFERENCES usuarios(id),
  producto TEXT NOT NULL,
  monto REAL NOT NULL,
  plazo INTEGER NOT NULL,
  cuota REAL,
  total_pagar REAL,
  estado TEXT DEFAULT 'pendiente_agente',
  pdf_path TEXT DEFAULT '',
  fecha TEXT DEFAULT (datetime('now','localtime'))
);

CREATE TABLE creditos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  id_solicitud INTEGER,
  id_cliente INTEGER REFERENCES usuarios(id),
  id_agente INTEGER,
  id_zona INTEGER,
  producto TEXT,
  monto REAL,
  plazo INTEGER,
  cuota REAL,
  total_pagar REAL,
  saldo REAL,
  pagos_hechos INTEGER DEFAULT 0,
  estado TEXT DEFAULT 'activo',
  fecha_desembolso TEXT DEFAULT (datetime('now','localtime'))
);

CREATE TABLE pagos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  id_credito INTEGER REFERENCES creditos(id),
  numero INTEGER,
  monto REAL,
  fecha_programada TEXT,
  fecha_pago TEXT,
  estado TEXT DEFAULT 'pendiente',
  cobrado_por INTEGER,
  metodo TEXT DEFAULT 'efectivo',
  folio TEXT DEFAULT ''
);
