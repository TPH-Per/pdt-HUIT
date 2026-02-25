@echo off
REM =====================================================
REM Start All Services Script
REM =====================================================

echo =====================================================
echo   HANH CHINH CONG Q5 - Starting All Services
echo =====================================================
echo.

REM Set base directory
SET BASE_DIR=%~dp0..

REM =====================================================
REM 1. Check PostgreSQL
REM =====================================================
echo [1/4] Checking PostgreSQL...
sc query postgresql-x64-16 | find "RUNNING" >nul
IF %ERRORLEVEL% NEQ 0 (
    echo      PostgreSQL is not running. Starting...
    net start postgresql-x64-16
) ELSE (
    echo      PostgreSQL is running.
)
echo.

REM =====================================================
REM 2. Start Backend
REM =====================================================
echo [2/4] Starting Backend (Spring Boot)...
start "Backend" cmd /c "cd /d %BASE_DIR%\backend && set JAVA_OPTS=-Xms1g -Xmx3g -XX:+UseG1GC && mvnw.cmd spring-boot:run"
timeout /t 10 >nul
echo      Backend starting on http://localhost:8081
echo.

REM =====================================================
REM 3. Start Client (React)
REM =====================================================
echo [3/4] Starting Client (React/Vite)...
start "Client" cmd /c "cd /d %BASE_DIR%\client && set NODE_OPTIONS=--max-old-space-size=512 && npm run dev"
timeout /t 5 >nul
echo      Client starting on http://localhost:5173
echo.

REM =====================================================
REM 4. Start AdminStaff (Vue)
REM =====================================================
echo [4/4] Starting AdminStaff (Vue/Vite)...
start "AdminStaff" cmd /c "cd /d %BASE_DIR%\AdminStaff && set NODE_OPTIONS=--max-old-space-size=512 && npm run dev"
timeout /t 5 >nul
echo      AdminStaff starting on http://localhost:5174
echo.

REM =====================================================
REM Summary
REM =====================================================
echo =====================================================
echo   All Services Started!
echo =====================================================
echo.
echo   Backend:    http://localhost:8081
echo   Client:     http://localhost:5173
echo   AdminStaff: http://localhost:5174
echo.
echo   Memory Allocation:
echo   - PostgreSQL: ~4GB (shared_buffers)
echo   - Backend:    1-3GB (JVM heap)
echo   - Client:     512MB (Node.js)
echo   - AdminStaff: 512MB (Node.js)
echo   - System:     ~4GB reserved
echo.
echo =====================================================
echo   Press any key to exit (services will keep running)
echo =====================================================
pause >nul
