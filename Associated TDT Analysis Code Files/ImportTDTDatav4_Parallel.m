function app=ImportTDTDatav4_Parallel(app,Fs,dt)
%Set Local Parameters
ImportBP60=app.Variables.Flags.ImportBP60;
ImportMult=app.Variables.Flags.ImportMult;
DetectOutliers=app.Variables.Flags.DetectOutliers;
FilterFlag=app.Variables.Flags.ImportFilterFlag;
BaseName=app.Variables.BaseName;
if app.Variables.Flags.ImportFilterFlag
    HP=app.Variables.HighPassFilter;
    LP=app.Variables.LowPassFilter;
end
NumSweeps=app.Variables.NumSweeps;
NumChannels=app.Variables.NumChannels;


            WindowLength=app.Variables.SweepChopDuration; %sec
            PreArtifactWindow=WindowLength*0.005; %sec
            PostArtifactWindow=WindowLength-PreArtifactWindow;
            WindowIndices=floor(WindowLength*Fs);
            PreWindowIndices=floor(PreArtifactWindow*Fs);
            PostWindowIndices=WindowIndices-PreWindowIndices;

%% Pull data from TDT files
parfor iStim=1:app.Variables.NumStims
    % -Goal of loading in all data for all channels, stims, and sweeps
    % -Assumes the base name for the initial path loaded is the same for every
    %folder, and the value at the end iterates
    % -All data will be stored in the variables AllRaw, AllBP60, etc. with the
    % dimensions being Stim x Sweep x Channel

    %Load in data
    LoadName=strcat(BaseName,num2str(iStim));
    data=SEV2mat(LoadName,'EventName','Raws');

    TraceTime=[0:dt:dt*(length(data.Raws.data(1,:))-1)];
    
    %Determine when sweeps start
    Epocs=TDTbin2mat(LoadName,'TYPE',{'epocs'});
    SweepStarts=Epocs.epocs.EpcV.onset;
    SweepStartIndices=round(SweepStarts.*Fs);

    
    %%%%%%%% Raw Data Parsing
    Raw=data.Raws.data;
    RawArtifactLocations=AppFindArtifacts(app.Variables,Raw,PostWindowIndices,Fs,SweepStartIndices,iStim);

    %Chop up into sweeps base on artifact timing
    [RawSweeps,RawSweepTime]=ParseTDTDatav2(Raw,app.Variables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,RawArtifactLocations);
    
    %Combine all sweeps across stims into a single variable
    AllRaw(iStim,:,:,:)=permute(RawSweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
    AllRawTime(iStim,:,:,:)=permute(RawSweepTime,[4 1 3 2]);
    AllRawArtifactLocations(iStim,:)=RawArtifactLocations;

    
    if FilterFlag
        FilteredRaw=zeros(app.Variables.NumChannels,size(Raw,2));
        for jj=1:app.Variables.NumChannels
            FilteredRaw(jj,:)=transpose(filtfilt2((Raw(jj,:)),HP,LP,Fs, 1));
        end
        FilteredRawArtifactLocations=AppFindArtifacts(app.Variables,FilteredRaw,PostWindowIndices,Fs,SweepStartIndices,iStim);
        [FilteredRawSweeps,FilteredRawSweepTime]=ParseTDTDatav2(FilteredRaw,app.Variables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,FilteredRawArtifactLocations);
        
        %Combine all sweeps across stims into a single variable
        AllFilteredRaw(iStim,:,:,:)=permute(FilteredRawSweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        AllFilteredRawArtifactLocations(iStim,:)=FilteredRawArtifactLocations;
    end
    
    
    %%%%%%%% BP60 Data Parsing
    if ImportBP60
        BP60data=SEV2mat(LoadName,'EventName','BP60');
        BP60=BP60data.BP60.data;
        [BP60Sweeps,BP60SweepTime]=ParseTDTDatav2(BP60,app.Variables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,RawArtifactLocations);
        AllBP60(iStim,:,:,:)=permute(BP60Sweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        AllBP60Time(iStim,:,:,:)=permute(BP60SweepTime,[4 1 3 2]);
        
        if FilterFlag
            FilteredBP60=zeros(app.Variables.NumChannels,size(BP60,2));
            for jj=1:app.Variables.NumChannels
                FilteredBP60(jj,:)=transpose(filtfilt2((BP60(jj,:)),HP,LP,Fs, 1));
            end
            
            %Chop up sweeps
            [FilteredBP60Sweeps,FilteredBP60SweepTime]=ParseTDTDatav2(FilteredBP60,app.Variables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,FilteredRawArtifactLocations);
            
            %Combine all sweeps across stims into a single variable
            AllFilteredBP60(iStim,:,:,:)=permute(FilteredBP60Sweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        end
    end
    
    %%%%%%%% Mult Data Parsing
    if ImportMult
        Multdata=SEV2mat(LoadName,'EventName','Mult');
        Mult=Multdata.Mult.data;
        [MultSweeps,MultSweepTime]=ParseTDTDatav2(Mult,app.Variables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,RawArtifactLocations);
        AllMult(iStim,:,:,:)=permute(MultSweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        AllMultTime(iStim,:,:,:)=permute(MultSweepTime,[4 1 3 2]);
        
        %FilterData
        if FilterFlag
            FilteredMult=zeros(app.Variables.NumChannels,size(Mult,2));
            for jj=1:app.Variables.NumChannels
                FilteredMult(jj,:)=transpose(filtfilt2((Mult(jj,:)),HP,LP,Fs, 1));
            end
            
            %Chop up sweeps
            [FilteredMultSweeps,FilteredMultSweepTime]=ParseTDTDatav2(FilteredMult,app.Variables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,FilteredRawArtifactLocations);
            
            %Combine all sweeps across stims into a single variable
            AllFilteredMult(iStim,:,:,:)=permute(FilteredMultSweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        end       
    end
end



timepts=AllRawTime(1,:)-AllRawTime(1,PreWindowIndices+1);
Note=['(MxNxPxQ) M=Stims, N=Sweeps, P=Channels, Q=time'];
    
app.Variables.Fs=Fs;
app.Variables.dt=dt;
app.Variables.WindowLength=WindowLength;
app.Variables.PreArtifactWindowLength=PreArtifactWindow;
app.Variables.PostArtifactWindowLength=PostArtifactWindow;
app.Variables.WindowLengthIndices=WindowIndices;
app.Variables.PreArtifactWindowLengthIndices=PreWindowIndices;
app.Variables.PostArtifactWindowLengthIndices=PostWindowIndices;
app.Variables.timepts=timepts;
app.Variables.Note=Note;
app.Variables.AllRawArtifactLocations=AllRawArtifactLocations;
app.Variables.AllRaw=AllRaw;

if FilterFlag
    app.Variables.AllFilteredRaw=AllFilteredRaw;
    app.Variables.AllFilteredRawArtifactLocations=AllFilteredRawArtifactLocations;
end

if ImportBP60
    app.Variables.AllBP60=AllBP60;
    app.Variables.AllFilteredBP60=AllFilteredBP60;
end

if ImportMult
    app.Variables.AllMult=AllMult;
    app.Variables.AllFilteredMult=AllFilteredMult;
end


%% Detect Outlier Sweeps
%Currently only detects outliers on Raw channel
if DetectOutliers
%         waitbar(0.99,h,strcat('Importing Complete, Detecting Outliers'));

    [OutlierFlag,ExcludeChannels]=AppDetectOutliers(app.Variables);
    app.Variables.Flags.OutliersExistFlag=OutlierFlag;
    app.Variables.Flags.ExcludeChannels=ExcludeChannels;
else
    app.Variables.Flags.OutliersExistFlag=zeros(app.Variables.NumStims,app.Variables.NumChannels);
    ExcludeChannels=[];
end



%% Average over Sweeps - remove outliers

if sum(app.Variables.Flags.OutliersExistFlag(:))
%             waitbar(0.99,h,strcat('Importing Complete, Removing Outliers'));
%for future parallelization
%             RawAverageOverSweeps=zeros(app.Variables.NumStims,app.Variables.NumSweeps,app.Variables.NumChannels,size(RawTraces,2));
%             RawStdOverSweeps=zeros(app.Variables.NumStims,app.Variables.NumSweeps,app.Variables.NumChannels,size(RawTraces,2));
%             if FilterFlag
%             FilteredRawAverageOverSweeps
%             
 for istim=1:app.Variables.NumStims
        for ch=1:app.Variables.NumChannels
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


app.Variables.RawAverageOverSweeps=RawAverageOverSweeps;
app.Variables.RawStdOverSweeps=RawStdOverSweeps;
if FilterFlag
    app.Variables.FilteredRawAverageOverSweeps=FilteredRawAverageOverSweeps;
    app.Variables.FilteredRawStdOverSweeps=FilteredRawStdOverSweeps;
end

if ImportBP60
    app.Variables.BP60AverageOverSweeps=BP60AverageOverSweeps;
    app.Variables.BP60StdOverSweeps=BP60StdOverSweeps;
    if FilterFlag
        app.Variables.FilteredBP60AverageOverSweeps=FilteredBP60AverageOverSweeps;
        app.Variables.FilteredBP60StdOverSweeps=FilteredBP60StdOverSweeps;
    end
end
if ImportMult
    app.Variables.MultAverageOverSweeps=MultAverageOverSweeps;
    app.Variables.MultStdOverSweeps=MultStdOverSweeps;
    if FilterFlag
        app.Variables.FilteredMultAverageOverSweeps=FilteredMultAverageOverSweeps;
        app.Variables.FilteredMultStdOverSweeps=FilteredMultStdOverSweeps;
    end
end


%% Remove outlier/broken channels

%Exlude channels with too much variation, signifying sweeps that are
%not 0 centered and fluctuate wildly over recordings
if ~isempty(ExcludeChannels) | isfield(app.Variables.Flags,'BadChannels')
%             waitbar(0.99,h,strcat('Importing Complete, Removing Broken Channel'));

    app.Variables.Flags.InterpolatedTraces=1;
    InterpolatedRaw=AppInterpolateChannels(app.Variables,app.Variables.RawAverageOverSweeps);
    app.Variables.UninterpolatedRawAverageOverSweeps=app.Variables.RawAverageOverSweeps;
    app.Variables.RawAverageOverSweeps=InterpolatedRaw;
    
    if FilterFlag
        InterpolatedFilteredRaw=InterpolateChannels(app.Variables,app.Variables.FilteredRawAverageOverSweeps);
        app.Variables.UninterpolatedFilteredRawAverageOverSweeps=app.Variables.FilteredRawAverageOverSweeps;
        app.Variables.FilteredRawAverageOverSweeps=InterpolatedFilteredRaw;
    end
    
    
    %Interpolate BP60 data
    if ImportBP60
        InterpolatedBP60=AppInterpolateChannels(app.Variables,app.Variables.BP60AverageOverSweeps);
        app.Variables.UninterpolatedBP60AverageOverSweeps=app.Variables.BP60AverageOverSweeps;
        app.Variables.BP60AverageOverSweeps=InterpolatedBP60;
        
        if FilterFlag
            InterpolatedFilteredBP60=AppInterpolateChannels(app.Variables,app.Variables.FilteredBP60AverageOverSweeps);
            app.Variables.UninterpolatedFilteredBP60AverageOverSweeps=app.Variables.FilteredBP60AverageOverSweeps;
            app.Variables.FilteredBP60AverageOverSweeps=InterpolatedFilteredBP60;
        end
    end
    
    %Interpolate Mult data
    if ImportMult
        InterpolatedMult=AppInterpolateChannels(app.Variables,app.Variables.MultAverageOverSweeps);
        app.Variables.UninterpolatedMultAverageOverSweeps=app.Variables.MultAverageOverSweeps;
        app.Variables.MultAverageOverSweeps=InterpolatedMult;
        
        if FilterFlag
            InterpolatedFilteredMult=AppInterpolateChannels(app.Variables,app.Variables.FilteredMultAverageOverSweeps);
            app.Variables.UninterpolatedFilteredMultAverageOverSweeps=app.Variables.FilteredMultAverageOverSweeps;
            app.Variables.FilteredMultAverageOverSweeps=InterpolatedFilteredMult;
        end
    end
    
    
end


%% Calculate CSDs
% waitbar(0.99,h,strcat('Importing Complete, Calculating CSDs'));
[Rawcsd]=CalculateCSDv3(app.Variables.RawAverageOverSweeps,app.Variables.ElectrodeSpacing);
app.Variables.Rawcsd=Rawcsd;
if FilterFlag
    [FilteredRawcsd]=CalculateCSDv3(app.Variables.FilteredRawAverageOverSweeps,app.Variables.ElectrodeSpacing);
    app.Variables.FilteredRawcsd=FilteredRawcsd;
end


if ImportBP60
    [BP60csd]=CalculateCSDv3(app.Variables.BP60AverageOverSweeps,app.Variables.ElectrodeSpacing);
    app.Variables.BP60csd=BP60csd;
    if FilterFlag
        [FilteredBP60csd]=CalculateCSDv3(app.Variables.FilteredBP60AverageOverSweeps,app.Variables.ElectrodeSpacing);
        app.Variables.FilteredBP60csd=FilteredBP60csd;
    end
end

if ImportMult
    [Multcsd]=CalculateCSDv3(app.Variables.MultAverageOverSweeps,app.Variables.ElectrodeSpacing);
    app.Variables.Multcsd=Multcsd;
    if FilterFlag
        [FilteredMultcsd]=CalculateCSDv3(app.Variables.FilteredMultAverageOverSweeps,app.Variables.ElectrodeSpacing);
        app.Variables.FilteredMultcsd=FilteredMultcsd;
    end
end



%% Save data and update GUI
% waitbar(0.99,h,strcat('Importing Complete, Saving Data'));
SavedImportedData=app.Variables;
%Need to make folder to save everything in
timevector=datestr(now, 'yymmdd-HHMMSS');
ImportedName=strcat(app.Variables.SaveFolder,filesep,'ImportedData',timevector,'.mat');
save(ImportedName,'SavedImportedData','-v7.3')
% waitbar(1,h,strcat('Importing: 100% Complete'));

app.Variables.CurrentPlottingVariable=1;

if DetectOutliers
    for ch=1:app.Variables.NumChannels
        VarNames{1,ch}=sprintf('Channel%d',ch);
    end
    for istim=1:length(app.Variables.AllStims)
        RowNamesVar{istim,1}=sprintf('%duA',app.Variables.AllStims(istim));
    end
    FoundOutliers=cell2table(WriteOutlierCSV,'VariableNames',VarNames,'RowNames',RowNamesVar);
    writetable(FoundOutliers,'Found Outlier Sweeps.csv','WriteRowNames',1,'writevariablenames',1)
    
    if ~isempty(ExcludeChannels)
        ExcludedTable=table(app.Variables.Flags.ExcludeChannels,'VariableNames',{'ExludedChannel'});
        writetable(ExcludedTable,'Excluded and Interpolated Channels.csv')
    else
        ExcludedTable=table({'none excluded'},'VariableNames',{'ExludedChannel'});
        writetable(ExcludedTable,'Excluded and Interpolated Channels.csv')
    end
end

% waitbar(1,h,strcat('Importing Completed, You may continue analyzing'));
cd(app.Variables.MainFunctionFolder)