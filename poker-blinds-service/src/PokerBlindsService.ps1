# Create a simple web server
$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:8080/")
$http.Start()

# Import the BlindCalculator module
Import-Module "$PSScriptRoot\modules\BlindCalculator\BlindCalculator.psm1"

try {
    while ($http.IsListening) {
        $context = $http.GetContext()
        $request = $context.Request
        $response = $context.Response

        # Parse query parameters
        $parameters = @{ }
        $request.QueryString.Keys | ForEach-Object {
            $parameters[$_] = $request.QueryString[$_]
        }

        if ($request.HttpMethod -eq 'GET' -and $request.Url.LocalPath -eq '/blinds') {
            $blindStructure = Calculate-BlindStructure `
                -numPlayers ([int]($parameters['players'] ?? 8)) `
                -roundLengthMinutes ([int]($parameters['roundLength'] ?? 15)) `
                -startingSmallBlind ([int]($parameters['smallBlind'] ?? 25)) `
                -startingBigBlind ([int]($parameters['bigBlind'] ?? 50)) `
                -startingChips ([int]($parameters['chips'] ?? 1500))

            $jsonResponse = $blindStructure | ConvertTo-Json
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = "application/json"
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        else {
            $response.StatusCode = 404
        }

        $response.Close()
    }
}
finally {
    $http.Stop()
}