function BatchImportTDTData_Parallel(BatchVariables,hObject,eventdata,handles,parentFolder,BaseName)
BatchVariables.Flags.ImportVersion='v2.1';
BatchVariables.Flags.BatchImported=1;

ImportBP60=BatchVariables.Flags.ImportBP60;
ImportMult=BatchVariables.Flags.ImportMult;

%% Use already selected folders


cd(parentFolder)
FolderContents=dir;
AnalysisFolderexists=0;
for pp=1:length(FolderContents)
    if strcmp(FolderContents(pp).name,'AnalysisGUIResults')
        AnalysisFolderexists=1;
        break
    end
end
if ~AnalysisFolderexists
    mkdir('AnalysisGUIResults')
end
if ~isfield(BatchVariables,'SaveFolder')
    BatchVariables.SaveFolder=strcat(parentFolder,'AnalysisGUIResults');
end
% BatchVariables.SaveFolder=strcat(parentFolder,filesep,'AnalysisGUIResults');

% h=waitbar(0,'Importing: 0% Complete');
WindowLength=BatchVariables.SweepChopDuration; %sec
% PreArtifactWindow=0.005; %sec
PreArtifactWindow=WindowLength*0.005; %sec
PostArtifactWindow=WindowLength-PreArtifactWindow;

FilterFlag=handles.FilterCheckBox.Value;
BatchVariables.Flags.ImportFilterFlag=FilterFlag;
%% Import LFPs
%Get first values of everything
LoadName=strcat(BaseName,num2str(1));
data=SEV2mat(LoadName,'EventName','Raws');
Fs=data.Raws.fs;
dt=1/Fs;
WindowIndices=floor(WindowLength*Fs);
PreWindowIndices=floor(PreArtifactWindow*Fs);
PostWindowIndices=WindowIndices-PreWindowIndices;

