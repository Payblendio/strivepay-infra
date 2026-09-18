@echo off
REM Update GitHub Environment secrets/variables.
REM
REM Full sync (auto-picks secrets\staging.env or consumer-api\.env):
REM   Set-StrivePayGitHubEnv.cmd staging
REM
REM Manual updates via a small file (recommended from CMD — avoids https:// parsing issues):
REM   Set-StrivePayGitHubEnv.cmd staging --manual --file secrets\staging.urls.env
REM
REM Dry run:
REM   Set-StrivePayGitHubEnv.cmd staging --dry-run

setlocal
cd /d "%~dp0\.."

set ENV_NAME=staging
set MANUAL=
set DRY=
set ENV_FILE=

:parse
if "%~1"=="" goto run
if /I "%~1"=="staging" (set ENV_NAME=staging& shift& goto parse)
if /I "%~1"=="production" (set ENV_NAME=production& shift& goto parse)
if /I "%~1"=="--manual" (set MANUAL=-ManualOnly& shift& goto parse)
if /I "%~1"=="--dry-run" (set DRY=-DryRun& shift& goto parse)
if /I "%~1"=="--file" (
  set "ENV_FILE=%~2"
  shift
  shift
  goto parse
)
echo Unknown argument: %~1
echo Use --file path\to\keys.env for KEY=value lines.
exit /b 1

:run
if not "%ENV_FILE%"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-StrivePayGitHubEnv.ps1" -Environment %ENV_NAME% %MANUAL% %DRY% -EnvFile "%ENV_FILE%"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-StrivePayGitHubEnv.ps1" -Environment %ENV_NAME% %MANUAL% %DRY%
)
exit /b %ERRORLEVEL%
