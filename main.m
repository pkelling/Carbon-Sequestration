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

% TODO:
%   1) Validate User Input
%   2) Change to loop so you can select different states.
%   3) Make chart based on actual energy output, not percent of output
%       -This will help give a better idea of energy output differences
%       between states
%   4) Change colors so they match resource (coal->black, hydro->blue...)


choice = menu("Compare state energy sources?","Yes","No");
if choice == 1
    stateNum = listdlg('PromptString',"Please select state(s)", 'ListString',states);
       renew = menu("Would you like to compare renewable and nonrenewable sources", 'Yes', 'No');
        
        while stateNum == 1
            warning("Cannot compare a single state by itself. Please select more states");
            stateNum = listdlg('PromptString',"Please select state(s)", 'ListString',states);
        end
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


% -------- Find Storage Volume By State ------------ %

% TODO:
%   1) Convert Storage to lbs CO2 for each site
%   2) Get total lbs of storage for each state

%calculations
MINlbs = ConversionFunction(minStorageCapacity,Densities);
AVGlbs = ConversionFunction(likelyStorageCapacity,Densities); % [lbs] converting kg to lbs
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
    MAXstateStorage = [MAXstateStorage,(me3)];                         %creating vector of storage for states
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
choice = menu("View Storage By State",["Minimum Projection","Likely Projection","Maximum Projection","Next Step"]);

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

fprintf('%0.0f years will be required to completely fill the storage for min storage capacity.\n' , Time_Years_min);
fprintf('%0.0f years will be required to completely fill the storage for likely storage capacity.\n' , Time_Years_likely);
fprintf('%0.0f years will be required to completely fill the storage for max storage capacity.\n\n' , Time_Years_max);





% ----------- Add in a rate of change in emissions -----------%
%
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
subplot(2,1,1);
plot(N_Years,Total_EMISSION,'--r','LineWidth',2)

hold on 

plot(N_Years,S,'g','LineWidth',2)
grid on
%   Ask user to input an emissions rate of change per year
%   -using that, and previous value of % emissions stored (or % increase
%   stored), plot storage and emissions over time to get a final idea of
%   how effective carbon sequestration will be at dealing with the
%   emissions problem.



% ---------------------------------Part 3 - 2 Projection------------------------------------------ %
again = 1;
while again ==1
        inputUser = {'Enter expected CO2 storage percent per year [0% - 10%]: ','Enter storage capability growth rate percent [0% - 10%]: '};
        dlgtitle = 'Info';
        dmsion = [1 75];
        defaultInput = {'',''};
        % Output vector of user input
        outputBox = inputdlg(inputUser,dlgtitle,dmsion,defaultInput);
        % Convert cell value to double
        output_Box = str2double(outputBox);
        output_Box(1) = output_Box(1)/100;
        output_Box(2) = output_Box(2)/100;

        % msg of data validation
        reinputUser = {'Re-enter expected storage percent per year [0% - 10%]: ','Re-enter storage capability growth rate percent [0% - 10%]: '};

        % Data validation [0% - 10%] - While Loop
                % output_Box(1) = Enter expected CO2 storage percent per year [0% - 10%]
                % output_Box(2) = Enter storage capability growth rate percent [0% - 10%]
                % output_Box(3) = Enter base-line capacity storage [BBLML]
                while output_Box(1) < 0 || output_Box(1) > 10 || output_Box(2) < 0 || output_Box(2) > 10
                    % Output vector of user input
                    outputBox = inputdlg(inputUser,dlgtitle,dmsion,defaultInput);
                    % Convert cell value to double
                    output_Box = str2double(outputBox);
                    output_Box(1) = output_Box(1)/100;
                    output_Box(2) = output_Box(2)/100;
                end    
        rate_Growth_CO2 = output_Box(1)/100;  
        num_Year = length(N_Years);
        for u = 1:1:num_Year       
                % Calculate amount of CO2 stored with provided percentage
                Projected_StorageCO2(u) = totalEmissions(u) .* rate_Growth_CO2;
                rate_Growth_CO2 = rate_Growth_CO2 + output_Box(2);
                
        end    
        
        Projected_StorageCO2 = Projected_StorageCO2';
        Total_Projected_StorageCO2 = Projected_StorageCO2 + S;
        
        x_Axis = 1:1:num_Year;
        subplot(2,1,2);
        plot(x_Axis, Total_Projected_StorageCO2);
        xlabel('Year');
        ylabel('Emission');
        hold on
        plot(x_Axis, S);
        
%         % Comparison
%         if  new_Projected_Cap > stored_Projected_CO2
%             excess_Cap = new_Projected_Cap - stored_Projected_CO2;
%             msg_Out = sprintf('Extra storage capacity is %0.2f [BBBML]',excess_Cap);
% %           fprintf('The amount of capacity shortage is %0.2f [BBBML]',excess_Cap)
%         elseif new_Projected_Cap < stored_Projected_CO2
%             excess_Cap = abs(new_Projected_Cap - stored_Projected_CO2);
%             msg_Out  = sprintf('The amount of capacity shortage is %0.2f [BBBML]',excess_Cap);
% %           fprintf('The amount of capacity shortage is %0.2f [BBBML]',excess_Cap);
%         elseif new_Projected_Cap == stored_Projected_CO2
%             excess_Cap = 0;
%             msg_Out = sprintf('The amount of capacity is the same as projected CO2 can be stored');
%         end    

%          fprintf('The amount of capacity shortage is %0.2f [BBBML]',excess_Cap);
%          tot_expected_Stored = abs(new_Projected_Cap - stored_Projected_CO2);

%         h=msgbox('Calculation Completed',...
%                  msg_Out,'custom',icondata,iconcmap);
%         [addIcon] = imread('mitbeccsflat.jpg'); 
        
        % Repeat request
        rep = menu('Do you want to repeat?', 'Yes', 'No');
        if rep == 1
        elseif rep == 2
          again =2;
        end


end

