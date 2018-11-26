% This function reads a csv file and return a string matrix that contains
% information on the seizure periods.
%
% Note that you can retrieve the data using the ID key. You can check
% how many seizures have occurred by using [x,y] = size(seizureTimes(ID)),
% where x indicates how many seizures occurred, and y should be 3.
% The seizures are stored in the format [ startTime, endTime, seizureType ]
%
% Please use seizureEventData.csv as a reference when creating the csv
% files. The ID, StartTime, Endtime and SeizureType headers must be
% available. 
function [seizureTimes] = loadSeizureTimes( fileName )

    % Load the data and count the number of seizures for each record
    rawData = readtable(fileName,'DurationType','text');
    records = unique(rawData.x_ID);
    recordCounts = cellfun(@(x) sum(ismember(rawData.x_ID,x)),records,'un',1);

    % initialize and preallocate seizureTimes
    seizureTimes = containers.Map('KeyType', 'char', 'ValueType', 'any');
    tempMap = containers.Map('keyType', 'char', 'ValueType', 'uint32');
    for k=1:length(records)
        seizureTimes(records{k}) = strings( recordCounts(k), 3 );
        tempMap(records{k}) = 0;
    end

    % enter the info
    for k=1:size(rawData,1)
        tempMap(rawData.x_ID{k}) = tempMap(rawData.x_ID{k}) + 1;
        tempArr = seizureTimes(rawData.x_ID{k});
        tempArr(tempMap(rawData.x_ID{k}), 1) = rawData.StartTime{k};
        tempArr(tempMap(rawData.x_ID{k}), 2) = rawData.EndTime{k};
        tempArr(tempMap(rawData.x_ID{k}), 3) = rawData.SeizureType{k};
        seizureTimes(rawData.x_ID{k}) = tempArr;
    end

end