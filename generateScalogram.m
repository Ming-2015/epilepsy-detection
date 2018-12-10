%%	Script for processing eye-tracking data
clear all;
warning off all;
clc;

%% Get all the records with seizure data
seizureTimes = loadSeizureTimes('seizureEventData.csv');
recordIds = string( keys(seizureTimes) );
recordIds = [recordIds, "041613_1", "041613_2", "042913", "050213", "050813_1", "050913", "052113", "052413_1", "052413_2", "060613", "061313"];

% Generate and save the scalograms
generateJointScalogramFromRecordId( recordIds, 'jointScalograms', 'eccentricity' );