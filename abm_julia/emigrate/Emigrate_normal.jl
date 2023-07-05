include("Emigrate_Society.jl")
include("Emigrate_Decision.jl")

module Simulation
    export run_one_episode, main
    using ..Society
    using ..Decision
    using CSV
    using DataFrames
    using Random

    # シミュレーション実行
    function run_one_episode(society, iteration, firstsize, Nmax, life_length, cool_time, old_time, kosodate_time, init_male_prop, go_out_rate, accident_rate, born_rate)
        DataFrame(step = [0], population_size = [firstsize], male_proportion = [init_male_prop]) |> CSV.write("./results/result.csv")

        # 一つの時間軸でシミュレーションを実行
        init_male = choose_init_males(firstsize, init_male_prop)
        initialize_sex(society, init_male)
        initialize_age(society, life_length)
        for step = 1:iteration
            come_in_size = go_out(society, go_out_rate)
            come_in(society, come_in_size, cool_time)
            copulation(society, life_length, cool_time, old_time, kosodate_time, born_rate)
            aging(society)
            death(society, life_length, accident_rate)
            judge_go_out(society, cool_time)
            population_control(society, Nmax)
            global popu_size, male_prop = calculation(society)

            DataFrame(step = [step], population_size = [popu_size], male_proportion = [male_prop]) |> CSV.write("./results/result.csv", append=true)
        end
    end


    # main処理
    # 死亡割合、流産しない割合を変化させて最終個体数の変化を観察
    # 色々なseedでアンサンブル平均を取る
    function main(iteration, firstsize, Nmax, life_length, cool_time, old_time, kosodate_time, init_male_prop, go_out_rate, accident_rate, born_rate, seeds)
        Random.seed!(seeds)
        mkpath("./results")
        society = SocietyType(firstsize)
        run_one_episode(society, iteration, firstsize, Nmax, life_length, cool_time, old_time, kosodate_time, init_male_prop, go_out_rate, accident_rate, born_rate)
    end
end


# 実行部分
using .Simulation

# パラメータの設定
const iteration = 50
const firstsize = 100
const Nmax = 10000
const life_length = 30
const cool_time = 10
const old_time = 0
const kosodate_time = 0
const init_male_prop = 0.5
const go_out_rate = 0.5
const accident_rate = 0.025
const born_rate = 0.3
const seeds = 0

# パラメータをテキストファイルで保存する
mkdir("./results")
open("./results/params.txt", "w") do out
    println(out, "iteration = $(iteration)")
    println(out, "firstsize = $(firstsize)")
    println(out, "Nmax = $(Nmax)")
    println(out, "life_length = $(life_length)")
    println(out, "cooltime = $(cool_time)")
    println(out, "old_time = $(old_time)")
    println(out, "kosodate_time = $(kosodate_time)")
    println(out, "init_male_prop = $(init_male_prop)")
    println(out, "go_out_rate = $(go_out_rate)")
    println(out, "accident_rate = $(accident_rate)")
    println(out, "born_rate = $(born_rate)")
    println(out, "seeds = $(seeds)")
end

@time main(iteration, firstsize, Nmax, life_length, cool_time, old_time, kosodate_time, init_male_prop, go_out_rate, accident_rate, born_rate, seeds)