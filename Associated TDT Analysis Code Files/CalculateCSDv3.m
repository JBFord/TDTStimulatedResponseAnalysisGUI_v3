function [CsdMat]=CalculateCSDv3(data,ElectrodeSpacing)

sp2=ElectrodeSpacing*ElectrodeSpacing;
CsdMat=-diff(diff(data,1,3),1,3)./sp2;

