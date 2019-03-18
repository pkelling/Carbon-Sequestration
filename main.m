clear all;
close all;
clc;


%Load emmision rates data [lb/MWh]
[emissionsRates,labels] = xlsread("egrid2016_summarytables.xlsx",4);
carbonEfficiency = emissionsRates(1:end-1,1);
states = string(labels(5:56,1));

%Load energy output by source [MWh]
[stateResourceMix, labels] = xlsread("egrid2016_summarytables.xlsx",5);

%list of power Sources
powerSources = labels(3,4:14);

%power sources percentages
sourcePercent = stateResourceMix(1:52,3:end);

%total energy for each state [MWh]
energyTotals = stateResourceMix(1:52,2);

%emissions totals for each state
totalEmissions = energyTotals .* carbonEfficiency;

%Matrix of emissions by state and source
emissions = totalEmissions .* sourcePercent;


stateNum = listdlg('PromptString',"Please select a state",'ListString',states);

barh(categorical(powerSources),emissions(stateNum,:));
tempTitle = sprintf("Emissions sources for %s",states(stateNum));
title(tempTitle);
xlabel("Source");
ylabel("Emissions [lbs CO2]");