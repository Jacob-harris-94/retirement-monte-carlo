module RMC

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

"""
TODO: update for actual historical rates
"""
struct RateHistorical <: AbstractRateProvider
    rates = Float64[0.01, -0.20, 0.30, 0.15, -0.05, 0.08, 0.06, 0.05]
end
rate(r::RateHistorical) = sample(r.rates)

#####
##### Strategies
#####

abstract type AbstractStrategy <: Any end

"""
    new_balances = step!(as::AbstractStrategy, balances)

Interface for AbstractStrategy.
Returns updated `balances`
"""
function step!(as::AbstractStrategy, balances)
    error("implement this for $(typeof(as))")
end

struct Balances
    savings::Float64
    investment::Float64
end
Balances() = Balances(0, 0)

function update!(bals::Balances, savings_rate, investment_rate)
   bals.savings = (one(savings_rate) + savings_rate) * bals.savings
   bals.investment = (one(investment_rate) + investment_rate) * bals.investment
end

function run_sim(savings_rate_provider, investment_rate_provider, strategy, iterations, balance_init=Balances())
    balances = balance_init
    for ii in 1:iterations
        balances = step!(strategy, balances)
        savings_rate = rate(savings_rate_provider)
        investment_rate = rate(investment_rate_provider)
        update!(balances, savings_rate, investment_rate)
    end
    return balances
end

end # module