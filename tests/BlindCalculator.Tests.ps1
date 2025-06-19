BeforeAll {
    Import-Module "$PSScriptRoot/../src/modules/BlindCalculator/BlindCalculator.psm1"
}

Describe "Get-RoundedpBlind" {
    It "should return the correct rounded small blind" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 1500
        $result | Should -Be 2000
    }
    
    It "should round up to the next multiple when exactly in between" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 1500
        $result | Should -Be 2000
    }
    
    It "should return the same value when proposed equals small blind" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 1000
        $result | Should -Be 1000
    }
    
    It "should round up when proposed is less than small blind" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 500
        $result | Should -Be 1000
    }
    
    It "should handle large values correctly" {
        $result = Get-RoundedpBlind -SmallBlind 5000 -ProposedSmallBlind 12000
        $result | Should -Be 15000
    }
    
    It "should handle fractional rounding correctly" {
        $result = Get-RoundedpBlind -SmallBlind 250 -ProposedSmallBlind 300
        $result | Should -Be 500
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
    
    It "should create correct number of rounds based on tournament duration" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 1000
            StartingStack = 100000
            BlindDurationMinutes = 15
            TournamentDurationHours = 2
            ChipTypes = @(1000, 5000, 25000, 50000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        # 2 hours = 120 minutes, 15 minute rounds = 8 rounds + 1 extra = 9 total
        $result.Count | Should -Be 9
    }
    
    It "should have generally increasing blind levels" {
        $params = @{
            NumberOfPlayers = 6
            StartingSmallBlind = 1000
            StartingStack = 100000
            BlindDurationMinutes = 20
            TournamentDurationHours = 3
            ChipTypes = @(1000, 5000, 25000, 50000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        # Check that the final round has higher blinds than the first round
        $result[-1].SmallBlind | Should -BeGreaterThan $result[0].SmallBlind
        
        # Check that there's an overall increasing trend (not necessarily every single round)
        $firstHalf = $result[0..([math]::Floor($result.Count/2))]
        $secondHalf = $result[([math]::Floor($result.Count/2))..$result.Count]
        $avgFirstHalf = ($firstHalf | Measure-Object -Property SmallBlind -Average).Average
        $avgSecondHalf = ($secondHalf | Measure-Object -Property SmallBlind -Average).Average
        $avgSecondHalf | Should -BeGreaterThan $avgFirstHalf
    }
    
    It "should maintain 2:1 ratio between big blind and small blind" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 500
            StartingStack = 50000
            BlindDurationMinutes = 10
            TournamentDurationHours = 1
            ChipTypes = @(500, 1000, 5000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        # Check that big blind is always double the small blind
        foreach ($round in $result) {
            $round.BigBlind | Should -Be ($round.SmallBlind * 2)
        }
    }
    
    It "should handle minimum parameters correctly" {
        $params = @{
            NumberOfPlayers = 2
            StartingSmallBlind = 1
            StartingStack = 1
            BlindDurationMinutes = 10
            TournamentDurationHours = 1
            ChipTypes = @(1)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        $result.Count | Should -BeGreaterThan 0
        $result[0].SmallBlind | Should -Be 1
        $result[0].BigBlind | Should -Be 2
    }
    
    It "should set correct round start times" {
        $startTime = Get-Date
        $params = @{
            NumberOfPlayers = 3
            StartingSmallBlind = 1000
            StartingStack = 100000
            BlindDurationMinutes = 30
            TournamentDurationHours = 2
            ChipTypes = @(1000, 5000)
            GameStartTime = $startTime
        }
        $result = Get-PokerBlindStructure @params
        
        # First round should start at game start time
        $result[0].RoundStartTime | Should -Be $startTime
        
        # Second round should start 30 minutes later
        if ($result.Count -gt 1) {
            $result[1].RoundStartTime | Should -Be $startTime.AddMinutes(30)
        }
    }
    
    It "should handle different chip denominations" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 100
            StartingStack = 10000
            BlindDurationMinutes = 15
            TournamentDurationHours = 1
            ChipTypes = @(25, 100, 500, 1000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        $result.Count | Should -BeGreaterThan 0
        $result[0].SmallBlind | Should -Be 100
    }
}

Describe "Get-PokerBlindStructure Parameter Validation" {
    It "should validate NumberOfPlayers minimum value" {
        $params = @{
            NumberOfPlayers = 1  # Below minimum of 2
            StartingSmallBlind = 1000
            StartingStack = 100000
        }
        { Get-PokerBlindStructure @params } | Should -Throw
    }
    
    It "should validate StartingSmallBlind minimum value" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 0  # Below minimum of 1
            StartingStack = 100000
        }
        { Get-PokerBlindStructure @params } | Should -Throw
    }
    
    It "should validate StartingStack minimum value" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 1000
            StartingStack = 0  # Below minimum of 1
        }
        { Get-PokerBlindStructure @params } | Should -Throw
    }
    
    It "should validate BlindDurationMinutes is multiple of 5" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 1000
            StartingStack = 100000
            BlindDurationMinutes = 13  # Not a multiple of 5
        }
        { Get-PokerBlindStructure @params } | Should -Throw
    }
    
    It "should validate BlindDurationMinutes minimum value" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 1000
            StartingStack = 100000
            BlindDurationMinutes = 5  # Below minimum of 10
        }
        { Get-PokerBlindStructure @params } | Should -Throw
    }
}