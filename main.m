clear all;
close all;
clc;


%Load emmisions data
[emmisionsRatesByState,labels] = xlsread("egrid2016_summarytables.xlsx",4);
carbonEfficiencyByState = emmisionsRatesByState(1:end-1,1);
states = labels(5:56,1);

[stateResourceMix, labels] = xlsread("egrid2016_summarytables.xlsx",5);

%list of power Sources
powerSources = labels(3,4:14);

%power sources percentages by state 
sourcesByState = stateResourceMix(1:52,3:end);
energyByState = stateResourceMix(1:52,2);

fprintf("hello world");

%hello world