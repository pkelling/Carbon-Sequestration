function [massCO2] = ConversionFunction(Vol,Denst)
%   Summary: To find the mass of CO2 storage from the given volume and
%   density by each location.

% Note- returns mass in lbs (lb-mass)

% Converting MMBBL to Cubic Meters
Vol = Vol * (10^6) .* 0.159;

% Calculating the mass of max CO2 storage
massCO2kg = Denst .* Vol;

% Convert to lbs
massCO2 = massCO2kg * 2.205; 

end

