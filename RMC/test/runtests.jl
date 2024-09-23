using Test, StatsBase
using RMC

@testset "RateProviders" begin
    rh = RMC.RH
    rh_mean = mean(rate(rh) for _ in 1:100000)
    @test 0.01 < rh_mean < 0.09
   
    TEST_RATE = 0.06
    rm_mean = mean(rate(RateMean(TEST_RATE)) for _ in 1:100000)
    @test isapprox(TEST_RATE, rm_mean)
end

@testset "Strategies" begin
    strat = InitialBalanceStrategy()
    ONE_HUNDRED = 100.0
    YEAR = 1
    test_balances = Balances(ONE_HUNDRED, ONE_HUNDRED)
    result_balances = step!(strat, test_balances, YEAR)
    @test result_balances == test_balances
end

@testset "sim math" begin
    strat = InitialBalanceStrategy()
    ONE = 1.0
    test_balances = Balances(ONE, ONE)
    SAVINGS_RATE = 0.01
    INVEST_RATE = 0.06
    savings_rp = RateMean(SAVINGS_RATE)
    invest_rp = RateMean(INVEST_RATE)
    YEARS = 50
    end_balances = run_sim!(savings_rp, invest_rp, strat, YEARS, test_balances)
    @test end_balances isa Balances
    @test end_balances.savings ≈ (1 + SAVINGS_RATE)^YEARS
    @test end_balances.investment ≈ (1 + INVEST_RATE)^YEARS
end