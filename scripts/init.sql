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

-- to_tsvector creates a vector of the columns including as parameters on
-- the fly which is slow therefore we can create a column that will house
-- the precomputed vector producing a much quicker query
ALTER TABLE card
  ADD COLUMN document tsvector;

UPDATE card
  set document = to_tsvector(name || ' ' || artist || ' ' || text);

--------------------------------------------------------------------------------------------------
-- improving query speed with index
ALTER TABLE card
  ADD COLUMN document_with_idx tsvector;

-- columns with null values need to be coalesced as they cause issues with 
-- the tsvector column
UPDATE card
  SET document_with_idx = to_tsvector(name || ' ' || artist || ' ' || coalesce(text, ''));

CREATE INDEX document_idx
  ON card
  USING GIN (document_with_idx);

---------------------------------------------------------------------------------------------------
-- alter weighting of columns
ALTER TABLE card
  ADD COLUMN document_with_weights tsvector;

UPDATE card
  SET document_with_weights = setweight(to_tsvector(name), 'A') || setweight(to_tsvector(artist), 'B') || setweight(to_tsvector(COALESCE(text, '')), 'C');

CREATE INDEX document_weights_idx
  ON card
  USING GIN (document_with_weights);