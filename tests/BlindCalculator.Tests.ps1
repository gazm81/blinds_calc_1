BeforeAll {
    Import-Module "$PSScriptRoot/../src/modules/BlindCalculator/BlindCalculator.psm1"
}

Describe "Get-RoundedpBlind" {
    It "should return the correct rounded small blind" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 1500
        $result | Should -Be 2000
    }
}

Describe "Get-PokerBlindStructure" {
    It "should return the correct blind structure" {
        $params = @{
            NumberOfPlayers = 5
            StartingSmallBlind = 1000
            StartingStack = 100000
            BlindDurationMinutes = 20
            TournamentDurationHours = 3
            ChipTypes = @(1000, 5000, 25000, 50000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        $result.Count | Should -BeGreaterThan 0
        $result[0].SmallBlind | Should -Be 1000
        $result[0].BigBlind | Should -Be 2000
    }

    It "should handle rebuys correctly" {
        $params = @{
            NumberOfPlayers = 5
            StartingSmallBlind = 1000
            StartingStack = 100000
            Rebuys = 2
            BlindDurationMinutes = 20
            TournamentDurationHours = 3
            ChipTypes = @(1000, 5000, 25000, 50000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        $result.Count | Should -BeGreaterThan 0
    }
}