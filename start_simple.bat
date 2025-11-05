@echo off
echo Starting BSEE...

:: Check if venv exists, create if not
if not exist "venv\" (
    echo Creating virtual environment...
    python -m venv venv
)

:: Activate virtual environment
call venv\Scripts\activate.bat

:: Install dependencies if needed
echo Checking dependencies...
pip install numpy scipy pyyaml >nul 2>&1

:: Run BSEE with provided arguments or help
if "%~1"=="" (
    python main.py --help
) else (
    python main.py %*
)

pause