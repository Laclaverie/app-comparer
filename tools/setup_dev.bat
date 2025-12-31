@echo off
REM Developer setup helper
python tools\setup_env.py
if %ERRORLEVEL% NEQ 0 (
  echo Setup script failed
  exit /b %ERRORLEVEL%
)

echo Running melos get to ensure packages
melos run get

echo You can now run:
echo   - melos run dev:server  (start data server)
echo   - melos run dev:client  (start client app)
