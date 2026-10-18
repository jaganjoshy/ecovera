# Get the current directory
$currentDir = Get-Location

# Start Flask server in background
Write-Host "Starting Flask server..."
$env:PYTHONPATH = "."
$flaskProcess = Start-Process -FilePath "python" -ArgumentList "backend/app.py" -WorkingDirectory $currentDir -PassThru -WindowStyle Hidden

# Wait for server to initialize
Write-Host "Waiting for server to start..."
Start-Sleep -Seconds 5

# Start Flutter app
Write-Host "Starting Flutter app..."
flutter run

# When Flutter app exits, kill the Flask server
if ($flaskProcess) {
    Stop-Process -Id $flaskProcess.Id -Force -ErrorAction SilentlyContinue
} 