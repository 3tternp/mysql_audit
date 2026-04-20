-- Enable MySQL general query logging to TABLE storage
-- Requires administrative privileges

SHOW VARIABLES LIKE 'general_log%';
SHOW VARIABLES LIKE 'log_output';

SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

SHOW VARIABLES LIKE 'general_log';
SHOW VARIABLES LIKE 'log_output';
