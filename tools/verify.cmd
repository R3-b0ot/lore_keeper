@echo off
call tools\flutter_safe.cmd analyze
if %errorlevel% neq 0 exit /b %errorlevel%
call tools\flutter_safe.cmd test
if %errorlevel% neq 0 exit /b %errorlevel%
echo Verification passed.
