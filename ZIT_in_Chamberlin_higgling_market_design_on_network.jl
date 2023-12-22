# Package loading
using Random
using Distributions
using DataFrames
using CSV

# Single simulation of Chamberlin billateral higgling
# n - numbers of buyers and sellers, in total 2 * n traders
# p - probability of edge exsistance between a buyer and a seller
function simV(n, p)
    S = rand(n)
    B = rand(n)
    if p > 0.1
        E = Tuple{Int,Int}[(i, j) for i in 1:n, j in 1:n if rand() < p]
    else
        m = Int(rand(Binomial(n*n, p)))
        x = Set{Tuple{Int,Int}}()
        while length(x) < m
            push!(x, (rand(1:n), rand(1:n)))
        end
        E = collect(Tuple{Int,Int}, x)
    end
    BS = [B[e[2]] - S[e[1]] for e in E]
    E2 = E[sortperm(BS, rev=true)]
    shuffle!(E)

    su = falses(n)
    bu = falses(n)
    V = 0.0
    for e in E
        i, j = e
        if !(su[i] || bu[j])
            if S[i] <= B[j]
                V += B[j] - S[i]
                su[i] = true
                bu[j] = true
            end
        end
    end

    su2 = falses(n)
    bu2 = falses(n)
    V2 = 0.0
    for e in E2
        i, j = e
        if !(su2[i] || bu2[j])
            if S[i] <= B[j]
                V2 += B[j] - S[i]
                su2[i] = true
                bu2[j] = true
            end
        end
    end
    (eff=V/n/0.25, particip=count(su)/n, greed_eff=V2/n/0.25, greed_particip=count(su2)/n, avg_degree=length(E)/n)
    # eff - market efficiency
    # particip - participation rate of traders
    # greed_eff - market efficiency given greedy matching of traders
    # greed_particip - participation rate given the greeding matching of traders
    # avg_degree - average degree, i.e. number of acquinted traders
end

# Single run
@time simV(1000, 0.01)

# a wrapper function to rerun the single simulation N=1000 times
function run_sims(n, p, N = 1000)
    df = DataFrame(simV(n,p) for i in 1:N)
    (
        n = n,
        p = p,
        eff = mean(df.eff),
        particip = mean(df.particip),
        greed_eff=mean(df.greed_eff),
        greed_particip=mean(df.greed_particip),
        avg_degree=mean(df.avg_degree)
    )
end

# Example run
run_sims(1000,0.05)
# Simulation experiments running 
Random.seed!(0)
df = DataFrame(run_sims(n,p) 
    for p in (1, 0.75, 0.5, 0.25, 0.01, 0.075, 0.05, 0.025, 0.01, 0.0075,0.005,0.0025, 0.001),
        n in (10,100,1000))

CSV.write("results.csv", df, delim=",")


print(df)  