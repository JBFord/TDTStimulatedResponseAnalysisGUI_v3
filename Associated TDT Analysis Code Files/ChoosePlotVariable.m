function PlottingVariable=ChoosePlotVariable(handles)
%Determine which Variable to plot (Raw, BP60, or Mult) and whether to plot
%the filtered and/or CSD of these channels
% handles.Variables.PlotFilteredBox.Value=0;

if ~isfield(handles.Variables,'CurrentPlottingVariable')
    handles.Variables.CurrentPlottingVariable=1;
end
switch handles.Variables.CurrentPlottingVariable
    
    case 1 %Raw Data
        if handles.CSDPlotBox.Value
            if handles.PlotFilteredBox.Value
                PlottingVariable=handles.Variables.FilteredRawcsd;
            else
                PlottingVariable=handles.Variables.Rawcsd;
            end
        else
            if handles.PlotFilteredBox.Value
                PlottingVariable=handles.Variables.FilteredRawAverageOverSweeps;
            else
                PlottingVariable=handles.Variables.RawAverageOverSweeps;
            end
        end
        
        
        
    case 2 %BP60 data
        
        if handles.CSDPlotBox.Value
            if handles.PlotFilteredBox.Value
                PlottingVariable=handles.Variables.FilteredBP60csd;
            else
                PlottingVariable=handles.Variables.BP60csd;
            end
        else
            if handles.PlotFilteredBox.Value
                PlottingVariable=handles.Variables.FilteredBP60AverageOverSweeps;
            else
                PlottingVariable=handles.Variables.BP60AverageOverSweeps;
            end
        end
        
    case 3 % Mult Data
        if handles.CSDPlotBox.Value
            if handles.PlotFilteredBox.Value
                PlottingVariable=handles.Variables.FilteredMultcsd;
            else
                PlottingVariable=handles.Variables.Multcsd;
            end
        else
            if handles.PlotFilteredBox.Value
                PlottingVariable=handles.Variables.FilteredMultAverageOverSweeps;
            else
                PlottingVariable=handles.Variables.MultAverageOverSweeps;
            end
        end
        
end