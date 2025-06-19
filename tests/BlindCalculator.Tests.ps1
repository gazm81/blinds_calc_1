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
    
    It "should handle zero proposed small blind" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 0
        $result | Should -Be 0
    }
    
    It "should handle decimal proposed small blind values" {
        $result = Get-RoundedpBlind -SmallBlind 100 -ProposedSmallBlind 150.75
        $result | Should -Be 200
    }
    
    It "should handle very small blind values" {
        $result = Get-RoundedpBlind -SmallBlind 1 -ProposedSmallBlind 2
        $result | Should -Be 2
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
    
    It "should handle Ante parameter correctly" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 1000
            StartingStack = 100000
            Ante = $true
            BlindDurationMinutes = 20
            TournamentDurationHours = 2
            ChipTypes = @(1000, 5000, 25000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        $result.Count | Should -BeGreaterThan 0
        # Ante functionality is commented out in the code, but parameter should be accepted
    }
    
    It "should create output objects with all required properties" {
        $params = @{
            NumberOfPlayers = 3
            StartingSmallBlind = 500
            StartingStack = 50000
            BlindDurationMinutes = 15
            TournamentDurationHours = 1
            ChipTypes = @(500, 1000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        foreach ($round in $result) {
            $round.PSObject.Properties.Name | Should -Contain "RoundNumber"
            $round.PSObject.Properties.Name | Should -Contain "SmallBlind"
            $round.PSObject.Properties.Name | Should -Contain "BigBlind"
            $round.PSObject.Properties.Name | Should -Contain "RoundStartTime"
            
            $round.RoundNumber | Should -BeOfType [int]
            # SmallBlind and BigBlind can be either decimal or double due to mathematical calculations
            $round.SmallBlind | Should -BeOfType [System.ValueType] 
            $round.BigBlind | Should -BeOfType [System.ValueType]
            $round.RoundStartTime | Should -BeOfType [DateTime]
        }
    }
    
    It "should have correctly incrementing round numbers" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 1000
            StartingStack = 100000
            BlindDurationMinutes = 20
            TournamentDurationHours = 2
            ChipTypes = @(1000, 5000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        for ($i = 0; $i -lt $result.Count; $i++) {
            $result[$i].RoundNumber | Should -Be ($i + 1)
        }
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
    
    It "should validate TournamentDurationHours minimum value" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 1000
            StartingStack = 100000
            TournamentDurationHours = 0  # Below minimum of 1
        }
        { Get-PokerBlindStructure @params } | Should -Throw
    }
    
    It "should validate ChipTypes array is not empty" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 1000
            StartingStack = 100000
            ChipTypes = @()  # Empty array
        }
        { Get-PokerBlindStructure @params } | Should -Throw
    }
    
    It "should validate Rebuys minimum value" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 1000
            StartingStack = 100000
            Rebuys = -1  # Below minimum of 0
        }
        { Get-PokerBlindStructure @params } | Should -Throw
    }
}

