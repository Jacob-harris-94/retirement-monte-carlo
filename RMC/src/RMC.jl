module RMC

#####
##### Exports / Imports
#####

export AbstractRateProvider, rate, RateMean, RateHistorical
export AbstractStrategy, Balances, step!, InitialBalanceStrategy
export update!, run_sim!

using StatsBase

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

struct InitialBalanceStrategy <: AbstractStrategy end

mutable struct Balances <: Any
    savings::Float64
    investment::Float64
end
Balances() = Balances(0.0, 0.0)

function step!(ibs::InitialBalanceStrategy, balances::Balances, _)
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

end # module