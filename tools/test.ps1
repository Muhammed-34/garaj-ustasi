param([string]$Suite = "res://tests")

$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "$env:USERPROFILE\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe" }
$project = Split-Path $PSScriptRoot -Parent

& $godot --headless --path $project --import | Out-Null
& $godot --headless --path $project -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a $Suite -c --ignoreHeadlessMode
exit $LASTEXITCODE
