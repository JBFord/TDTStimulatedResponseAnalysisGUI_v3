function BatchAnalyzeFcn(handles,ImportFile,NameFile,WindowFile)


%Load Data
temp.Variables=SavedImportedData;

%Load Names
load(NameFile)
handles.Variables.ChannelNames=SavedNames.Variables.ChannelNames;
handles.Variables.PeakIsNeg=SavedNames.Variables.PeakIsNeg;
handles.Variables.AreaIsNeg=SavedNames.Variables.AreaIsNeg;
handles.Variables.AreaIsPos=SavedNames.Variables.AreaIsPos;

%Load Windows
load(WindowFile)
handles.Variables.AllWindowStart=SavedWindows.Variables.AllWindowStart;
handles.Variables.AllWindowEnd=SavedWindows.Variables.AllWindowEnd;
handles.Variables.WindowDefinitionCompleted=SavedWindows.Variables.WindowDefinitionCompleted;
handles.Variables.AllWindowStartIndices=SavedWindows.Variables.AllWindowStartIndices;
handles.Variables.AllWindowEndIndices=SavedWindows.Variables.AllWindowEndIndices;




%Calculate peak of signal within windows
if handles.PeakBox.Value
    handles.Variables.Flags.PeakAnalyzed=1;
    if AnalyzeLFPs
        if RunRaw
            if RunFiltered
                handles.Variables.Results.RawLFPPeaks=PeakAnalysis_v2(handles,handles.Variables.FilteredRawAverageOverSweeps);
            else
                handles.Variables.Results.RawLFPPeaks=PeakAnalysis_v2(handles,handles.Variables.RawAverageOverSweeps);
            end
        end
        
        if RunBP60
            if RunFiltered
                handles.Variables.Results.BP60LFPPeaks=PeakAnalysis_v2(handles,handles.Variables.FilteredBP60AverageOverSweeps);
            else
                handles.Variables.Results.BP60LFPPeaks=PeakAnalysis_v2(handles,handles.Variables.BP60AverageOverSweeps);
            end
        end
        
        if RunMult
            if RunFiltered
                handles.Variables.Results.MultLFPPeaks=PeakAnalysis_v2(handles,handles.Variables.FilteredMultAverageOverSweeps);
            else
                handles.Variables.Results.MultLFPPeaks=PeakAnalysis_v2(handles,handles.Variables.MultAverageOverSweeps);
            end
        end
        
    end
    
    if AnalyzeCSDs
        if RunRaw
            if RunFiltered
                handles.Variables.Results.RawCSDPeaks=PeakAnalysis_v2(handles,handles.Variables.FilteredRawcsd);
            else
                handles.Variables.Results.RawCSDPeaks=PeakAnalysis_v2(handles,handles.Variables.Rawcsd);
            end
        end
        
        if RunBP60
            if RunFiltered
                handles.Variables.Results.BP60CSDPeaks=PeakAnalysis_v2(handles,handles.Variables.FilteredBP60csd);
            else
                handles.Variables.Results.BP60CSDPeaks=PeakAnalysis_v2(handles,handles.Variables.BP60csd);
            end
        end
        
        if RunMult
            if RunFiltered
                handles.Variables.Results.MultCSDPeaks=PeakAnalysis_v2(handles,handles.Variables.FilteredMultcsd);
            else
                handles.Variables.Results.MultCSDPeaks=PeakAnalysis_v2(handles,handles.Variables.Multcsd);
            end
        end
        
    end
end

%Calculate AUC of signal within windows
if handles.AreaBox.Value
    handles.Variables.Flags.AreaAnalyzed=1;
    
    
    
    if AnalyzeLFPs
        if RunRaw
            if RunFiltered
                handles.Variables.Results.RawLFPAUC=AreaAnalysis_v2(handles,handles.Variables.FilteredRawAverageOverSweeps);
            else
                handles.Variables.Results.RawLFPAUC=AreaAnalysis_v2(handles,handles.Variables.RawAverageOverSweeps);
            end
        end
        
        if RunBP60
            if RunFiltered
                handles.Variables.Results.BP60LFPAUC=AreaAnalysis_v2(handles,handles.Variables.FilteredBP60AverageOverSweeps);
            else
                handles.Variables.Results.BP60LFPAUC=AreaAnalysis_v2(handles,handles.Variables.BP60AverageOverSweeps);
            end
        end
        
        if RunMult
            if RunFiltered
                handles.Variables.Results.MultLFPAUC=AreaAnalysis_v2(handles,handles.Variables.FilteredMultAverageOverSweeps);
            else
                handles.Variables.Results.MultLFPAUC=AreaAnalysis_v2(handles,handles.Variables.MultAverageOverSweeps);
            end
        end
        
    end
    
    if AnalyzeCSDs
        if RunRaw
            if RunFiltered
                handles.Variables.Results.RawCSDAUC=AreaAnalysis_v2(handles,handles.Variables.FilteredRawcsd);
            else
                handles.Variables.Results.RawCSDAUC=AreaAnalysis_v2(handles,handles.Variables.Rawcsd);
            end
        end
        
        if RunBP60
            if RunFiltered
                handles.Variables.Results.BP60CSDAUC=AreaAnalysis_v2(handles,handles.Variables.FilteredBP60csd);
            else
                handles.Variables.Results.BP60CSDAUC=AreaAnalysis_v2(handles,handles.Variables.BP60csd);
            end
        end
        
        if RunMult
            if RunFiltered
                handles.Variables.Results.MultCSDAUC=AreaAnalysis_v2(handles,handles.Variables.FilteredMultcsd);
            else
                handles.Variables.Results.MultCSDAUC=AreaAnalysis_v2(handles,handles.Variables.Multcsd);
            end
        end
        
    end
        
end

ResultsData=handles.Variables.Results;
%Need to make folder to save everything in
SaveName=strcat(handles.Variables.SaveFolder,filesep,'AnalysisResults.mat');
save(SaveName,'ResultsData','-v7.3')

ExportAllResults_v2(handles);