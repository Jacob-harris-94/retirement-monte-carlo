# Retirement Savings and Investing Monte Carlo Simulator

## Use Cases
Note: these are intended, but not all currently supported.
1. > What portfolio value is generated with at least `X` confidence after `Y` years, given an investment strategy `I`?
2. > How many years are required with at least `X` confidence to achieve `V` portfolio value, given an investment strategy `I`?
3. > What investment strategy `I` will achive value `V` or better at year `Y` with confidence `X`?
4. > How many years does `P` portfolio last, with at least `X` confidence, given a drawdown strategy `D`?

## Setup
assuming you have julia installed

- in `RMC`: `julia --project=.`
- `]instantiate`
- `]test`

then run interactively from the REPL, for example...

## Examples

These currently only address Use Case 1.

### High level
```julia
result_balances = test_run(invest_rp=RateHistorical(s_and_p_generator(pessimism=1)), investment_init=10_000.0, years=30, strat=TakeGainsOffTableStrategy(20_000.0, [], 1e6))
analyze(result_balances, "30 years, 20k cont, 1e6 threshold, p1") # generates histogram with 5, 50 percentile marks
```

### Low level
```julia
INIT_BALANCE = 10_000.0
YEARS = 25
savings_rp = RateMean(0.0)
invest_rp = RateHistorical(RMC.s_and_p_500_historical)
for ii in 1:100_000
    bals = Balances(0, INIT_BALANCE)
    out = run_sim!(savings_rp, invest_rp, InitialBalanceStrategy(), YEARS, bals)
    push!(results, out.investment)
end
percentile(results, 05)
```