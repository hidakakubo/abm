module Decision
    export choose_init_males, initialize_sex, initialize_age, copulation, aging, death, population_control, calculation
    using StatsBase

    
    # 初期人口から初期オス比の分を、オスのエージェントとしてランダムサンプリングする
    function choose_init_males(firstsize, init_male_prop)
        init_male = StatsBase.self_avoid_sample!(1:firstsize, [i for i = 1:Int(firstsize * init_male_prop)])

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


    # 集団内の交尾
    function copulation(society, cool_time, born_rate)
        # 生殖可能なオス個体のインデックス
        male_copu_id = [i for i = 1:society.population if (society.sex[i] == "m") && (society.age[i] > cool_time)]

        # 生殖可能なメス個体のインデックス
        female_copu_id = [i for i = 1:society.population if (society.sex[i] == "f") && (society.age[i] > cool_time)]

        # 流産しない個体を選ぶ
        chosen_female_id = [female_copu_id[i] for i = eachindex(female_copu_id) if rand() <= born_rate]

        # メスが子供を産む
        if length(male_copu_id) != 0
            for i = 1:length(chosen_female_id)          # eachindexをつかうべき？？？？？？？？？？？？？？？
                push!(society.sex, sample(["m", "f"]))  # 子供の性別は "m":"f" = 1:1
                push!(society.age, 0)                   # 子供の年齢は0歳
                society.population += 1
            end
        end
    end


    # 歳をとる
    function aging(society)
        society.age = broadcast(+, society.age, 1)  # ブロードキャストで足し算
    end


    # 個体が死亡する
    function death(society, life_length, accident_rate)
        # 死亡する個体のインデックスを記録
        death_list = []
        for i = 1:society.population
            if society.age[i] >= life_length
                push!(death_list, i)         # 寿命で死亡する個体のindex
            elseif rand() <= ((1/life_length) + accident_rate)
                push!(death_list, i)         # 一定の死亡率で死亡する個体のindex
            end
        end

        # 個体を取り除く
        deleteat!(society.age, death_list)
        deleteat!(society.sex, death_list)
        society.population -= length(death_list)
    end


    # 個体数抑制
    function population_control(society, Nmax)
        while society.population > Nmax
            index = rand(1:society.population)
            deleteat!(society.age, index)
            deleteat!(society.sex, index)
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