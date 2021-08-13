function dummycoding(df)
    T = Union{Number,Missing}
    tf = mapreduce(vcat, names(df)) do name
        col = df[!, name]
        vals = unique(col)
        if !(eltype(col) <: T)
            @. name => ByRow(isequal(vals)) .=> Symbol(name * "_", vals)
        else
            Pair[]
        end
    end
    removed = filter(names(df)) do name
        col = df[!, name]
        !(eltype(col) <: T)
    end
    select(transform(df, tf...), Not(removed))
end
