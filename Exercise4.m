clear; clc;
close all;
warning off;

%% Exercise 4: Economic Batch Model and Wagner-Whitin Algorithm

% Define the sales points (PVs)
% PV: 458 461 467 470 476 483

[PVData, pvNames, productNames] = LoadPVData("Tables.xlsx");

%% Batch Model - Definition of economic lot size and delivery period

% Assumed distances of PVs from the warehouse (20 km for all PVs)
distances = 20 * ones(size(pvNames, 1), 1);

% Annual demand
% Initialize DemandMatrix: 6x3 matrix for 3 products and 6 sellers
DemandMatrix = zeros(6, 3);

% Loop over each PV dataset
for i = 1:length(pvNames)
    currentPVData = PVData.(pvNames{i});
    % Sum the demand for each product and store in DemandMatrix
    for col = 1:size(currentPVData, 2)
        DemandMatrix(i, col) = sum(currentPVData(:, col));
    end
end

% Assumed cost of product P = 2€
% Annual storage cost per liter of product cm = 3% * 2€
storageCost = 0.06;

% Transportation cost: 50 cents/km * round trip distance
orderCost = 0.5 * distances * 2;

% Tanker Max Capacity (39 kl)
maxCapacity = 39000;

% Limiting to one trip per supply request

% Goal : minimize the total cost which is a function of the economic orer
% quantity Q

% Q: Quantity of product ordered at the beginning of each cycle

% The total cost is the sum of the ordering cost and Storage cost:
% TC (Q) = ( D/Q ) * f_0 + ( Q/2 ) * h * unitPrice
% the TC is the sum of :
%                       1) the the number of order per period * fixed ordering cost [Ordering Cost]
%                       2) the avarage inventory level * holding cost per unit per period * unitPrice [Storage Cost]

% Derivative of TC (Q) respect to Q and setting to zero to find the optimal order quantity
% TC'(Q) = (h * unitPrice )/2 - ( f_0 * D ) / Q^2
% Solution Qo = sqrt ( (2 * f_0 * D) / (h * unitPrice))

% Calculate Qo which is the optimal quantity (economic lot)
optimalQuantity = zeros(6, 3);

% Loop over each PV and product type to calculate optimal quantity
for pv = 1:6
    for col = 1:3
        optimalQuantity(pv, col) = ceil(sqrt(2 * orderCost(pv) * DemandMatrix(pv, col) / storageCost));
        optimalQuantity(pv, col) = min(optimalQuantity(pv, col), maxCapacity);
    end
end

% Optimal supply period for each product and PV
optimalSupplyPeriod = floor((optimalQuantity ./ DemandMatrix) * size(currentPVData, 1));

%% Wagner-Whitin Algorithm

% Goal: To find the optimal schedule for ordering that minimizes total cost, considering variable demand over multiple periods.

% Problem properties:
% Zero Inventory Ordering (ZIO) Property: Orders are placed exactly when the inventory level reaches zero.
% Exact Requirement Policy: Each order quantity matches the exact demand for future periods.

% Formulation: The problem is formulated as finding the minimum cost path in an acyclic graph,
% where:
% - Nodes represent time periods.
% - Edges (t_i, t_j) represent costs satisfying a period from i to (j-1) included.

% Solution (y*, q*, I*) can be found using dynamic programming:
% y_t : Boolean variable equal to 1 if an order is placed at time t, otherwise 0.
% q_t : Batch quantity to be ordered in interval t.
% I_t: Inventory level at the end of interval t.
% These variables form vectors of dimension T, where T is the planning horizon.

%%% Graph
% Daily storage cost
dailyStorageCost = storageCost / 364;

% Loop over each PV dataset
for i = 1:length(pvNames)
    currentPVData = PVData.(pvNames{i});
    % For each product of each PV
    for j = 1:size(currentPVData, 2)
        demandData = currentPVData(:, j);
        % Create a supply graph from the demand data
        supplyGraph = graphFromData(demandData, orderCost(i), dailyStorageCost, maxCapacity);
        % Find the shortest path and its cost in the supply graph
        [route, cost] = shortestpath(supplyGraph, 1, size(supplyGraph.Nodes, 1));
        % Store the optimal costs and routes
        optimalCosts.(pvNames{i}).(productNames(j)).cost = cost;
        optimalCosts.(pvNames{i}).(productNames(j)).route = route;
    end
