using Random

# https://www.slickcharts.com/sp500/returns

const s_and_p_500_historical = [21.13, 26.29, -18.11, 28.71, 18.40, 31.49, -4.38, 21.83, 11.96, 1.38, 13.69, 32.39, 16.00, 2.11, 15.06, 26.46, -37.00, 5.49, 15.79, 4.91, 10.88, 28.68, -22.10, -11.89, -9.10, 21.04, 28.58, 33.36, 22.96, 37.58, 1.32, 10.08, 7.62, 30.47, -3.10, 31.69, 16.61, 5.25, 18.67, 31.73, 6.27, 22.56, 21.55, -4.91, 32.42, 18.44, 6.56, -7.18, 23.84, 37.20, -26.47, -14.66, 18.98, 14.31, 4.01, -8.50, 11.06, 23.98, -10.06, 12.45, 16.48, 22.80, -8.73, 26.89, 0.47, 11.96, 43.36, -10.78, 6.56, 31.56, 52.62, -0.99, 18.37, 24.02, 31.71, 18.79, 5.50, 5.71, -8.07, 36.44, 19.75, 25.90, 20.34, -11.59 -9.78, -0.41, 31.12, -35.03, 33.92, 47.67, -1.44, 53.99, -8.19, -43.34, -24.90, -8.42, 43.61, 37.49, 11.62] ./ 100

"""
    s_and_p_generator(; pessimism=0)

Returns a sequence to sample from based on the `s_and_p_500_historical` data.
Setting `pessimism=p` replaces `p` number of best yearly returns with worst yearly returns.
Use with caution.
"""
function s_and_p_generator(sequence=s_and_p_500_historical; pessimism=0)
    if pessimism == 0
        return sequence
    end
    sorted = sort(sequence)
    n_worst = sorted[1:pessimism]
    n_best = sorted[end-pessimism:end]
    filter!(e -> !(e in n_best), sorted)
    append!(sorted, n_worst)
    return shuffle(sorted)
end