BeforeAll {
    Import-Module "$PSScriptRoot/../src/modules/BlindCalculator/BlindCalculator.psm1"
}

Describe "Calculate-BlindStructure" {
    It "Should calculate correct number of rounds" {
        $result = Calculate-BlindStructure -numPlayers 9 -roundLengthMinutes 20 -startingSmallBlind 25 -startingBigBlind 50 -startingChips 1500
        $result.Count | Should -Be 15
    }

    It "Should have increasing blind levels" {
        $result = Calculate-BlindStructure -numPlayers 9 -roundLengthMinutes 20 -startingSmallBlind 25 -startingBigBlind 50 -startingChips 1500
        $result[1].BigBlind | Should -BeGreaterThan $result[0].BigBlind
    }
}