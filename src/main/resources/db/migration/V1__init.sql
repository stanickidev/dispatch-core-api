-- Núcleo de Despacho Logístico | Schema inicial (Flyway V1)

-- Sequências --------------------------------------------------------------------------------------

CREATE SEQUENCE IF NOT EXISTS customer_internal_code_seq START WITH 1;
CREATE SEQUENCE IF NOT EXISTS shipper_internal_code_seq START WITH 1;
CREATE SEQUENCE IF NOT EXISTS stock_internal_code_seq START WITH 1;

--- Eventos Outbox ---------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS outbox_event
(
    id             VARCHAR(26)              NOT NULL,
    aggregate_type VARCHAR(100)             NOT NULL, -- Ex. "Order", "Customer"...
    aggregate_id   VARCHAR(100)             NOT NULL, -- ID da entidade de origem
    event_type     VARCHAR(255)             NOT NULL, -- Ex: "OrderCreatedEvent"
    payload        JSONB                    NOT NULL, -- Payload em formato JSON binário
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at   TIMESTAMP WITH TIME ZONE,          -- NULL indica pendente
    correlation_id VARCHAR(100),                      -- Para Distributed Tracing
    failure_reason TEXT,                              -- Guarda o erro caso o envio falhe

    CONSTRAINT pk_outbox_event PRIMARY KEY (id)
);

-- Índice parcial de alta performance para o worker
CREATE INDEX idx_outbox_event_pending ON outbox_event (created_at) WHERE processed_at IS NULL;

--- Clientes ---------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS customer
(
    id            VARCHAR(26)  NOT NULL,
    internal_code INTEGER      NOT NULL DEFAULT nextval('customer_internal_code_seq'),
    document      VARCHAR(14)  NOT NULL,
    name          VARCHAR(150) NOT NULL,
    email         VARCHAR(256),
    birth_date    DATE,

    contact_name  VARCHAR(30),
    area_code     VARCHAR(3),
    phone_number  VARCHAR(15),

    postal_code   VARCHAR(9),
    state         VARCHAR(2),
    city          VARCHAR(100),
    district      VARCHAR(100),
    street        VARCHAR(100),
    number        VARCHAR(50),

    status        VARCHAR(10)  NOT NULL DEFAULT 'ACTIVE',
    version       BIGINT       NOT NULL DEFAULT 0,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT customer_pk PRIMARY KEY (id),
    CONSTRAINT customer_document_uk UNIQUE (document),
    CONSTRAINT customer_email_uk UNIQUE (email),
    CONSTRAINT customer_phone_uk UNIQUE (phone_number),
    CONSTRAINT customer_status_chk CHECK (status IN ('ACTIVE', 'INACTIVE', 'BLOCKED'))
);

