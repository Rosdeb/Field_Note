@echo off
REM ==============================================================================
REM Field Notes - Local Environment Setup Script (Windows)
REM ==============================================================================
echo [Field Notes] Setting up local environment...

if exist "%~dp0..\.env" (
    echo [Field Notes] .env already exists. Skipping overwrite.
) else (
    if exist "%~dp0..\.env.example" (
        copy "%~dp0..\.env.example" "%~dp0..\.env" >nul
        echo [Field Notes] Successfully created .env from .env.example!
    ) else (
        echo [Field Notes] Error: .env.example was not found!
        exit /b 1
    )
)

echo [Field Notes] Environment ready! Run:
echo   flutter pub get
echo   flutter run
