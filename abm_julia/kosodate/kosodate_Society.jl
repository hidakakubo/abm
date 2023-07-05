module Society
    export SocietyType

    mutable struct SocietyType
        population::Int              # エージェントの初期数
        sex::Vector{AbstractString}  # エージェントの性別
        age::Vector{Int}             # エージェントの年齢
        kosodate_time::Vector{Int}   # 子供を産んでから次の子供を産めるようになる時間

        # コンストラクタの定義
        SocietyType(firstsize) = new(
            firstsize,
            ["m" for i = 1:firstsize],  # とりあえず最初は全部オスにしとく
            [0 for i = 1:firstsize],    # とりあえず最初は全部0歳にしとく
            [0 for i = 1:firstsize]     # とりあえず最初は全部0
        )
    end
end