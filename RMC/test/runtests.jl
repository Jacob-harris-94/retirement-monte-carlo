using Test, StatsBase
using RMC

@testset "RateProviders" begin
    # TODO: set seed
    rh = RateHistorical(s_and_p_generator())
    rh_mean = mean(rate(rh) for _ in 1:100000)
    @test 0.01 < rh_mean < 0.14
   
    TEST_RATE = 0.06
    rm_mean = mean(rate(RateConst(TEST_RATE)) for _ in 1:100000)
    @test isapprox(TEST_RATE, rm_mean)
end

@testset "Strategies" begin
    @testset "basic strats" begin
        strat = InitialBalanceStrategy()
        ONE_HUNDRED = 100.0
        YEAR = 1
        test_balances = Balances(ONE_HUNDRED, ONE_HUNDRED)
        result_balances = step!(strat, test_balances, YEAR)
        @test result_balances == test_balances
        # testing regular contributions
        ONE_HUNDRED = 100.0
        strat = RegularContributionStrategy(ONE_HUNDRED)
        test_balances = Balances(ONE_HUNDRED, ONE_HUNDRED)
        SAVINGS_RATE = 0.0 
        INVEST_RATE = 0.0
        savings_rp = RateConst(SAVINGS_RATE)
        invest_rp = RateConst(INVEST_RATE)
        YEARS = 50
        test_sim = Simulation(savings_rp, invest_rp, strat, test_balances, YEARS, 1)
        end_balances = first(run_fixed_years(test_sim))
        @test end_balances.investment == (YEARS + 1) * ONE_HUNDRED
    end
    @testset "skip years" begin
    # testing skip + regular contributions
        ONE_HUNDRED = 100.0
        YEARS = 50
        SKIP_YEARS = Int64.(1:10)
        strat = SkipRegularContributionStrategy(ONE_HUNDRED, SKIP_YEARS)
        test_balances = Balances(ONE_HUNDRED, ONE_HUNDRED)
        SAVINGS_RATE = 0.0 
        INVEST_RATE = 0.0
        savings_rp = RateConst(SAVINGS_RATE)
        invest_rp = RateConst(INVEST_RATE)
        test_sim = Simulation(savings_rp, invest_rp, strat, test_balances, YEARS, 1)
        end_balances_1  = first(run_fixed_years(test_sim))
        @test end_balances_1.savings == ONE_HUNDRED # not touched
        @test end_balances_1.investment == (YEARS + 1 - length(SKIP_YEARS)) * ONE_HUNDRED
        # same but with interest
        ONE_HUNDRED = 100.0
        YEARS = 50
        SKIP_YEARS_EARLY = Int64.(1:10) # skip first 10
        SKIP_YEARS_LATE = Int64.(41:50) # skip last 10
        strat_early = SkipRegularContributionStrategy(ONE_HUNDRED, SKIP_YEARS_EARLY)
        strat_late = SkipRegularContributionStrategy(ONE_HUNDRED, SKIP_YEARS_LATE)
        SAVINGS_RATE = 0.0 
        INVEST_RATE = 0.05
        savings_rp = RateConst(SAVINGS_RATE)
        invest_rp = RateConst(INVEST_RATE)
        balances_early = Balances(ONE_HUNDRED, ONE_HUNDRED)
        test_sim_early = Simulation(savings_rp, invest_rp, strat_early, balances_early, YEARS, 1)
        end_balances_early  = first(run_fixed_years(test_sim_early))
        balances_late = Balances(ONE_HUNDRED, ONE_HUNDRED)
        test_sim_late = Simulation(savings_rp, invest_rp, strat_late, balances_late, YEARS, 1)
        end_balances_late = first(run_fixed_years(test_sim_late))
        @info end_balances_early.investment
        @info end_balances_late.investment
        @test end_balances_late.investment > 1.1 * end_balances_early.investment # just guessing it will be this different
    end
    @testset "TakeGainsOffTable" begin
        THRESHOLD = 1_000_000.0
        strat = TakeGainsOffTableStrategy(20_000.0, Int64[], THRESHOLD)
        test_balances = Balances(0, 0)
        SAVINGS_RATE = 0.0 # just cash
        INVEST_RATE = 0.30 # ridiculous yearly rate
        YEARS = 50
        savings_rp = RateConst(SAVINGS_RATE)
        invest_rp = RateConst(INVEST_RATE)
        test_sim = Simulation(savings_rp, invest_rp, strat, test_balances, YEARS, 1)
        end_balances  = first(run_fixed_years(test_sim))
        @test isapprox(end_balances.investment, THRESHOLD, rtol=0.1+INVEST_RATE)
        @test end_balances.savings > 0
    end
    @testset "TargetRato" begin
        # test that a single iteration works
        strat = TargetRatioStrategy(0.0, [], [0.25])
        rebalanced = step!(strat, Balances(100.0, 0.0), 1)
        @test (rebalanced.investment == 25.0) && (rebalanced.savings == 75.0)
        # test it works over multiple iterations
        YEARS = 25
        strat = TargetRatioStrategy(0.0, [], sigmoid(YEARS))
        bals = Balances(100.0, 0.0)
        results = []
        for yi in 1:YEARS
            # no contribution, just rebalancing
            bals = step!(strat, bals, yi)
            push!(results, deepcopy(bals))
        end
        totals = sum.(results)
        ratios = map(b -> b.investment / sum(b), results)
        @test all(totals .≈  100.0)
        @test all(ratios .≈ sigmoid(YEARS))
    end
end

@testset "pessimism" begin
    p0 = s_and_p_generator(; pessimism=0)
    p1 = s_and_p_generator(; pessimism=1)
    # 1 2 3 4
    # 1 1 2 3
    @test sort(p0)[1:end-1] == sort(p1)[2:end] # same except lowest, highest
end

@testset "sim math" begin
    # testing the compound interest math
    strat = InitialBalanceStrategy()
    ONE = 1.0
    test_balances = Balances(ONE, ONE)
    SAVINGS_RATE = 0.01
    INVEST_RATE = 0.06
    savings_rp = RateConst(SAVINGS_RATE)
    invest_rp = RateConst(INVEST_RATE)
    YEARS = 50
    test_sim = Simulation(savings_rp, invest_rp, strat, test_balances, YEARS, 1)
    end_balances = first(run_fixed_years(test_sim))
    @test end_balances isa Balances
    @test end_balances.savings ≈ (1 + SAVINGS_RATE)^YEARS
    @test end_balances.investment ≈ (1 + INVEST_RATE)^YEARS
end

