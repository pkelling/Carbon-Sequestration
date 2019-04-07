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

% List of power Sources
powerSources = labels(3,4:14);
renewSources = ["Renewable", "Nonrenewable", "Other Unknown/Purchased Fuel"];

% Power sources percentages
sourcePercent = stateResourceMix(1:51,3:end);

% Total energy for each state [MWh]
energyTotals = stateResourceMix(1:51,2);

% Energy consumption by source for each state
energyBySource = energyTotals .* sourcePercent;

%Emissions totals for each state
totalEmissions = energyTotals .* emissionsFactors;

%list of renewable, nonrenewable, and unknown resources
renewableSources = energyTotals .* sum((stateResourceMix(1:51, 7:12)),2);
nonrenewableSources = energyTotals .* sum((stateResourceMix(1:51, 3:6)),2);
unknownSources = energyTotals .* stateResourceMix(1:51, 13);
groupSources = [renewableSources, nonrenewableSources, unknownSources];




% ----------- Load in statesCenters data ---------------- %
latlng = xlsread("statesCenters.xlsx");
lat = latlng(:,1);
lng = latlng(:,2);



% This makes the initial map larger
figh = figure(1);
pos = get(figh,'position');
set(figh,'position',[pos(1:2)/2 pos(3:4)*1.5])



repeatWholeProgram = true;
while(repeatWholeProgram)

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

source = menu("View a particular power source?", ['Move to Next Step',powerSources]);

% Validate selection
if(source == 0)
    warning("No option selected, moving to next step");
end


while(source > 1)
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

choice = menu("Compare states energy sources?","Yes","No");
while choice == 1
    stateNum = listdlg('PromptString',"Please select states", 'ListString',states);
        
    while length(stateNum) == 1
        warning("Cannot compare a single state by itself. Please select more states");
        stateNum = listdlg('PromptString',"Please select state(s)", 'ListString',states);
    end

    renew = menu("Compare renewables and nonrenewables or all sources?", 'Renewables/Nonrenewables', 'All Sources');    
    if(~isempty(stateNum)) && renew == 1
        barh(categorical(states(stateNum)),groupSources(stateNum,:),'stacked');
        legend(renewSources);
        title("Energy Generation by Sources Per State");
        xlabel("Energy Generated per Resource [MWh]");
        ylabel("State");
    elseif(~isempty(stateNum)) && renew == 2
        barh(categorical(states(stateNum)),energyBySource(stateNum,:),'stacked');
        legend(powerSources);
        title("Energy Generation by Sources Per State");
        xlabel("Energy Generated per Resource [MWh]");
        ylabel("State");
    else
        warning("No state selected, moving to next step.");
    end
    
    choice = menu("Compare different states energy sources?","Yes","No");
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

volumesMin = numbers(1:272,13);
volumesMax = numbers(1:272,15);
densitiesMin = numbers(1:272,21);
densitiesMax = numbers(1:272,23);


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

volumesMin(blankLines) = [];
volumesMax(blankLines) = [];
densitiesMin(blankLines) = [];
densitiesMax(blankLines) = [];


% -------- Find Storage Volume By State ------------ %


%calculations (Note, this doesn't consider the density variations
%   which are small but not completely insignificant);
AVGlbs = ConversionFunction(likelyStorageCapacity,Densities); % [lbs] converting kg to lbs 
MINlbs = ConversionFunction(minStorageCapacity,Densities);
MAXlbs = ConversionFunction(maxStorageCapacity,Densities); % [lbs] converting kg to lbs 

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
    MAXstateStorage = [MAXstateStorage,(me3)];      %creating vector of storage for states
    me1 = 0;
    me2 = 0;
    me3 = 0; %reseting in order to calc. total of next state
end


% ------------ Map lbs storage by state ------------- %

shortStatesAbbr = ["AL";"AK";"AR";"CA";"CO";"FL";"GA";"ID";"IL";"IN";"KS";"KY";"LA";"MD";"MI";"MS";"MO";"MT";"NE";"NJ";"NM";"NY";"NC";"ND";"OH";"OK";"OR";"PA";"SC";"SD";"TX";"UT";"VA";"WA";"WV";"WY"];
shortStatesNames = help;
storeLats = [];
storeLngs = [];

for i = 1:length(shortStatesNames)
   locInStatesVar = find( strcmpi(states, shortStatesAbbr(i)));
   storeLats = [storeLats; lat(locInStatesVar)];
   storeLngs = [storeLngs; lng(locInStatesVar)];
end

