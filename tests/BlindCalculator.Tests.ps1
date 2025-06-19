BeforeAll {
    Import-Module "$PSScriptRoot/../src/modules/BlindCalculator/BlindCalculator.psm1"
}

Describe "Get-RoundedpBlind" {
    It "should return the correct rounded small blind" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 1500
        $result | Should -Be 2000
    }

    It "should handle exact multiples correctly" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 2000
        $result | Should -Be 2000
    }

    It "should round up small values correctly" {
        $result = Get-RoundedpBlind -SmallBlind 100 -ProposedSmallBlind 150
        $result | Should -Be 200
    }

    It "should handle single increment rounding" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 1001
        $result | Should -Be 2000
    }

    It "should handle large values correctly" {
        $result = Get-RoundedpBlind -SmallBlind 50000 -ProposedSmallBlind 75000
        $result | Should -Be 100000
    }

    It "should handle minimum rounding case" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 1
        $result | Should -Be 1000
    }

    It "should handle equal values" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 1000
        $result | Should -Be 1000
    }

    It "should handle zero proposed blind" {
        $result = Get-RoundedpBlind -SmallBlind 1000 -ProposedSmallBlind 0
        $result | Should -Be 0
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

    Context "Parameter Validation" {
        It "should accept minimum valid NumberOfPlayers" {
            $params = @{
                NumberOfPlayers = 2
                StartingSmallBlind = 1000
                StartingStack = 100000
            }
            { Get-PokerBlindStructure @params } | Should -Not -Throw
        }

        It "should accept minimum valid StartingSmallBlind" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1
                StartingStack = 100000
            }
            { Get-PokerBlindStructure @params } | Should -Not -Throw
        }

        It "should accept minimum valid StartingStack" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 1
            }
            { Get-PokerBlindStructure @params } | Should -Not -Throw
        }

        It "should accept minimum valid BlindDurationMinutes" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                BlindDurationMinutes = 10
            }
            { Get-PokerBlindStructure @params } | Should -Not -Throw
        }

        It "should accept BlindDurationMinutes that are multiples of 5" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                BlindDurationMinutes = 15
            }
            { Get-PokerBlindStructure @params } | Should -Not -Throw
        }

        It "should accept minimum valid TournamentDurationHours" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                TournamentDurationHours = 1
            }
            { Get-PokerBlindStructure @params } | Should -Not -Throw
        }

        It "should accept zero rebuys" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                Rebuys = 0
            }
            { Get-PokerBlindStructure @params } | Should -Not -Throw
        }
    }

    Context "Mathematical Calculations" {
        It "should calculate correct number of rounds based on duration" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                BlindDurationMinutes = 20
                TournamentDurationHours = 2
            }
            $result = Get-PokerBlindStructure @params
            # 2 hours = 120 minutes, 120/20 = 6 rounds + 1 = 7 rounds
            $result.Count | Should -Be 7
        }

        It "should have progressive blind increases" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                BlindDurationMinutes = 20
                TournamentDurationHours = 3
            }
            $result = Get-PokerBlindStructure @params
            
            # First round should be starting blind
            $result[0].SmallBlind | Should -Be 1000
            
            # Final round should be higher than first round
            if ($result.Count -gt 1) {
                $result[-1].SmallBlind | Should -BeGreaterThan $result[0].SmallBlind
            }
        }

        It "should maintain 2:1 ratio between big blind and small blind" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
            }
            $result = Get-PokerBlindStructure @params
            
            foreach ($round in $result) {
                $round.BigBlind | Should -Be ($round.SmallBlind * 2)
            }
        }

        It "should calculate total chips correctly with rebuys" {
            # This test verifies the logic indirectly by ensuring that with more rebuys,
            # the final blinds are higher (since total chips in play affects final blind calculation)
            $paramsNoRebuys = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                Rebuys = 0
                TournamentDurationHours = 3
            }
            $paramsWithRebuys = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                Rebuys = 3
                TournamentDurationHours = 3
            }
            
            $resultNoRebuys = Get-PokerBlindStructure @paramsNoRebuys
            $resultWithRebuys = Get-PokerBlindStructure @paramsWithRebuys
            
            # With more chips in play (rebuys), final blinds should be higher
            $finalBlindNoRebuys = $resultNoRebuys[-1].SmallBlind
            $finalBlindWithRebuys = $resultWithRebuys[-1].SmallBlind
            $finalBlindWithRebuys | Should -BeGreaterThan $finalBlindNoRebuys
        }
    }

    Context "Time Calculations" {
        It "should set correct round start times" {
            $gameStart = Get-Date -Year 2024 -Month 1 -Day 1 -Hour 20 -Minute 0 -Second 0
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                BlindDurationMinutes = 30
                TournamentDurationHours = 2
                GameStartTime = $gameStart
            }
            $result = Get-PokerBlindStructure @params
            
            # First round should start at game start time
            $result[0].RoundStartTime | Should -Be $gameStart
            
            # Second round should start 30 minutes later
            if ($result.Count -gt 1) {
                $expectedSecondRoundStart = $gameStart.AddMinutes(30)
                $result[1].RoundStartTime | Should -Be $expectedSecondRoundStart
            }
            
            # Third round should start 60 minutes after game start
            if ($result.Count -gt 2) {
                $expectedThirdRoundStart = $gameStart.AddMinutes(60)
                $result[2].RoundStartTime | Should -Be $expectedThirdRoundStart
            }
        }
    }

    Context "Default Values" {
        It "should use default values when not specified" {
            $result = Get-PokerBlindStructure
            $result.Count | Should -BeGreaterThan 0
            $result[0].SmallBlind | Should -Be 1000  # Default StartingSmallBlind
            $result[0].BigBlind | Should -Be 2000
        }

        It "should handle ante parameter" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                Ante = $true
            }
            $result = Get-PokerBlindStructure @params
            $result.Count | Should -BeGreaterThan 0
            # Just verify it doesn't break when ante is enabled
        }
    }

    Context "Edge Cases" {
        It "should handle minimum tournament configuration" {
            $params = @{
                NumberOfPlayers = 2
                StartingSmallBlind = 1
                StartingStack = 1
                BlindDurationMinutes = 10
                TournamentDurationHours = 1
            }
            $result = Get-PokerBlindStructure @params
            $result.Count | Should -BeGreaterThan 0
            $result[0].SmallBlind | Should -Be 1
            $result[0].BigBlind | Should -Be 2
        }

        It "should handle large tournament configuration" {
            $params = @{
                NumberOfPlayers = 100
                StartingSmallBlind = 25000
                StartingStack = 1000000
                BlindDurationMinutes = 15
                TournamentDurationHours = 8
            }
            $result = Get-PokerBlindStructure @params
            $result.Count | Should -BeGreaterThan 0
            $result[0].SmallBlind | Should -Be 25000
            $result[0].BigBlind | Should -Be 50000
        }

        It "should handle very short tournament" {
            $params = @{
                NumberOfPlayers = 5
                StartingSmallBlind = 1000
                StartingStack = 100000
                BlindDurationMinutes = 10
                TournamentDurationHours = 1
            }
            $result = Get-PokerBlindStructure @params
            # Should have 6 rounds + 1 = 7 total rounds (60 minutes / 10 minutes per round)
            $result.Count | Should -Be 7
        }
    }

    Context "Data Structure Validation" {
        It "should return objects with correct properties" {
            $result = Get-PokerBlindStructure
            foreach ($round in $result) {
                $round.RoundNumber | Should -BeOfType [int]
                $round.SmallBlind | Should -Not -BeNullOrEmpty
                $round.BigBlind | Should -Not -BeNullOrEmpty
                $round.RoundStartTime | Should -BeOfType [datetime]
                
                $round.RoundNumber | Should -BeGreaterThan 0
                $round.SmallBlind | Should -BeGreaterThan 0
                $round.BigBlind | Should -BeGreaterThan 0
            }
        }

        It "should have sequential round numbers" {
            $result = Get-PokerBlindStructure
            for ($i = 0; $i -lt $result.Count; $i++) {
                $result[$i].RoundNumber | Should -Be ($i + 1)
            }
        }
    }

    Context "Error Handling" {
        It "should throw error for invalid NumberOfPlayers (too low)" {
            { Get-PokerBlindStructure -NumberOfPlayers 1 } | Should -Throw
        }

        It "should throw error for invalid StartingSmallBlind (zero)" {
            { Get-PokerBlindStructure -StartingSmallBlind 0 } | Should -Throw
        }

        It "should throw error for invalid StartingStack (zero)" {
            { Get-PokerBlindStructure -StartingStack 0 } | Should -Throw
        }

        It "should throw error for invalid BlindDurationMinutes (not multiple of 5)" {
            { Get-PokerBlindStructure -BlindDurationMinutes 13 } | Should -Throw
        }

        It "should throw error for invalid BlindDurationMinutes (too low)" {
            { Get-PokerBlindStructure -BlindDurationMinutes 5 } | Should -Throw
        }

        It "should throw error for invalid TournamentDurationHours (zero)" {
            { Get-PokerBlindStructure -TournamentDurationHours 0 } | Should -Throw
        }

        It "should throw error for negative rebuys" {
            { Get-PokerBlindStructure -Rebuys -1 } | Should -Throw
        }
    }

    Context "Consistency Tests" {
        It "should produce consistent results for same parameters" {
            $params = @{
                NumberOfPlayers = 6
                StartingSmallBlind = 2000
                StartingStack = 200000
                BlindDurationMinutes = 15
                TournamentDurationHours = 4
                GameStartTime = (Get-Date -Year 2024 -Month 1 -Day 1 -Hour 18 -Minute 0 -Second 0)
            }
            
            $result1 = Get-PokerBlindStructure @params
            $result2 = Get-PokerBlindStructure @params
            
            $result1.Count | Should -Be $result2.Count
            
            for ($i = 0; $i -lt $result1.Count; $i++) {
                $result1[$i].SmallBlind | Should -Be $result2[$i].SmallBlind
                $result1[$i].BigBlind | Should -Be $result2[$i].BigBlind
                $result1[$i].RoundNumber | Should -Be $result2[$i].RoundNumber
                $result1[$i].RoundStartTime | Should -Be $result2[$i].RoundStartTime
            }
        }
    }
}