# Prediction_Planning_VRP

This project focuses on inventory management and routing optimization for a set of point of sales (PV) locations. It includes several exercises that address different aspects of the problem, from data analysis to advanced optimization techniques.

## Project Structure

The project consists of the following main components:

1. `LoadPVData.m`: Script for loading and sanitizing data from 'Tables.xlsx'
2. `Exercise1.m`: Implementation of Exercise 1 (Moving Averages and Control Charts)
3. `Exercise2.m`: Implementation of Exercise 2 (Deseasonalization)
4. `Exercise3.m`: Implementation of Exercise 3 (Continuous Inventory Management)
5. `Exercise4.m`: Implementation of Exercise 4 (Data Analysis and Wagner-Within Algorithm)
6. `Exercise5_v1.m`: First version of Exercise 5 (single-stop routing)
7. `Exercise5_v2.m`: Second version of Exercise 5 (multi-stop routing)

## Data

The project uses data from the 'Tables.xlsx' file, which contains information about product sales and point of sales locations. The `LoadPVData.m` script is responsible for loading and preprocessing this data, ensuring it's ready for use in the exercises.

## Exercises

### Exercise 1: Moving Averages and Control Charts

This exercise focuses on calculating moving averages and creating control charts:
- Calculate moving averages of order 2, 3, and 4 for the historical series described in the table.
- Compute corresponding MAD and MSE values.
- Plot the tracking signal and control chart for each of the calculated averages.

### Exercise 2: Deseasonalization

This exercise involves the "deseasonalization" of a given historical series:
- Apply deseasonalization techniques to a two-year dataset.
- Analyze seasonal patterns and trends in the data.

### Exercise 3: Continuous Inventory Management

This exercise deals with determining the optimal management policy using a continuous model:
- Annual demand: 400 units
- Order cost: 100
- Annual maintenance cost: 12% of unit value
- Unit price: 200
- Compare results with those obtained using the total cost technique in the case where demand in the current year follows the pattern indicated in the provided table.

### Exercise 4: Data Analysis and Wagner-Within Algorithm

This exercise involves working with the 'Tables.xlsx' file and focuses on the following points of sale (PV): 458, 461, 467, 470, 476, 483. For each PV and each product:

- Eliminate data inconsistencies (e.g., negative sales)
- Define characteristic data - size, delivery period - assuming economic lot with storage cost equal to the cost of capital immobilization (e.g., 3% of the value in storage) and delivery cost via 39kl tanker at 0.5€/km.
- Using 2015 data identically projected onto 2017 as predicted deterministic demand data, define the optimal order sequence for each PV (Wagner-Within algorithm)

### Exercise 5: Inventory/Routing Problem

Exercise 5 is implemented in two versions:

1. `Exercise5_v1.m`: Single-stop routing
   - The vehicle must return to the depot after visiting each point of sale.

2. `Exercise5_v2.m`: Multi-stop routing
   - The vehicle can visit multiple points of sale before returning to the depot.

Both versions address an inventory/routing problem for delivering three products (B95, B98, dieseltech) to six point of sales locations. The problem is formulated as a mathematical programming problem with the following characteristics:

- Points of sale are arranged in a regular hexagon with 60km sides on a Euclidean plane.
- The depot is located at the center of the hexagon.
- Only dedicated deliveries (full drop) are allowed.
- A single vehicle with a 21kl capacity, divided into two compartments (10kl and 11kl), is available.
- 2015 data is projected onto 2017 as deterministic demand forecast.
- Planning horizon is between 7 and 14 days.
- The objective is to minimize total costs (transportation + inventory).

## Usage

1. Ensure MATLAB is installed on your system.
2. Place the 'Tables.xlsx' file in the project directory.
3. Run the `LoadPVData.m` script to preprocess the data.
4. Execute the desired exercise scripts (`Exercise1.m`, `Exercise2.m`, etc.) to perform specific analyses or optimizations.

## Notes

- Each script contains commented sections with theoretical background and explanations for each part of the implementation.
- The solving time for Exercise 5 is limited to 4-5 minutes maximum.
- In Exercise 5, one compartment of the vehicle must always be filled and delivered entirely to a single point of sale.

## Authors

- [Martin Martuccio](https://github.com/Martin-Martuccio) - Project Author
- [Samuele Pellegrini](https://github.com/PSamK) - Project Author
- [Daniel Brendo Flores Mendoza](https://github.com/FMDani) - Project Author

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
