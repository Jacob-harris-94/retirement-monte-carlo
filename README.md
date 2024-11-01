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


### Use Case 1: run a simulation of only market exposure for 30 years
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

### Use Case 2: run a simulation of only market exposure, until a target value is reached
```julia
s2 = SimulationFixedValue(
    RateConst(0.03),
    RateHistorical(s_and_p_generator(; pessimism=1)),
    TargetRatioStrategy(1_000.0, [], fill(1.0, 30)),
    Balances(0, 10_000),
    100_000
    100,
    100_000
    )
analyze_years(run_fixed_value(s2))
```

### Use Case 3: What investment strategy `I` will achive value `V` or better at year `Y` with confidence `X`?
Currently unimplemented. This is really hard, because
- It's unclear what the space of strategies is
- Any optimization for maximizing final value will just result in investing as much as possible as early as possible, unless a tradeoff is specified.
    - Writing a cost function for an optimization requires specifying preferences on consumption now and security later with mathematical precision.
    - Maybe an optimization for highest smoothed consumption is possible? that would still need explicit constraints on money available to invest or consume.

### Use Case 4: How many years does `P` portfolio last, with at least `X` confidence, given a drawdown strategy `D`?
```julia
s4 = Simulation(
    RateConst(0.03),
    RateHistorical(s_and_p_generator(; pessimism=1)),
    MultipleStrategy([TargetRatioStrategy(0.0, [], fill(0.5, 100)), InvestmentDrawdownStrategy(4e3)]), # yearly rebalance to 50/50 high yeild savings and withdrwing 10k
    Balances(0, 100e3),
    50,
    100_000
)
s4_result = run_fixed_years(s4)
analyze(s4_result)
println(percentilerank(sum.(s4_result), 100e3)) # see what percentage end lower than the initial balance
```