%%	Script for processing eye-tracking data
clear all;
warning off all;
clc;

%% Generate the plots here
recordId = '072513';
% generateScalogramDiscontinuous(recordId, 10000, 0);
% generateScalogramDiscontinuous(recordId, 10000, 1);

generateScalogramContinuous(recordId, 1, 40000, 0, 'eccentricity');
generateScalogramContinuous(recordId, 1, 40000, 1, 'eccentricity');