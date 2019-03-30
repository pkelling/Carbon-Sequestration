function bubbleScale = calcBubbleSize(energyBySource,currSource)
% Calculates bubble size so sizes are more consistent across sources


totalMax = max(max(energyBySource));
currMax = max(energyBySource(:,currSource));

% convert totalMin-totalMax scale to a scale of [1:25]
divisor = totalMax / 25;
maxVal = currMax / divisor;

%improve scale (still not perfect, but better)
%maxVal = maxVal + (25/maxVal);

if maxVal < 3
    maxVal = 3;
end

bubbleScale = [1,maxVal];
end

