# sp_SendJobFailureAlert

A smarter way to handle SQL Server Agent job failure alerts.

Instead of sending an email every time a job fails, this procedure sends a notification only when a job fails more than X times within a Y-hour window.

Reduce noise. Detect patterns. Focus on real problems.

---

## Why This Exists

SQL Server Agent’s default alerting can create alert fatigue.

This procedure allows you to:

- Define a failure threshold
- Define a lookback window
- Optionally include recent failure history
- Use Database Mail with a specified profile

---

## Requirements

- SQL Server 2017 or newer (uses STRING_AGG)
- Database Mail configured and enabled
- Permission to read:
  - msdb.dbo.sysjobs
  - msdb.dbo.sysjobhistory
- Permission to execute:
  - msdb.dbo.sp_send_dbmail

---

## Installation

1. Download `sp_SendJobFailureAlert.sql`
2. Deploy to a user database (not a system database)
3. Grant execute permissions as required

---

## Parameters

| Parameter | Type | Required | Description |
|------------|------|----------|-------------|
| @JobName | NVARCHAR(128) | Yes | SQL Agent job name |
| @ToEmail | NVARCHAR(256) | Yes | Recipient(s), comma-separated |
| @FailureThreshold | INT | No | Failures required to trigger alert (default 3) |
| @CheckIntervalHours | INT | No | Lookback window in hours (default 24) |
| @ProfileName | NVARCHAR(128) | No | Database Mail profile |
| @Subject | NVARCHAR(200) | No | Custom email subject |
| @IncludeHistory | BIT | No | Include recent failure history (default 1) |

---

## Usage Pattern

1. Create your SQL Agent job.
2. Configure all job steps to go to a final step on failure.
3. Add a final step that executes:

```sql
EXEC dbo.sp_SendJobFailureAlert
    @JobName = 'Your Job Name',
    @ToEmail = 'dba@company.com';
