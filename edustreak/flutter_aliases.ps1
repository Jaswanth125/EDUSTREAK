# Flutter PowerShell Aliases
# Source this file in your PowerShell profile to add Flutter shortcuts
# Add to your profile: . "$PSScriptRoot\flutter_aliases.ps1"

$FlutterPath = "C:\src\flutter\bin\flutter.bat"

function flutter {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$args)
    
    $ProjectDir = "C:\EDUSTREAK(4)\EDUSTREAK\edustreak"
    Push-Location $ProjectDir
    
    try {
        $command = "`"$FlutterPath`" $($args -join ' ')"
        cmd /c $command 2>&1 | Where-Object { 
            $_ -notmatch "DIR /B /O:D" -and 
            $_ -notmatch "is not recognized as an internal or external command" 
        }
    }
    finally {
        Pop-Location
    }
}

# Export the function
Export-ModuleMember -Function flutter

Write-Host "Flutter aliases loaded. Use 'flutter' command directly." -ForegroundColor Green

