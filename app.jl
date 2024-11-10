using Dash
using CSV, DataFrames

external_stylesheets = []
external_scripts = [
    Dict("src"=>"https://cdn.tailwindcss.com"),
    # Dict("src"=>"https://cdn.jsdelivr.net/npm/flowbite@2.5.2/dist/flowbite.min.js")
]
app = dash(external_scripts=external_scripts)

# Load the data
df = CSV.read("Minerals_Database.csv", DataFrame)
df[!," index"] = 1:nrow(df)

visible_columns = ["Name", "Crystal Structure", "Mohs Hardness", "Diaphaneity", "Specific Gravity", "Optical", "Refractive Index", "Dispersion"]

app.layout = html_div(className="container py-5 mx-auto px-4") do
    html_h1("Mineral Similarity Search", className="text-2xl"),
    dcc_graph(),
    html_div(className="flex space-x-4 justify-between mb-2") do
        [
            html_div(className="flex flex-col") do
                [
                    html_label("Entries per page"),
                    dcc_input(
                        id="datatable-page-size",
                        type="number",
                        min=1,
                        max=20,
                        value=10,
                        className="rounded border border-slate-300 hover:border-slate-400 ps-1"
                    )
                ]
            end,
            html_div(className="flex flex-col") do 
                [
                    html_label("Search"),
                    dcc_input(
                        id="datatable-search", 
                        value="", 
                        debounce=false,
                        className="rounded border border-slate-300 hover:border-slate-400 ps-1",
                        placeholder="Mineral name"
                    ) 
                ]
            end,
        ]
    end,
    dash_datatable(
        id="datatable",
        columns=[Dict("name" => c, "id" => c) for c in visible_columns],
        page_current=0,
        page_action="custom",
        row_selectable="multi",
        column_selectable="single",
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
    html_button("Calculate cosine similarity", className="rounded border border-slate-300 p-2 bg-[#65a30d] text-white")
end

# Callback to update the table data based on page, search input, and update page count
callback!(app,
    Output("datatable", "data"),
    Output("datatable", "page_count"),
    Output("datatable", "page_current"),
    Input("datatable", "page_current"),
    Input("datatable", "page_size"),
    Input("datatable-search", "value")
) do page_current, page_size, search
    # Filter rows based on search input, if provided
    filtered_df = if !isempty(search)
        df[occursin.(search, df[!, "Name"]), :]
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
    return Dict.(pairs.(eachrow(paginated_df))), page_count, page_current
end

# Callback for updating page size when changed by the user
callback!(app,
    Output("datatable", "page_size"),
    Input("datatable-page-size", "value")
) do page_size
    return page_size isa Nothing || page_size < 1 ? nothing : page_size
end

# Run the server
run_server(app, "0.0.0.0", debug=true)