
module Calculate
export find_similar_minerals

using LinearAlgebra, DataFrames


function cosine_similarity(x, y)
    norm_x = norm(x)
    norm_y = norm(y)
    # Check for zero vectors to avoid division by zero
    if norm_x == 0 || norm_y == 0
        return 0.0  # No similarity if either vector has no magnitude
    end
    return dot(x, y) / (norm_x * norm_y)
end


function find_similar_minerals(df, target_index, columns, n=5)
    if target_index == Nothing || target_index < 1 || target_index > nrow(df)
        return DataFrame()  # Return an empty DataFrame if the target_index is invalid
    end

    numeric_df = df[:, columns]
    target = numeric_df[target_index, columns] 

    # Compute cosine similarity with each row
    similarities = [cosine_similarity(target, row) for row in eachrow(numeric_df)]

    # Get indices of the top-n most similar rows, excluding the target itself
    sorted_indices = sortperm(similarities, rev=true)
    sorted_indices = filter(i -> i != target_index, sorted_indices)[1:n]

    # Create the result DataFrame with names, similarity scores, and selected columns
    result_df = DataFrame(
        Name = df[sorted_indices, :Name],  # Adjust column name as necessary
        Similarity = similarities[sorted_indices]
    )

    return result_df
end

end