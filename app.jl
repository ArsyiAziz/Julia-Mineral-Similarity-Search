using Dash
using CSV, DataFrames, PlotlyJS
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


PROPERTY_COLUMNS = ["Crystal Structure", "Mohs Hardness", "Diaphaneity", "Specific Gravity", "Optical", "Refractive Index", "Dispersion"]
ELEMENT_COLUMNS = [
    "Hydrogen", "Helium", "Lithium", "Beryllium", "Boron", "Carbon", "Nitrogen", "Oxygen", "Fluorine", "Neon",
    "Sodium", "Magnesium", "Aluminium", "Silicon", "Phosphorus", "Sulfur", "Chlorine", "Argon", "Potassium", "Calcium",
    "Scandium", "Titanium", "Vanadium", "Chromium", "Manganese", "Iron", "Cobalt", "Nickel", "Copper", "Zinc",
    "Gallium", "Germanium", "Arsenic", "Selenium", "Bromine", "Krypton", "Rubidium", "Strontium", "Yttrium", "Zirconium",
    "Niobium", "Molybdenum", "Technetium", "Ruthenium", "Rhodium", "Palladium", "Silver", "Cadmium", "Indium", "Tin",
    "Antimony", "Tellurium", "Iodine", "Xenon", "Cesium", "Barium", "Lanthanum", "Cerium", "Praseodymium", "Neodymium",
    "Promethium", "Samarium", "Europium", "Gadolinium", "Terbium", "Dysprosium", "Holmium", "Erbium", "Thulium", "Ytterbium",
    "Lutetium", "Hafnium", "Tantalum", "Tungsten", "Rhenium", "Osmium", "Iridium", "Platinum", "Gold", "Mercury",
    "Thallium", "Lead", "Bismuth", "Polonium", "Astatine", "Radon", "Francium", "Radium", "Actinium", "Thorium",
    "Protactinium", "Uranium", "Neptunium", "Plutonium", "Americium", "Curium", "Berkelium", "Californium", "Einsteinium",
    "Fermium", "Mendelevium", "Nobelium", "Lawrencium", "Rutherfordium", "Dubnium", "Seaborgium", "Bohrium", "Hassium",
    "Meitnerium", "Darmstadtium", "Roentgenium", "Copernicium", "Nihonium", "Flerovium", "Moscovium", "Livermorium",
    "Tennessine", "Oganesson"
]

VISIBLE_COLUMNS = vcat(["Name"], PROPERTY_COLUMNS)



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
            columns=[Dict("name" => c, "id" => c) for c in VISIBLE_COLUMNS],
            page_current=0,
            page_action="custom",
            row_selectable="single",
            # column_selectable="single",
            selected_columns=[],
            cell_selectable=false,
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
            html_h2("Similarity Summary", className="text-xl font-bold"),
            html_div(className="grid grid-cols-1 divide-y", [
                html_div([
                    html_div(className="flex justify-between mb-4", [
                        html_div(className="flex flex-row mb-2", [
                            dcc_store(id="memory-metric"),
                            html_button("Ruzicka", id="btn-ruzicka-metric", className="border-b-4 border-[#2563eb] px-2"),
                            html_button("Cosine", id="btn-cosine-metric", className="border-b-4 border-gray px-2"),
                            html_button("Manhattan", id="btn-manhattan-metric", className="border-b-4 border-gray px-2"),
                            html_button("Euclidean", id="btn-euclidean-metric", className="border-b-4 border-gray px-2"),
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
                                columns=[Dict("name" => "Name", "id" => "Name"), Dict("name" => "Similarity (%)", "id" => "Similarity")],
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
                                cell_selectable=false,
                                row_selectable="single",
                                selected_rows=[]
                            ),
                        ]),
                        dcc_graph(
                            id="graph-properties", 
                            className="md:col-span-2 min-h-96",
                            
                        )
                    ]),
                ]),
                html_div(className="pt-4", [
                    html_h3("Composition", className="text-xl font-bold"),
                    dash_datatable(
                        id="datatable-composition",
                        cell_selectable=false,
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
                        columns=vcat([Dict("name" => "Mineral Name", "id" => "Name")], [Dict("name" => c, "id" => c) for c in ELEMENT_COLUMNS])
                    )
                ])
            ])
            
        ])
    ]),
    html_footer(className="px-10 py-6 mx-auto mt-8 bg-[#52525b] w-screen", [
        html_p("CSCI 6221 - Julia Group", className="text-xl font-mono text-white")
    ]),
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


function get_datatable_row_index(data, row)
    data[row]["index"][1]
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
        return [], html_div("No selected mineral", className="border border-white rounded rounded-md px-2 bg-red-500 text-white")
    end 

    selected_index = get_datatable_row_index(data, selected_rows[1] + 1)
   

    if metric == "manhattan"
        metric = manhattan_distance
    elseif metric == "cosine"
        metric = cosine_similarity
    elseif metric == "euclidean"
        metric = euclidean_distance
    else
        metric = ruzicka_similarity
    end

    selected_mineral = html_div(df[selected_index, "Name"], className="border border-slate-500 rounded rounded-md px-2 bg-[#475569] text-white")


    df_similarity  = find_similar_minerals(df, selected_index, PROPERTY_COLUMNS, metric, similar_size)
    Dict.(pairs.(eachrow(df_similarity))), selected_mineral
