USE tcryptapi_new;

select object_name(id) as tablename, sy.[name] as indexname, sf.name, sf.filename
from sysindexes sy
    join sysfiles sf on sf.groupid = sy.groupid
--where id = object_id('tablename')
where filename not in ('G:\mdf\tcryptapi.mdf', 'H:\ldf\tcryptapi_log.ldf')