DECLARE @type CHAR(1);

/*
Тип резервного копирования. Возможны следующие варианты:
D = база данных
I = разностное копирование базы данных;
L = журнал
F = копирование файла или файловой группы;
G = разностное копирование файла;
P = частичное копирование;
Q = частичное разностное копирование.
Может иметь значение NULL.
*/

SET @type = 'D';

SELECT [backup_start_date]  = FORMAT(bs.backup_start_date, 'dd-MM-yyyy HH:mm:ss')
     , [backup_finish_date] = FORMAT(bs.backup_finish_date, 'dd-MM-yyyy HH:mm:ss')
     , bs.database_name
     , bs.name
     , [type] = CASE bs.type
                    WHEN 'D' THEN 'FULL'
                    WHEN 'I' THEN 'DIFF'
                    WHEN 'L' THEN 'LOG'
                END
     , bs.backup_size
     , bs.compressed_backup_size
     , bm.physical_device_name
FROM msdb.dbo.backupset bs
    JOIN msdb.dbo.backupmediafamily bm ON bm.media_set_id = bs.media_set_id
WHERE type = @type
ORDER BY bs.backup_start_date DESC;