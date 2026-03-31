@echo off
:: Check if the script is running as Administrator
NET SESSION >nul 2>&1
if %errorLevel% neq 0 (
    :: Launch itself with Admin privileges
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Set variables
SET HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts
SET DOMAINS=account.core-bank.local transaction.core-bank.local customer.core-bank.local auth.core-bank.local discovery.core-bank.local grafana.core-bank.local prometheus.core-bank.local
SET IP=127.0.0.1

:: Check if the domains are already present
findstr /C:"auth.core-bank.local" "%HOSTS_FILE%" >nul
if %errorLevel% equ 0 (
    exit /b
) else (
    :: Append to the hosts file
    echo.>> "%HOSTS_FILE%"
    echo %IP%  %DOMAINS% >> "%HOSTS_FILE%"
)
