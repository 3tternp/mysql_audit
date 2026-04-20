-- MySQL activity reporting queries
-- Requires general logging to be enabled for full query collection

-- Recent executed SQL statements
SELECT
    event_time,
    user_host,
    thread_id,
    server_id,
    command_type,
    argument AS executed_sql
FROM mysql.general_log
WHERE command_type = 'Query'
ORDER BY event_time DESC
LIMIT 500;

-- Query count grouped by user
SELECT
    SUBSTRING_INDEX(user_host, '[', 1) AS username,
    COUNT(*) AS total_queries
FROM mysql.general_log
WHERE command_type = 'Query'
GROUP BY username
ORDER BY total_queries DESC;

-- Detailed per-user command history
SELECT
    event_time,
    SUBSTRING_INDEX(user_host, '[', 1) AS username,
    argument AS executed_sql
FROM mysql.general_log
WHERE command_type = 'Query'
ORDER BY event_time DESC;

-- Connection / session events
SELECT
    event_time,
    user_host,
    command_type,
    argument
FROM mysql.general_log
WHERE command_type IN ('Connect', 'Quit')
ORDER BY event_time DESC
LIMIT 500;

-- Optional: recent activity from performance_schema (recent, not long-term)
SELECT
    t.PROCESSLIST_USER AS username,
    t.PROCESSLIST_HOST AS host,
    es.EVENT_ID,
    es.EVENT_NAME,
    es.SQL_TEXT,
    es.TIMER_START,
    es.TIMER_END,
    es.LOCK_TIME,
    es.ERRORS,
    es.WARNINGS
FROM performance_schema.events_statements_history es
JOIN performance_schema.threads t
    ON es.THREAD_ID = t.THREAD_ID
WHERE t.PROCESSLIST_USER IS NOT NULL
ORDER BY es.EVENT_ID DESC
LIMIT 200;
