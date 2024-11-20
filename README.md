# Mineral Similarity Search

This project provides a visual interface to compare the similarity between minerals. It is built using Julia and the Dash library, and offers an interactive dashboard for exploring mineral data and performing similarity analyses.

## Features

This application includes the following features:

- A mineral database table that allows users to browse and query mineral properties.
- A method to calculate the most similar minerals using one of four metrics:
  - Ruzicka (weighted Jaccard)
  - Cosine Similarity
  - Manhattan Distance
  - Euclidean Distance
- A radar chart to visualize the property similarities of the compared minerals.
- A comparison table to visualize the similarity between selected minerals.

## Database

This project uses a comprehensive mineral dataset, which is available on Kaggle.  
[Comprehensive Database of Minerals](https://www.kaggle.com/datasets/vinven7/comprehensive-database-of-minerals/data)

## Getting Started

### Prerequisites

Ensure the following are installed before running the application:

- Julia programming language
- Required Julia packages:
  1. Dash
	2. CSV
	3. DataFrames
	4. PlotlyJS

### Running the Application
1. Start the application by running the following command in Julia:
```
Julia App.jl
```
2.	Open your web browser and navigate to http://localhost:8050 to access the dashboard.
