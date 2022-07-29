USE DBAtools
GO

SELECT [Object Name] = object_name(cp.major_id),
       [Object Type] = obj.type_desc,   
       [Cert/Key] = coalesce(c.name, a.name),
       cp.crypt_type_desc
FROM   sys.crypt_properties cp
INNER JOIN sys.objects obj        ON obj.object_id = cp.major_id
LEFT   JOIN sys.certificates c    ON c.thumbprint = cp.thumbprint
LEFT   JOIN sys.asymmetric_keys a ON a.thumbprint = cp.thumbprint
ORDER BY [Object Name] ASC