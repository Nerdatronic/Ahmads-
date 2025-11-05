@echo off
setlocal enabledelayedexpansion

title BSEE - Binary Structure Exploration Engine

echo.
echo  ========================================
echo    BSEE - Binary Structure Exploration Engine
echo  ========================================
echo.

:: Check if Python is installed
echo [1/5] Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo    ERROR: Python is not installed or not in PATH
    echo    Please install Python 3.9+ from https://python.org
    echo    Make sure to check "Add Python to PATH" during installation
    echo.
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo    Found Python %PYTHON_VERSION%

:: Check if virtual environment exists
echo [2/5] Checking virtual environment...
if not exist "venv\" (
    echo    Creating virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo    ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
    echo    Virtual environment created successfully
) else (
    echo    Virtual environment found
)

:: Activate virtual environment
echo [3/5] Activating virtual environment...
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo    ERROR: Failed to activate virtual environment
    pause
    exit /b 1
)

:: Check and install required dependencies
echo [4/5] Checking dependencies...
echo    Checking required packages...

:: List of required packages
set PACKAGES=numpy scipy pyyaml matplotlib pillow psutil

:: Check each package and install if missing
for %%p in (%PACKAGES%) do (
    python -c "import %%p" >nul 2>&1
    if errorlevel 1 (
        echo    Installing %%p...
        pip install %%p
        if errorlevel 1 (
            echo    WARNING: Failed to install %%p, continuing anyway...
        ) else (
            echo    %%p installed successfully
        )
    ) else (
        echo    %%p is already installed
    )
)

:: Check optional packages
echo    Checking optional packages...
set OPTIONAL_PACKAGES=lz4 zstandard

for %%p in (%OPTIONAL_PACKAGES%) do (
    python -c "import %%p" >nul 2>&1
    if errorlevel 1 (
        echo    Installing optional package %%p...
        pip install %%p
        if errorlevel 1 (
            echo    WARNING: Failed to install %%p (not critical)
        ) else (
            echo    Optional package %%p installed successfully
        )
    ) else (
        echo    Optional package %%p is already installed
    )
)

:: Display usage information
echo [5/5] Ready to start BSEE
echo.
echo  Usage Examples:
echo    python main.py input_file.bin --strategy greedy --max-operations 100
echo    python main.py data.bin --policy policy_ideality.yaml --strategy annealing
echo    python main.py test.bin --help
echo.

:: Check if user provided arguments
if "%~1"=="" (
    echo    No arguments provided. BSEE will start in interactive mode.
    echo    You can also run: start.bat "your arguments here"
    echo.
    echo    Example: start.bat "test.bin --strategy greedy --max-operations 50"
    echo.

    :: Run BSEE with help to show available options
    python main.py --help

    echo.
    echo    Press any key to exit...
    pause >nul
) else (
    echo    Starting BSEE with arguments: %*
    echo.

    :: Run BSEE with user-provided arguments
    python main.py %*

    if errorlevel 1 (
        echo.
        echo    BSEE encountered an error. Check the error message above.
        echo    Make sure the input file exists and arguments are correct.
    )
)

echo.
echo    BSEE execution completed.
echo    Results are saved in the 'results' directory.
echo.
pause