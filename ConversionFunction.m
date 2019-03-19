function [massCO2] = ConversionFunction(Vol,Denst)
%   Summary: To find the mass of CO2 storage from the given volume and
%   density by each location.
Vol = (1:1:10)';
Denst = (0.1:0.1:1)';

% Converting MMBBL to Cubic Meters
Vol = Vol* 10.^6 .* 0.159;

% Calculating the mass of max CO2 storage
massCO2 = Denst .* Vol;

end

