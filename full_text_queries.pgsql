-- search single column
select name, artist, text
from card
where to_tsvector(name) @@ to_tsquery('Wall');

-- search multiple columns, uses concatenation
SELECT name, artist, text
from card
where to_tsvector(name || ' ' || text) @@ to_tsquery('Wall');

SELECT name, artist, text
from card
where to_tsvector(name || ' ' || artist || ' ' || text) @@ to_tsquery('Avon');

-- to_tsvector creates a vector of the columns including as parameters on
-- the fly which is slow therefore we can create a column that will house
-- the precomputed vector producing a much quicker query
ALTER TABLE card
  ADD COLUMN document tsvector;

UPDATE card
  set document = to_tsvector(name || ' ' || artist || ' ' || text);

-- abbreviated query with pre-computed column
SELECT name, artist, text
from card
where document @@ to_tsquery('Avon');

-- analyzing changes in speed
EXPLAIN ANALYZE SELECT name, artist, text
from card
where document @@ to_tsquery('Avon');

EXPLAIN ANALYZE SELECT name, artist, text
from card
where to_tsvector(name || ' ' || artist || ' ' || text) @@ to_tsquery('Avon');

-------------------------------------------------------------------------------
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

EXPLAIN ANALYZE SELECT name, artist, text
  from card
  where document_with_idx @@ to_tsquery('Avon');

  -- ranking the returned rows
SELECT name, artist, text
  from card
  where document_with_idx @@ plainto_tsquery('island')
  order by ts_rank(document_with_idx, plainto_tsquery('island'));

-- alter weighting of columns
ALTER TABLE card
  ADD COLUMN document_with_weights tsvector;

UPDATE card
  SET document_with_weights = setweight(to_tsvector(name), 'A') || setweight(to_tsvector(artist), 'B') || setweight(to_tsvector(COALESCE(text, '')), 'C');

CREATE INDEX document_weights_idx
  ON card
  USING GIN (document_with_weights);

SELECT name, artist, text
  from card
  where document_with_idx @@ plainto_tsquery('island')
  order by ts_rank(document_with_weights, plainto_tsquery('island')) DESC;