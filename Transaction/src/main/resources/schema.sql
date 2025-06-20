CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS transaction (
    transac_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    accnoowner UUID,
    accnoreceive UUID,
    amount NUMERIC,
    transac_type VARCHAR,
    transac_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);