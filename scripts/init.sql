CREATE TABLE card (
  id SERIAL
  ,name VARCHAR(255)
  ,artist VARCHAR(255)
  ,text TEXT
);

COPY card (name,artist,text)
  FROM '/home/data/3c.csv'
  DELIMITER ','
  CSV HEADER;

ALTER TABLE card
  ADD COLUMN document tsvector;

UPDATE card
  set document = to_tsvector(name || ' ' || artist || ' ' || text);

--------------------------------------------------------------------------------------------------
ALTER TABLE card
  ADD COLUMN document_with_idx tsvector;

UPDATE card
  SET document_with_idx = to_tsvector(name || ' ' || artist || ' ' || coalesce(text, ''));

CREATE INDEX document_idx
  ON card
  USING GIN (document_with_idx);

---------------------------------------------------------------------------------------------------
ALTER TABLE card
  ADD COLUMN document_with_weights tsvector;

UPDATE card
  SET document_with_weights = setweight(to_tsvector(name), 'A') || setweight(to_tsvector(artist), 'B') || setweight(to_tsvector(COALESCE(text, '')), 'C');

CREATE INDEX document_weights_idx
  ON card
  USING GIN (document_with_weights);