using Dash
using CSV, DataFrames

external_stylesheets = ["css/style.css"]
external_scripts = [
    Dict("src"=>"https://cdn.tailwindcss.com"),
    # Dict("src"=>"https://cdn.jsdelivr.net/npm/flowbite@2.5.2/dist/flowbite.min.js")
]
app = dash(external_scripts=external_scripts)

# Load the data
df = CSV.read("Minerals_Database.csv", DataFrame)
df[!," index"] = 1:nrow(df)

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
                        id="datatable-search", 
                        value="", 
                        debounce=false,
                        className="rounded border border-slate-300 hover:border-slate-400 ps-2 rounded-full",
                        placeholder="Search mineral"
                    ) 
                ]),
        ]),
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
        html_button("Reset", className="rounded border border-slate-300 p-2 bg-[#475569] text-white px-6"),
        html_button("Calculate", className="rounded border border-slate-300 p-2 bg-[#2563eb] text-white px-6"),
        ]),
        
        html_div(className="px-8 py-6 rounded rounded-md bg-white", [
            html_h2("Similarity Summary", className="text-xl font-bold"),
            html_div(className="flex flex-row mb-6", [
                html_button("Cosine", className="border-b-4 border-[#2563eb] px-2"),
                html_button("Jaccard", className="border-b-4 border-gray px-2"),
                html_button(),
            ]),
            html_div(className="mb-2", [
                html_div(id="selected-minerals", className="flex flex-row", [
                    html_h3("Selected minerals:", className="pe-2 font-bold"), 

                    html_div("Mineral 1", className="rounded-md border border-black px-2")])
                ]),
            html_div(className="grid md:grid-cols-3", [
                html_div([
                    html_div("Top 5 Minerals"),
                    html_table(className="table-auto w-full text-left", [
                        html_thead([
                            html_th("Mineral Name"),
                            html_th("Score")
                        ])
                        html_tbody([
                            html_tr([
                                html_td("Placeholder"),
                                html_td("90%")
                            ]),
                            html_tr([
                                html_td("Placeholder"),
                                html_td("90%")
                            ]),
                            html_tr([
                                html_td("Placeholder"),
                                html_td("90%")
                            ]),
                            html_tr([
                                html_td("Placeholder"),
                                html_td("90%")
                            ]),
                            html_tr([
                                html_td("Placeholder"),
                                html_td("90%")
                            ]),
                            
                        ])
                    ]),
                ]),
                html_div(className="md:col-span-2", [
                        html_div("Similarity scores"),
                        dcc_graph()
                ]),
            ]),
        ])
    ])
])

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