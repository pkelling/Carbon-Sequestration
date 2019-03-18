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
%       4) energyBySource [MWh] -energy each state produces by source
%       5) totalEmissions [lb] -CO2 emissions by state

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

%energy consumption by source for each state
energyBySource = energyTotals .* sourcePercent;

%emissions totals for each state
totalEmissions = energyTotals .* carbonEfficiency;



% ----------- Map Visualization of largest power source --------------- %

latlng = xlsread("statesCenters.xlsx");
lat = latlng(:,1);
lng = latlng(:,2);


%get largest power source for each state
[temp,sourceIdx] = max(sourcePercent,[],2);
largestSources = string(powerSources(sourceIdx))';


% Setup for the map (create a table)
dataTable = table(lat, lng,totalEmissions,largestSources);
dataTable.Properties.VariableNames = {'Latitudes', 'Longitudes',...
                        'Emissions','MajorSource'};
dataTable.MajorSource = categorical(dataTable.MajorSource);
              

% Create the map
gb = geobubble(dataTable, 'Latitudes','Longitudes',...
        'SizeVariable','Emissions',...
        'ColorVariable','MajorSource',...
        'ColorLegendTitle','Largest Energy Source',...
        'SizeLegendTitle','Emissions [lb CO2]',...
        'ScaleBarVisible',false,'GridVisible',false,...
        'Title',"Total Emissions and Major Power Source");
    
  

    
% ---------- Map Visualization of particular power source --------- %
source = menu("View particular power source on map?", powerSources);
totalMaxEnergy = max(max(energyBySource));

while(source ~= 0)
    % Create table for map
    srcTable = table(lat, lng,energyBySource(:,source));
    srcTable.Properties.VariableNames = {'Latitudes', 'Longitudes','EnergyProduced'};
    
    %unique titles for current source
    sizeTitle = sprintf("%s production [MWh]",string(powerSources(source)));
    mainTitle = sprintf("States Energy Production from %s",string(powerSources(source)));
    
    bubbleRatio = max(energyBySource(:,source)) / totalMaxEnergy;
    maxBubbleSize = ceil(bubbleRatio*40);
    
    % Create map
    geobubble(srcTable,'Latitudes','Longitudes',...
                    'SizeVariable','EnergyProduced',...
                    'SizeLegendTitle',sizeTitle,...
                    'Title',mainTitle,...
                    'GridVisible',false,...
                    'ScaleBarVisible',false,'BubbleWidthRange',[1,maxBubbleSize]);
        
    source = menu("View another power source on map?", powerSources);
end



%% ---------- Help User Visualize Data ------------- %

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