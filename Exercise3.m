clear; clc;
close all;
warning off;

%% Exercise 3: EBM + LTC
% The Economic Batch Model  is a fundamental concept in inventory management, 
% used to determine the optimal order quantity that minimizes total inventory costs.
% Note: This strategy aims to ensure that there are no stockouts or periods.

% Annual Demand [D]
annualDemand = 400;

% Ordering Cost (fixedOrderCost - regardless of the order quantity.) [f_0]
fixedOrderCost = 100;

% Unit Price (unitPrice)
unitPrice = 200;

% Annual unit maintenance cost as a percentage of the unit price ,
% incurred for storing one unit for one year.
% (holdingCostPercentage) [h]

holdingCostPercentage = 0.12;

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
% Solution Q* = sqrt ( (2 * f_0 * D) / (h * unitPrice))

% Calculate EOQ (Economic Order Quantity)
optimalOrderQuantity = ceil(sqrt(2 * fixedOrderCost * ...
                       annualDemand / (holdingCostPercentage * unitPrice)));

% Duration of the supply cycle
optimalCycleDuration = optimalOrderQuantity / annualDemand; 
% Demand rate, assuming constant demand over time
demandRate = optimalOrderQuantity / optimalCycleDuration;
% Total cost calculation = storage cost + ordering cost
totalCost = (holdingCostPercentage * unitPrice) * ...
            optimalOrderQuantity / 2 + fixedOrderCost *...
            annualDemand / optimalOrderQuantity;

% Time array for plotting
time = linspace(0, 1, 10^4);

% Inventory level over time, assuming instantaneous replenishment
inventoryLevel = -demandRate * mod(time, optimalCycleDuration) + optimalOrderQuantity;
% Order quantity remains constant over time
orderQuantity = optimalOrderQuantity * ones(size(time));

% Plot the inventory level and order quantity over time
figure;
plot(time, inventoryLevel, 'b');
hold on;
plot(time, orderQuantity, 'r--');
xlabel('Time');
ylabel('Inventory Level / Order Quantity');
title('Inventory Level and Order Quantity Over Time');
legend('Inventory Level', 'Order Quantity');
grid on;

%% The Least Total Cost

% LTC approach seeks to minimize the total cost by balancing 
% the holding cost and ordering cost across multiple periods.

% Demand for each period (e.g., bi-monthly)
demand = [60 90 50 70 80 50];
numPeriods = length(demand);

% Holding cost per period
holdingCostPerPeriod = holdingCostPercentage * unitPrice / numPeriods;

%{
% Example on Slide
demand = [50 0 30 0 20 10 0 10 0 40 20 20];
numPeriods = length(demand);
holdingCostPerPeriod = 0.5;
%}

% Initialize variables for the LTC approach
orders = zeros(1, numPeriods);
startPeriod = 1;
endPeriod = 1;
minDiff = Inf; % Initial high value for the minimum cost difference
numOrders = 0;

% Iteratively find the optimal order size to minimize total cost
% (minimizing the cost difference between holding and ordering costs.)

while startPeriod <= numPeriods
    currentBatchSize = sum(demand(1, startPeriod:endPeriod)); % Calculate current batch size
    totalInventory = 0;
    for i = startPeriod:endPeriod
        totalInventory = totalInventory + (currentBatchSize - sum(demand(1, startPeriod:i))); % Calculate total inventory
    end
    holdingCost = totalInventory * holdingCostPerPeriod; % Calculate holding cost for the period

    costDifference = abs(holdingCost - fixedOrderCost); % Calculate the difference between holding cost and ordering cost (it helps to determine how close we are to the optimal point)
    if costDifference <= minDiff 
        minHoldingCost = holdingCost; % Update minimum holding cost
        endPeriod = endPeriod + 1;    % Move to the next period
        minDiff = costDifference;     % Update minimum cost difference

        % If the end period exceeds the number of periods, finalize the order for the current period
        if endPeriod > numPeriods
            orders(1, startPeriod) = sum(demand(1, startPeriod:endPeriod-1)); % Set orders for the period
            numOrders = numOrders + 1; % Increment the number of orders
            break;
        end
    else
        orders(1, startPeriod) = sum(demand(1, startPeriod:endPeriod-1)); % Finalize orders for the period
        numOrders = numOrders + 1; % Increment the number of orders
        startPeriod = endPeriod;   % Move to the next start period
        minDiff = 100000;          % Reset minimum cost difference
    end
end

% Calculate inventory levels based on orders and demand for each period
inventory = zeros(1, numPeriods);
inventory(1) = max(0, orders(1) - demand(1));
for i = 2:numPeriods
    inventory(i) = max(0, orders(i) + inventory(i-1) - demand(i));
end

% Calculate the total least cost considering ordering and holding costs
totalLeastCost = numOrders * fixedOrderCost + sum(inventory) * holdingCostPerPeriod;

% Plot the demand, orders, and inventory over time
figure;
plot(1:numPeriods, demand, 'b', 'LineWidth', 1.5);
hold on;
plot(1:numPeriods, orders, 'r--', 'LineWidth', 1.5);
plot(1:numPeriods, inventory, 'g-.', 'LineWidth', 1.5);
xlabel('Period');
ylabel('Quantity');
title('Demand, Orders, and Inventory Over Time');
legend('Demand', 'Orders', 'Inventory');
grid on;