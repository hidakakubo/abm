module Decision
    export choose_init_males, initialize_sex, initialize_age, initialize_kosodate_time, go_out, come_in, copulation, aging, death, judge_go_out, population_control, calculation
    using StatsBase

    
    # 初期人口から初期オス比の分を、オスのエージェントとしてランダムサンプリングする
    function choose_init_males(firstsize, init_male_prop)
        init_male_size = Int(firstsize * init_male_prop)
        init_male = ifelse(init_male_size != 0, StatsBase.self_avoid_sample!(1:firstsize, [i for i = 1:init_male_size]), [])

        return init_male
    end


    # 全エージェントの性別を初期化
    function initialize_sex(society, init_male)
        for id = 1:society.population
            society.sex[id] = ifelse(id in init_male, "m", "f")  # ifelse(条件式, Trueの時の処理, Falseの時の処理)
        end
    end


    # 全エージェントの年齢を初期化
    function initialize_age(society, life_length)
        society.age = [rand(0:(life_length - 1)) for i = 1:society.population]
    end


    #################################################
    # 全エージェントのkosodate_timeを初期化
    # 性成熟したメスはkosodate_timeがランダムに与えられる
    function initialize_kosodate_time(society, init_male, cool_time, kosodate_time)
        init_female = [i for i = 1:society.population]
        deleteat!(init_female, init_male)
        for id = 1:society.population
            society.kosodate_time[id] = ifelse((id in init_female) && (society.age[id] > cool_time), rand(0:(kosodate_time - 1)), 0)
        end
    end
    #################################################


    # 個体の移出
    function go_out(society, go_out_rate)
        # 移出する個体のインデックス
        out_list = [i for i = 1:society.population if (society.emigrate[i]) && (rand() <= go_out_rate)]
        
        # 移出させる
        deleteat!(society.age, out_list)
        deleteat!(society.sex, out_list)
        deleteat!(society.kosodate_time, out_list)
        deleteat!(society.emigrate, out_list)
        society.population -= length(out_list)

        return length(out_list)
    end


    # 個体の移入
    function come_in(society, come_in_size, cool_time)
        # とりあえず移入数＝移出数
        for i = 1:come_in_size
            push!(society.sex, "f")               # 移入する個体は全てメス
            push!(society.age, (cool_time + 1))   # 性成熟した個体
            push!(society.kosodate_time, 0)       # 子供を産んでいない
            push!(society.emigrate, false)        # もう移出しない
            society.population += 1
        end
    end


    # 集団内の交尾
    function copulation(society, life_length, cool_time, old_time, kosodate_time, born_rate)
        # 生殖可能なオス個体のインデックス
        male_copu_id = [i for i = 1:society.population if (society.sex[i] == "m") && (cool_time < society.age[i] < (life_length - old_time))]

        # 生殖可能なメス個体のインデックス
        female_copu_id = [i for i = 1:society.population if (society.sex[i] == "f") && (cool_time < society.age[i] < (life_length - old_time)) && (society.kosodate_time[i] <= 0)]

        # 流産しない個体を選ぶ
        chosen_female_id = [female_copu_id[i] for i = eachindex(female_copu_id) if rand() <= born_rate]

        # メスが子供を産む
        if length(male_copu_id) != 0
            for i = eachindex(chosen_female_id)
                push!(society.sex, sample(["m", "f"]))  # 子供の性別は "m":"f" = 1:1
                push!(society.age, 0)                   # 子供の年齢は0歳
                push!(society.kosodate_time, 0)         # 子供のkosodate_timeは0
                push!(society.emigrate, false)          # 子供は移出しない
                society.population += 1
            end
        end

        # 子供を産んだメスは子育てに入る
        # 子供を産んだら移出しない
        for i = chosen_female_id
            society.kosodate_time[i] = kosodate_time
            society.emigrate[i] = false
        end
    end


    # 歳をとる
    function aging(society)
        society.age = broadcast(+, society.age, 1)  # ブロードキャストで足し算
        for id = 1:society.population
            society.kosodate_time[id] = ifelse(society.kosodate_time[id] > 0, society.kosodate_time[id] - 1, 0)
        end
    end


    # 個体が死亡する
    function death(society, life_length)
        # 死亡する個体のインデックスを記録
        death_list = []
        for i = 1:society.population
            if society.age[i] >= life_length
                push!(death_list, i)         # 寿命で死亡する個体のindex
            elseif rand() <= (1/life_length)
                push!(death_list, i)         # 一定の死亡率で死亡する個体のindex
            end
        end

        # 個体を取り除く
        deleteat!(society.age, death_list)
        deleteat!(society.sex, death_list)
        deleteat!(society.kosodate_time, death_list)
        deleteat!(society.emigrate, death_list)
        society.population -= length(death_list)
    end


    # 移出するかしないか決定
    function judge_go_out(society, cool_time)
        # 成熟したメス個体は移出する
        for i = 1:society.population
            if (society.sex[i] == "f") && (society.age[i] == (cool_time + 1))
                society.emigrate[i] = true
            end
        end
    end


    # 個体数抑制
    function population_control(society, Nmax)
        while society.population > Nmax
            index = rand(1:society.population)
            deleteat!(society.age, index)
            deleteat!(society.sex, index)
            deleteat!(society.kosodate_time, index)
            deleteat!(society.emigrate, index)
            society.population -= 1
        end
    end


    # 個体数、性比を記録する
    function calculation(society)
        population_size = society.population
        male_size = length([1 for sex = society.sex if sex == "m"])
        male_proportion = ifelse(population_size != 0, male_size/population_size, 0)

        return population_size, male_proportion
    end
end