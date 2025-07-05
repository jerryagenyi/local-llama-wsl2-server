# PowerShell script to add Ollama models to LiteLLM
# Make sure to set your LITELLM_MASTER_KEY in your environment variables

$headers = @{
    "Authorization" = "Bearer $env:LITELLM_MASTER_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    "model_name" = "llama3.2:latest"
    "litellm_params" = @{
        "model" = "ollama/llama3.2:latest"
        "api_base" = "http://host.docker.internal:11434"
    }
} | ConvertTo-Json -Depth 3

try {
    $response = Invoke-RestMethod -Uri "http://localhost:4000/model/new" -Method POST -Headers $headers -Body $body
    Write-Host "Successfully added llama3.2:latest to LiteLLM"
    Write-Host $response
} catch {
    Write-Host "Error adding model: $($_.Exception.Message)"
}

# Add more models as needed
# You can repeat the above block with different model names
