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