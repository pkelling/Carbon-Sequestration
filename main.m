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


% Load emmision rates data [lb/MWh]
[emissionsRates,labels] = xlsread("egrid2016_summarytables.xlsx",4);
emissionsFactors = emissionsRates(1:51,1);
states = string(labels(5:55,1));

% Load energy output by source [MWh]
[stateResourceMix, labels] = xlsread("egrid2016_summarytables.xlsx",5);

% List of power Sources
powerSources = labels(3,4:14);

% Power sources percentages
sourcePercent = stateResourceMix(1:51,3:end);

% Total energy for each state [MWh]
energyTotals = stateResourceMix(1:51,2);

% Energy consumption by source for each state
energyBySource = energyTotals .* sourcePercent;

%Emissions totals for each state
totalEmissions = energyTotals .* emissionsFactors;





% ----------- Load in statesCenters data ---------------- %
latlng = xlsread("statesCenters.xlsx");
lat = latlng(:,1);
lng = latlng(:,2);


% This makes the initial map larger
figh = figure(1);
pos = get(figh,'position');
set(figh,'position',[pos(1:2)/2 pos(3:4)*1.5])




% ----------- Map Visualization of States Emissions --------------- %
% Get largest power source for each state
[temp,sourceIdx] = max(sourcePercent,[],2);
largestSources = string(powerSources(sourceIdx))';

% Setup for the map (create a table)
data = {lat, lng, totalEmissions, largestSources};
labels = ["CO2Emissions", "MajorSource"];
titles = ["CO2 Emissions For Each State", "Emissions [lb CO2]", "Largest Energy Source"];

CreateMap(data,labels,titles,[4,25]);
  



% ---------- Map Visualization of particular power source --------- %

% TODO:
%   1) Change sizes of bubbles so scale is same for every power source.

source = menu("View a particular power source?", ['Move to Next Step',powerSources]);

% Validate selection
if(source == 0)
    warning("No option selected, moving to next step");
end


while(source > 0)
    source = source - 1;
    
    % Construct unique titles for current source
    sizeTitle = sprintf("%s production [MWh]",string(powerSources(source)));
    mainTitle = sprintf("States Energy Production from %s",string(powerSources(source)));
    
    %setup inputs for map function
    data = {lat, lng, energyBySource(:,source)};
    labels = "EnergyProduced";
    titles = [mainTitle, sizeTitle];
    
    %get bubble scale
    bubbleScale = calcBubbleSize(energyBySource,source);

    % Create map
    CreateMap(data,labels,titles,bubbleScale);
       
    
    % Ask user to repeat
    source = menu("View another power source on map?", ['Move to Next Step',powerSources]);
    
    % Validate selection
    if(source == 0)
        warning("No option selected, moving to next step");
    elseif source == 1
        break;
    end
end






% ---------- States Side by Side comparison ------------- %

% TODO:
%   1) Validate User Input
%   2) Change to loop so you can select different states.
%   3) Make chart based on actual energy output, not percent of output
%       -This will help give a better idea of energy output differences
%       between states
%   4) Change colors so they match resource (coal->black, hydro->blue...)


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
        warning("No state selected, moving to next step.");
    end
end











% -------- Load in Carbon Storage data -------------- %
% Variables:
%   1) Volumes = contains likely volume of every location
%   2) Densities = contains likely density of every location
%   3) stateWithStorage = list of states where location is
%   4) percentInState = percentage of location in corresponding state
%       -Note: if Nan has corresponding state, it is <1% (we assume 0) 

[numbers,labels] = xlsread('Table_1.xlsx');

stateWithStorage = string(labels(9:280,93:2:107));
percentInState = numbers(1:272,92:2:106);
storageCapacity = numbers(1:272,2);

Volumes = numbers(1:272,14);
Densities = numbers(1:272,22);

% -- Validate Data 

% Remove lines where Volume is Nan (they were blank lines)
blankLines = find(isnan(Volumes));
Volumes(blankLines) = [];
Densities(blankLines) = [];
stateWithStorage(blankLines,:) = [];
percentInState(blankLines,:) = [];
storageCapacity(blankLines) = [];

% -------- Find Storage Volume By State ------------ %

% TODO:
%   1) Convert Storage to lbs CO2 for each site
%   2) Get total lbs of storage for each state

%calculations
bbl = storageCapacity.*7758.37; % [bbl] converting acres sq.ft. to bbl (barrels of oil) 
MMbbl = bbl./1000000; %[MMbbl] converting bbl to MMbbl
%m = D.*v
mass = Densities.*MMbbl.*6.28981; % [kg] mult. density by MMbbl converted to m^3
lbs = mass.*2.20462; % [lbs] converting kg to lbs 

help = unique(stateWithStorage); %assembling vector with all unique state names
percentInState(isnan(percentInState)) = 0; %changing NaN elements into 0 in order to perform operations

me = 0;
pls = [];
for k = 1:length(help)
    [ex,why] = find(stateWithStorage == help(k)); %using find function to find [row,col] in order to index
    for p = 1:length(ex)
        me = me +(lbs(ex(p),1).*(percentInState(ex(p),(why(p))))/100); %getting total storage for state(k)
    end
    pls = [pls,(me)]; %creating vector of storage for states
    me = 0; %reseting in order to calc. total of next state
end
 
M = containers.Map(help,pls); %assigning states with their respective total storage capacity

% ------------ Map lbs storage by state ------------- %
%           Along with lbs emissions ????
%   Possible: select between 3 maps: min, M likely, and max storage?



% ----------- Plot storage over years ------------ %
%   -Using 100% storage rate plot storage over time to see when storage
%   fills up
%   -Then, ask user to input % of emissions stored per year 
%   OR
%   -Ask user to enter increase in emissions stored per year (% increase)
%   plot storage and emissions over time


% ----------- Add in a rate of change in emissions -----------%
%   Ask user to input an emissions rate of change per year
%   -using that, and previous value of % emissions stored (or % increase
%   stored), plot storage and emissions over time to get a final idea of
%   how effective carbon sequestration will be at dealing with the
%   emissions problem.














