module Calculate
export find_similar_minerals, cosine_similarity, jaccard_similarity

using LinearAlgebra, DataFrames

function cosine_similarity(x, y)
    norm_x = norm(x)
    norm_y = norm(y)
    if norm_x == 0 || norm_y == 0
        return 0.0  # No similarity if either vector has no magnitude
    end
    return dot(x, y) / (norm_x * norm_y)
end

function jaccard_similarity(x_row, y_row)
    x_vec = Vector(x_row)  # Explicitly convert DataFrameRow to Vector
    y_vec = Vector(y_row)  # Explicitly convert DataFrameRow to Vector

    # Element-wise operations are performed on vectors
    intersection = sum(min.(x_vec, y_vec))
    union = sum(max.(x_vec, y_vec))

    if union == 0
        return 0.0  # Avoid division by zero, implies no overlap
    end

    return intersection / union
end

function find_similar_minerals(df, target_index, columns, metric::Function, n)
    if target_index == Nothing || target_index < 1 || target_index > nrow(df)
        return DataFrame()  # Return an empty DataFrame if the target_index is invalid
    end

    numeric_df = df[:, columns]
    target = numeric_df[target_index, :] 

    # Compute similarity with each row using the specified metric
    similarities = [metric(target, row) for row in eachrow(numeric_df)]

    # Get indices of the top-n most similar rows, excluding the target itself
    sorted_indices = sortperm(similarities, rev=true)
    sorted_indices = filter(i -> i != target_index, sorted_indices)[1:n]

    # Create the result DataFrame with names, similarity scores, and selected columns
    result_df = DataFrame(
        Name = df[sorted_indices, :Name],  # Adjust column name as necessary
        Similarity = similarities[sorted_indices]
    )

    # Optionally, include additional columns for context
    for col in columns
        result_df[!, col] = df[sorted_indices, col]
    end

    return result_df
end

end