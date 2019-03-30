clear all;
close all;
clc;


% ----------- Load Emissions Data --------------%
%          And Extract Useful Information
%
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


%list of renewable, nonrenewable, and unknown resources
nonrenewableSources = sum(stateResourceMix(1:51, 3:6));
renewableSources = sum(stateResourceMix(1:51, 7:12));
unknownSources = stateResourceMix(1:51, 13);

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
%   1) Make another section for renewable

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
        
        barh(categorical(states(stateNum)),energyBySource(stateNum,:),'stacked');
        legend(powerSources);
        title("Emissions sources by state");
        xlabel("Enegery Generated per Resource [MWh]");
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
minStorageCapacity = numbers(1:272,13);
likelyStorageCapacity = numbers(1:272,14);
maxStorageCapacity = numbers(1:272,15);

Volumes = numbers(1:272,14);
Densities = numbers(1:272,22);

% -- Validate Data 

% Remove lines where Volume is Nan (they were blank lines)
blankLines = find(isnan(Volumes));
Volumes(blankLines) = [];
Densities(blankLines) = [];
stateWithStorage(blankLines,:) = [];
percentInState(blankLines,:) = [];
minStorageCapacity(blankLines) = [];
likelyStorageCapacity(blankLines) = [];
maxStorageCapacity(blankLines) = [];

% -------- Find Storage Volume By State ------------ %

% TODO:
%   1) Convert Storage to lbs CO2 for each site
%   2) Get total lbs of storage for each state

%calculations
%m = D.*v
mass = Densities.*likelyStorageCapacity.*6.28981; % [kg] mult. density by MMbbl converted to m^3
AVGlbs = mass.*2.20462; % [lbs] converting kg to lbs 

%m = D.*v
mass = Densities.*minStorageCapacity.*6.28981; % [kg] mult. density by MMbbl converted to m^3
MINlbs = mass.*2.20462; % [lbs] converting kg to lbs 

%m = D.*v
mass = Densities.*maxStorageCapacity.*6.28981; % [kg] mult. density by MMbbl converted to m^3
MAXlbs = mass.*2.20462; % [lbs] converting kg to lbs 

[rowx,coly] = size(stateWithStorage);

%Correcting mispelled state names
for i = 1:rowx
    for j = 1:coly
        if stateWithStorage(i,j) == 'Utah '
            stateWithStorage(i,j) = 'Utah';
        end
        if stateWithStorage(i,j) == 'Pensylvania'
            stateWithStorage(i,j) = 'Pennsylvania';
        end
    end
end

help = unique(stateWithStorage); %assembling vector with all unique state names
help(cellfun('isempty',help)) = [];
percentInState(isnan(percentInState)) = 0; %changing NaN elements into 0 in order to perform operations

me1 = 0;
me2 = 0;
me3 = 0;
MINstateStorage = [];
AVGstateStorage = [];
MAXstateStorage = [];
for k = 1:length(help)
    [ex,why] = find(stateWithStorage == help(k)); %using find function to find [row,col] in order to index
    for p = 1:length(ex)
        me1 = me1 +(MINlbs(ex(p),1).*(percentInState(ex(p),(why(p))))/100); %getting total storage for state(k)
        me2 = me2 +(AVGlbs(ex(p),1).*(percentInState(ex(p),(why(p))))/100); %getting total storage for state(k)
        me3 = me3 +(MAXlbs(ex(p),1).*(percentInState(ex(p),(why(p))))/100); %getting total storage for state(k)
    end
    MINstateStorage = [MINstateStorage,(me1)];
    AVGstateStorage = [AVGstateStorage,(me2)];
    MAXstateStorage = [MAXstateStorage,(me3)];                         %creating vector of storage for states
    me1 = 0;
    me2 = 0;
    me3 = 0; %reseting in order to calc. total of next state
end
 
mapMIN = containers.Map(help,MINstateStorage); %assigning states with their respective total storage capacity
mapAVG = containers.Map(help,AVGstateStorage); %assigning states with their respective total storage capacity
mapMAX = containers.Map(help,MAXstateStorage); %assigning states with their respective total storage capacity

% %12-2 office hours

% ------------ Map lbs storage by state ------------- %
%           Along with lbs emissions ????
%   Possible: select between 3 maps: min, M likely, and max storage?

shortStatesAbbr = ["AL";"AK";"AR";"CA";"CO";"FL";"GA";"ID";"IL";"IN";"KS";"KY";"LA";"MD";"MI";"MS";"MO";"MT";"NE";"NJ";"NM";"NY";"NC";"ND";"OH";"OK";"OR";"PA";"SC";"SD";"TX";"UT";"VA";"WA";"WV";"WY"];
shortStatesNames = help;
storeLats = [];
storeLngs = [];

for i = 1:length(shortStatesNames)
   locInStatesVar = find( strcmpi(states, shortStatesAbbr));
   storeLats = [storeLats, lat(locInStatesVar)];
   storeLngs = [storeLngs, lng(locInStatesVar)];
end


% Setup for the map
data = {storeLats, storeLngs, AVGstateStorage};
labels = ["LbsStorage"];
titles = ["Lbs Storage For Each State", "Storage [lbs CO2]"];

CreateMap(data,labels,titles,[4,25]);

% ------------ Map lbs storage by state ------------- %





% ----------- Calculate storage over years ------------ %
%   -Using 100% storage rate plot storage over time to see when storage
%   fills up
%   -Then, ask user to input % of emissions stored per year 
%   OR
%   -Ask user to enter increase in emissions stored per year (% increase)
%   plot storage and emissions over time



% ----------- Add in a rate of change in emissions -----------%
%
Growth_rate= input('Enter a percent change of CO2 emission per year between (-5)-5%:  ');




while  Growth_rate < -5 || Growth_rate > 5 
    warning(sprintf('You entered %0.2f, Please consider entering a value between (-5)-5%',Growth_rate));
    Growth_rate= input('Enter a percent change of CO2 emission per year between (-5)-5%:   ');
end 

N_Years= input('Enter the number of years for the projection:');

while N_Years <= 0
    warning(sprintf('You entered %0.0f, Please consider entering a value greater than zero',N_Years));
    N_Years= input('Enter the number of years for the projection:');
end 

Growth_rate= Growth_rate/100+1;
N_Years= 1:N_Years;

S=[];
S_Y=[];
SUM_EMISSION= sum(totalEmissions );
for i= 1:length(N_Years)

Proj= Growth_rate * SUM_EMISSION* N_Years(i);

S=[S;Proj];

end 

Total_EMISSION=ones(length(N_Years))* SUM_EMISSION;
plot(N_Years,Total_EMISSION,'--r','LineWidth',2)

hold on 

plot(N_Years,S,'g','LineWidth',2)
grid on
%   Ask user to input an emissions rate of change per year
%   -using that, and previous value of % emissions stored (or % increase
%   stored), plot storage and emissions over time to get a final idea of
%   how effective carbon sequestration will be at dealing with the
%   emissions problem.














