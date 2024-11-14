using Dash
using CSV, DataFrames
include("Calculate.jl")
using .Calculate


external_stylesheets = ["css/style.css"]
external_scripts = [
    Dict("src"=>"https://cdn.tailwindcss.com"),
    # Dict("src"=>"https://cdn.jsdelivr.net/npm/flowbite@2.5.2/dist/flowbite.min.js")
]
app = dash(external_scripts=external_scripts)

# Load the data
df = CSV.read("Minerals_Database.csv", DataFrame)
df[!,"index"] = 1:nrow(df)

visible_columns = ["Name", "Crystal Structure", "Mohs Hardness", "Diaphaneity", "Specific Gravity", "Optical", "Refractive Index", "Dispersion"]

app.layout = html_div([
    html_div(className="px-10 py-6 mx-auto bg-[#52525b] w-screen", [
        html_h1("Mineral Similarity Search", className="text-2xl font-mono text-white")
    ]),
    html_div(className="container mx-auto flex flex-col space-y-6 my-4", [
        html_div(className="px-8 py-6 rounded rounded-md bg-white", [
        html_h2("Mineral Database", className="text-xl font-bold"),
        html_div(className="flex space-x-4 justify-between mb-2", 
            [
                html_div(className="flex flex-col", [
                        html_label("Entries per page"),
                        dcc_input(
                            id="datatable-page-size",
                            type="number",
                            min=5,
                            max=20,
                            value=10,
                            className="rounded border border-slate-300 hover:border-slate-400 ps-2 rounded-full"
                        )
                ]),
                html_div(className="flex flex-col-reverse", [
                    dcc_input(
                        id="search-database", 
                        value="", 
                        debounce=false,
                        className="rounded border border-slate-300 hover:border-slate-400 ps-2 rounded-full",
                        placeholder="Search mineral"
                    ) 
                ]),
        ]),
        dash_datatable(
            id="datatable-database",
            columns=[Dict("name" => c, "id" => c) for c in visible_columns],
            page_current=0,
            page_action="custom",
            row_selectable="single",
            # column_selectable="single",
            selected_columns=[],
            selected_rows=[],
            style_table=Dict(
                        "minWidth" => "100%",      # Ensures table stretches to full width
                        "overflowX" => "auto"      # Enables horizontal scroll
            ),
            style_cell=Dict(
                "textAlign" => "left",     # Left-align text
                # "minWidth" => "150px",     # Minimum width for columns
                "width" => "150px",        # Width of columns
                "maxWidth" => "300px",     # Max width for larger screens
                "whiteSpace" => "normal",  # Wrap text instead of truncating
            ),
            style_header=Dict(
                "fontWeight" => "bold"     # Bold header text
            ),
            # style_data=Dict("border"=>"1px solid black"),
            # style_header=Dict("border"=>"1px solid black"),
        ),
        ]),
        
        html_div(className="px-8 py-6 rounded rounded-md bg-white", [
            html_h2("Property Similarity Summary", className="text-xl font-bold"),
            
            html_div(className="flex justify-between", [
                html_div(className="flex flex-row mb-2", [
                    dcc_store(id="memory-metric"),
                    html_button("Cosine", id="btn-cosine-metric", className="border-b-4 border-[#2563eb] px-2"),
                    html_button("Jaccard", id="btn-jaccard-metric", className="border-b-4 border-gray px-2"),
                    html_button(),
                ]),
                html_div(className="flex flex-col mb-2",[
                    html_div("Best of"),
                    dcc_input(
                        id="similar_size",
                        type="number",
                        min=5,
                        max=100,
                        value=10,
                        className="rounded border border-slate-300 hover:border-slate-400 ps-2 rounded-full"
                    ),
                ]),
            ]),
            html_div(className="mb-2", [
                html_div(className="flex flex-row", [
                    html_h3("Selected mineral:", className="pe-2 font-bold"), 
                    html_div(id="selected-minerals", className="flex flex-row space-x-2")
                ])
            ]),
            html_div(className="grid md:grid-cols-3", [
                html_div([
                    dash_datatable(
                        id="datatable-property-similarity",
                        columns=[Dict("name" => "Name", "id" => "Name"), Dict("name" => "Similarity", "id" => "Similarity")],
                        style_table=Dict(
                            "minWidth" => "100%",      # Ensures table stretches to full width
                            "overflowX" => "auto"      # Enables horizontal scroll
                        ),
                        style_cell=Dict(
                            "textAlign" => "left",     # Left-align text
                            # "minWidth" => "150px",     # Minimum width for columns
                            "width" => "150px",        # Width of columns
                            "maxWidth" => "300px",     # Max width for larger screens
                            "whiteSpace" => "normal",  # Wrap text instead of truncating
                        ),
                        style_header=Dict(
                            "fontWeight" => "bold"     # Bold header text
                        ),
                    ),
                ]),
                dcc_graph(className="md:col-span-2 min-h-96	")
            ]),
        ])
    ])
])

