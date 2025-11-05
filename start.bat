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
set PACKAGES=numpy scipy pyyaml matplotlib pillow psutil click tqdm lz4 zstandard

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
echo  Launch Options:
echo    1. GUI Mode (Recommended)       - Launch graphical interface
echo    2. CLI Mode                    - Command line interface
echo    3. Help                        - Show command line options
echo.

:: Ask user what mode to launch
if "%~1"=="" (
    echo    Choose launch mode [1-3]:
    choice /c 123 /n /m "Choose launch mode (1=GUI, 2=CLI, 3=Help): "

    if errorlevel 3 (
        echo.
        echo    Showing CLI help...
        python main.py --help
        echo.
        echo    Press any key to exit...
        pause >nul
    ) else if errorlevel 2 (
        echo.
        echo    CLI Interactive Mode
        echo    ===================
        echo.

        :: Ensure input folder exists
        if not exist "inputs\" mkdir inputs

        :: Get input file
        :get_file
        echo    Available files in inputs\ folder:
        if exist "inputs\*.bin" (
            dir /b inputs\*.bin 2>nul
        ) else (
            echo    No .bin files found in inputs\ folder
            echo.
            set /p CREATE_TEST="Create a test file for demonstration? [Y/n]: "
            if /i not "%CREATE_TEST%"=="n" if /i not "%CREATE_TEST%"=="no" (
                echo    Creating test binary file...
                python -c "
import os
import random
import struct

# Create interesting test data
test_data = bytearray()

# Add repeated patterns
test_data.extend(b'\xAA\x55\xAA\x55' * 64)  # Alternating pattern
test_data.extend(b'\x00\xFF\x00\xFF' * 64)  # Complementary pattern
test_data.extend(b'\x12\x34\x56\x78' * 32)  # Sequential pattern

# Add random data
test_data.extend(bytes([random.randint(0, 255) for _ in range(256)]))

# Add structured data
for i in range(64):
    test_data.extend(struct.pack('<I', i))

# Add ASCII text
test_data.extend(b'Hello, BSEE! This is a test binary file for analysis.' * 8)

# Add high-entropy data
test_data.extend(os.urandom(512))

# Write to file
with open('inputs\test.bin', 'wb') as f:
    f.write(test_data)

print(f'Created test.bin ({len(test_data)} bytes)')
"
                echo    Created: inputs\test.bin
                echo.
            )
        )
        echo.
        set /p INPUT_FILE="Enter input filename (from inputs\ folder, e.g., test.bin): "
        set /p FULL_PATH="Or enter full path to file (optional): "

        if "%INPUT_FILE%"=="" if "%FULL_PATH%"=="" (
            echo    ERROR: Please enter a filename
            goto get_file
        )

        if "%FULL_PATH%"=="" (
            if not exist "inputs\%INPUT_FILE%" (
                echo    ERROR: File inputs\%INPUT_FILE% does not exist
                echo    Please make sure the file is in the inputs\ folder
                goto get_file
            )
        ) else (
            if exist "%FULL_PATH%" (
                echo    Copying file from %FULL_PATH% to inputs folder...
                copy "%FULL_PATH%" "inputs\" >nul
                for %%F in ("%FULL_PATH%") do set INPUT_FILE=%%~nxF
                echo    Copied to: inputs\%INPUT_FILE%
            ) else (
                echo    ERROR: File %FULL_PATH% does not exist
                goto get_file
            )
        )

        echo    Using file: inputs\%INPUT_FILE%
        echo.

        :: Get strategy
        echo    Available strategies:
        echo    1. greedy     - Always select best operation (fast)
        echo    2. beam       - Keep top N candidates
        echo    3. annealing - Simulated annealing search
        echo    4. mcts       - Monte Carlo Tree Search
        echo    5. genetic    - Evolutionary algorithm
        echo    6. heuristic  - Rule-based selection
        echo.
        set /p STRATEGY_CHOICE="Choose strategy [1-6, default=1]: "

        if "%STRATEGY_CHOICE%"=="" set STRATEGY_CHOICE=1
        if "%STRATEGY_CHOICE%"=="1" set STRATEGY=greedy
        if "%STRATEGY_CHOICE%"=="2" set STRATEGY=beam
        if "%STRATEGY_CHOICE%"=="3" set STRATEGY=annealing
        if "%STRATEGY_CHOICE%"=="4" set STRATEGY=mcts
        if "%STRATEGY_CHOICE%"=="5" set STRATEGY=genetic
        if "%STRATEGY_CHOICE%"=="6" set STRATEGY=heuristic
        if "%STRATEGY_CHOICE%"=="1" set STRATEGY=greedy

        for %%s in (greedy beam annealing mcts genetic heuristic) do (
            if "!STRATEGY_CHOICE!"=="%%s" set STRATEGY=%%s
        )

        echo    Strategy: !STRATEGY!
        echo.

        :: Get max operations
        set /p MAX_OPS="Enter max operations [default=1000]: "
        if "%MAX_OPS%"=="" set MAX_OPS=1000
        echo    Max operations: %MAX_OPS%
        echo.

        :: Get max cost
        set /p MAX_COST="Enter max cost [default=10000]: "
        if "%MAX_COST%"=="" set MAX_COST=10000
        echo    Max cost: %MAX_COST%
        echo.

        :: Get metrics choice
        echo    Metric presets:
        echo    1. Default - file_ideality_score, entropy_global, lz77_ratio
        echo    2. Entropy focus - entropy_global, shannon_entropy_global
        echo    3. Compression focus - lz77_ratio, compression_ratio
        echo    4. Custom - enter your own metrics
        echo.
        set /p METRICS_CHOICE="Choose metrics preset [1-4, default=1]: "

        if "%METRICS_CHOICE%"=="" set METRICS_CHOICE=1
        if "%METRICS_CHOICE%"=="1" set METRICS=file_ideality_score,entropy_global,lz77_ratio
        if "%METRICS_CHOICE%"=="2" set METRICS=entropy_global,shannon_entropy_global
        if "%METRICS_CHOICE%"=="3" set METRICS=lz77_ratio,compression_ratio
        if "%METRICS_CHOICE%"=="4" (
            set /p METRICS="Enter custom metrics (comma-separated): "
            if "!METRICS!"=="" set METRICS=file_ideality_score,entropy_global,lz77_ratio
        )

        echo    Metrics: !METRICS!
        echo.

        :: Get output directory
        set /p OUTPUT_DIR="Enter output directory [default=results]: "
        if "%OUTPUT_DIR%"=="" set OUTPUT_DIR=results
        echo    Output directory: %OUTPUT_DIR%
        echo.

        :: Show configuration summary
        echo    Configuration Summary:
        echo    ====================
        echo    Input File:     inputs\%INPUT_FILE%
        echo    Strategy:       !STRATEGY!
        echo    Max Operations: %MAX_OPS%
        echo    Max Cost:       %MAX_COST%
        echo    Metrics:        !METRICS!
        echo    Output Dir:     %OUTPUT_DIR%
        echo.

        :: Confirm execution
        set /p CONFIRM="Start analysis with these settings? [Y/n]: "
        if /i not "%CONFIRM%"=="n" if /i not "%CONFIRM%"=="no" (
            echo.
            echo    Starting BSEE analysis...
            echo    ========================
            echo.

            :: Create results directory if it doesn't exist
            if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

            :: Run BSEE with the configured parameters
            python main.py "inputs\%INPUT_FILE%" ^
                --strategy !STRATEGY! ^
                --max-operations %MAX_OPS% ^
                --max-cost %MAX_COST% ^
                --metrics "!METRICS!" ^
                --output-dir "%OUTPUT_DIR%" ^
                --target-metrics "file_ideality_score=max,entropy_global=min"

            if errorlevel 1 (
                echo.
                echo    BSEE encountered an error. Check the error message above.
                echo    Make sure the input file exists and arguments are correct.
            ) else (
                echo.
                echo    Analysis completed successfully!
                echo    Results are saved in the '%OUTPUT_DIR%' directory.
            )
        )

        echo.
        echo    Press any key to exit...
        pause >nul
    ) else if errorlevel 1 (
        echo.
        echo    Starting BSEE GUI...
        python gui_main.py

        if errorlevel 1 (
            echo.
            echo    BSEE GUI encountered an error. Check the error message above.
            echo    Make sure all dependencies are installed correctly.
        )
    )
) else (
    :: Direct argument provided - check if GUI requested
    if "%~1"=="gui" (
        echo    Starting BSEE GUI with arguments: %*
        python gui_main.py %2 %3 %4 %5 %6 %7 %8 %9
    ) else (
        echo    Starting BSEE CLI with arguments: %*
        python main.py %*

        if errorlevel 1 (
            echo.
            echo    BSEE encountered an error. Check the error message above.
            echo    Make sure the input file exists and arguments are correct.
        )
    )
)

echo.
echo    BSEE execution completed.
echo    Results are saved in the 'results' directory.
echo.
pause