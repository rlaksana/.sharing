@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM Auto Commit & Push Script
REM Usage: auto-commit.bat ["commit message"]

echo ============================================
echo  Auto Commit & Push
echo ============================================

REM Check if we're in a git repo
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Not a git repository.
    exit /b 1
)

REM Check current branch
git rev-parse --abbrev-ref HEAD > temp_branch.txt
set /p BRANCH=<temp_branch.txt
del temp_branch.txt
echo [INFO] Current branch: %BRANCH%

REM Check for changes
git status --porcelain > temp_status.txt
for /f %%a in ('type temp_status.txt ^| find /c /v ""') do set CHANGES=%%a
del temp_status.txt

if %CHANGES% equ 0 (
    echo [INFO] No changes to commit. Working tree clean.
    exit /b 0
)

echo [INFO] Found %CHANGES% changed file(s).
git status --short

REM Get commit message
if "%~1"=="" (
    set /p MSG="Enter commit message: "
    if "!MSG!"=="" set MSG=chore: update files
) else (
    set MSG=%~1
)

echo.
echo [INFO] Staging all changes...
git add -A

echo [INFO] Committing with message: "%MSG%"
git commit -m "%MSG%"

if errorlevel 1 (
    echo [ERROR] Commit failed.
    exit /b 1
)

echo [INFO] Pushing to origin/%BRANCH%...
git push origin %BRANCH%

if errorlevel 1 (
    echo [ERROR] Push failed.
    exit /b 1
)

echo.
echo ============================================
echo  ✓ Success! Changes committed and pushed.
echo ============================================

endlocal
