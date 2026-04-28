$currentPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$newPaths = 'D:\Users\platform-tools;D:\Users\cmdline-tools\latest\bin;D:\Users\emulator'

if ($currentPath -notlike '*D:\Users\platform-tools*') {
    [System.Environment]::SetEnvironmentVariable('Path', "$currentPath;$newPaths", 'User')
    Write-Host 'PATH actualizado con herramientas de Android' -ForegroundColor Green
} else {
    Write-Host 'Las rutas de Android ya estan en el PATH' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Configuracion completada!' -ForegroundColor Green
Write-Host 'Variables configuradas:' -ForegroundColor Cyan
Write-Host '  ANDROID_HOME = D:\Users'
Write-Host '  ANDROID_SDK_ROOT = D:\Users'
Write-Host ''
Write-Host 'IMPORTANTE: Cierra y vuelve a abrir tu terminal para que los cambios surtan efecto' -ForegroundColor Yellow