# Callback to update the table data based on page, search input, and update page count
callback!(app,
    Output("datatable-database", "data"),
    Output("datatable-database", "page_count"),
    Output("datatable-database", "page_current"),
    Output("datatable-database", "selected_rows"),  # Reset selected_columns when search happens
    Input("datatable-database", "page_current"),
    Input("datatable-database", "page_size"),
    Input("search-database", "value")
) do page_current, page_size, search
    # Filter rows based on search input, if provided
    filtered_df = if !isempty(search)
        df[occursin.(lowercase(search), lowercase.(df[!, "Name"])), :]
    else
        df
    end

    # Calculate the new page count based on filtered data
    page_count = ceil(Int, nrow(filtered_df) / page_size)

    # Reset to the first page if a search term changes
    page_current = if page_current * page_size >= nrow(filtered_df)
        0
    else
        page_current
    end

    # Paginate the filtered data
    paginated_df = filtered_df[(page_current*page_size+1):min((page_current+1)*page_size, nrow(filtered_df)), :]

    # Return the updated table data, page count, current page, and reset selected_columns to an empty list
    Dict.(pairs.(eachrow(paginated_df))), page_count, page_current, []  # Reset selected_columns here
end



callback!(app,
    Output("datatable-property-similarity", "data"),
    Output("selected-minerals", "children"),
    Input("datatable-database", "selected_rows"),
    Input("memory-metric", "data"),
    Input("similar_size", "value"),
    State("datatable-database", "data"),
    State("datatable-database", "page_current"),
    State("datatable-database", "page_size"),

) do selected_rows, metric, similar_size, data, page_current, page_size
    if selected_rows == []
        return [Dict("Name" => "-", "Similarity" => "-")], ""
    end 
    selected_rows = map(row -> row + 1, selected_rows)
    selected_indices = map(row -> data[row]["index"], selected_rows)
    
    if metric == "jaccard"
        metric = jaccard_similarity
    else
        metric = cosine_similarity
    end

    selected_minerals = map(row -> begin
        html_div(row, className="border border-slate-500 rounded rounded-md px-2 bg-[#475569] text-white")
        end, df[selected_indices, "Name"]
    )
    similarity_columns = ["Crystal Structure", "Mohs Hardness", "Diaphaneity", "Specific Gravity", "Optical", "Refractive Index", "Dispersion"]

    df_similarity  = find_similar_minerals(df, selected_indices[1], similarity_columns, metric, similar_size)
    Dict.(pairs.(eachrow(df_similarity))), selected_minerals
end

callback!(app,
    Output("btn-cosine-metric", "className"),
    Output("btn-jaccard-metric", "className"),
    Output("memory-metric", "data"),
    Input("btn-cosine-metric", "n_clicks"),
    Input("btn-jaccard-metric", "n_clicks"),
) do _, _
    ctx = callback_context()
    if isempty(ctx.triggered)
        return "border-b-4 border-[#2563eb] px-2 active-similarity-button", "border-b-4 border-gray px-2", "cosine"
    end

    triggered_id = ctx.triggered[1][1][1:end-9]  
    if triggered_id == "btn-cosine-metric"
        "border-b-4 border-[#2563eb] px-2 active-similarity-button", "border-b-4 border-gray px-2", "cosine"
    elseif triggered_id == "btn-jaccard-metric"
        "border-b-4 border-gray px-2", "border-b-4 border-[#2563eb] px-2 active-similarity-button", "jaccard"
    else
        # Default state
        "border-b-4 border-[#2563eb] px-2 active-similarity-button", "border-b-4 border-gray px-2", "cosine"
    end
end

# Callback for updating page size when changed by the user
callback!(app,
    Output("datatable-database", "page_size"),
    Input("datatable-page-size", "value")
) do page_size
    page_size isa Nothing || page_size < 1 ? nothing : page_size
end

# Run the server
run_server(app, "0.0.0.0", debug=true)