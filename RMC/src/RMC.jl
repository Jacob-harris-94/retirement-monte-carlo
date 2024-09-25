module RMC

#####
##### Exports / Imports
#####

export AbstractRateProvider, rate, RateMean, RateHistorical
export AbstractStrategy, Balances, step!, InitialBalanceStrategy, RegularContributionStrategy, SkipRegularContributionStrategy
export update!, run_sim!, test_run, analyze

using StatsBase, Plots

include("historical.jl")

#####
##### Rate Providers
#####

abstract type AbstractRateProvider <: Any end

"""
    rate(arp::AbstractRateProvider)

Interface for AbstractRateProvider.
Returns a single rate as a decimal.
"""
function rate(arp::AbstractRateProvider)
    error("implement this for $(typeof(arp))")
end

struct RateMean <: AbstractRateProvider
    rate::Float64
end
rate(r::RateMean) = r.rate

struct RateHistorical <: AbstractRateProvider
    rates::Vector{Float64}
end
rate(r::RateHistorical) = sample(r.rates)
"""
TODO: update for actual historical rates
"""
const RH = RateHistorical(Float64[0.01, -0.2, +0.3, +0.05, +0.01, -0.05, +0.02, +0.1, +0.1, +0.20])

#####
##### Strategies
#####

abstract type AbstractStrategy <: Any end

"""
    new_balances = step!(as::AbstractStrategy, balances)

Interface for AbstractStrategy.
Returns updated `balances`
"""
function step!(as::AbstractStrategy, balances, year_index)
    error("implement this for $(typeof(as))")
end

mutable struct Balances <: Any
    savings::Float64
    investment::Float64
end
Balances() = Balances(0.0, 0.0)

struct InitialBalanceStrategy <: AbstractStrategy end
function step!(ibs::InitialBalanceStrategy, balances::Balances, _)
    return balances
end

struct RegularContributionStrategy <: AbstractStrategy 
    amount_yearly::Float64
end
function step!(strat::RegularContributionStrategy, balances::Balances, year_index)
    balances.investment += strat.amount_yearly
    return balances
end

struct SkipRegularContributionStrategy <: AbstractStrategy
    amount_yearly::Float64
    years_to_skip::Vector{Int64}
end
function step!(strat::SkipRegularContributionStrategy, balances::Balances, year_index)
    if year_index in strat.years_to_skip
        return balances
    end
    balances.investment += strat.amount_yearly
    return balances
end

#####
##### Simulation running logic
#####

function update!(bals::Balances, savings_rate, investment_rate)
   bals.savings = (one(savings_rate) + savings_rate) * bals.savings
   bals.investment = (one(investment_rate) + investment_rate) * bals.investment
   return nothing
end

function run_sim!(savings_rate_provider, investment_rate_provider, strategy, iterations, balance_init=Balances())
    balances = balance_init
    for ii in 1:iterations
        balances = step!(strategy, balances, ii)
        savings_rate = rate(savings_rate_provider)
        investment_rate = rate(investment_rate_provider)
        update!(balances, savings_rate, investment_rate)
    end
    return balances
end

function test_run(; investment_init, years, yearly_contribution=0.0, years_to_skip=[], num_sims=100_000)
    savings_rp = RateMean(0.0)
    invest_rp = RateHistorical(s_and_p_500_historical)
    strat = nothing
    if yearly_contribution > 0.0
        strat = SkipRegularContributionStrategy(yearly_contribution, years_to_skip)
    else
        strat = InitialBalanceStrategy()
    end
    results = Float64[]
    for ii in 1:num_sims
        bals = Balances(0, investment_init)
        out = run_sim!(savings_rp, invest_rp, strat, years, bals)
        push!(results, out.investment)
    end
    return results
end

function analyze(results)
    results_no_outliers = results[percentile(results, 1) .< results .< percentile(results, 99)] # only for plotting
    hist = fit(Histogram, results_no_outliers, nbins=250)
    plot(hist)
    h_max_plus = Int(ceil(maximum(hist.weights) * 1.2)) # for nicely plotting vertical lines
    pct_5 = percentile(results, 5)
    pct_50 = percentile(results, 50)
    pct_5_formatted_millions = round(pct_5 / 1e6, digits=2)
    pct_50_formatted_millions = round(pct_50 / 1e6, digits=2)
    plot!([(pct_5, 0), (pct_5, h_max_plus)]; linestyle=:dash, lineweight=:thick, color=:red, label="5th percentile (millions) $pct_5_formatted_millions")
    plot!([(pct_50, 0), (pct_50, h_max_plus)]; linestyle=:dash, lineweight=:thick, color=:red, label="50th percentile (millions) $pct_50_formatted_millions")
end 


end # module