# Script para limpiar markers de conflicto tomando siempre la version HEAD (Nicole)
# Para cada archivo: conserva lineas entre inicio del archivo y "=======" (o sea la version HEAD)
# Si hay marcadores "<<<<<<< HEAD" ... "=======" ... ">>>>>>> origin/Naldo2"
# Conservamos el bloque HEAD y eliminamos el bloque Naldo2

function Resolve-ConflictFile {
    param([string]$FilePath)
    
    $lines = Get-Content -Path $FilePath -Encoding UTF8
    $result = [System.Collections.Generic.List[string]]::new()
    $inConflict = $false
    $inNaldo2Block = $false

    foreach ($line in $lines) {
        if ($line -match '^<<<<<<< HEAD') {
            # Inicio de bloque de conflicto - comenzamos a tomar la version HEAD
            $inConflict = $true
            $inNaldo2Block = $false
            continue
        }
        elseif ($line -match '^=======$' -and $inConflict) {
            # Fin de bloque HEAD, inicio de bloque Naldo2 - lo ignoramos
            $inNaldo2Block = $true
            continue
        }
        elseif ($line -match '^>>>>>>> origin/Naldo2' -and $inConflict) {
            # Fin del conflicto - volvemos al modo normal
            $inConflict = $false
            $inNaldo2Block = $false
            continue
        }
        else {
            if (-not $inNaldo2Block) {
                $result.Add($line)
            }
        }
    }
    
    [System.IO.File]::WriteAllLines($FilePath, $result, [System.Text.UTF8Encoding]::new($false))
    Write-Host "✅ Resuelto: $FilePath ($(($lines | Select-String '<<<<<<< HEAD').Count) conflictos removidos)"
}

Resolve-ConflictFile "lib\screens\home\home_screen_content.dart"
Resolve-ConflictFile "lib\screens\recipe\recipe_detail_screen.dart"

Write-Host "`n🔍 Verificando que no queden markers..."
$remaining = git grep -l "<<<<<<< HEAD" -- "*.dart" 2>&1
if ($remaining) {
    Write-Host "⚠️ Aún hay markers en: $remaining"
} else {
    Write-Host "✅ Sin markers de conflicto."
}
