clear all;
close all;
clc;

% ----------- Load Emissions Data --------------%
%          And Extract Useful Information

% Important Variables
%   Strings:
%       1) states (abbreviated state names)
%       2) powerSources (sources of power- gas,solar,coal...)
%
%   Vectors:
%       1) carbonEfficiency [lb/MWh] -efficiency of power gen by state.
%               -lower is better (less carbon per MWh)
%       2) sourcePercent [%] -sources of power for each state
%       3) energyTotals [MWh] -total energy created for each state
%       4) totalEmissions [lb] -CO2 emissions by state

%Load emmision rates data [lb/MWh]
[emissionsRates,labels] = xlsread("egrid2016_summarytables.xlsx",4);
carbonEfficiency = emissionsRates(1:end-2,1);
states = string(labels(5:55,1));

%Load energy output by source [MWh]
[stateResourceMix, labels] = xlsread("egrid2016_summarytables.xlsx",5);

%list of power Sources
powerSources = labels(3,4:14);

%power sources percentages
sourcePercent = stateResourceMix(1:51,3:end);

%total energy for each state [MWh]
energyTotals = stateResourceMix(1:51,2);

%emissions totals for each state
totalEmissions = energyTotals .* carbonEfficiency;




% ----------- Map Visualization --------------- %
%Create map of emissions by state
latlng = xlsread("statesCenters.xlsx");

[temp,sourceIdx] = max(sourcePercent,[],2);
largestSources = string(powerSources(sourceIdx))';

% Setup for the map (create a table)
dataTable = table(latlng(:,1), latlng(:,2),totalEmissions,largestSources);
dataTable.Properties.VariableNames = {'Latitudes', 'Longitudes',...
                        'Emissions','MajorSource'};
dataTable.MajorSource = categorical(dataTable.MajorSource);
              

% Create a map         
gb = geobubble(dataTable, 'Latitudes','Longitudes',...
        'SizeVariable','Emissions',...
        'ColorVariable','MajorSource',...
        'ColorLegendTitle','Largest Energy Source',...
        'SizeLegendTitle','Emissions [lb CO2]',...
        'MapLayout','maximized','GridVisible',false,...
        'ScaleBarVisible',false);
title("Each states largest power sources");

    


% ---------- Help User Visualize Data ------------- %

choice = menu("View particular power sources by State?","yes","no");

if choice == 1
    stateNum = listdlg('PromptString',"Please select a state", 'ListString',states);

    if(~isempty(stateNum))
        barh(categorical(states(stateNum)),sourcePercent(stateNum,:),'stacked');
        legend(powerSources);
        title("Emissions sources by state");
        xlabel("Source");
        ylabel("Percentage of Power Generation");
    else
        fprintf("No state selected, moving to next step. \n");
    end
end