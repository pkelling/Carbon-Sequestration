clear all;
close all;
clc;

% ----------- Load Emissions Data --------------%
%          And Extract Useful Information

% Important Variables
%   Strings:
%       1) states = abbreviated state names
%       2) powerSources = sources of power (gas,solar,coal...)
%
%   Vectors:
%       1) emissionsFactors = [lb/MWh] cleanliness of energy production
%               -lower is better (less CO2 for energy created)
%       2) sourcePercent = [%] sources of power for each state
%       3) energyTotals = [MWh] total energy created for each state
%       4) totalEmissions = [lb] CO2 emissions by state
%
%   Matrix
%       1) energyBySource = [MWh] energy each state produces by source


%Load emmision rates data [lb/MWh]
[emissionsRates,labels] = xlsread("egrid2016_summarytables.xlsx",4);
emissionsFactors = emissionsRates(1:51,1);
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
totalEmissions = energyTotals .* emissionsFactors;


% ----------- Map Visualization of States Emissions --------------- %

latlng = xlsread("statesCenters.xlsx");
lat = latlng(:,1);
lng = latlng(:,2);

%get largest power source for each state
[temp,sourceIdx] = max(sourcePercent,[],2);
largestSources = string(powerSources(sourceIdx))';

% Setup for the map (create a table)
dataTable = table(lat, lng,totalEmissions,largestSources);
dataTable.Properties.VariableNames = {'Latitude', 'Longitude',...
                        'CO2Emissions','MajorSource'};
dataTable.MajorSource = categorical(dataTable.MajorSource);
              

% This makes the initial map larger
figh = figure(1);
pos = get(figh,'position');
set(figh,'position',[pos(1:2)/2 pos(3:4)*1.5])


% Create the map
geobubble(dataTable, 'Latitude','Longitude',...
        'SizeVariable','CO2Emissions',...
        'ColorVariable','MajorSource',...
        'Title',"CO2 Emissions For Each State",...
        'ColorLegendTitle','Largest Energy Source',...
        'SizeLegendTitle','Emissions [lb CO2]',...
        'BubbleWidthRange',[4,25],...
        'ScaleBarVisible',false,'GridVisible',false);
    

     
    

% ---------- Map Visualization of particular power source --------- %



source = menu("View a particular power source?", powerSources);
totalMaxEnergy = max(max(energyBySource));

while(source ~= 0)
    % Create table for map
    srcTable = table(lat, lng,energyBySource(:,source));
    srcTable.Properties.VariableNames = {'Latitudes', 'Longitudes','EnergyProduced'};
    
    %unique titles for current source
    sizeTitle = sprintf("%s production [MWh]",string(powerSources(source)));
    mainTitle = sprintf("States Energy Production from %s",string(powerSources(source)));
    
    % This creates a standard size, so 2 different sources are
    %   on the same size scale
    bubbleRatio = max(energyBySource(:,source)) / totalMaxEnergy;
    maxBubbleSize = 3 + ceil(bubbleRatio*35);
    
    % Create map
    geobubble(srcTable,'Latitudes','Longitudes',...
                    'SizeVariable','EnergyProduced',...
                    'SizeLegendTitle',sizeTitle,...
                    'Title',mainTitle,...
                    'GridVisible',false,...
                    'ScaleBarVisible',false,'BubbleWidthRange',[1,maxBubbleSize]);
        
    source = menu("View another power source on map?", powerSources);
end




% ---------- Help User Visualize Data ------------- %

choice = menu("Compare state power sources?","yes","no");

if choice == 1
    stateNum = listdlg('PromptString',"Please select state(s)", 'ListString',states);

    if(~isempty(stateNum))
        barh(categorical(states(stateNum)),sourcePercent(stateNum,:),'stacked');
        legend(powerSources);
        title("Emissions sources by state");
        xlabel("Percentage of Power Generation");
        ylabel("State");
    else
        fprintf("No state selected, moving to next step. \n");
    end
end




% -------- Load in Carbon Storage data -------------- %

[numbers,labels] = xlsread('Table_1.xlsx');

statesStorage = labels(9:280,93:2:107);
statesPercent = numbers(1:272,92:106);

Volumes = numbers(1:272,14);
Densities = numbers(1:272,22);








