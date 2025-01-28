# Create a simple web server
$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:8080/")
$http.Start()

function Calculate-BlindStructure {
    param (
        [int]$numPlayers,
        [int]$roundLengthMinutes,
        [int]$startingSmallBlind,
        [int]$startingBigBlind,
        [int]$startingChips
    )

    $rounds = [System.Collections.ArrayList]::new()
    $currentSmall = $startingSmallBlind
    $currentBig = $startingBigBlind
    $numRounds = [Math]::Min(20, [Math]::Ceiling($startingChips / ($startingBigBlind * 2)))

    for ($i = 1; $i -le $numRounds; $i++) {
        $round = @{
            Level = $i
            SmallBlind = $currentSmall
            BigBlind = $currentBig
            TimeInMinutes = $roundLengthMinutes
        }
        $rounds.Add($round) | Out-Null

        # Increase blinds by ~50% each round
        $currentSmall = [Math]::Round($currentSmall * 1.5)
        $currentBig = $currentSmall * 2
    }

    return $rounds
}

try {
    while ($http.IsListening) {
        $context = $http.GetContext()
        $request = $context.Request
        $response = $context.Response

        # Parse query parameters
        $parameters = @{}
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