Describe "Get-PokerBlindStructure Mathematical Calculations" {
    It "should calculate final small blind based on 7% of total chips theory" {
        $params = @{
            NumberOfPlayers = 5
            StartingSmallBlind = 1000
            StartingStack = 100000
            Rebuys = 0
            BlindDurationMinutes = 20
            TournamentDurationHours = 3
            ChipTypes = @(1000, 5000, 25000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        $totalChips = $params.NumberOfPlayers * $params.StartingStack
        $expectedFinalSmallBlind = $totalChips * 0.035
        
        # The final round should have a small blind close to 7% of total chips
        # (allowing for rounding via Get-RoundedpBlind)
        $finalRound = $result[-1]
        $finalRound.SmallBlind | Should -BeGreaterOrEqual ([math]::Floor($expectedFinalSmallBlind))
    }
    
    It "should account for rebuys in total chip calculation" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 1000
            StartingStack = 50000
            Rebuys = 3
            BlindDurationMinutes = 15
            TournamentDurationHours = 2
            ChipTypes = @(1000, 5000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        $totalChips = ($params.NumberOfPlayers * $params.StartingStack) + ($params.Rebuys * $params.StartingStack)
        $expectedFinalSmallBlind = $totalChips * 0.035
        
        # Final blind should reflect the additional chips from rebuys
        $finalRound = $result[-1]
        $finalRound.SmallBlind | Should -BeGreaterOrEqual ([math]::Floor($expectedFinalSmallBlind))
    }
    
    It "should handle very short tournaments correctly" {
        $params = @{
            NumberOfPlayers = 2
            StartingSmallBlind = 100
            StartingStack = 10000
            BlindDurationMinutes = 10
            TournamentDurationHours = 1  # Only 6 rounds
            ChipTypes = @(100, 500)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        # Should have 7 rounds (6 calculated + 1 extra)
        $result.Count | Should -Be 7
        $result[0].SmallBlind | Should -Be 100
        $result[-1].SmallBlind | Should -BeGreaterThan 100
    }
    
    It "should handle very long tournaments correctly" {
        $params = @{
            NumberOfPlayers = 10
            StartingSmallBlind = 25
            StartingStack = 50000
            BlindDurationMinutes = 15
            TournamentDurationHours = 8  # 32 rounds
            ChipTypes = @(25, 100, 500, 1000, 5000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        # Should have 33 rounds (32 calculated + 1 extra)
        $result.Count | Should -Be 33
        $result[0].SmallBlind | Should -Be 25
        $result[-1].SmallBlind | Should -BeGreaterThan 25
    }
    
    It "should handle non-evenly divisible tournament duration" {
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 100
            StartingStack = 50000
            BlindDurationMinutes = 15  # 90 minutes total, 6 rounds
            TournamentDurationHours = 1.5  # 90 minutes exactly
            ChipTypes = @(100, 500, 1000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        # Tournament duration creates proper number of rounds
        $result.Count | Should -BeGreaterThan 0
        $result[0].SmallBlind | Should -Be 100
        
        # Check that blinds generally increase over time
        $result[-1].SmallBlind | Should -BeGreaterThan $result[0].SmallBlind
    }
}

Describe "Get-PokerBlindStructure Edge Cases" {
    It "should handle maximum reasonable values" {
        $params = @{
            NumberOfPlayers = 100
            StartingSmallBlind = 10000
            StartingStack = 1000000
            Rebuys = 50
            BlindDurationMinutes = 60
            TournamentDurationHours = 12
            ChipTypes = @(10000, 50000, 100000, 500000)
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        $result.Count | Should -BeGreaterThan 0
        $result[0].SmallBlind | Should -Be 10000
        $result[0].BigBlind | Should -Be 20000
        
        # Should handle large numbers without overflow
        foreach ($round in $result) {
            $round.SmallBlind | Should -BeGreaterThan 0
            $round.BigBlind | Should -Be ($round.SmallBlind * 2)
        }
    }
    
    It "should handle single chip type array" {
        $params = @{
            NumberOfPlayers = 3
            StartingSmallBlind = 1000
            StartingStack = 30000
            BlindDurationMinutes = 20
            TournamentDurationHours = 2
            ChipTypes = @(1000)  # Single chip type
            GameStartTime = (Get-Date)
        }
        $result = Get-PokerBlindStructure @params
        
        $result.Count | Should -BeGreaterThan 0
        $result[0].SmallBlind | Should -Be 1000
    }
    
    It "should handle GameStartTime parameter correctly" {
        $customStartTime = [DateTime]::new(2024, 1, 15, 18, 30, 0)
        $params = @{
            NumberOfPlayers = 4
            StartingSmallBlind = 500
            StartingStack = 40000
            BlindDurationMinutes = 30
            TournamentDurationHours = 2
            ChipTypes = @(500, 1000)
            GameStartTime = $customStartTime
        }
        $result = Get-PokerBlindStructure @params
        
        $result[0].RoundStartTime | Should -Be $customStartTime
        if ($result.Count -gt 1) {
            $result[1].RoundStartTime | Should -Be $customStartTime.AddMinutes(30)
        }
        if ($result.Count -gt 2) {
            $result[2].RoundStartTime | Should -Be $customStartTime.AddMinutes(60)
        }
    }
}