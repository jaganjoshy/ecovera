# Start Flask server in background
$env:PYTHONPATH = "."
Start-Process python -ArgumentList "app.py" -NoNewWindow

# Wait a moment for the server to start
Write-Host "Waiting for server to start..."
Start-Sleep -Seconds 5

# Run tests
Write-Host "Running tests..."
python test_api.py

# Get the test result
$testResult = $LASTEXITCODE

# Kill the Flask server process
Get-Process python | Where-Object { $_.CommandLine -like "*app.py*" } | Stop-Process -Force

# Exit with the test result
exit $testResult 