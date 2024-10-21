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

### run a simulation of only market exposure for 30 years
```julia
s1 = Simulation(
    RateConst(0.03),
    RateHistorical(s_and_p_generator(; pessimism=1)),
    TargetRatioStrategy(0.0, [], fill(1.0, 30)),
    Balances(0, 10_000),
    30,
    100_000
    )
analyze(run_fixed_years(s1))
```
