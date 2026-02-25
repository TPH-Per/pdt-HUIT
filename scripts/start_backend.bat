@echo off
REM =====================================================
REM Spring Boot Startup Script with JVM Tuning
REM Optimized for i5 Gen 12 + 16GB RAM
REM =====================================================

REM Set JAVA_HOME if not set
IF "%JAVA_HOME%"=="" (
    echo Warning: JAVA_HOME is not set
)

REM =====================================================
REM JVM Memory Settings
REM =====================================================
REM -Xms: Initial heap size (1GB for development)
REM -Xmx: Maximum heap size (3GB - leaves room for PostgreSQL and OS)
REM =====================================================
SET JAVA_HEAP=-Xms1g -Xmx3g

REM =====================================================
REM Garbage Collector Settings
REM =====================================================
REM G1GC: Best for applications with heap > 4GB
REM MaxGCPauseMillis: Target max GC pause time
REM =====================================================
SET JAVA_GC=-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+ParallelRefProcEnabled

REM =====================================================
REM Performance & Debugging
REM =====================================================
SET JAVA_PERF=-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=./heapdump.hprof
SET JAVA_DEBUG=-XX:+PrintGCDetails -Xloggc:./gc.log

REM =====================================================
REM JMX Monitoring (Optional - uncomment to enable)
REM =====================================================
REM SET JAVA_JMX=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9010 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false

REM =====================================================
REM Combine all options
REM =====================================================
SET JAVA_OPTS=%JAVA_HEAP% %JAVA_GC% %JAVA_PERF%

echo =====================================================
echo Starting Spring Boot with JVM options:
echo %JAVA_OPTS%
echo =====================================================

REM Navigate to backend directory
cd /d %~dp0..\backend

REM Run Spring Boot
call mvnw.cmd spring-boot:run -Dspring-boot.run.jvmArguments="%JAVA_OPTS%"

pause
