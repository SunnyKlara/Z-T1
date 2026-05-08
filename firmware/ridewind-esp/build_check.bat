@echo off
C:\Espressif\frameworks\esp-idf-v5.3.5\tools\idf.py build > build_output.log 2>&1
echo Exit code: %ERRORLEVEL%
