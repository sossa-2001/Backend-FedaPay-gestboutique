Write-Host "=== Generating Isar code ===" -ForegroundColor Cyan
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -eq 0) {
    Write-Host "=== Fixing schema IDs for web compatibility ===" -ForegroundColor Cyan
    dart run tool/fix_schema_ids.dart
    Write-Host "=== Done ===" -ForegroundColor Green
} else {
    Write-Host "=== Build runner failed ===" -ForegroundColor Red
}
