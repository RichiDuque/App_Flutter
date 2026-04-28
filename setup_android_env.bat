@echo off
echo ============================================
echo Configurando variables de entorno Android
echo ============================================
echo.

REM Ubicacion del SDK de Android
set ANDROID_SDK_PATH=D:\Users

echo Verificando si existe el SDK en: %ANDROID_SDK_PATH%
if not exist "%ANDROID_SDK_PATH%" (
    echo [ERROR] No se encontro el SDK de Android en %ANDROID_SDK_PATH%
    echo.
    echo Por favor, verifica que Android Studio este instalado correctamente.
    echo La ubicacion del SDK debe ser una de estas:
    echo   - %LOCALAPPDATA%\Android\Sdk
    echo   - C:\Program Files\Android\Android Studio\sdk
    echo.
    pause
    exit /b 1
)

echo [OK] SDK encontrado en: %ANDROID_SDK_PATH%
echo.

REM Configurar variables de entorno del sistema
echo Configurando ANDROID_HOME...
setx ANDROID_HOME "%ANDROID_SDK_PATH%"

echo Configurando ANDROID_SDK_ROOT...
setx ANDROID_SDK_ROOT "%ANDROID_SDK_PATH%"

REM Agregar herramientas de Android al PATH
echo Agregando herramientas de Android al PATH...
set "NEW_PATH=%ANDROID_SDK_PATH%\platform-tools;%ANDROID_SDK_PATH%\cmdline-tools\latest\bin;%ANDROID_SDK_PATH%\emulator"

REM Obtener PATH actual
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "CURRENT_PATH=%%b"

REM Verificar si ya esta en el PATH
echo %CURRENT_PATH% | findstr /C:"%ANDROID_SDK_PATH%" >nul
if errorlevel 1 (
    echo Agregando al PATH del usuario...
    setx PATH "%CURRENT_PATH%;%NEW_PATH%"
    echo [OK] PATH actualizado
) else (
    echo [INFO] Las rutas de Android ya estan en el PATH
)

echo.
echo ============================================
echo Configuracion completada!
echo ============================================
echo.
echo IMPORTANTE:
echo 1. Cierra y vuelve a abrir tu terminal/IDE para que los cambios surtan efecto
echo 2. Verifica la configuracion ejecutando: flutter doctor
echo.
echo Variables configuradas:
echo   ANDROID_HOME = %ANDROID_SDK_PATH%
echo   ANDROID_SDK_ROOT = %ANDROID_SDK_PATH%
echo.
echo Rutas agregadas al PATH:
echo   - %ANDROID_SDK_PATH%\platform-tools
echo   - %ANDROID_SDK_PATH%\cmdline-tools\latest\bin
echo   - %ANDROID_SDK_PATH%\emulator
echo.
pause