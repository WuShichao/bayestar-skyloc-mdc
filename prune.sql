-- For each sim_inspiral record, for each 'sim_inspiral<-->coinc_event'
-- association, select the one with the lowest false alarm rate.
CREATE TEMPORARY TABLE to_keep_coincs AS SELECT DISTINCT
    (SELECT ci.coinc_event_id FROM coinc_inspiral AS ci
    INNER JOIN coinc_event_map AS cem2
    ON (cem2.event_id = ci.coinc_event_id)
    INNER JOIN coinc_event_map AS cem1
    ON (cem1.coinc_event_id = cem2.coinc_event_id)
    INNER JOIN coinc_event AS ce
    ON (ce.coinc_event_id = cem2.coinc_event_id)
    INNER JOIN coinc_definer AS cd ON (ce.coinc_def_id = cd.coinc_def_id)
    WHERE cem1.table_name = 'sim_inspiral'
    AND cem2.table_name = 'coinc_event'
    AND cem1.event_id = simulation_id
    AND cd.description = 'sim_inspiral<-->coinc_event coincidences (nearby)'
    ORDER BY ci.combined_far ASC, ci.snr DESC LIMIT 1)
    AS coinc_event_id FROM sim_inspiral WHERE coinc_event_id IS NOT NULL;

-- Make a list of all 'sim_inspiral<-->coinc_event' associations but those.
CREATE TEMPORARY TABLE to_delete_coincs AS SELECT
    coinc_event_id FROM coinc_event
    WHERE coinc_event_id NOT IN (SELECT coinc_event_id FROM to_keep_coincs);

-- Delete those 'sim_inspiral<-->coinc_event' associations that do not have
-- the minimum FAR for that sim_inspiral record.
DELETE FROM coinc_event
    WHERE coinc_event.coinc_event_id IN (SELECT * FROM to_delete_coincs);

-- Delete orphaned coinc_event_map records.
DELETE FROM coinc_event_map
    WHERE coinc_event_map.coinc_event_id IN (SELECT * FROM to_delete_coincs);

-- Delete orphaned coinc_event_map records.
DELETE FROM coinc_event_map
    WHERE coinc_event_map.event_id IN (SELECT * FROM to_delete_coincs);

-- Delete orphaned sngl_inspiral records.
DELETE FROM sngl_inspiral WHERE event_id NOT IN
    (SELECT event_id FROM coinc_event_map WHERE table_name = 'sngl_inspiral');

-- Delete orphaned process records.
DELETE FROM process WHERE process_id NOT IN
    (SELECT process_id FROM sngl_inspiral);

-- Delete orphaned process_params records.
DELETE FROM process_params WHERE process_id NOT IN
    (SELECT process_id FROM process);

-- Delete tables that we won't need.
DROP TABLE IF EXISTS filter;
DROP TABLE IF EXISTS coinc_inspiral;
DROP TABLE IF EXISTS sim_inspiral;
DROP TABLE IF EXISTS search_summary;
DROP TABLE IF EXISTS search_summvars;
DROP TABLE IF EXISTS summ_value;
DROP TABLE IF EXISTS time_slide;

-- Clean up unused space.
VACUUM;
