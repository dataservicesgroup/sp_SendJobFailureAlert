/*
 sqlcmd-mode installer for Data Services Group sp_SendJobFailureAlert proc.
 
 run from sqlcmd.exe using the following command-line:
 
 sqlcmd -S {sql-server} -i .\install-human-events.sql -v TargetDB = "{TargetDB}" SqlLogin = "{SqlLogin}" -C
 
 {sql-server} is the name of the target SQL Server
 {TargetDB} is where we'll install the sp_SendJobFailureAlert procedures.
 {SqlLogin} is the login which will be granted permissions to execute the sp_SendJobFailureAlert procedure.  This login must exist in both the target database and msdb. The script will apply the appropriate permissions.
 */
:on error exit 
:setvar SqlCmdEnabled "True" 
:setvar TargetDB "" 
:setvar SqlLogin "" 

DECLARE @msg NVARCHAR(2048);

SET @msg = N'sp_SendJobFailureAlert installer, by Data Services Group.';

RAISERROR(@msg, 10, 1) WITH NOWAIT;

SET @msg = N'Connected to SQL Server ' + @@SERVERNAME + N' as ' + SUSER_SNAME();

RAISERROR(@msg, 10, 1) WITH NOWAIT;

IF '$(SqlCmdEnabled)' NOT LIKE 'True'
BEGIN
    RAISERROR(N'This script is designed to run via sqlcmd.  Aborting.', 15, 127) WITH NOWAIT;

    SET NOEXEC ON;

END;
IF N'$(TargetDB)' = N'' OR N'$(SqlLogin)' = N''
BEGIN
    SET @msg = N'You must specify the target database and the sql login via the sqlcmd -V parameters (TargetDB = "{TargetDB}", SqlLogin = "{SqlLogin}")';

    RAISERROR(@msg, 15, 1) WITH NOWAIT;

    SET @msg = N'sqlcmd.exe -S <servername> -E -i .\install-sp_SendJobFailureAlert.sql -v TargetDB = "<database_name>" SqlLogin = "<sql_login>" -C';

    RAISERROR(@msg, 15, 1) WITH NOWAIT;

    SET @msg = N'Aborting.';

    RAISERROR(@msg, 15, 127) WITH NOWAIT;

    SET NOEXEC ON;

END;
IF NOT EXISTS
(
    SELECT 1
    FROM [sys].[databases] d
    WHERE d.[name] = N'$(TargetDB)'
)
BEGIN
    SET @msg
        = N'The specified target database, $(TargetDB), does not exist.  Please ensure the specified database exists, and is accessible to login $(SqlLogin).  Aborting.'
          + QUOTENAME(SUSER_SNAME()) + N'.';

    RAISERROR(@msg, 15, 127) WITH NOWAIT;

    SET NOEXEC ON;

END;
ELSE
BEGIN
    SET @msg = N'sp_SendJobFailureAlert will be installed into the [$(TargetDB)] database.';

    RAISERROR(@msg, 10, 1) WITH NOWAIT;

END;
GO
USE [$(TargetDB)];

GO
    :r sp_SendJobFailureAlert.sql
GO
DECLARE @msg NVARCHAR(2048);

IF OBJECT_ID(N'dbo.sp_SendJobFailureAlert') IS NOT NULL
BEGIN
    SET @msg
        = N'dbo.sp_SendJobFailureAlert has been successfully installed into the [$(TargetDB)] database on '
          + @@SERVERNAME + N'.';

    RAISERROR(@msg, 10, 1) WITH NOWAIT;

END;
SET @msg = N'install-sp_SendJobFailureAlert.sql completed.';

RAISERROR(@msg, 10, 1) WITH NOWAIT;

/* Apply permissions to the installed procedure */
IF EXISTS
(
    SELECT 1
    FROM sys.objects
    WHERE name = 'sp_SendJobFailureAlert'
          AND type = 'P'
)
BEGIN
    DECLARE @sql NVARCHAR(2048);
    IF EXISTS
    (
        SELECT 1
        FROM sys.database_principals
        WHERE name = N'$(SqlLogin)'
    )
    BEGIN
        SET @sql = N'GRANT EXECUTE ON dbo.sp_SendJobFailureAlert TO [$(SqlLogin)]';

        EXEC sp_executesql @sql;

        SET @msg
        = N'Permissions have been successfully granted to [$(SqlLogin)] in the [$(TargetDB)] database on '
          + @@SERVERNAME + N'.';

        RAISERROR(@msg, 10, 1) WITH NOWAIT;
    END;
    ELSE
    BEGIN
        SET @msg
            = N'Login [$(SqlLogin)] does not exist in [$(TargetDB)]. Permissions have not been granted. Please ensure the user exists and execute the script again.';
        RAISERROR(@msg, 15, 127) WITH NOWAIT;
    END;
END;

USE [msdb];
IF EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'$(SqlLogin)'
)
BEGIN
    SET @sql
        = N'GRANT EXECUTE ON dbo.agent_datetime TO [$(SqlLogin)];GRANT EXECUTE ON dbo.sp_send_dbmail TO [$(SqlLogin)];GRANT SELECT ON dbo.sysjobhistory TO [$(SqlLogin)];GRANT SELECT ON dbo.sysjobs TO [$(SqlLogin)]';

    EXEC sp_executesql @sql;

        SET @msg
        = N'Permissions have been successfully granted to [$(SqlLogin)] in the [' + DB_NAME() + N'] database on '
          + @@SERVERNAME + N'.';

        RAISERROR(@msg, 10, 1) WITH NOWAIT;
END;
ELSE
BEGIN
    SET @msg
        = N'Login [$(SqlLogin)] does not exist in [' + DB_NAME() + N']. Permissions have not been granted. Please ensure the user exists and execute the script again.';
    RAISERROR(@msg, 15, 127) WITH NOWAIT;
END;