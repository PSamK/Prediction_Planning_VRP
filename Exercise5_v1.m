clear; clc;
close all;
warning off;

%% Exercise 5: VRP Problem (Version Depot-PV-Depot)

% PV: 458 461 467 470 476 483
[PVData, pvNames, productNames] = LoadPVData("Tables.xlsx");

% Create an optimization problem with a minimization objective
prob = optimproblem('ObjectiveSense', 'min');

% Define the number of nodes (PVs), days, compartments, and products
numNodes = length(pvNames);  % Number of PVs (Points of Sale)
numDays = 14;  % From 7 to 14 days
numCompartments = 2;  % Number of compartments in the vehicle
numProducts = 3;  % Number of products

% Define parameters for compartment capacities, transport cost, distance, and a large constant BigM
compartmentCapacity1 = 10000; % 10 kL for the first compartment
compartmentCapacity2 = 11000; % 11 kL for the second compartment
transportCostPerKm = 0.5; % euros per kilometer
distanceToDepot = 60; % distance from the depot to all PVs in km
BigM = 10000; % Large constant for the Big-M method

% Define the inventory cost per liter per day
inventoryCostPerLiterPerDay = 0.06 / 364; % €/(L*day)

% Define the initial state of the inventory at each PV for each product
initialInventory = ones(numNodes, numProducts) * 150;
initialInventory(4, 2) = 0; % PV 470 has no demand for B98

% Load demand data for the PVs
demandData = struct2array(PVData);
demandData = demandData(180:(180+numDays-1), :);

%% Problem Definition

% Define decision variables

% x(pv, day): 1 if the truck visits PV on day, 0 otherwise
visitDecision = optimvar('visitDecision', [numNodes, numDays],...
                         'Type', 'integer',...
                         'LowerBound', 0, 'UpperBound', 1);

% y(pv, product, compartment, day): 1 if supplying PV with product using compartment on day, 0 otherwise
supplyDecision = optimvar('supplyDecision', [numNodes, numProducts, numCompartments, numDays],...
                          'Type', 'integer',...
                          'LowerBound', 0, 'UpperBound', 1);

% s(pv, product, day): inventory of PV for product on day (L)
inventoryLevel = optimvar('inventoryLevel', [numNodes, numProducts, numDays],...
                          'LowerBound', 0);

% Define the cost function
totalInventoryCost = 0;
for day = 1:numDays
    for pv = 1:numNodes
        for product = 1:numProducts
            totalInventoryCost = totalInventoryCost + (inventoryLevel(pv, product, day) * inventoryCostPerLiterPerDay);
        end
    end
end

totalTransportCost = 0;
for day = 1:numDays
    for pv = 1:numNodes
        totalTransportCost = totalTransportCost + visitDecision(pv, day) * transportCostPerKm * distanceToDepot * 2;
    end
end

prob.Objective = totalTransportCost + totalInventoryCost;

%% Constraints

% At time 1, the inventory levels are equal to initialInventory for each product
initialInventoryConstraint = optimconstr();
count = 1;
for pv = 1:numNodes
    for product = 1:numProducts
        initialInventoryConstraint(count) = inventoryLevel(pv, product, 1) == initialInventory(pv, product);
        count = count + 1;
    end
end
prob.Constraints.initialInventoryConstraint = initialInventoryConstraint;

% Inventory level constraints for subsequent days
inventoryUpdateConstraint = optimconstr();
count = 1;
for day = 1:numDays-1
    for pv = 1:numNodes
        for product = 1:numProducts
            demandIndex = 3 * (pv - 1) + product;
            inventoryUpdateConstraint(count) = inventoryLevel(pv, product, day+1) == inventoryLevel(pv, product, day) + ...
                                               supplyDecision(pv, product, 1, day) * compartmentCapacity1 + ...
                                               supplyDecision(pv, product, 2, day) * compartmentCapacity2 - ...
                                               demandData(day, demandIndex); 
            count = count + 1;
        end
    end
end
prob.Constraints.inventoryUpdateConstraint = inventoryUpdateConstraint;

% Compartment coherence: only one product per compartment
compartmentCoherenceConstraint = optimconstr();
count = 1; 
for day = 1:numDays
    for pv = 1:numNodes
        for compartment = 1:numCompartments
            compartmentCoherenceConstraint(count) = sum(supplyDecision(pv, :, compartment, day), 2) <= 1;
            count = count + 1;
        end 
    end
end
prob.Constraints.compartmentCoherenceConstraint = compartmentCoherenceConstraint;