end

function update_metric_buttons(triggered_id)
    # Define default styles for buttons
    default_style = "border-b-4 border-gray px-2"
    active_style = "border-b-4 border-[#2563eb] px-2 active-similarity-button"

    # Initialize styles with default values
    styles = [default_style for _ in 1:4]

    # Define the metric names in the same order as the buttons
    metrics = ["cosine", "ruzicka", "manhattan", "euclidean"]

    # Determine which button was pressed and update styles and metric accordingly
    index = findfirst(isequal(triggered_id), ["btn-$(metric)-metric" for metric in metrics])
    if index !== nothing
        styles[index] = active_style
        return (styles..., metrics[index])
    else
        # Return default state when no button is matched
        return (active_style, default_style, default_style, default_style, "cosine")
    end
end


# Set up the callback with multiple outputs and inputs
callback!(app,
    Output("btn-cosine-metric", "className"),
    Output("btn-ruzicka-metric", "className"),
    Output("btn-manhattan-metric", "className"),
    Output("btn-euclidean-metric", "className"),
    Output("memory-metric", "data"),
    Input("btn-cosine-metric", "n_clicks"),
    Input("btn-ruzicka-metric", "n_clicks"),
    Input("btn-manhattan-metric", "n_clicks"),
    Input("btn-euclidean-metric", "n_clicks")
) do _, _, _, _
    ctx = callback_context()
    
    # Check if any button was triggered
    if isempty(ctx.triggered)
        # Default state if no button has been pressed
        return ("border-b-4 border-gray px-2",
                "border-b-4 border-[#2563eb] px-2 active-similarity-button",
                "border-b-4 border-gray px-2",
                "border-b-4 border-gray px-2",
                "ruzicka")
    end

    # Extract the ID of the triggered button and adjust styles accordingly
    triggered_id = ctx.triggered[1][1][1:end-9]
    update_metric_buttons(triggered_id)
end


# Set up the callback with multiple outputs and inputs
callback!(app,
    Output("graph-properties", "figure"),
    Input("datatable-database", "selected_rows"),
    Input("datatable-property-similarity", "selected_rows"),
    State("datatable-database", "data"),
    State("datatable-property-similarity", "data"),
) do database_selected_rows, property_similarity_selected_rows, database_data, property_similarity_data
    if database_selected_rows == [] || property_similarity_selected_rows == []
        return plot(scatterpolar(r=[0, 0, 0, 0, 0, 0, 0], theta=vcat(PROPERTY_COLUMNS, PROPERTY_COLUMNS[1]) ))
    end

    current_element_index = get_datatable_row_index(database_data, database_selected_rows[1] + 1)
    similar_element_index = get_datatable_row_index(property_similarity_data, property_similarity_selected_rows[1] + 1)
    
    a = Vector(df[current_element_index, PROPERTY_COLUMNS])
    b = Vector(df[similar_element_index, PROPERTY_COLUMNS])


    # Modified element_similarities calculation
    element_similarities = [max(abs(a[i]), abs(b[i])) != 0 ? 
                            1 - abs(a[i] - b[i]) / (max(abs(a[i]), abs(b[i]))) : 
                            1 for i in 1:length(a)]
                            
    return plot(scatterpolar(
        r=vcat(element_similarities, element_similarities[1]),
        theta=vcat(PROPERTY_COLUMNS, PROPERTY_COLUMNS[1]),
        fill="tonext",
        connectgaps=true,
        name=""
        # labels=Dict("x" => df[current_element_index, "Name"], "y" => df[similar_element_index, "Name"])
    ))
end

# Set up the callback with multiple outputs and inputs
callback!(app,
    Output("datatable-property-similarity", "selected_rows"),
    Input("datatable-property-similarity", "data"),
) do _
    return []
end

callback!(app,
    Output("datatable-composition", "data"),
    Input("datatable-database", "selected_rows"),
    State("datatable-database", "data"),

) do database_selected_rows, database_data
    if database_selected_rows == []
        return []
    end
    selected_index = get_datatable_row_index(database_data, database_selected_rows[1] + 1)
    selected_row = df[selected_index, :]
    
    Dict.(pairs.(eachrow(selected_row))) 
end




callback!(app,
    Output("datatable-property-similarity", "columns"),  # Add this to update the columns
    Input("memory-metric", "data"),
) do metric
    similarity_columns = [Dict("name" => "Name", "id" => "Name"), Dict("name" => "Similarity (%)", "id" => "Similarity")]
    distance_columns = [Dict("name" => "Name", "id" => "Name"), Dict("name" => "Distance", "id" => "Similarity")]
    metric ∈ ["cosine", "ruzicka"] ?  similarity_columns : distance_columns
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