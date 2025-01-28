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

    return $rounds
}

Export-ModuleMember -Function Calculate-BlindStructure