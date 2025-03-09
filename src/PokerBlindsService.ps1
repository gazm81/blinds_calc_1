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
                
                $result = Get-PokerBlindStructure `
                    -NumberOfPlayers ($params["NumberOfPlayers"] ? [int]$params["NumberOfPlayers"] : 6) `
                    -BlindDurationMinutes ($params["BlindDurationMinutes"] ? [int]$params["BlindDurationMinutes"] : 15) `
                    -StartingSmallBlind ($params["StartingSmallBlind"] ? [int]$params["StartingSmallBlind"] : 25) `
                    -StartingBigBlind ($params["StartingBigBlind"] ? [int]$params["StartingBigBlind"] : 50) `
                    -StartingStack ($params["StartingStack"] ? [int]$params["StartingStack"] : 1000)
                    
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
            params.append('NumberOfPlayers', document.getElementById('NumberOfPlayers').value);
            params.append('BlindDurationMinutes', document.getElementById('BlindDurationMinutes').value);
            params.append('StartingSmallBlind', document.getElementById('StartingSmallBlind').value);
            params.append('StartingBigBlind', document.getElementById('StartingBigBlind').value);
            params.append('StartingStack', document.getElementById('StartingStack').value);
            
            window.location.href = '/pokerblinds/calculate?' + params.toString();
        }
    </script>
</head>
<body>
    <form class="config-section" onsubmit="event.preventDefault(); updateValues();">
        <div class="form-row">
            <label>Number of Players:</label>
            <input type="number" id="numPlayers" value="$($params["NumberOfPlayers"] ? $params["NumberOfPlayers"] : 6)">
        </div>
        <div class="form-row">
            <label>Round Length (minutes):</label>
            <input type="number" id="roundLength" value="$($params["BlindDurationMinutes"] ? $params["BlindDurationMinutes"] : 15)">
        </div>
        <div class="form-row">
            <label>Starting Small Blind:</label>
            <input type="number" id="startingSmall" value="$($params["StartingSmallBlind"] ? $params["StartingSmallBlind"] : 25)">
        </div>
        <div class="form-row">
            <label>Starting Big Blind:</label>
            <input type="number" id="startingBig" value="$($params["StartingBigBlind"] ? $params["StartingBigBlind"] : 50)">
        </div>
        <div class="form-row">
            <label>Starting Chips:</label>
            <input type="number" id="chipsPerPlayer" value="$($params["StartingStack"] ? $params["StartingStack"] : 1000)">
        </div>
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