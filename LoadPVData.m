function [PVData, pvNames, productNames] = LoadPVData(filename)

    % PV: 458 461 467 470 476 483
    % Read data from the Excel file and store in a structured variable
    PVData = struct();
    PVData.pv458 = readmatrix(filename, "Range", "AI3:AK366");
    PVData.pv461 = readmatrix(filename, "Range", "AL3:AN366");
    PVData.pv467 = readmatrix(filename, "Range", "AO3:AQ366");
    PVData.pv470 = readmatrix(filename, "Range", "AR3:AS366");
    PVData.pv476 = readmatrix(filename, "Range", "AT3:AV366");
    PVData.pv483 = readmatrix(filename, "Range", "AW3:AY366");
    pvNames = string(fieldnames(PVData));
    productNames = ["B95", "B98", "Dieseltech"];

    %%% Data Sanitation

    % Array to keep track of cell coordinates that need to be edited
    editCoordinates = [];
    
    % Loop over each PV dataset
    for i = 1:length(pvNames)
        currentPVData = PVData.(pvNames{i}); % Get current PV dataset
        % Loop over each column (product type)
        for col = 1:size(currentPVData, 2)
            % Loop over each row (time period)
            for row = 1:size(currentPVData, 1)
                prevValue = 0; % Initialize previous value
                nextValue = 0; % Initialize next value
                % If current cell is positive and editCoordinates is empty
                if currentPVData(row, col) > 0 && isempty(editCoordinates)
                    prevValue = currentPVData(row, col); % Set previous value
                % If current cell is positive and editCoordinates is not empty
                elseif currentPVData(row, col) > 0 && ~isempty(editCoordinates)
                    nextValue = currentPVData(row, col); % Set next value
                    % Calculate average of previous and next values
                    avgValue = ceil((prevValue + nextValue) / 2);
                    % Edit cells at editCoordinates with the average value
                    for k = 1:size(editCoordinates, 2)
                        currentPVData(editCoordinates(1, k), editCoordinates(2, k)) = avgValue;
                    end
                    editCoordinates = []; % Clear editCoordinates
                % If current cell is negative or NaN, add to editCoordinates
                elseif currentPVData(row, col) < 0 || isnan(currentPVData(row, col))
                    editCoordinates = [editCoordinates [row; col]];
                end
            end
    
            % If there are any remaining cells to edit, set them to prevValue
            for k = 1:size(editCoordinates, 2)
                currentPVData(editCoordinates(1, k), editCoordinates(2, k)) = prevValue;
            end
    
            % Evaluate threshold to delete large values
            avgValue = ceil(mean(currentPVData(:, col))); % Calculate column average
            stdDeviation = std(currentPVData(:, col)); % Calculate column standard deviation
            threshold = avgValue + 3 * stdDeviation; % Set threshold
            % Replace values greater than threshold with average value
            for row = 1:size(currentPVData, 1)
                if currentPVData(row, col) > threshold
                    currentPVData(row, col) = avgValue;
                end
            end
            PVData.(pvNames{i}) = currentPVData; % Update PVData with sanitized data
        end
    
        editCoordinates = []; % Clear editCoordinates for next PV
    
    end
    
    % Adapt pv 470 by moving data from column 2 to column 3 and setting column 2 to 0
    currentPVData = PVData.pv470;
    for row = 1:size(currentPVData, 1)
        currentPVData(row, 3) = currentPVData(row, 2); % Move data from column 2 to 3
        currentPVData(row, 2) = 0; % Set column 2 to 0
    end
    
    PVData.pv470 = currentPVData; % Update PVData with adapted pv470

end