% Setup for the map
stateStorage = [MINstateStorage', AVGstateStorage', MAXstateStorage'];      
choice = menu("View CO2 Storage By State",["Minimum Estimated","Likely Estimated","Maximum Estimated","Next Step"]);

while(choice ~= 0 && choice ~= 4)
    data = {storeLats, storeLngs, stateStorage(:,choice)};
    labels = ["LbsStorage"];
    titles = ["Lbs Storage For Each State", "Storage [lbs CO2]"];
    CreateMap(data,labels,titles,[4,25]);
    choice = menu("View Storage By State",["Minimum Projection","Likely Projection","Maximum Projection","Next Step"]);
end



%------------ find the number of year to store 100 % of U.S emission -------------- %

% the total U.S emission per year [lb/year]
emission_US = sum(totalEmissions);

% the total U.S storage [lb]
Storage_US_likely = sum(ConversionFunction(Volumes,Densities));
Storage_US_min = sum(ConversionFunction(volumesMin,densitiesMin));
Storage_US_max = sum(ConversionFunction(volumesMax,densitiesMax));

%Number of years required to store the U.S emission
Time_Years_likely = Storage_US_likely / emission_US;
Time_Years_min = Storage_US_min / emission_US;
Time_Years_max = Storage_US_max / emission_US;

fprintf('%0.0f years will be required to completely fill the storage for min estimated storage capacity.\n' , Time_Years_min);
fprintf('%0.0f years will be required to completely fill the storage for likely storage capacity.\n' , Time_Years_likely);
fprintf('%0.0f years will be required to completely fill the storage for max estimated storage capacity.\n\n' , Time_Years_max);




% ----------- Projections for CO2 Emissions -----------%

repeatEmissions = true;
while repeatEmissions

    Growth_rate= input('Enter a percent change of CO2 emission per year between -5% and +5%: ');

    while  Growth_rate < -5 || Growth_rate > 5 
        warning(sprintf('You entered %0.2f, Please enter a value between -5% and +5%: ',Growth_rate));
        Growth_rate= input('Enter a percent change of CO2 emission per year between -5% and +5%: ');
    end 

    N_Years= input('Enter the number of years for the projection: ');

    while N_Years <= 0
        warning(sprintf('You entered %0.0f, Please enter a value greater than zero: ',N_Years));
        N_Years= input('Enter the number of years for the projection: ');
    end 

    Growth_rate= Growth_rate/100+1;
    N_Years= 1:N_Years;

    S=[];
    S_Y=[];
    S(1) = sum(totalEmissions);
    for i= 2:length(N_Years)
        Proj= Growth_rate * S(i-1);
        S= [S;Proj];
    end



    % --------------------------- Projections for CO2 Emissions and Storage --------------------------%

    openPlot = 1;
    again = 1;
    while again == 1
        inputUser = {'Enter starting CO2 capture per year as percent of emissions [0% < num < 2%]: ',...
                    'Enter multiplication factor to represent increase in use of carbon capture technologies [1 < num < 5]: '};
        dlgtitle = 'Carbon Capture Inputs';
        dmsion = [1 110];
        defaultInput = {'',''};
        
        % Output vector of user input
        outputBox = inputdlg(inputUser,dlgtitle,dmsion,defaultInput);
        
        % Convert cell value to double
        output_Box_value = str2double(outputBox);
             
        % msg of data validation
        reinputUser = {'Re-enter starting CO2 capture percent [ 0% < num < 2%]: ',...
                    'Re-enter factor for increase in use of carbon capture [1 < num < 5]: '};
 
        % Data validation - While Loop
        while isempty(output_Box_value) || output_Box_value(1) <= 0 || output_Box_value(1) > 2 || output_Box_value(2) <= 1 || output_Box_value(2) >= 5
            % Output vector of user input
            outputBox = inputdlg(inputUser,dlgtitle,dmsion,defaultInput);
            % Convert cell value to double
            output_Box_value = str2double(outputBox);
        end
        
        captureRate_CO2 = output_Box_value(1)/100;
        multFactor = output_Box_value(2);
        
        num_Year = length(N_Years); 
        startingCapture = captureRate_CO2 * S(1);
        total_Storage_Cap = Storage_US_likely;
        Total_Projected_Capture_CO2 = 0;
        
        Projected_Capture_StorageCO2(1) = startingCapture;
        Total_Captured_CO2 = startingCapture;
        emissions_Not_Captured(1) = S(1) - startingCapture;
        
        for u = 2:num_Year       
                % Calculate amount of CO2 stored for each year
                co2Stored = Projected_Capture_StorageCO2(u-1) * multFactor;

                if(co2Stored > S(u))
                    % 100% of emissions captured
                    co2Stored = S(u);
                end
                
                if(Total_Captured_CO2 + co2Stored > total_Storage_Cap)
                    % Ran out of Storage
                    co2Stored = total_Storage_Cap - Total_Captured_CO2;
                end
                    
                Projected_Capture_StorageCO2(u) = co2Stored;
                emissions_Not_Captured(u) = S(u) - co2Stored;
                Total_Captured_CO2 = Total_Captured_CO2 + co2Stored;
        end
        
        
       % Get data for pie chart
        percent_Storage = Total_Captured_CO2 / total_Storage_Cap;
        if( percent_Storage >= 1)
            percent_Storage = .99999;
        end
        pie_data = [percent_Storage, (1-percent_Storage)];

        
        % bring new figure to front
        if( openPlot == 1)
            figh = figure(2);
            pos = get(figh,'position');
            set(figh,'position',[pos(1:2)/2 pos(3:4)*1.5])
            openPlot = 0;
        end
        
        % Plot the graph
        subplot(2,1,1)
        x_Axis = 1:num_Year;
        y_Axis = [Projected_Capture_StorageCO2(1:num_Year)', emissions_Not_Captured(1:num_Year)'];
        fig2 = bar(x_Axis, y_Axis, 'stacked');

        xlim auto;          ylim auto
        xlabel('Year');     ylabel('Emissions [Lbs]');
        title('Total Projection CO2 Capture & Emission By Year');
        legend(fig2,{'Captured CO2','Uncaptured CO2'},'Location', 'Best');
        %grid on
        
        
        % Plot Pie Chart
        subplot(2,1,2)
        labels = {'CO2 Captured','Remaining Storage'};
        pie(pie_data,labels);
        tlt = sprintf('Total CO2 Emission Captured Versus Storage Capacity');
        title(tlt);


        % Repeat request
        rep = menu('Do you want to repeat projections?', 'Yes, with new emissions', 'Yes, with same emissions','No');

        if rep == 3 || rep == 0
            again = 2;
            repeatEmissions = false;
        elseif rep == 1
            again = 2;
        end


    end
    
    if repeatEmissions == false
        close(figh);
    end
    
end
 

    choice = menu('Do you want to repeat the program?', 'Yes','Exit');
    if choice == 0 || choice == 2
        repeatWholeProgram = false;
    end
    
%whole while loop
end
