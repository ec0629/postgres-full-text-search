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
EXPLAIN ANALYZE SELECT name, artist, text
  from card
  where document_with_idx @@ to_tsquery('Avon');

  -- ranking the returned rows
SELECT name, artist, text
  from card
  where document_with_idx @@ plainto_tsquery('island')
  order by ts_rank(document_with_idx, plainto_tsquery('island'));

-- alter weighting of columns
SELECT name, artist, text
  from card
  where document_with_idx @@ plainto_tsquery('island')
  order by ts_rank(document_with_weights, plainto_tsquery('island')) DESC;

-- view ranking
SELECT name, artist, text, ts_rank(document_with_weights, plainto_tsquery('island'))
  from card
  where document_with_idx @@ plainto_tsquery('island')
  order by ts_rank(document_with_weights, plainto_tsquery('island')) DESC;