--- Fornecedor / Embarcador ------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS shipper
(
    id             VARCHAR(26)  NOT NULL,
    internal_code  INTEGER      NOT NULL DEFAULT nextval('shipper_internal_code_seq'),
    document       VARCHAR(14)  NOT NULL,
    corporate_name VARCHAR(150) NOT NULL,
    trade_name     VARCHAR(150),

    email          VARCHAR(256),
    contact_name   VARCHAR(30),
    area_code      VARCHAR(3),
    phone_number   VARCHAR(15),

    postal_code    VARCHAR(9),
    state          VARCHAR(2),
    city           VARCHAR(100),
    district       VARCHAR(100),
    street         VARCHAR(100),
    number         VARCHAR(50),

    status         VARCHAR(10)  NOT NULL DEFAULT 'ACTIVE',
    version        BIGINT       NOT NULL DEFAULT 0,
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT shipper_pk PRIMARY KEY (id),
    CONSTRAINT shipper_document_uk UNIQUE (document),
    CONSTRAINT shipper_status_chk CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

--- Estoque / Centro de Distribuição ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS stock
(
    id              VARCHAR(26)    NOT NULL,
    internal_code   INTEGER        NOT NULL DEFAULT nextval('stock_internal_code_seq'),
    name            VARCHAR(100)   NOT NULL,

    manager_name    VARCHAR(30),
    email           VARCHAR(256),
    area_code       VARCHAR(3),
    phone_number    VARCHAR(15),

    postal_code     VARCHAR(9),
    state           VARCHAR(2),
    city            VARCHAR(100),
    district        VARCHAR(100),
    street          VARCHAR(100),
    number          VARCHAR(50),

    volume_capacity NUMERIC(15, 4) NOT NULL, -- Volume máximo em m³
    weight_capacity NUMERIC(15, 4) NOT NULL, -- Peso máximo suportado em kg

    status          VARCHAR(10)    NOT NULL DEFAULT 'ACTIVE',
    version         BIGINT         NOT NULL DEFAULT 0,
    created_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT stock_pk PRIMARY KEY (id),
    CONSTRAINT stock_status_chk CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

--- Veículo ----------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS vehicle
(
    id              VARCHAR(26)    NOT NULL,
    plate           VARCHAR(10)    NOT NULL,
    document        VARCHAR(11),                              -- Registro nacional do veículo
    model           VARCHAR(100)   NOT NULL,
    manufacturer    VARCHAR(100),
    model_year      SMALLINT,

    weight_capacity NUMERIC(15, 4) NOT NULL,                  -- Capacidade máxima em kg
    volume_capacity NUMERIC(15, 4) NOT NULL,                  -- Volume máximo em m³
    current_weight  NUMERIC(15, 4) NOT NULL DEFAULT 0,        -- Peso total atual
    current_volume  NUMERIC(15, 4) NOT NULL DEFAULT 0,        -- Volume total atual

    status          VARCHAR(20)    NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, ON_ROUTE, MAINTENANCE
    version         BIGINT         NOT NULL DEFAULT 0,
    created_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT vehicle_pk PRIMARY KEY (id),
    CONSTRAINT vehicle_status_chk CHECK (status IN ('ACTIVE', 'ON_ROUTE', 'MAINTENANCE'))
);

--- Manifesto --------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS manifest
(
    id                    VARCHAR(26)    NOT NULL,
    associated_vehicle_id VARCHAR(26)    NOT NULL,
    total_amount          NUMERIC(15, 4) NOT NULL DEFAULT 0,       -- Somatório imutável de valores
    total_weight          NUMERIC(15, 4) NOT NULL DEFAULT 0,       -- Somatório de peso (kg)
    total_volume          NUMERIC(15, 4) NOT NULL DEFAULT 0,       -- Somatório de volume (m³)
    departure_time        TIMESTAMP WITH TIME ZONE,
    arrival_time          TIMESTAMP WITH TIME ZONE,                -- Preenchido quando status = COMPLETED
    km_distance           NUMERIC(10, 2) NOT NULL,                 -- Distância estimada
    status                VARCHAR(20)    NOT NULL DEFAULT 'DRAFT', -- DRAFT, IN_TRANSIT, COMPLETED
    version               BIGINT         NOT NULL DEFAULT 0,
    created_at            TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT manifest_pk PRIMARY KEY (id),
    CONSTRAINT manifest_vehicle_fk FOREIGN KEY (associated_vehicle_id) REFERENCES vehicle (id),
    CONSTRAINT manifest_status_chk CHECK (status IN ('DRAFT', 'IN_TRANSIT', 'COMPLETED'))
);

-- Índice de FK: leitura de manifesto sempre parte do veículo associado
CREATE INDEX idx_manifest_vehicle_id ON manifest (associated_vehicle_id);

--- Encomenda / Carga ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS cargo
(
    id             VARCHAR(26)    NOT NULL,
    tracking_code  VARCHAR(100)   NOT NULL,
    weight         NUMERIC(15, 4) NOT NULL,                   -- Peso em kg
    volume         NUMERIC(15, 4) NOT NULL,                   -- Volume em m³
    declared_value NUMERIC(15, 4) NOT NULL,                   -- Valor fiscal

    shipper_id     VARCHAR(26)    NOT NULL,
    stock_id       VARCHAR(26)    NOT NULL,
    customer_id    VARCHAR(26)    NOT NULL,
    manifest_id    VARCHAR(26),                               -- NULL quando status for PENDING

    destination    TEXT           NOT NULL,
    status         VARCHAR(20)    NOT NULL DEFAULT 'PENDING', -- PENDING, ON_TRACK, DELIVERED
    version        BIGINT         NOT NULL DEFAULT 0,         -- Lock Otimista
    created_at     TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT cargo_pk PRIMARY KEY (id),
    CONSTRAINT cargo_shipper_fk FOREIGN KEY (shipper_id) REFERENCES shipper (id),
    CONSTRAINT cargo_stock_fk FOREIGN KEY (stock_id) REFERENCES stock (id),
    CONSTRAINT cargo_customer_fk FOREIGN KEY (customer_id) REFERENCES customer (id),
    CONSTRAINT cargo_manifest_fk FOREIGN KEY (manifest_id) REFERENCES manifest (id),
    CONSTRAINT cargo_status_chk CHECK (status IN ('PENDING', 'ON_TRACK', 'DELIVERED'))
);

-- Indexação obrigatória B-Tree única para o código de rastreamento
CREATE UNIQUE INDEX idx_cargo_tracking_code ON cargo USING btree (tracking_code);

-- Índices de FK: essenciais para o JOIN único
CREATE INDEX idx_cargo_manifest_id ON cargo (manifest_id);
CREATE INDEX idx_cargo_shipper_id ON cargo (shipper_id);
CREATE INDEX idx_cargo_stock_id ON cargo (stock_id);
CREATE INDEX idx_cargo_customer_id ON cargo (customer_id);