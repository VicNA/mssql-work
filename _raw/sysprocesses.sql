select spid, kpid, blocked, waittype, waittime, lastwaittype, dbid, uid, cpu, physical_io, memusage, login_time
     , last_batch, ecid, open_tran, status, sid, hostname, program_name, hostprocess, cmd, net_address
     , net_library, loginame, stmt_start, stmt_end, request_id
from sys.sysprocesses
--where cmd = 'BACKUP DATABASE'
order by cpu desc