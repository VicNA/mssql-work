select database_name
     , name
     , type
     , backup_size
     , compressed_backup_size
     , backup_start_date
     , backup_finish_date
from msdb.dbo.backupset
where type = 'D'