CREATE TABLE IF NOT EXISTS outbox_event
(
    id             VARCHAR(26)              NOT NULL,
    aggregate_type VARCHAR(100)             NOT NULL,
    aggregate_id   VARCHAR(100)             NOT NULL,
    event_type     VARCHAR(255)             NOT NULL,
    payload        JSONB                    NOT NULL,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at   TIMESTAMP WITH TIME ZONE,
    correlation_id VARCHAR(100),
    failure_reason TEXT,

    CONSTRAINT pk_outbox_event PRIMARY KEY (id)
);

CREATE INDEX idx_outbox_event_pending ON outbox_event (created_at) WHERE processed_at IS NULL;

CREATE TABLE IF NOT EXISTS customer
(
    id            VARCHAR(26)              NOT NULL,
    internal_code INTEGER GENERATED ALWAYS AS IDENTITY,
    document      VARCHAR(14)              NOT NULL,
    name          VARCHAR(150)             NOT NULL,
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

    status        VARCHAR(10)              NOT NULL DEFAULT 'ACTIVE',
    version       BIGINT                   NOT NULL DEFAULT 0,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT customer_pk PRIMARY KEY (id),
    CONSTRAINT customer_document_uk UNIQUE (document),
    CONSTRAINT customer_email_uk UNIQUE (email),
    CONSTRAINT customer_phone_uk UNIQUE (phone_number),
    CONSTRAINT customer_status_chk CHECK (status IN ('ACTIVE', 'INACTIVE', 'BLOCKED'))
);

CREATE TABLE IF NOT EXISTS shipper
(
    id             VARCHAR(26)              NOT NULL,
    internal_code  INTEGER GENERATED ALWAYS AS IDENTITY,
    document       VARCHAR(14)              NOT NULL,
    corporate_name VARCHAR(150)             NOT NULL,
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

    status         VARCHAR(10)              NOT NULL DEFAULT 'ACTIVE',
    version        BIGINT                   NOT NULL DEFAULT 0,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT shipper_pk PRIMARY KEY (id),
    CONSTRAINT shipper_document_uk UNIQUE (document),
    CONSTRAINT shipper_status_chk CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

CREATE TABLE IF NOT EXISTS stock
(
    id              VARCHAR(26)              NOT NULL,
    internal_code   INTEGER GENERATED ALWAYS AS IDENTITY,
    name            VARCHAR(100)             NOT NULL,

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

    volume_capacity NUMERIC(15, 4)           NOT NULL,
    weight_capacity NUMERIC(15, 4)           NOT NULL,

    status          VARCHAR(10)              NOT NULL DEFAULT 'ACTIVE',
    version         BIGINT                   NOT NULL DEFAULT 0,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT stock_pk PRIMARY KEY (id),
    CONSTRAINT stock_status_chk CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

CREATE TABLE IF NOT EXISTS vehicle
(
    id              VARCHAR(26)              NOT NULL,
    plate           VARCHAR(10)              NOT NULL,
    document        VARCHAR(11),
    model           VARCHAR(100)             NOT NULL,
    manufacturer    VARCHAR(100),
    model_year      SMALLINT,

    weight_capacity NUMERIC(15, 4)           NOT NULL,
    volume_capacity NUMERIC(15, 4)           NOT NULL,

    status          VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',
    version         BIGINT                   NOT NULL DEFAULT 0,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT vehicle_pk PRIMARY KEY (id),
    CONSTRAINT vehicle_plate_uk UNIQUE (plate),
    CONSTRAINT vehicle_status_chk CHECK (status IN ('ACTIVE', 'ON_ROUTE', 'MAINTENANCE', 'INACTIVE'))
);

CREATE TABLE IF NOT EXISTS manifest
(
    id                    VARCHAR(26)              NOT NULL,
    associated_vehicle_id VARCHAR(26)              NOT NULL,
    total_amount          NUMERIC(15, 4)           NOT NULL DEFAULT 0,
    total_weight          NUMERIC(15, 4)           NOT NULL DEFAULT 0,
    total_volume          NUMERIC(15, 4)           NOT NULL DEFAULT 0,
    departure_time        TIMESTAMP WITH TIME ZONE,
    arrival_time          TIMESTAMP WITH TIME ZONE,
    km_distance           NUMERIC(10, 2)           NOT NULL,
    status                VARCHAR(20)              NOT NULL DEFAULT 'DRAFT',
    version               BIGINT                   NOT NULL DEFAULT 0,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT manifest_pk PRIMARY KEY (id),
    CONSTRAINT manifest_vehicle_fk FOREIGN KEY (associated_vehicle_id) REFERENCES vehicle (id),
    CONSTRAINT manifest_status_chk CHECK (status IN ('DRAFT', 'IN_TRANSIT', 'COMPLETED', 'CANCELLED'))
);

CREATE INDEX idx_manifest_vehicle_id ON manifest (associated_vehicle_id);

CREATE TABLE IF NOT EXISTS cargo
(
    id             VARCHAR(26)              NOT NULL,
    tracking_code  VARCHAR(100)             NOT NULL,
    weight         NUMERIC(15, 4)           NOT NULL,
    volume         NUMERIC(15, 4)           NOT NULL,
    declared_value NUMERIC(15, 4)           NOT NULL,

    shipper_id     VARCHAR(26)              NOT NULL,
    stock_id       VARCHAR(26)              NOT NULL,
    customer_id    VARCHAR(26)              NOT NULL,
    manifest_id    VARCHAR(26),

    postal_code    VARCHAR(9)               NOT NULL,
    state          VARCHAR(2)               NOT NULL,
    city           VARCHAR(100)             NOT NULL,
    district       VARCHAR(100),
    street         VARCHAR(100),
    number         VARCHAR(50),

    status         VARCHAR(20)              NOT NULL DEFAULT 'PENDING',
    version        BIGINT                   NOT NULL DEFAULT 0,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT cargo_pk PRIMARY KEY (id),
    CONSTRAINT cargo_shipper_fk FOREIGN KEY (shipper_id) REFERENCES shipper (id),
    CONSTRAINT cargo_stock_fk FOREIGN KEY (stock_id) REFERENCES stock (id),
    CONSTRAINT cargo_customer_fk FOREIGN KEY (customer_id) REFERENCES customer (id),
    CONSTRAINT cargo_manifest_fk FOREIGN KEY (manifest_id) REFERENCES manifest (id),
    CONSTRAINT cargo_status_chk CHECK (status IN ('PENDING', 'IN_TRANSIT', 'DELIVERED', 'RETURNED',
                                                  'CANCELLED', 'LOST'))
);

CREATE UNIQUE INDEX idx_cargo_tracking_code ON cargo USING btree (tracking_code);
CREATE INDEX idx_cargo_manifest_id ON cargo (manifest_id);
CREATE INDEX idx_cargo_shipper_id ON cargo (shipper_id);
CREATE INDEX idx_cargo_stock_id ON cargo (stock_id);
CREATE INDEX idx_cargo_customer_id ON cargo (customer_id);

CREATE OR REPLACE FUNCTION fn_manifest_requires_cargo()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status
        AND OLD.status = 'DRAFT'
        AND NEW.status <> 'CANCELLED'
        AND NOT EXISTS (SELECT 1 FROM cargo WHERE manifest_id = NEW.id) THEN
        RAISE EXCEPTION 'Manifest % precisa de pelo menos 1 cargo para sair de DRAFT', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_manifest_requires_cargo
    BEFORE UPDATE
    ON manifest
    FOR EACH ROW
EXECUTE FUNCTION fn_manifest_requires_cargo();