% Compartment coherence: each compartment must always be filled and must be delivered entirely to a PV
compartmentFullConstraint = optimconstr();
count = 1; 
for day = 1:numDays
    for pv = 1:numNodes
        for compartment = 1:numCompartments
            % The compartment must be full if used for a delivery
            compartmentFullConstraint(count) = sum(supplyDecision(pv, :, compartment, day), 2) * ...
                                                ((compartment == 1) * compartmentCapacity1 + ...
                                                (compartment == 2) * compartmentCapacity2) >= ...
                                                visitDecision(pv, day) * ((compartment == 1) * compartmentCapacity1 + ...
                                                (compartment == 2) * compartmentCapacity2);
            count = count + 1;
        end 
    end
end
prob.Constraints.compartmentFullConstraint = compartmentFullConstraint;

% At most two different products can be delivered per trip
maxProductsPerTripConstraint = optimconstr();
count = 1; 
for pv = 1:numNodes
    for day = 1:numDays
        maxProductsPerTripConstraint(count) = sum(sum(supplyDecision(pv, :, :, day), 2), 3) <= numCompartments; 
        count = count + 1;
    end 
end
prob.Constraints.maxProductsPerTripConstraint = maxProductsPerTripConstraint;

% Binding binary variables x and y with the Big-M method
bigMConstraint = optimconstr();
count = 1;
for pv = 1:numNodes
    for day = 1:numDays
        bigMConstraint(count) = sum(sum(supplyDecision(pv, :, :, day), 2), 3) - BigM * visitDecision(pv, day) <= 0;
        count = count + 1;
    end
end
prob.Constraints.bigMConstraint = bigMConstraint;

%% Solve the Problem

% Display problem structure
%show(prob);

% Set solver options and solve the problem
options = optimoptions('intlinprog', ...
                       'IntegerTolerance', 1e-6, ...
                       'MaxTime', 60*5);%, ...
                       %'Display', 'off');
[solution, cost] = solve(prob, 'options', options);

%% Plot the Results

% Extract results
visitResults = solution.visitDecision;
inventoryResults = solution.inventoryLevel;

%%% Plot the inventory levels for each PV over time
figure;
for pv = 1:numNodes
    subplot(3, 2, pv)
    hold on;
    for product = 1:numProducts
        plot(1:numDays, squeeze(inventoryResults(pv, product, :)), 'DisplayName', productNames(product));
    end
    hold off;
    title("PV #" + pvNames(pv))
    xlabel('Days');
    ylabel('Inventory (L)');
    legend;
end
sgtitle("Inventory Levels for each StorePoint");

%%% Plot the order of PVs' visits

% Define the coordinates of the PVs in a hexagonal pattern
angle = pi / 3;
pv_coords = zeros(numNodes, 2);
for i = 1:numNodes
    pv_coords(i, :) = [distanceToDepot * cos((i-1) * angle), distanceToDepot * sin((i-1) * angle)];
end
depot_coords = [0, 0]; % Define the depot coordinates (center of the hexagon)

% Generate the plot for the truck routes over the days
figure;
for day = 1:14
    subplot(2, 7, day);
    hold on;
    title(['Day ', num2str(day)]);
    xlabel('X (km)');
    ylabel('Y (km)');

    % Plot the depot
    scatter(depot_coords(1), depot_coords(2), 100, 'red', 's', 'filled');
    text(depot_coords(1), depot_coords(2), 'Depot', 'VerticalAlignment', 'bottom', ...
                                                    'HorizontalAlignment', 'center', ...
                                                    'FontSize', 10);

    % Plot the PVs
    scatter(pv_coords(:, 1), pv_coords(:, 2), 100, 'blue', 'o', 'filled');
    text(pv_coords(:, 1), pv_coords(:, 2), pvNames(:), 'VerticalAlignment', 'bottom', ...
                                                    'HorizontalAlignment', 'center', ...
                                                    'FontSize', 10);

    % Plot the routes for the current day
    for pv = 1:6
        if int32(visitResults(pv, day)) == 1
            plot([depot_coords(1), pv_coords(pv, 1)], ...
                 [depot_coords(2), pv_coords(pv, 2)], 'green');
        end
    end
    
    % Set new sizes
    xlim_current = xlim;
    ylim_current = ylim;
    xlim([(xlim_current(1) * 1.5), (xlim_current(2) * 1.5)]);
    ylim([(ylim_current(1) * 1.5), (ylim_current(2) * 1.5)]);
    
    hold off;
end
sgtitle('Truck Routes over Days');