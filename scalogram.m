%%	Script for processing eye-tracking data
clear all;
warning off all;
clc;

%% Generate the plots here
recordId = '042913';
% generateScalogramDiscontinuous(recordId, 10000, 0);
% generateScalogramDiscontinuous(recordId, 10000, 1);

% This will load all the seizure occurrence timings into seizureTimes
seizureTimes = loadSeizureTimes('seizureEventData.csv');
generateScalogramContinuous(recordId, 1, 20000, 0, 'eccentricity',seizureTimes);
generateScalogramContinuous(recordId, 1, 20000, 1, 'eccentricity',seizureTimes);