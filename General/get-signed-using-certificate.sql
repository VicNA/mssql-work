SELECT [Object Name] = OBJECT_NAME(cp.major_id),
       [Object Type] = obj.type_desc,   
       [Cert/Key]    = COALESCE(c.name, a.name),
       cp.crypt_type_desc
FROM sys.objects obj
    JOIN sys.crypt_properties cp    ON cp.major_id = obj.object_id
    LEFT JOIN sys.certificates c    ON c.thumbprint = cp.thumbprint
    LEFT JOIN sys.asymmetric_keys a ON a.thumbprint = cp.thumbprint
ORDER BY [Object Name] ASC