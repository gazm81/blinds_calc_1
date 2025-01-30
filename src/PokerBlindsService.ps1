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
                    -numPlayers ($params["numPlayers"] ? [int]$params["numPlayers"] : 6) `
                    -roundLengthMinutes ($params["roundLength"] ? [int]$params["roundLength"] : 15) `
                    -startingSmallBlind ($params["startingSmall"] ? [int]$params["startingSmall"] : 25) `
                    -startingBigBlind ($params["startingBig"] ? [int]$params["startingBig"] : 50) `
                    -startingChips ($params["chipsPerPlayer"] ? [int]$params["chipsPerPlayer"] : 1000)
                    
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
            params.append('numPlayers', document.getElementById('numPlayers').value);
            params.append('roundLength', document.getElementById('roundLength').value);
            params.append('startingSmall', document.getElementById('startingSmall').value);
            params.append('startingBig', document.getElementById('startingBig').value);
            params.append('chipsPerPlayer', document.getElementById('chipsPerPlayer').value);
            
            window.location.href = '/pokerblinds/calculate?' + params.toString();
        }
    </script>
</head>
<body>
    <form class="config-section" onsubmit="event.preventDefault(); updateValues();">
        <div class="form-row">
            <label>Number of Players:</label>
            <input type="number" id="numPlayers" value="$($params["numPlayers"] ? $params["numPlayers"] : 6)">
        </div>
        <div class="form-row">
            <label>Round Length (minutes):</label>
            <input type="number" id="roundLength" value="$($params["roundLength"] ? $params["roundLength"] : 15)">
        </div>
        <div class="form-row">
            <label>Starting Small Blind:</label>
            <input type="number" id="startingSmall" value="$($params["startingSmall"] ? $params["startingSmall"] : 25)">
        </div>
        <div class="form-row">
            <label>Starting Big Blind:</label>
            <input type="number" id="startingBig" value="$($params["startingBig"] ? $params["startingBig"] : 50)">
        </div>
        <div class="form-row">
            <label>Starting Chips:</label>
            <input type="number" id="chipsPerPlayer" value="$($params["chipsPerPlayer"] ? $params["chipsPerPlayer"] : 1000)">
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
            "<tr><td>$($_.Level)</td><td>$($_.SmallBlind)</td><td>$($_.BigBlind)</td><td>$($_.TimeInMinutes)</td></tr>"
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