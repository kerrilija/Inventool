CREATE TABLE sql_history (
    id BIGSERIAL PRIMARY KEY,
    query TEXT NOT NULL,
    query_type VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app_config (
  id bigserial PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL
);

CREATE TABLE exchange (
    exchange_id BIGSERIAL NOT NULL PRIMARY KEY,
    toIssue INTEGER,
    toReturn INTEGER,
    newTool BOOLEAN,
	toDispose INTEGER,
    sourcetable VARCHAR(20),
    issued INTEGER,
    returned INTEGER,
    machine INTEGER
);

create table tool (
    id BIGSERIAL NOT NULL PRIMARY KEY,
	tooltype VARCHAR(50) NOT NULL,
	steel BOOLEAN,
    stainless BOOLEAN,
    castiron BOOLEAN,
    aluminum BOOLEAN,
    universal BOOLEAN,
    catnum VARCHAR(50),
	invnum VARCHAR(50) NOT NULL,
    unit VARCHAR(10),
	grinded VARCHAR(10),
    mfr VARCHAR(50),
    holdertype VARCHAR(50),
    tipdiamm NUMERIC(10, 4),
    tipdiainch NUMERIC(10, 4),
    shankdia NUMERIC(10, 4),
    pitch VARCHAR(20),
    neckdia NUMERIC(10, 4),
    tslotdp NUMERIC(10, 4),
    toollen NUMERIC(10, 4),
    splen NUMERIC(10, 4),
    worklen NUMERIC(10, 4),
    bladecnt INT,
    tiptype VARCHAR(10),
    tipsize VARCHAR(10),
    material VARCHAR(20),
    coating VARCHAR(40),
    inserttype VARCHAR(50),
    cabinet VARCHAR(20),
    qty INT,
    issued INT,
    avail INT,
    minqty INT,
    secocab VARCHAR(20),
    sandvikcab VARCHAR(20),
    kennacab VARCHAR(20),
    niagaracab VARCHAR(20),
    extcab INT,
    sourcetable VARCHAR(20),
    subtype VARCHAR(50) 
);

\copy tool(tooltype, steel, stainless, castiron, aluminum, universal, catnum, invnum, unit, grinded, mfr, holdertype, tipdiamm, tipdiainch, shankdia, pitch, neckdia, tslotdp, toollen, splen, worklen, bladecnt, tiptype, tipsize, material, coating, inserttype, cabinet, qty, issued, avail, minqty, secocab, sandvikcab, kennacab, niagaracab, extcab, sourcetable, subtype) FROM '/data/tool_inventory.csv' WITH DELIMITER ';' CSV HEADER;