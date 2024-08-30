clear; clc;
close all;
warning off;

%% Exercise 5: VRP Problem ("General" Version)

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

% Define the coordinates of the PVs in a hexagonal pattern
angle = pi / 3; % 60 degrees in radians
pv_coords = zeros(numNodes, 2);
for i = 1:numNodes
    pv_coords(i, :) = [distanceToDepot * cos((i-1) * angle), distanceToDepot * sin((i-1) * angle)];
end
depot_coords = [0, 0]; % Define the depot coordinates (center of the hexagon)

% Define the distance matrix between PVs
distanceMatrix = zeros(numNodes, numNodes);
for i = 1:numNodes
    for j = 1:numNodes
        if i ~= j
            distanceMatrix(i, j) = sqrt((pv_coords(j, 1) - pv_coords(i, 1))^2 + (pv_coords(j, 2) - pv_coords(i, 2))^2);
        end
    end
end

%% Problem Definition

% Define decision variables

% x(pv, day): 1 if the truck visits PV on day, 0 otherwise
visitDecision = optimvar('visitDecision', [numNodes, numDays],...
                         'Type', 'integer',...
                         'LowerBound', 0, 'UpperBound', 1);

% travel(pv1, pv2, day): 1 if the truck travels from pv1 to pv2 on day, 0 otherwise
travelDecision = optimvar('travelDecision', [numNodes, numNodes, numDays], ...
                          'Type', 'integer', ...
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
    for pv1 = 1:numNodes
        totalTransportCost = totalTransportCost + visitDecision(pv1, day) * transportCostPerKm * distanceToDepot;
        for pv2 = 1:numNodes
            if pv1 ~= pv2
                totalTransportCost = totalTransportCost + travelDecision(pv1, pv2, day) * transportCostPerKm * distanceMatrix(pv1, pv2);
            end
        end
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

% Compartment must be full if used for delivery
compartmentFullConstraint = optimconstr();
count = 1;
for day = 1:numDays
    for pv = 1:numNodes
        for compartment = 1:numCompartments
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

% Constraint: Each compartment can be used only once per journey between PVs
compartmentUsageConstraint = optimconstr();
count = 1;
for day = 1:numDays
    for pv1 = 1:numNodes
        for pv2 = 1:numNodes
            if pv1 ~= pv2
                for compartment = 1:numCompartments
                    compartmentUsageConstraint(count) = 2 - travelDecision(pv1, pv2, day) >= ...
                        sum(supplyDecision(pv1, :, compartment, day)) + ...
                        sum(supplyDecision(pv2, :, compartment, day));
                    count = count + 1;
                end
            end
        end
    end
end
prob.Constraints.compartmentUsageConstraint = compartmentUsageConstraint;

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

% Each PV must be visited exactly once per day
visitConstraint = optimconstr([numNodes, numDays]);
for pv = 1:numNodes
    for day = 1:numDays
        visitConstraint(pv, day) = sum(travelDecision(pv, :, day)) + sum(travelDecision(:, pv, day)) <= visitDecision(pv, day);
    end
end
prob.Constraints.visitConstraint = visitConstraint;

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
travelResults = solution.travelDecision;

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
figure;
for day = 1:numDays
    subplot(2, ceil(numDays / 2), day);
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

    % Plot the routes for the current day with arrows
    for pv1 = 1:numNodes
        for pv2 = 1:numNodes
            if travelResults(pv1, pv2, day) > 0.5
                x1 = pv_coords(pv1, 1);
                y1 = pv_coords(pv1, 2);
                x2 = pv_coords(pv2, 1);
                y2 = pv_coords(pv2, 2);
                quiver(x1, y1, x2 - x1, y2 - y1, 0, 'green', 'MaxHeadSize', 0.5, 'AutoScale', 'off');
            end
        end
    end

    % Plot the routes from the depot to the PVs and back with arrows
    for pv = 1:numNodes
        if visitResults(pv, day) > 0.5
            % From depot to PV
            x1 = depot_coords(1);
            y1 = depot_coords(2);
            x2 = pv_coords(pv, 1);
            y2 = pv_coords(pv, 2);
            if sum(travelResults(pv, :, day)) > 0.5
                quiver(x1, y1, x2 - x1, y2 - y1, 0, 'blue', 'MaxHeadSize', 0.5, 'AutoScale', 'off');
            elseif sum(travelResults(:, pv, day)) > 0.5
                quiver(x2, y2, x1 - x2, y1 - y2, 0, 'blue', 'MaxHeadSize', 0.5, 'AutoScale', 'off');
            elseif visitResults(pv) > 0.5    
                quiver(x1, y1, x2 - x1, y2 - y1, 0, 'blue', 'MaxHeadSize', 0.5, 'AutoScale', 'off');
                quiver(x2, y2, x1 - x2, y1 - y2, 0, 'blue', 'MaxHeadSize', 0.5, 'AutoScale', 'off');
            end
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