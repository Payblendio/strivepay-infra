@echo off
REM Push env file to GitHub Environment secrets for all StrivePay repos.
REM Usage:
REM   Set-StrivePayGitHubEnv.cmd staging
REM   Set-StrivePayGitHubEnv.cmd staging C:\path\to\staging.env
REM   Set-StrivePayGitHubEnv.cmd staging --dry-run

setlocal
set ENV_NAME=%~1
if "%ENV_NAME%"=="" set ENV_NAME=staging
set ENV_FILE=%~2
set EXTRA=%~3

cd /d "%~dp0\.."

if /I "%ENV_FILE%"=="--dry-run" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-StrivePayGitHubEnv.ps1" -Environment %ENV_NAME% -DryRun
  exit /b %ERRORLEVEL%
)

if "%ENV_FILE%"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-StrivePayGitHubEnv.ps1" -Environment %ENV_NAME% %EXTRA%
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-StrivePayGitHubEnv.ps1" -Environment %ENV_NAME% -EnvFile "%ENV_FILE%" %EXTRA%
)
exit /b %ERRORLEVEL%
