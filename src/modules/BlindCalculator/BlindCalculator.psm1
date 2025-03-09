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

        $currentSmall = [Math]::Round($currentSmall * 1.5)
        $currentBig = $currentSmall * 2
    }

    Write-Host "Processing request with parameters:" -ForegroundColor Cyan
    Write-Host "- Players: $numPlayers" -ForegroundColor Gray
    Write-Host "- Round Length: $roundLengthMinutes minutes" -ForegroundColor Gray
    Write-Host "- Starting Small Blind: $startingSmallBlind" -ForegroundColor Gray
    Write-Host "- Starting Big Blind: $startingBigBlind" -ForegroundColor Gray
    Write-Host "- Starting Chips: $startingChips" -ForegroundColor Gray

    return $rounds
}

function Get-RoundedpBlind { 
    [CmdletBinding()]
    param (
        [int]$SmallBlind,
        [int]$ProposedSmallBlind
    )

    return [math]::Ceiling($ProposedSmallBlind / $SmallBlind) * $SmallBlind
}

function Get-PokerBlindStructure { 
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [ValidateRange(2, [Int16]::MaxValue)]
        [Int16]$NumberOfPlayers = 5,
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, [Int16]::MaxValue)]
        [Int16]$StartingSmallBlind = 1000,
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]$StartingStack = 100000,
        [ValidateNotNullOrEmpty()]
        [System.Boolean]$Ante = $false,
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, [Int16]::MaxValue)]
        [Int16]$Rebuys = 0,
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ ($_ / 5) -is [int] })] # Validate that the value is a multiple of 5
        [ValidateRange(10, [Int16]::MaxValue)]
        [Int16]$BlindDurationMinutes = 20,
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, [Int16]::MaxValue)]
        [Int16]$TournamentDurationHours = 3,
        [ValidateNotNullOrEmpty()]
        [ValidateCount(1, [Int16]::MaxValue)]
        [Int32[]]$ChipTypes = @(1000, 5000, 25000, 50000),
        [System.DateTime]$GameStartTime = (Get-Date)
    )

    $TotalChips = ( $NumberOfPlayers * $StartingStack ) + ( $Rebuys * $StartingStack )
    
    # This is based on the theory that game is over when the big blind is 7% of the total chips in play
    $FinalSmallBlind = Get-RoundedpBlind -SmallBlind $StartingSmallBlind -ProposedSmallBlind ($TotalChips * 0.035) 
    
    $TournamentDurationMins = $TournamentDurationHours * 60
    
    $TournamentRounds = [System.Math]::Floor($TournamentDurationMins  / $BlindDurationMinutes)

    $base = $FinalSmallBlind / $StartingSmallBlind
    $exponent = 1 / $TournamentRounds
    $multiplier = [System.Math]::Pow($base, $exponent)

    $Blinds = @()

    for ($RoundNumber = 1; $RoundNumber -le ($TournamentRounds + 1); $RoundNumber++) {

        $ProposedSmallBlind = $StartingSmallBlind * ( [System.Math]::Pow($multiplier, ($RoundNumber - 1)))

        $RoundSmallBlind = Get-RoundedpBlind -SmallBlind $StartingSmallBlind -ProposedSmallBlind $ProposedSmallBlind

        $RoundStartTime = $GameStartTime.AddMinutes($BlindDurationMinutes * ($RoundNumber - 1))

        $Blinds += New-Object -TypeName PSObject -Property @{
            RoundNumber = $RoundNumber
            SmallBlind = $RoundSmallBlind
            BigBlind = $RoundSmallBlind * 2
            RoundStartTime = $RoundStartTime
            #Ante = if ($Ante) { $StartingSmallBlind / 10 } else { 0 }
        }
    }

    Return $Blinds

 }

Export-ModuleMember -Function Calculate-BlindStructure, Get-RoundedpBlind, Get-PokerBlindStructure