end

% Stock Level Plot
figure;
clf
data.T = 100;  % Assuming a fixed period for visualization
data.costLevel = zeros(length(pvNames), length(productNames), data.T);
data.demand = cell(length(pvNames), length(productNames));
data.stock = cell(length(pvNames), length(productNames));
colors = lines(length(productNames));  % Color map for different products

for pvIdx = 1:length(pvNames)
    currentPVData = PVData.(pvNames{pvIdx});
    for prodIdx = 1:length(productNames)
        data.demand{pvIdx, prodIdx} = currentPVData(:, prodIdx);
        data.demand{pvIdx, prodIdx} = [0; data.demand{pvIdx, prodIdx}];
        data.stock{pvIdx, prodIdx} = zeros(data.T, 1);

        demand = data.demand{pvIdx, prodIdx};
        route = optimalCosts.(pvNames{pvIdx}).(productNames{prodIdx}).route;
        idx = 1;
        for t = 1:data.T
            if t > 1
                data.costLevel(pvIdx, prodIdx, t) = data.costLevel(pvIdx, prodIdx, t - 1);
                data.stock{pvIdx, prodIdx}(t) = data.stock{pvIdx, prodIdx}(t - 1) - demand(t);
            end

            if t == route(idx) && idx < length(route)
                data.costLevel(pvIdx, prodIdx, t) = data.costLevel(pvIdx, prodIdx, t) + ...
                    edgeCost(route(idx), route(idx + 1), demand, orderCost(pvIdx), dailyStorageCost, maxCapacity);
                batchSize = sum(demand(t + 1:route(idx + 1)));
                data.stock{pvIdx, prodIdx}(t) = data.stock{pvIdx, prodIdx}(t) + batchSize;
                idx = idx + 1;
            end
        end
    end
end

for pvIdx = 1:length(pvNames)
    subplot(3, 2, pvIdx)
    title("PV #" + pvNames(pvIdx));
    hold on
    grid on
    ylabel("Stock Level");
    maxstock = 0;
    for prodIdx = 1:length(productNames)
        stock = data.stock{pvIdx, prodIdx};
        if stock(data.T) > maxstock
            maxstock = stock(data.T);
        end
        plot(0:data.T-1, stock, "-", "Color", colors(prodIdx, :));
    end
    xlim([0 data.T-1]);
    xlabel("Time");
    legend(productNames);
end
sgtitle("Stock Levels for each StorePoint");

% Cost Plot
figure;
clf
barData = zeros(length(pvNames), length(productNames));
for pvIdx = 1:length(pvNames)
    for prodIdx = 1:length(productNames)
        barData(pvIdx, prodIdx) = optimalCosts.(pvNames{pvIdx}).(productNames{prodIdx}).cost;
    end
end

bar(barData);
legend(productNames);
xlabel("StorePoints");
ylabel("Total cost");
title("Costs for each StorePoint");
grid on

%%% Function declarations

% Function to create a graph from supplied data
function [supplyGraph] = graphFromData(suppliedData, orderCost, dailyStorageCost, maxCapacity)
    % Number of nodes
    numNodes = length(suppliedData) + 1;
    % Adjacency matrix
    adjacencyMatrix = zeros(numNodes, numNodes);
    % Loop over pairs of nodes to calculate edge costs
    for i = 1:numNodes-1
        for j = i+1:numNodes       
            adjacencyMatrix(i, j) = edgeCost(i, j, suppliedData, orderCost, dailyStorageCost, maxCapacity);
        end
    end
    % Create graph from adjacency matrix
    supplyGraph = digraph(adjacencyMatrix);
end

% Function to calculate the cost of an edge in the graph
function [cost] = edgeCost(from, to, suppliedData, orderCost, dailyStorageCost, maxCapacity)
    % Initial cost
    batchSize = sum(suppliedData(from:to-1));
    if batchSize > maxCapacity
        cost = Inf; % Exceeding Capacity
    else
        cost = orderCost; 
        count = 0;
        % Add storage costs for nodes along the edge
        for i = from:to-1
            cost = cost + count * suppliedData(i) * dailyStorageCost;
            count = count + 1;
        end
    end
end
