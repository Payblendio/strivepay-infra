@echo off
REM Update GitHub Environment secrets/variables.
REM
REM Full sync:
REM   Set-StrivePayGitHubEnv.cmd staging
REM
REM Manual:
REM   Set-StrivePayGitHubEnv.cmd staging --manual --file secrets\staging.urls.env

setlocal EnableExtensions
set "SCRIPT_DIR=%~dp0"
cd /d "%~dp0.."

set "ENV_NAME=staging"
set "MANUAL="
set "DRY="
set "ENV_FILE="

:parse
if "%~1"=="" goto run
if /I "%~1"=="staging" (set "ENV_NAME=staging" & shift & goto parse)
if /I "%~1"=="production" (set "ENV_NAME=production" & shift & goto parse)
if /I "%~1"=="--manual" (set "MANUAL=-ManualOnly" & shift & goto parse)
if /I "%~1"=="--dry-run" (set "DRY=-DryRun" & shift & goto parse)
if /I "%~1"=="--file" (
  set "ENV_FILE=%~2"
  shift
  shift
  goto parse
)
echo Unknown argument: %~1
echo Use: --file secrets\staging.urls.env
exit /b 1

:run
set "PS1=%SCRIPT_DIR%Set-StrivePayGitHubEnv.ps1"
if not exist "%PS1%" (
  echo Missing %PS1%
  exit /b 1
)

if "%ENV_FILE%"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%PS1%' -Environment '%ENV_NAME%' %MANUAL% %DRY%"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%PS1%' -Environment '%ENV_NAME%' %MANUAL% %DRY% -EnvFile '%CD%\%ENV_FILE%'"
)
exit /b %ERRORLEVEL%
