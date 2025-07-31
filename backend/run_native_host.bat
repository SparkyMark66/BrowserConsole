@echo off
REM This batch file ensures the Python script is executed by the Python interpreter.

REM IMPORTANT: Replace "C:\path\to\your\python.exe" with the actual path to your Python interpreter.
REM You can find this by opening Command Prompt and typing 'where python'
REM or 'python -c "import sys; print(sys.executable)"'

set PYTHON_EXECUTABLE="C:\Python313\python.exe"
REM OR, if python is in your PATH and you don't want a fixed path:
REM set PYTHON_EXECUTABLE=python.exe

set SCRIPT_PATH="%~dp0native_host.py"
REM %~dp0 expands to the directory of the batch file, ensuring it finds native_host.py

%PYTHON_EXECUTABLE% %SCRIPT_PATH%