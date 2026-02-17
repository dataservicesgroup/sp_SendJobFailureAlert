USE msdb;
GO

EXEC sp_add_job
    @job_name = N'Example Failing Job';
GO

EXEC sp_add_jobstep
    @job_name = N'Example Failing Job',
    @step_name = N'Failing Step',
    @subsystem = N'TSQL',
    @command = N'SELECT 1/0;',
    @on_fail_action = 3; -- Go to next step
GO

EXEC sp_add_jobstep
    @job_name = N'Example Failing Job',
    @step_name = N'Alert Step',
    @subsystem = N'TSQL',
    @command = N'
        EXEC dbo.sp_SendJobFailureAlert
            @JobName = ''Example Failing Job'',
            @ToEmail = ''dba@company.com'';
    ';
GO
