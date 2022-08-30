::@echo off
:: PATH_v6-5.bat by Charlie Belinsky 
:: 8/29/22

:: 6-5 Changes
:: include admb2r.cpp in the installation -- gets added to the include folder in ADMB

:: 6-4 Changes
:: Sets the default app for tpl file to Emacs
::   - PATH needs to be run in Admin mode for this to work
::   - This does not work if the default app was previously set for tpl file

:: 6-3 Changes
:: PATH now looks for the latest versions of RTools and ADMB

:: 6-2 changes:
:: Switch from Rtools 40 to Rtool42 (now only affects TMB)
:: Using g++ from ADMB bin indtead of Rtools bin (affects ADMB only)
:: If path exists then delete first and readd (this way it appears in the correct order)

:: Changes since version 5:
:: .emacs now adds the Environment Path
:: Reordered PATH to put ADMB last
:: Added x64 folder in R (xterm was moved to that folder -- needed in Emacs for TMB)
:: Switch temp file to the local appdata folder (Windows 11 fix)

:: This batch file will
::   1) Get the four paths the need to be in the PATH User Environment
::   2) Get the current PATH 
::   3) Reformat the PATH to correct for slashes are semicolons
::   4) Prepend to the PATH any of the four paths needed that are not in the User PATH
::   5) Set the editted path as the new User PATH 
::   6) Copy the emacs config files to the home directory

:: This batch file DOES NOT REMOVE anything from the old User PATH Environemnt variable

:: The five paths that need to be in the PATH User Environment are:
::   1) c:\Program Files\R\R-?.?.?\bin;      The ? represent the R version number (currently 4.2.1)
::   2) c:\Program Files\R\R-?.?.?\bin\x64;  The ? represent the R version number (this is only needed for older versions of .emacs)
::   3) c:\admb-??.?\utilities\mingw64\bin;  g++ for ADMB
::   4) c:\rtools??\usr\bin;                 Compiler for TMB (current version of RTools: 4.2)
::   5) c:\admb-??.?\bin;                    The ? represent the ADMB version (currently 13.0)

:: looks for latest R installation -- sets the R bin folder as R_PATH
for /d %%D in ("c:\Program Files\R\R-?.?.?") do set R_PATH=%%~fD\bin;
for /d %%D in ("c:\Program Files\R\R-?.?.?") do set R_PATH2=%%~fD\bin\x64;

:: looks for latest ADMB installation -- sets the ADMB bin folder as ADMB_PATH
for /d %%D in ("c:\admb-??.?") do set ADMB_FOLDER=%%~fD
set ADMB_PATH=%ADMB_FOLDER%\bin;

:: looks for latest RTools installation -- sets the RTools folder as RTOOLS_PATH\usr\bin --
::   this folder has make.exe and sed.exe
for /d %%D in ("c:\rtools??") do set RTOOLS_PATH=%%~fD\usr\bin;

:: set the folder with the g++ compiler
::set RTOOLS_MINGW_PATH=c:\ADMB??.?\ultilities\mingw64\bin;
set RTOOLS_MINGW_PATH=%ADMB_FOLDER%\utilities\mingw64\bin;

::Get the current user PATH environment variable and save it to OLD_USER_PATH
for /F "tokens=2* delims= " %%f IN ('reg query HKCU\Environment /v PATH ^| findstr /i path') do set OLD_USER_PATH=%%g

:: Skip the next couple of steps if there is no PATH variable (or PATH is empty)
if "%OLD_USER_PATH%"=="" goto :empty 

::Change all backslashes to frontslashes if there was a PATH variable (they are equivalent in environment)
if not "%OLD_USER_PATH%"=="" (set OLD_USER_PATH=%OLD_USER_PATH:/=\%)

:: Add a semicolon to the end of the path if there is not one already
if not "%OLD_USER_PATH:~-1%"==";" (set OLD_USER_PATH=%OLD_USER_PATH%;)

