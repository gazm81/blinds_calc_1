Import-Module "$PSScriptRoot/modules/BlindCalculator/BlindCalculator.psm1"

try {
    $Listener = New-Object System.Net.HttpListener
    $Listener.Prefixes.Add("http://+:8080/")
    $Listener.Start()

    Write-Host "Server started at http://localhost:8080/"

    while ($Listener.IsListening) {
        $context = $Listener.GetContext()
        
        # Set CORS and content type headers
        $context.Response.Headers.Add("Access-Control-Allow-Origin", "*")
        $context.Response.Headers.Add("Content-Type", "application/json")

        try {
            if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -match '^/pokerblinds/calculate') {
                $params = [System.Web.HttpUtility]::ParseQueryString($context.Request.Url.Query)
                
                $result = Calculate-BlindStructure `
                    -numPlayers ([int]$params["numPlayers"]) `
                    -roundLengthMinutes ([int]$params["roundLength"]) `
                    -startingSmallBlind ([int]$params["startingSmall"]) `
                    -startingBigBlind ([int]$params["startingBig"]) `
                    -startingChips ([int]$params["chipsPerPlayer"])
                    
                $response = $result | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($response)
                $context.Response.ContentLength64 = $buffer.Length
                $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        catch {
            Write-Host "Error processing request: $_"
            $errorResponse = @{error = $_.Exception.Message} | ConvertTo-Json
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorResponse)
            $context.Response.StatusCode = 500
            $context.Response.ContentLength64 = $buffer.Length
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        finally {
            $context.Response.Close()
        }
    }
}
finally {
    if ($Listener) {
        $Listener.Stop()
        $Listener.Close()
        Write-Host "Server stopped"
    }
}