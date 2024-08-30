clear; clc;
close all;
warning off;

%% Exercise 1: Moving Averages

%% Calcolation
% Initial data
indices = 1:12;  % Time indices
values = [5 6 8 7 6 10 11 12 10 14 12 16];  % Historical time series data

% A moving average is a technique used to smooth out short-term fluctuations
% and highlight longer-term trends or cycles in data. 
% The formula for an n-order moving average is:
% MA_t = 1/n SUM (from i = 0 to n-1) of X_t-i
% where X are the values of the times series and t is the time

% Calculate moving averages of order 2, 3, and 4
ma2 = movmean(values, 2); % Moving average with a window of 2
ma3 = movmean(values, 3); % Moving average with a window of 3
ma4 = movmean(values, 4); % Moving average with a window of 4

% Adjusting moving average arrays to align with the values array
ma2 = ma2(2:end);
ma3 = ma3(3:end);
ma4 = ma4(4:end);

% Mean Absolute Deviation (MAD) measures the average magnitude of errors 
% in a set of predictions, without considering their direction.
% It is calculated as:
% MAD = 1/(T-1) SUM (from t = 2 to T) of |e_t|
% where e_t = X_t - MA_t
% This formula accounts for the mean absolute deviation from the moving average.

% Calculate MAD for each moving average
MAD2 = mean(abs(values(2:end) - ma2));  % MAD for order 2
MAD3 = mean(abs(values(3:end) - ma3));  % MAD for order 3
MAD4 = mean(abs(values(4:end) - ma4));  % MAD for order 4

% Mean Squared Error (MSE) measures the average of the squares of the errors.
% It is calculated as:
% MSE = 1/(T-1) SUM (from t = 2 to T) of (e_t)^2
% where e_t = X_t - MA_t
% This formula accounts for the mean squared deviation from the moving average.

% Calculate MSE for each moving average
MSE2 = mean((values(2:end) - ma2).^2);  % MSE for order 2
MSE3 = mean((values(3:end) - ma3).^2);  % MSE for order 3
MSE4 = mean((values(4:end) - ma4).^2);  % MSE for order 4

% Display the results
fprintf('MAD for MA2: %.2f\n', MAD2);
fprintf('MAD for MA3: %.2f\n', MAD3);
fprintf('MAD for MA4: %.2f\n', MAD4);

% The tracking signal is calculated using the cumulative sum of forecast errors divided by the MAD for each moving average order.

% Calculate the tracking signal
tracking_signal2 = cumsum(values(2:end) - ma2) / MAD2;
tracking_signal3 = cumsum(values(3:end) - ma3) / MAD3;
tracking_signal4 = cumsum(values(4:end) - ma4) / MAD4;

%% Graphs

% Plotting moving averages
figure;
plot(indices, values, '-o', 'DisplayName', 'Original Values');  % Plot original values
hold on;
plot(indices(2:end), ma2, '-x', 'DisplayName', 'Moving Average 2');  % Plot MA2
plot(indices(3:end), ma3, '-s', 'DisplayName', 'Moving Average 3');  % Plot MA3
plot(indices(4:end), ma4, '-d', 'DisplayName', 'Moving Average 4');  % Plot MA4
legend();
title('Moving Averages of Order 2, 3, and 4');
xlabel('Index');
ylabel('Values');
grid on;
hold off;

% Control charts for each moving average order are plotted in separate subplots to monitor the stability and variability of the process.
figure;
subplot(3,2,1);
plot(indices(2:end), values(2:end), '-o', indices(2:end), ma2, '-x');
title('Tracking Line N=2');
xlabel('Index');
ylabel('Values');
grid on;

subplot(3,2,2);
plot(indices(2:end), values(2:end) - ma2, '-o');
title('Control Chart N=2');
xlabel('Index');
ylabel('Errors');
grid on;

subplot(3,2,3);
plot(indices(3:end), values(3:end), '-o', indices(3:end), ma3, '-s');
title('Tracking Line N=3');
xlabel('Index');
ylabel('Values');
grid on;

subplot(3,2,4);
plot(indices(3:end), values(3:end) - ma3, '-o');
title('Control Chart N=3');
xlabel('Index');
ylabel('Errors');
grid on;

subplot(3,2,5);
plot(indices(4:end), values(4:end), '-o', indices(4:end), ma4, '-d');
title('Tracking Line N=4');
xlabel('Index');
ylabel('Values');
grid on;

subplot(3,2,6);
plot(indices(4:end), values(4:end) - ma4, '-o');
title('Control Chart N=4');
xlabel('Index');
ylabel('Errors');
grid on;

% Plotting tracking signals
figure;
plot(indices(2:end), tracking_signal2, '-x', 'DisplayName', 'Tracking Signal 2');
hold on;
plot(indices(3:end), tracking_signal3, '-s', 'DisplayName', 'Tracking Signal 3');
plot(indices(4:end), tracking_signal4, '-d', 'DisplayName', 'Tracking Signal 4');
legend();
title('Tracking Signals for Moving Averages of Order 2, 3, and 4');
xlabel('Index');
ylabel('Tracking Signal');
grid on;
hold off;