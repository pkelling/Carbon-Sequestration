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

% TODO:
% Maybe do:
%   1) experiment with initial map size on different computers

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

% TODO:
%   1) Change sizes of bubbles so scale is same for every power source.
%   2) fire warning if user makes no choice and closes window
%   3) add escape for exit loop


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





% ---------- States Side by Side comparison ------------- %

% TODO:
%   1) **Validate User Input**
%   2) Change to loop so you can select different states.
%   3) Make chart based on actual energy output, not percent of output
%       -This will help give a better idea of energy output differences
%       between states
% maybe do:
%   1) Change colors so they match resource (coal->black, hydro->blue...)
%   2) 

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

Volumes = numbers(1:272,14);
Densities = numbers(1:272,22);

% -- Validate Data 

% Remove lines where Volume is Nan (they were blank lines)
blankLines = find(isnan(Volumes));
Volumes(blankLines) = [];
Densities(blankLines) = [];
stateWithStorage(blankLines,:) = [];
percentInState(blankLines,:) = [];



% -------- Find Storage Volume By State ------------ %

% TODO:
%   1) Convert Storage to lbs CO2 for each site
%   2) Get total lbs of storage for each state



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
%%
Growth_rate= input('Enter a percent change of CO2 emission per year between (-5)-5%:  ');

while  Growth_rate < -5 || Growth_rate > 5 
    warning(sprintf('You entered %0.2f, Please consider entering a value between (-5)-5%',Growth_rate))
    Growth_rate= input('Enter a percent change of CO2 emission per year between (-5)-5%:   ');
end 

N_Years= input('Enter the number of years for the projection:');

while N_Years <= 0
    warning(sprintf('You entered %0.0f, Please consider entering a value greater than zero',N_Years))
    N_Years= input('Enter the number of years for the projection:');
end 

Growth_rate= Growth_rate/100+1;
N_Years= 1:N_Years;

S=[];
S_Y=[]
SUM_EMISSION= sum(totalEmissions )
for i= 1:length(N_Years)

Proj= Growth_rate * SUM_EMISSION* N_Years(i);

S=[S;Proj]

end 

Total_EMISSION=ones(length(N_Years))* SUM_EMISSION
plot(N_Years,Total_EMISSION,'--r','LineWidth',2)

hold on 

plot(N_Years,S,'g','LineWidth',2)
grid on
%   Ask user to input an emissions rate of change per year
%   -using that, and previous value of % emissions stored (or % increase
%   stored), plot storage and emissions over time to get a final idea of
%   how effective carbon sequestration will be at dealing with the
%   emissions problem.














