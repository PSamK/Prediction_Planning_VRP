clear; clc;
close all;
warning off;

%% Exercise 2: Deseasonalization

% Deseasonalization is the process of removing the seasonal component
% from a time series to analyze the underlying trend and cyclical patterns.

% Possible use: After the deseasonalization process, we can identify the
% function that interpolates the historical series without the seasonal component. 
% This allows for more accurate forecasting of future periods. Once the forecasts
% are made, the seasonal indices can be re-applied to incorporate the seasonal effects
% back into the forecasted values.

% Initial data for two years
year1 = [5 6 8 6 6 3 2 6 10 12 8 7];
year2 = [8 8 9 7 7 5 4 8 12 13 10 8];

% Calculate the average for each year
mean1 = mean(year1);
mean2 = mean(year2);

% Normalize each year by dividing by its average
normalized1 = year1 / mean1;
normalized2 = year2 / mean2;

% Calculate seasonal indices as the average of normalized values
seasonal_indices = (normalized1 + normalized2) / 2;

% Deseasonalize the series by dividing original values by seasonal indices
deseasonalized1 = year1 ./ seasonal_indices;
deseasonalized2 = year2 ./ seasonal_indices;

% Display results
disp('Seasonal Indices:');
disp(seasonal_indices);

disp('Deseasonalized Data for Year 1:');
disp(deseasonalized1);

disp('Deseasonalized Data for Year 2:');
disp(deseasonalized2);

%% Plotting the Original and Deseasonalized Data

% Plot the original data
figure;
subplot(2,1,1);
plot(1:12, year1, '-o', 'DisplayName', 'Year 1');
hold on;
plot(1:12, year2, '-x', 'DisplayName', 'Year 2');
title('Original Data');
xlabel('Period (Month)');
ylabel('Values');
legend;
grid on;

% Plot the deseasonalized data
subplot(2,1,2);
plot(1:12, deseasonalized1, '-o', 'DisplayName', 'Year 1 Deseasonalized');
hold on;
plot(1:12, deseasonalized2, '-x', 'DisplayName', 'Year 2 Deseasonalized');
title('Deseasonalized Data');
xlabel('Period (Month)');
ylabel('Deseasonalized Values');
legend;
grid on;
