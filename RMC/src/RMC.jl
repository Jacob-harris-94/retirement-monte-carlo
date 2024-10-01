module RMC

#####
##### Exports / Imports
#####

export AbstractRateProvider, rate, RateMean, RateHistorical, s_and_p_generator
export AbstractStrategy, Balances, step!, InitialBalanceStrategy, RegularContributionStrategy, SkipRegularContributionStrategy, TakeGainsOffTableStrategy, TargetRatioStrategy, sigmoid
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

#####
##### Strategies
#####

abstract type AbstractStrategy <: Any end

"""
    new_balances = step!(as::AbstractStrategy, balances)

Interface for AbstractStrategy.
Returns updated `balances`, takes current `balances`.
"""
function step!(as::AbstractStrategy, balances, year_index)
    error("implement this for $(typeof(as))")
end

mutable struct Balances <: Any
    savings::Float64
    investment::Float64
end
Balances() = Balances(0.0, 0.0)
function Base.sum(b::Balances)
    return b.investment + b.savings
end

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

struct TakeGainsOffTableStrategy <: AbstractStrategy
    amount_yearly::Float64
    years_to_skip::Vector{Int64}
    threshold::Float64
end
function step!(strat::TakeGainsOffTableStrategy, balances::Balances, year_index)
    if year_index in strat.years_to_skip
        return balances
    end
    excess = balances.investment - strat.threshold
    if excess > 0
        balances.investment -= excess
        balances.savings += excess
    end
    balances.investment += strat.amount_yearly
    return balances
end

struct TargetRatioStrategy <: AbstractStrategy
    amount_yearly::Float64
    years_to_skip::Vector{Int64}
    investment_fraction_per_year::Vector{Float64} # same length as number of years
end
function step!(strat::TargetRatioStrategy, balances::Balances, year_index)
    if year_index in strat.years_to_skip
        return balances
    end
    balances.investment += strat.amount_yearly # going to be rebalanced immediately anyway
    total_balance = sum(balances)
    target_ratio = strat.investment_fraction_per_year[year_index]
    actual_ratio = balances.investment / total_balance
    adjustment_fraction = target_ratio - actual_ratio
    adjustment_amount = adjustment_fraction * total_balance
    balances.investment += adjustment_amount
    balances.savings -= adjustment_amount
    return balances
end
function sigmoid(num_years::Int, start=-5, stop=5)
    x = range(start, stop, length=num_years)
    e = Base.MathConstants.e
    y = 1 .- (1 ./ (1 .+ e.^(-x))) # TODO: clean up?
    return y
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
    # TODO: add a drawdown phase
    # TODO: add inflation compensation
    return balances
end

# TODO: better way to view and compare multiple runs, e.g. violin plots?
# approx 5 year treasury
# yearly_contribution=0.0, years_to_skip=[], threshold=0.0,
function test_run(; savings_rp=RateMean(0.03), invest_rp=RateHistorical(s_and_p_generator(pessimism=5)), strat, investment_init, years, num_sims=100_000)
    results = Balances[]
    for ii in 1:num_sims
        bals = Balances(0, investment_init)
        out = run_sim!(savings_rp, invest_rp, strat, years, bals)
        push!(results, out)
    end
    return results
end

function analyze(result_balances, plot_title="")
    results = sum.(result_balances)/1e6 # combine savings and investment
    results_no_outliers = results[percentile(results, 1) .< results .< percentile(results, 99)] # only for plotting
    hist = fit(Histogram, results_no_outliers, nbins=250)
    plot(hist, title=plot_title)
    h_max_plus = Int(ceil(maximum(hist.weights) * 1.05)) # for nicely plotting vertical lines
    pct_5 = percentile(results, 5)
    pct_50 = percentile(results, 50)
    pct_5_formatted_millions = round(pct_5, digits=2)
    pct_50_formatted_millions = round(pct_50, digits=2)
    plot!([(pct_5, 0), (pct_5, h_max_plus)]; linestyle=:dash, lineweight=:thick, color=:red, label="5th percentile (millions) $pct_5_formatted_millions")
    plot!([(pct_50, 0), (pct_50, h_max_plus)]; linestyle=:dash, lineweight=:thick, color=:red, label="50th percentile (millions) $pct_50_formatted_millions")
end 

end # module

# TODO: does it make sense that TakeGainsOffTable seems to dominate the other Strategies? I would expect TargetRatioStrategy to do better with the right ratios... but I might be wrong.