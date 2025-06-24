function handles=UpdatePlot(hObject,eventdata,handles)

%Get Variables
ArtifactPeakIndex=handles.Variables.PreArtifactWindowLengthIndices;
CurrentPositionChannel=handles.ChannelListBox.Value;
ChannelsOfInterest=handles.Variables.ChannelsOfInterest;
ChannelNames=handles.Variables.ChannelNames;
WindowStart=str2double(handles.WindowStartBox.String)/1000; %Put this into seconds for saving in data files
WindowEnd=str2double(handles.WindowEndBox.String)/1000; %Put this into seconds for saving in data files
WindowStartIndices=ArtifactPeakIndex+floor(WindowStart*handles.Variables.Fs);
WindowEndIndices=ArtifactPeakIndex+floor(WindowEnd*handles.Variables.Fs);

for ii=1:handles.Variables.NumStims
    StimLegend{ii}=strcat(num2str(handles.Variables.AllStims(ii)),' ','\muA');
end
%Plot on Axes
axes(handles.axes1)
cla(handles.axes1)
hold on
PlottingVariable=(ChoosePlotVariable(handles));
timepts=handles.Variables.timepts;
 
plot(1000.*timepts,squeeze(PlottingVariable(:,1,ChannelsOfInterest(CurrentPositionChannel),:)))
%plot(1000.*timepts,squeeze(PlottingVariable(:,ChannelsOfInterest(CurrentPositionChannel),:)).*1000)
xlim([WindowStart*1000 WindowEnd*1000]) %Put this into milliseconds for plotting
xlabel('Time (ms)');
if handles.CSDPlotBox.Value
ylabel('Current Source Density (V/mm^2)')    
else
ylabel('Voltage (V)')
end
if handles.PlotYLim.Value
    ylim([str2double(handles.yminBox.String)  str2double(handles.ymaxBox.String)])
else
    ylim auto
end
title({['Channel',' ',num2str(ChannelsOfInterest(CurrentPositionChannel)),',',' Channel Name=',ChannelNames{CurrentPositionChannel}]})
legend(StimLegend)
handles.Variables.CurrentPlottingWindowStart=WindowStart;
handles.Variables.CurrentPlottingWindowEnd=WindowEnd;
handles.Variables.CurrentPlottingWindowStartIndices=WindowStartIndices;
handles.Variables.CurrentPlottingWindowEndIndices=WindowEndIndices;
handles.Variables.CurrentlottingPositionChannel=CurrentPositionChannel;