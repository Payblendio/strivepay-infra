@echo off
REM Update GitHub Environment secrets/variables for StrivePay repos.
REM
REM Full sync from secrets\staging.env (or consumer-api\.env):
REM   Set-StrivePayGitHubEnv.cmd staging
REM
REM Manual updates only (no .env):
REM   Set-StrivePayGitHubEnv.cmd staging --manual STRIVEPAY_WEB_BASE_URL=https://staging.strivepay.io STRIVEPAY_SUPPORT_CUSTOMER_URL=https://staging.strivepay.io/dashboard/support
REM
REM Dry run:
REM   Set-StrivePayGitHubEnv.cmd staging --dry-run
REM   Set-StrivePayGitHubEnv.cmd staging --manual --dry-run KEY=value

setlocal EnableDelayedExpansion
cd /d "%~dp0\.."

set ENV_NAME=staging
set MANUAL=
set DRY=
set ENV_FILE=
set SET_ARGS=

:parse
if "%~1"=="" goto run
if /I "%~1"=="staging" (set ENV_NAME=staging& shift& goto parse)
if /I "%~1"=="production" (set ENV_NAME=production& shift& goto parse)
if /I "%~1"=="--manual" (set MANUAL=-ManualOnly& shift& goto parse)
if /I "%~1"=="--dry-run" (set DRY=-DryRun& shift& goto parse)
if /I "%~1"=="--file" (
  set ENV_FILE=-EnvFile "%~2"
  shift
  shift
  goto parse
)
REM KEY=value
set SET_ARGS=!SET_ARGS! "%~1"
shift
goto parse

:run
if not "!SET_ARGS!"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-StrivePayGitHubEnv.ps1" -Environment %ENV_NAME% %MANUAL% %DRY% %ENV_FILE% -Set !SET_ARGS!
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-StrivePayGitHubEnv.ps1" -Environment %ENV_NAME% %MANUAL% %DRY% %ENV_FILE%
)
exit /b %ERRORLEVEL%
