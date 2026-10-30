@echo off
setlocal
pushd "%~dp0" || exit /b 1

where node >nul 2>&1
if errorlevel 1 goto :missing_tools
where npm >nul 2>&1
if errorlevel 1 goto :missing_tools
if not exist "node_modules\typescript\bin\tsc" goto :missing_dependencies
if not exist "node_modules\rimraf\dist\esm\bin.mjs" goto :missing_dependencies

echo [1/4] Cleaning core and MCP build outputs...
node node_modules\rimraf\dist\esm\bin.mjs packages/core/dist packages/mcp/dist packages/core/tsconfig.tsbuildinfo
if errorlevel 1 goto :failed

echo [2/4] Building core and MCP...
node node_modules\typescript\bin\tsc --build --force packages/core packages/mcp
if errorlevel 1 goto :failed

echo [3/4] Checking CLI entry points...
node --check packages/hce/bin/hce.js
if errorlevel 1 goto :failed
node --check packages/hce-unscoped/bin/hce.js
if errorlevel 1 goto :failed

echo [4/4] Linking global hce to this checkout...
pushd packages\hce || goto :failed
call npm link --force --ignore-scripts
set "LINK_RESULT=%errorlevel%"
popd
if not "%LINK_RESULT%"=="0" goto :failed

echo.
echo [OK] Build complete. Global hce now points to this checkout.
echo Restart or reconnect your MCP client to load the updated code.
echo Runtime configuration and repository indexes were not changed.
popd
exit /b 0

:missing_tools
echo [ERROR] Node.js and npm must be available on PATH.
goto :failed

:missing_dependencies
echo [ERROR] Workspace dependencies are missing. Run pnpm install first.
goto :failed

:failed
echo [ERROR] Rebuild stopped. Fix the error above and run this script again.
popd
exit /b 1
