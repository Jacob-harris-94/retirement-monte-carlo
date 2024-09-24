# Retirement Savings and Investing Monte Carlo Simulator

### Setup
assuming you have julia installed

- in `RMC`: `julia --project=.`
- `]instantiate`
- `]test`

then run interactively from the REPL, for example...

### Examples

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