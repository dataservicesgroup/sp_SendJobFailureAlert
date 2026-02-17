/*
    sqlcmd-mode installer for Data Services Group sp_SendJobFailureAlert proc.

    run from sqlcmd.exe using the following command-line:

    sqlcmd -S {sql-server} -i .\install-human-events.sql -v TargetDB = "{target-database}" -C

    {sql-server} is the name of the target SQL Server
    {target-database} is where we'll install the sp_SendJobFailureAlert procedures.
*/
:on error exit
:setvar SqlCmdEnabled "True"
:setvar TargetDB ""
:setvar 

DECLARE @msg nvarchar(2048);
SET @msg = N'sp_SendJobFailureAlert installer, by Data Services Group.';
RAISERROR (@msg, 10, 1) WITH NOWAIT;
SET @msg = N'Connected to SQL Server ' + @@SERVERNAME + N' as ' + SUSER_SNAME();
RAISERROR (@msg, 10, 1) WITH NOWAIT;

IF '$(SqlCmdEnabled)' NOT LIKE 'True'
BEGIN
    RAISERROR (N'This script is designed to run via sqlcmd.  Aborting.', 10, 127) WITH NOWAIT;
    SET NOEXEC ON;
END

IF N'$(TargetDB)' = N''
BEGIN
    SET @msg = N'You must specify the target database via the sqlcmd -V parameter (TargetDB = "{server-name}")';
    RAISERROR (@msg, 10, 1) WITH NOWAIT;
    SET @msg = N'sqlcmd.exe -S <servername> -E -i .\install-human-events.sql -v TargetDB = "<database_name>"';
    RAISERROR (@msg, 10, 1) WITH NOWAIT;
    SET @msg = N'Aborting.';
    RAISERROR (@msg, 10, 127) WITH NOWAIT;
    SET NOEXEC ON;
END

IF NOT EXISTS
(
    SELECT 1
    FROM [sys].[databases] d
    WHERE d.[name] = N'$(TargetDB)'
)
BEGIN
    SET @msg = N'The specified target database, $(TargetDB), does not exist.  Please ensure the specified database exists, and is accessible to login ' + QUOTENAME(SUSER_SNAME()) + N'.';
    RAISERROR (@msg, 10, 127) WITH NOWAIT;
    SET NOEXEC ON;
END
ELSE
BEGIN
    SET @msg = N'sp_SendJobFailureAlert will be installed into the [$(TargetDB)] database.';
    RAISERROR (@msg, 10, 1) WITH NOWAIT;
END
GO

USE [$(TargetDB)];
GO

:r sp_SendJobFailureAlert.sql
GO

DECLARE @msg nvarchar(2048);
IF OBJECT_ID(N'dbo.sp_SendJobFailureAlert') IS NOT NULL
BEGIN
    SET @msg = N'dbo.sp_SendJobFailureAlert has been successfully installed into the [$(TargetDB)] database on ' + @@SERVERNAME + N'.';
    RAISERROR (@msg, 10, 1) WITH NOWAIT;
END
SET @msg = N'install-sp_SendJobFailureAlert.sql completed.';
RAISERROR (@msg, 10, 1) WITH NOWAIT;
