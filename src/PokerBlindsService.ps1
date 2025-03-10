Import-Module "$PSScriptRoot/modules/BlindCalculator/BlindCalculator.psm1"

try {
    $Listener = New-Object System.Net.HttpListener
    $Listener.Prefixes.Add("http://+:80/")
    $Listener.Start()

    Write-Host "Server started at http://localhost:80/"

    while ($Listener.IsListening) {
        $context = $Listener.GetContext()
        
        # Set CORS and content type headers
        $context.Response.Headers.Add("Access-Control-Allow-Origin", "*")
        $context.Response.Headers.Add("Content-Type", "application/json")

        try {
            if ($context.Request.HttpMethod -eq 'GET' ){#-and $context.Request.RawUrl -match '^/pokerblinds/calculate') {
                $params = [System.Web.HttpUtility]::ParseQueryString($context.Request.Url.Query)

                write-host "Processing request with parameters: $params" -ForegroundColor Cyan

                $PokerGameParams = @{
                    NumberOfPlayers = ($params["NumberOfPlayers"] ? [int]$params["NumberOfPlayers"] : 4) ;
                    StartingSmallBlind = ($params["StartingSmallBlind"] ? [int]$params["StartingSmallBlind"] : 1000) ;
                    StartingStack = ($params["StartingStack"] ? [int]$params["StartingStack"] : 100000) ;
                    Rebuys = ($params["Rebuys"] ? [int]$params["Rebuys"] : 0) ;
                    BlindDurationMinutes = ($params["BlindDurationMinutes"] ? [int]$params["BlindDurationMinutes"] : 20) ;
                    TournamentDurationHours = ($params["TournamentDurationHours"] ? [int]$params["TournamentDurationHours"] : 3) ;
                    ChipTypes = ($params["ChipTypes"] ? (ConvertFrom-Json -InputObject $params["ChipTypes"]) : @("1000","5000","25000","50000")) ;
                    GameStartTime = ($params["GameStartTime"] ? [datetime]$params["GameStartTime"] : (Get-Date))
                }

                $result = Get-PokerBlindStructure @PokerGameParams

                # Create HTML table
                $htmlTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .config-section { margin: 20px 0; padding: 15px; background-color: #f8f8f8; border: 1px solid #ddd; }
        .form-row { margin: 10px 0; }
        .form-row label { display: inline-block; width: 200px; font-weight: bold; }
        .form-row input { 
            padding: 5px; 
            width: 100px; 
            border: 1px solid #aaa;
            background-color: white;
            cursor: text;
        }
        button { 
            margin-top: 10px;
            padding: 8px 15px;
            background-color: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
        }
    </style>
    <script>
        function updateValues() {
            const params = new URLSearchParams();
            $(
                foreach ($PokerGameParam in $PokerGameParams.Keys) {
                    "params.append('$PokerGameParam', document.getElementById('$PokerGameParam').value);"
                }
            )
            
            window.location.href = '/pokerblinds/calculate?' + params.toString();
        }
    </script>
</head>
<body>
    <form class="config-section" onsubmit="event.preventDefault(); updateValues();">
        $(
            foreach ($PokerGameParam in $PokerGameParams.Keys) {
                switch ($PokerGameParam) {
                    'GameStartTime' {
                        $inputType = 'datetime-local'
                    }
                    'ChipTypes' {
                        $inputType = 'text'
                    }
                    default {
                        $inputType = 'number'
                    }
                }
                $PokerGameParamJson = $PokerGameParams[$PokerGameParam] | ConvertTo-Json -Compress
                Write-Host "Processing $PokerGameParam with value $PokerGameParamJson" -ForegroundColor Yellow
                "<div class='form-row'><label>$PokerGameParam</label><input type='$InputType' id='$PokerGameParam' value='$PokerGameParamJson'></div>"
            }
        )
        <button type="submit">Update Values</button>
    </form>
    <table>
        <tr>
            <th>Level</th>
            <th>Small Blind</th>
            <th>Big Blind</th>
            <th>Time</th>
        </tr>
        $($result | ForEach-Object {
            "<tr><td>$($_.RoundNumber)</td><td>$($_.SmallBlind)</td><td>$($_.BigBlind)</td><td>$($_.RoundStartTime.ToShortTimeString())</td></tr>"
        })
    </table>
</body>
</html>
"@
                $context.Response.ContentType = "text/html"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($htmlTemplate)
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