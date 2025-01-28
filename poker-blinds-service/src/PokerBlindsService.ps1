Import-Module "$PSScriptRoot/modules/BlindCalculator/BlindCalculator.psm1"

$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:8080/")
$http.Start()

Write-Host "Server started at http://localhost:8080/"

while ($http.IsListening) {
    $context = $http.GetContext()
    
    if ($context.Request.HttpMethod -eq 'POST' -and $context.Request.RawUrl -eq '/calculate') {
        $reader = [System.IO.StreamReader]::new($context.Request.InputStream)
        $body = $reader.ReadToEnd() | ConvertFrom-Json
        
        $result = Calculate-BlindStructure `
            -numPlayers $body.numPlayers `
            -roundLengthMinutes $body.roundLengthMinutes `
            -startingSmallBlind $body.startingSmallBlind `
            -startingBigBlind $body.startingBigBlind `
            -startingChips $body.startingChips
            
        $response = $result | ConvertTo-Json
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($response)
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    }
    
    $context.Response.Close()
}