parfor iStim=1:BatchVariables.NumStims
    % -Goal of loading in all data for all channels, stims, and sweeps
    % -Assumes the base name for the initial path loaded is the same for every
    %folder, and the value at the end iterates
    % -All data will be stored in the BatchVariables AllRaw, AllBP60, etc. with the
    % dimensions being Stim x Sweep x Channel
    %     waitbar((iStim-1)/BatchVariables.NumStims,h,strcat('Importing :',num2str(100*(iStim-1)/BatchVariables.NumStims),'% Complete'));
    iBatchVariables=BatchVariables;
    %Load in data
    LoadName=strcat(BaseName,num2str(iStim));
    %     data=TDTbin2mat(LoadName);
    data=SEV2mat(LoadName,'EventName','Raws');
    
    %Make time vector
    %     Fs=data.Raws.fs;
    %     dt=1/Fs;
    TraceTime=[0:dt:dt*(length(data.Raws.data(1,:))-1)];
    
    %Determine when sweeps start
    Epocs=TDTbin2mat(LoadName,'TYPE',{'epocs'});
    SweepStarts=Epocs.epocs.EpcV.onset;
    SweepStartIndices=round(SweepStarts.*Fs);
    
    %Define window around the artifact that is chopped
    %     WindowIndices=floor(WindowLength*Fs);
    %     PreWindowIndices=floor(PreArtifactWindow*Fs);
    %     PostWindowIndices=WindowIndices-PreWindowIndices;
    
    %%%%%%%% Raw Data Parsing
    Raw=data.Raws.data;
    RawArtifactLocations=BatchFindArtifacts(iBatchVariables,Raw,PostWindowIndices,Fs,SweepStartIndices,iStim);
    
    %     if iStim == 8
    %         keyboard
    %     end
    %Chop up into sweeps base on artifact timing
    [RawSweeps,RawSweepTime]=ParseTDTDatav2(Raw,iBatchVariables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,RawArtifactLocations);
    
    %Combine all sweeps across stims into a single variable
    AllRaw(iStim,:,:,:)=permute(RawSweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
    AllRawTime(iStim,:,:,:)=permute(RawSweepTime,[4 1 3 2]);
    AllRawArtifactLocations(iStim,:)=RawArtifactLocations;
    
    %FilterData
    
    if FilterFlag
        %         clear FilteredRaw
        %         BatchVariables.ImportFilterFlag=1;
        HP=str2double(handles.HPText.String);
        LP=str2double(handles.LPText.String);
        %         BatchVariables.HighPassFilter=HP;
        %         BatchVariables.LowPassFilter=LP;
        FilteredRaw=zeros(iBatchVariables.NumChannels,size(Raw,2));
        for jj=1:iBatchVariables.NumChannels
            FilteredRaw(jj,:)=transpose(filtfilt2((Raw(jj,:)),HP,LP,Fs, 1));
        end
        
        FilteredRawArtifactLocations=BatchFindArtifacts(iBatchVariables,FilteredRaw,PostWindowIndices,Fs,SweepStartIndices,iStim);
        [FilteredRawSweeps,FilteredRawSweepTime]=ParseTDTDatav2(FilteredRaw,iBatchVariables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,FilteredRawArtifactLocations);
        
        %Combine all sweeps across stims into a single variable
        AllFilteredRaw(iStim,:,:,:)=permute(FilteredRawSweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        AllFilteredRawArtifactLocations(iStim,:)=FilteredRawArtifactLocations;
    end
    
    
    %%%%%%%% BP60 Data Parsing
    if ImportBP60
        BP60data=SEV2mat(LoadName,'EventName','BP60');
        BP60=BP60data.BP60.data;
        [BP60Sweeps,BP60SweepTime]=ParseTDTDatav2(BP60,iBatchVariables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,RawArtifactLocations);
        AllBP60(iStim,:,:,:)=permute(BP60Sweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        AllBP60Time(iStim,:,:,:)=permute(BP60SweepTime,[4 1 3 2]);
        
        
        %FilterData
        if FilterFlag
            %             clear FilteredBP60
            %             HP=BatchVariables.HighPassFilter;
            %             LP=BatchVariables.LowPassFilter;
            FilteredBP60=zeros(iBatchVariables.NumChannels,size(BP60,2));
            for jj=1:iBatchVariables.NumChannels
                FilteredBP60(jj,:)=transpose(filtfilt2((BP60(jj,:)),HP,LP,Fs, 1));
            end
            
            %Chop up sweeps
            [FilteredBP60Sweeps,FilteredBP60SweepTime]=ParseTDTDatav2(FilteredBP60,iBatchVariables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,FilteredRawArtifactLocations);
            
            %Combine all sweeps across stims into a single variable
            AllFilteredBP60(iStim,:,:,:)=permute(FilteredBP60Sweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        end
    end
    
    %%%%%%%% Mult Data Parsing
    if ImportMult
        Multdata=SEV2mat(LoadName,'EventName','Mult');
        Mult=Multdata.Mult.data;
        [MultSweeps,MultSweepTime]=ParseTDTDatav2(Mult,iBatchVariables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,RawArtifactLocations);
        AllMult(iStim,:,:,:)=permute(MultSweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        AllMultTime(iStim,:,:,:)=permute(MultSweepTime,[4 1 3 2]);
        
        %FilterData
        if FilterFlag
            %             clear FilteredMult
            %             HP=BatchVariables.HighPassFilter;
            %             LP=BatchVariables.LowPassFilter;
            FilteredMult=zeros(iBatchVariables.NumChannels,size(Mult,2));
            for jj=1:iBatchVariables.NumChannels
                FilteredMult(jj,:)=transpose(filtfilt2((Mult(jj,:)),HP,LP,Fs, 1));
            end
            
            %Chop up sweeps
            [FilteredMultSweeps,FilteredMultSweepTime]=ParseTDTDatav2(FilteredMult,iBatchVariables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,FilteredRawArtifactLocations);
            
            %Combine all sweeps across stims into a single variable
            AllFilteredMult(iStim,:,:,:)=permute(FilteredMultSweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        end
        
        
    end
    
    
    
    
end



if FilterFlag
    BatchVariables.ImportFilterFlag=1;
    BatchVariables.HighPassFilter=str2double(handles.HPText.String);
    BatchVariables.LowPassFilter=str2double(handles.LPText.String);
else
    BatchVariables.ImportFilterFlag=0;
end

timepts=AllRawTime(1,:)-AllRawTime(1,PreWindowIndices+1);
Note=['(MxNxPxQ) M=Stims, N=Sweeps, P=Channels, Q=time'];

BatchVariables.Fs=Fs;
BatchVariables.dt=dt;
BatchVariables.WindowLength=WindowLength;
BatchVariables.PreArtifactWindowLength=PreArtifactWindow;
BatchVariables.PostArtifactWindowLength=PostArtifactWindow;
BatchVariables.WindowLengthIndices=WindowIndices;
BatchVariables.PreArtifactWindowLengthIndices=PreWindowIndices;
BatchVariables.PostArtifactWindowLengthIndices=PostWindowIndices;
BatchVariables.timepts=timepts;
BatchVariables.Note=Note;
BatchVariables.AllRawArtifactLocations=AllRawArtifactLocations;
BatchVariables.AllRaw=AllRaw;

if FilterFlag
    BatchVariables.AllFilteredRaw=AllFilteredRaw;
    BatchVariables.AllFilteredRawArtifactLocations=AllFilteredRawArtifactLocations;
end

if ImportBP60
    BatchVariables.AllBP60=AllBP60;
    if FilterFlag
        BatchVariables.AllFilteredBP60=AllFilteredBP60;
    end
end
if ImportMult
    BatchVariables.AllMult=AllMult;
    if FilterFlag
        BatchVariables.AllFilteredMult=AllFilteredMult;
    end
end


%% Detect Outlier Sweeps
%Currently only detects outliers on Raw channel
if BatchVariables.Flags.DetectOutliers
%     waitbar(0.99,h,strcat('Importing Complete, Detecting Outliers'));
    
    [OutlierFlag,ExcludeChannels]=BatchDetectOutliers(BatchVariables);
    BatchVariables.Flags.OutliersExistFlag=OutlierFlag;
    BatchVariables.Flags.ExcludeChannels=ExcludeChannels;
    %     BatchVariables.AllOutliers=AllOutliers;
else
    BatchVariables.Flags.OutliersExistFlag=zeros(BatchVariables.NumStims,BatchVariables.NumChannels);
    ExcludeChannels=[];
end



%% Average over Sweeps - remove outliers
%need to reject outliers

if sum(BatchVariables.Flags.OutliersExistFlag(:))
%     waitbar(0.99,h,strcat('Importing Complete, Removing Outliers'));
    
    for istim=1:BatchVariables.NumStims
        for ch=1:BatchVariables.NumChannels
            Outliers=find(squeeze(OutlierFlag(istim,:,ch))==1);
            WriteOutlierCSV{istim,ch}=num2str(Outliers);
            
            RawTraces=squeeze(AllRaw(istim,:,ch,:));
            RawTraces(Outliers,:)=[];
            RawAverageOverSweeps(istim,:,ch,:)=mean(RawTraces,1,'omitnan');
            RawStdOverSweeps(istim,:,ch,:)=std(RawTraces,[],1,'omitnan');
            
            if FilterFlag
                FilteredRawTraces=squeeze(AllFilteredRaw(istim,:,ch,:));
                FilteredRawTraces(Outliers,:)=[];
                FilteredRawAverageOverSweeps(istim,:,ch,:)=mean(FilteredRawTraces,1,'omitnan');
                FilteredRawStdOverSweeps(istim,:,ch,:)=std(FilteredRawTraces,[],1,'omitnan');
            end
            
            if ImportBP60
                BP60Traces=squeeze(AllBP60(istim,:,ch,:));
                BP60Traces(Outliers,:)=[];
                BP60AverageOverSweeps(istim,:,ch,:)=mean(BP60Traces,1,'omitnan');
                BP60StdOverSweeps(istim,:,ch,:)=std(BP60Traces,[],1,'omitnan');
                
                if FilterFlag
                    FilteredBP60Traces=squeeze(AllFilteredBP60(istim,:,ch,:));
                    FilteredBP60Traces(Outliers,:)=[];
                    FilteredBP60AverageOverSweeps(istim,:,ch,:)=mean(FilteredBP60Traces,1,'omitnan');
                    FilteredBP60StdOverSweeps(istim,:,ch,:)=std(FilteredBP60Traces,[],1,'omitnan');
                end
            end
            
            
            if ImportMult
                MultTraces=squeeze(AllMult(istim,:,ch,:));
                MultTraces(Outliers,:)=[];
                MultAverageOverSweeps(istim,:,ch,:)=mean(MultTraces,1,'omitnan');
                MultStdOverSweeps(istim,:,ch,:)=std(MultTraces,[],1,'omitnan');
                
                if FilterFlag
                    FilteredMultTraces=squeeze(AllFilteredMult(istim,:,ch,:));
                    FilteredMultTraces(Outliers,:)=[];
                    FilteredMultAverageOverSweeps(istim,:,ch,:)=mean(FilteredMultTraces,1,'omitnan');
                    FilteredMultStdOverSweeps(istim,:,ch,:)=std(FilteredMultTraces,[],1,'omitnan');
                end
            end
        end
    end
    
else
    RawAverageOverSweeps=mean(AllRaw,2,'omitnan');
    RawStdOverSweeps=std(AllRaw,[],2,'omitnan');
    
    if ImportBP60
        BP60AverageOverSweeps=mean(AllBP60,2,'omitnan');
        BP60StdOverSweeps=std(AllBP60,[],2,'omitnan');
    end
    if ImportMult
        MultAverageOverSweeps=mean(AllMult,2,'omitnan');
        MultStdOverSweeps=std(AllMult,[],2,'omitnan');
    end
end


BatchVariables.RawAverageOverSweeps=RawAverageOverSweeps;
BatchVariables.RawStdOverSweeps=RawStdOverSweeps;
if FilterFlag
    BatchVariables.FilteredRawAverageOverSweeps=FilteredRawAverageOverSweeps;
    BatchVariables.FilteredRawStdOverSweeps=FilteredRawStdOverSweeps;
end

if ImportBP60
    BatchVariables.BP60AverageOverSweeps=BP60AverageOverSweeps;
    BatchVariables.BP60StdOverSweeps=BP60StdOverSweeps;
    if FilterFlag
        BatchVariables.FilteredBP60AverageOverSweeps=FilteredBP60AverageOverSweeps;
        BatchVariables.FilteredBP60StdOverSweeps=FilteredBP60StdOverSweeps;
    end
end
if ImportMult
    BatchVariables.MultAverageOverSweeps=MultAverageOverSweeps;
    BatchVariables.MultStdOverSweeps=MultStdOverSweeps;
    if FilterFlag
        BatchVariables.FilteredMultAverageOverSweeps=FilteredMultAverageOverSweeps;
        BatchVariables.FilteredMultStdOverSweeps=FilteredMultStdOverSweeps;
    end
end


%% Remove outlier/broken channels

%Exlude channels with too much variation, signifying sweeps that are
%not 0 centered and fluctuate wildly over recordings
if ~isempty(ExcludeChannels) | isfield(BatchVariables.Flags,'BadChannels')
%     waitbar(0.99,h,strcat('Importing Complete, Removing Broken Channel'));
    
    BatchVariables.Flags.InterpolatedTraces=1;
    InterpolatedRaw=BatchInterpolateChannels(BatchVariables,BatchVariables.RawAverageOverSweeps);
    BatchVariables.UninterpolatedRawAverageOverSweeps=BatchVariables.RawAverageOverSweeps;
    BatchVariables.RawAverageOverSweeps=InterpolatedRaw;
    
    if FilterFlag
        InterpolatedFilteredRaw=BatchInterpolateChannels(BatchVariables,BatchVariables.FilteredRawAverageOverSweeps);
        BatchVariables.UninterpolatedFilteredRawAverageOverSweeps=BatchVariables.FilteredRawAverageOverSweeps;
        BatchVariables.FilteredRawAverageOverSweeps=InterpolatedFilteredRaw;
    end
    
    
    %Interpolate BP60 data
    if ImportBP60
        InterpolatedBP60=BatchInterpolateChannels(BatchVariables,BatchVariables.BP60AverageOverSweeps);
        BatchVariables.UninterpolatedBP60AverageOverSweeps=BatchVariables.BP60AverageOverSweeps;
        BatchVariables.BP60AverageOverSweeps=InterpolatedBP60;
        
        if FilterFlag
            InterpolatedFilteredBP60=BatchInterpolateChannels(BatchVariables,BatchVariables.FilteredBP60AverageOverSweeps);
            BatchVariables.UninterpolatedFilteredBP60AverageOverSweeps=BatchVariables.FilteredBP60AverageOverSweeps;
            BatchVariables.FilteredBP60AverageOverSweeps=InterpolatedFilteredBP60;
        end
    end
    
    %Interpolate Mult data
    if ImportMult
        InterpolatedMult=BatchInterpolateChannels(BatchVariables,BatchVariables.MultAverageOverSweeps);
        BatchVariables.UninterpolatedMultAverageOverSweeps=BatchVariables.MultAverageOverSweeps;
        BatchVariables.MultAverageOverSweeps=InterpolatedMult;
        
        if FilterFlag
            InterpolatedFilteredMult=BatchInterpolateChannels(BatchVariables,BatchVariables.FilteredMultAverageOverSweeps);
            BatchVariables.UninterpolatedFilteredMultAverageOverSweeps=BatchVariables.FilteredMultAverageOverSweeps;
            BatchVariables.FilteredMultAverageOverSweeps=InterpolatedFilteredMult;
        end
    end
    
    
end


%% Calculate CSDs
% waitbar(0.99,h,strcat('Importing Complete, Calculating CSDs'));
[Rawcsd]=CalculateCSDv2(handles,BatchVariables.RawAverageOverSweeps);
BatchVariables.Rawcsd=Rawcsd;
if FilterFlag
    [FilteredRawcsd]=CalculateCSDv2(handles,BatchVariables.FilteredRawAverageOverSweeps);
    BatchVariables.FilteredRawcsd=FilteredRawcsd;
end


if ImportBP60
    [BP60csd]=CalculateCSDv2(handles,BatchVariables.BP60AverageOverSweeps);
    BatchVariables.BP60csd=BP60csd;
    if FilterFlag
        [FilteredBP60csd]=CalculateCSDv2(handles,BatchVariables.FilteredBP60AverageOverSweeps);
        BatchVariables.FilteredBP60csd=FilteredBP60csd;
    end
end

if ImportMult
    [Multcsd]=CalculateCSDv2(handles,BatchVariables.MultAverageOverSweeps);
    BatchVariables.Multcsd=Multcsd;
    if FilterFlag
        [FilteredMultcsd]=CalculateCSDv2(handles,BatchVariables.FilteredMultAverageOverSweeps);
        BatchVariables.FilteredMultcsd=FilteredMultcsd;
    end
end



%% Save data and update GUI
% waitbar(0.99,h,strcat('Importing Complete, Saving Data'));
SavedImportedData=BatchVariables;
%Need to make folder to save everything in
timevector=datestr(now, 'yymmdd-HHMMSS');
ImportedName=strcat(BatchVariables.SaveFolder,filesep,'ImportedData',timevector,'.mat');
save(ImportedName,'SavedImportedData','-v7.3')
% waitbar(1,h,strcat('Importing: 100% Complete'));

BatchVariables.CurrentPlottingVariable=1;

if BatchVariables.Flags.DetectOutliers
    for ch=1:BatchVariables.NumChannels
        VarNames{1,ch}=sprintf('Channel%d',ch);
    end
    for istim=1:length(BatchVariables.AllStims)
        RowNamesVar{istim,1}=sprintf('%duA',BatchVariables.AllStims(istim));
    end
    FoundOutliers=cell2table(WriteOutlierCSV,'VariableNames',VarNames,'RowNames',RowNamesVar);
    writetable(FoundOutliers,'Found Outlier Sweeps.csv','WriteRowNames',1,'writevariablenames',1)
    
    if ~isempty(ExcludeChannels)
        ExcludedTable=table(BatchVariables.Flags.ExcludeChannels,'VariableNames',{'ExludedChannel'});
        writetable(ExcludedTable,'Excluded and Interpolated Channels.csv')
    else
        ExcludedTable=table({'none excluded'},'VariableNames',{'ExludedChannel'});
        writetable(ExcludedTable,'Excluded and Interpolated Channels.csv')
    end
end
% close all
% waitbar(1,h,strcat('Importing Completed, You may continue analyzing'));
cd(handles.MainFunctionFolder)