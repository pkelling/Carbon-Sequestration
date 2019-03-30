function CreateMap(data,labels,titles,bubbleRange)
% Create a map of the input data
    
labels = ["Latitude", "Longitude", labels];
lat = data{1};
lng = data{2};
sizes = data{3};
    
if length(labels) == 3
   colorVar = '';
   dataTable = table(lat,lng,sizes);
else
    colorVar = labels(4);
    colors = categorical(data{4});
    dataTable = table(lat,lng,sizes,colors);
end

if length(titles) ~= 3
    titles(3) = 0;
end
    
    
% Setup for the map (create a table)
dataTable.Properties.VariableNames = labels;
                        
    
geobubble(dataTable, 1,2,...
        'SizeVariable',3,...
        'ColorVariable',colorVar,...
        'Title',titles(1),...
        'SizeLegendTitle',titles(2),...
        'ColorLegendTitle',titles(3),...
        'BubbleWidthRange',bubbleRange,...
        'ScaleBarVisible',false,...
        'GridVisible',false);
    
    

end