:empty

:: Display the current PATH variable and save the PATH variable to temp file 
::  It would be better to save PATH to a variable but I am not sure yet how to do this yet...
echo old path: %OLD_USER_PATH%
echo %OLD_USER_PATH% > %localappdata%/temp/test.txt

::Check for, and add if not present, the R path
findstr /i /c:"%R_PATH%" %localappdata%\temp\test.txt >nul 2>&1
if %errorlevel% GTR 0 (set "APPENDED_PATH=%APPENDED_PATH%%R_PATH%")

::Check for, and add if not present, the R x64 path
findstr /i /c:"%R_PATH2%" %localappdata%\temp\test.txt >nul 2>&1
if %errorlevel% GTR 0 (set "APPENDED_PATH=%APPENDED_PATH%%R_PATH2%")

::Check for, and add if not present, the RTools path
findstr /i /c:"%RTOOLS_PATH%" %localappdata%\temp\test.txt >nul 2>&1
if %errorlevel% GTR 0 (set "APPENDED_PATH=%APPENDED_PATH%%RTOOLS_PATH%")

::Check for, and add if not present, the rtool minGW path
findstr /i /c:"%RTOOLS_MINGW_PATH%" %localappdata%\temp\test.txt >nul 2>&1
if %errorlevel% GTR 0 (set "APPENDED_PATH=%APPENDED_PATH%%RTOOLS_MINGW_PATH%")

::Check for, and add if not present, the ADMB path
findstr /i /c:"%ADMB_PATH%" %localappdata%\temp\test.txt >nul 2>&1
if %errorlevel% GTR 0 (set "APPENDED_PATH=%APPENDED_PATH%%ADMB_PATH%")

echo new path: "%APPENDED_PATH%%OLD_USER_PATH%"

::set the new user PATH variable
setx PATH "%APPENDED_PATH%%OLD_USER_PATH%"

::set the default home path to Emacs
set EMACS_PATH=%AppData%

:: Check if there is a HOME directory -- set emacs path to this
if not "%HOME%"=="" set EMACS_PATH=%HOME%

:: The home directory for Emacs can be set in registry but I believe that
::   this needs to be maually done so I am commenting out the deletion of this value

:: Check for a registry entry for Emacs HOME in user - delete if it is there
::reg delete HKCU\Software\Gnu\Emacs /v HOME /f

:: Check for a registry entry for Emacs HOME in local machine - delete if it is there
:: This will only work if you run as administrator 
::reg delete HKLM\Software\Gnu\Emacs /v HOME /f

::create a folder for the the emacs config file
if not exist %EMACS_PATH% mkdir %EMACS_PATH%

:: copy emacs config file to the folder
xcopy "%~dp0\emacsConfigFiles\" %EMACS_PATH% /h /i /c /k /e /r /y

:: copy admb2r.cpp to the include folder in ADMB
xcopy "%~dp0\admb2r.cpp" "%ADMB_FOLDER%\include\" /h /i /c /k /e /r /y
xcopy "%~dp0\admb2r.cpp" "%ADMB_FOLDER%\include\contrib\" /h /i /c /k /e /r /y

:: make Emacs the default program to open tpl files
assoc .tpl=tplfile
ftype tplfile=C:\Program Files\Emacs\x86_64\bin\runemacs.exe "%1"

:: where to remove file extension in Reg Editor
::   Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts
::set /p "CPPEmacs=Do you want CPP files to open in Emacs?: "
::if NOT "%CPPEmacs%"=="yes" goto :nocpp 
assoc .cpp=cppfile
ftype cppfile=C:\Program Files\Emacs\x86_64\bin\runemacs.exe "%1"

::User hits button to exit (so we can view the progress)
pause

:: ISSUES
:: Cannot write a file directly to C:\ unless you run in Admin mode --
::   So, hopefully, HOME is not set to c:\ on the user's computer