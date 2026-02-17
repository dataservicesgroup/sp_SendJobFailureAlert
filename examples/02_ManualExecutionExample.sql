EXEC dbo.sp_SendJobFailureAlert
    @JobName = 'Example Failing Job',
    @ToEmail = 'dba@company.com',
    @FailureThreshold = 2,
    @CheckIntervalHours = 12,
    @IncludeHistory = 1;
