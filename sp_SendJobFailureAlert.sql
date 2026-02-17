/*
    sp_SendJobFailureAlert
    Author: Nick Pennisi (Data Services Group)
    License: MIT
    Version: 1.0
    Requires: SQL Server 2017+

    Description:
    Sends an alert when a SQL Agent job fails more than X times
    within a defined time window.

*/
CREATE OR ALTER PROCEDURE [dbo].[sp_SendJobFailureAlert]
(
    @JobName NVARCHAR(128),
    @ToEmail NVARCHAR(256),
    @FailureThreshold INT = 3,
    @CheckIntervalHours INT = 24,
    @ProfileName NVARCHAR(128) = NULL,
    @Subject NVARCHAR(200) = NULL,
    @IncludeHistory BIT = 1
)
AS
BEGIN

    SET NOCOUNT ON;

    -- Ensure Database Mail is enabled
    IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'Database Mail XPs' AND value_in_use = 1)
    BEGIN
        RAISERROR('Database Mail is not enabled on this server. Enable Database Mail XPs before using this procedure.', 16, 1);
        RETURN 1;
    END

    DECLARE @job_id UNIQUEIDENTIFIER;

    SELECT @job_id = job_id 
    FROM msdb.dbo.sysjobs 
    WHERE [name] = @JobName;

    IF @job_id IS NULL
    BEGIN
        RAISERROR('Job "%s" not found in msdb.dbo.sysjobs.', 16, 1, @JobName);
        RETURN 2;
    END

    DECLARE @Cutoff DATETIME2 = DATEADD(hour, -@CheckIntervalHours, SYSUTCDATETIME());
    DECLARE @FailCount INT;

    SELECT @FailCount = COUNT_BIG(1)
    FROM msdb.dbo.sysjobhistory h
    WHERE h.job_id = @job_id
      AND h.step_id = 0        -- job outcome
      AND h.run_status = 0     -- 0 = failed
      AND msdb.dbo.agent_datetime(h.run_date, h.run_time) >= @Cutoff;

    IF @FailCount >= @FailureThreshold
    BEGIN
        IF @Subject IS NULL
            SET @Subject = CONCAT('ALERT: Job ', @JobName, ' failed ', @FailCount, 
                                  ' times in last ', @CheckIntervalHours, ' hours');

        DECLARE @Body NVARCHAR(MAX) = CONCAT(
            'Job: ', @JobName, CHAR(13)+CHAR(10),
            'Failures in last ', @CheckIntervalHours, ' hours: ', @FailCount, CHAR(13)+CHAR(10),
            'Cutoff: ', CONVERT(NVARCHAR(30), @Cutoff, 120), CHAR(13)+CHAR(10), CHAR(13)+CHAR(10)
        );

        IF @IncludeHistory = 1
        BEGIN
            ;WITH failures AS (
                SELECT TOP (100)
                    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS failure_time,
                    LEFT(ISNULL(h.message, ''), 2000) AS message
                FROM msdb.dbo.sysjobhistory h
                WHERE h.job_id = @job_id
                  AND h.step_id = 0
                  AND h.run_status = 0
                  AND msdb.dbo.agent_datetime(h.run_date, h.run_time) >= @Cutoff
                ORDER BY failure_time DESC
            )
            SELECT @Body = @Body + STRING_AGG(
                CONCAT(
                    'Time: ', CONVERT(NVARCHAR(30), failure_time, 120),
                    ' - Message: ', message
                ),
                CHAR(13)+CHAR(10)
            )
            FROM failures;
        END

        -- Send email via Database Mail
        IF @ProfileName IS NULL
        BEGIN
            EXEC msdb.dbo.sp_send_dbmail
                @recipients = @ToEmail,
                @subject = @Subject,
                @body = @Body,
                @body_format = 'TEXT';
        END
        ELSE
        BEGIN
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = @ProfileName,
                @recipients = @ToEmail,
                @subject = @Subject,
                @body = @Body,
                @body_format = 'TEXT';
        END

        RETURN 0;
    END

    RETURN 0;

END;
GO
