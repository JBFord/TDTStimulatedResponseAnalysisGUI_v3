function app=ImportTDTDatav5_Parallel(app)
%Set Local Parameters
% ImportBP60=app.Variables.Flags.ImportBP60;
% ImportMult=app.Variables.Flags.ImportMult;
NumSelectedStreams=size(app.Tree.CheckedNodes,1);

DetectOutliers=app.Variables.Flags.DetectOutliers;
FilterFlag=app.Variables.Flags.ImportFilterFlag;

if FilterFlag
    HP=app.Variables.HighPassFilter;
    LP=app.Variables.LowPassFilter;
end

%             WindowLength=app.Variables.SweepChopDuration; %sec
%             PreArtifactWindow=WindowLength*0.005; %sec
%             PostArtifactWindow=WindowLength-PreArtifactWindow;
          h=waitbar(0,strcat('Importing LFPs'));  

%% Pull data from TDT files
%  for iStim=1:app.Variables.NumStims
    % -Goal of loading in all data for all channels, stims, and sweeps
    % -Assumes the base name for the initial path loaded is the same for every
    %folder, and the value at the end iterates
    % -All data will be stored in the variables AllRaw, AllBP60, etc. with the
    % dimensions being Stim x Sweep x Channel



for iNode=1:NumSelectedStreams
    CurrentStream=app.Tree.CheckedNodes(iNode).Text;
    ImportedStreams{iNode}=CurrentStream;
    app.Variables=setfield(app.Variables,CurrentStream,struct());
    app=GetDataFromTDT(app,CurrentStream);
end
app.Variables.DataStreamsImported=ImportedStreams;

  
app.Variables.Note=['(MxNxPxQ) M=Stims, N=Sweeps, P=Channels, Q=time'];


%% Detect Outlier Sweeps
%Currently only detects outliers on Raw channel
if DetectOutliers
    waitbar(0.8,h,strcat('Detecting Outliers'));

    for iNode=1:NumSelectedStreams
        CurrentStream=app.Tree.CheckedNodes(iNode).Text;
        [OutlierFlag,ExcludeChannels]=AppDetectOutliers(app.Variables,CurrentStream);
        app.Variables=setfield(app.Variables,CurrentStream,'Flags','OutliersExistFlag',OutlierFlag);
        app.Variables=setfield(app.Variables,CurrentStream,'Flags','ExcludeChannels',ExcludeChannels);
%         app.Variables.Flags.OutliersExistFlag=OutlierFlag;
%         app.Variables.Flags.ExcludeChannels=ExcludeChannels;
    end
else
     for iNode=1:NumSelectedStreams
                 CurrentStream=app.Tree.CheckedNodes(iNode).Text;
    app.Variables=setfield(app.Variables,CurrentStream,'Flags','OutliersExistFlag',zeros(app.Variables.NumStims,app.Variables.NumChannels));
    app.Variables=setfield(app.Variables,CurrentStream,'Flags','ExcludeChannels',[]);
%     ExcludeChannels=[];
     end
end



%% Average over Sweeps - remove outliers


%for future parallelization
%             RawAverageOverSweeps=zeros(app.Variables.NumStims,app.Variables.NumSweeps,app.Variables.NumChannels,size(RawTraces,2));
%             RawStdOverSweeps=zeros(app.Variables.NumStims,app.Variables.NumSweeps,app.Variables.NumChannels,size(RawTraces,2));
%             if FilterFlag
%             FilteredRawAverageOverSweeps
%
for iNode=1:NumSelectedStreams
    CurrentStream=app.Tree.CheckedNodes(iNode).Text;
    TempOutlierFlag{iNode}=getfield(app.Variables,CurrentStream,'Flags','OutliersExistFlag');
   HasOutlier(iNode)=sum(TempOutlierFlag{iNode}(:))>0;

end

waitbar(0.85,h,strcat('Removing Outliers'));
% Iterate over each stimulation intensity and channel to remove outlier
% sweeps during averaging
for istim=1:app.Variables.NumStims
    for ch=1:app.Variables.NumChannels
        for iNode=find(HasOutlier)
            CurrentStream=app.Tree.CheckedNodes(iNode).Text;
            if istim==1 && ch==1
                LFPData{iNode}=getfield(app.Variables,CurrentStream,'LFPData');
            end

            Outliers=find(squeeze(TempOutlierFlag{iNode}(istim,:,ch))==1);
            WriteOutlierCSV{istim,ch,iNode}=num2str(Outliers);
            
            Traces=squeeze(LFPData{iNode}(istim,:,ch,:));
            Traces(Outliers,:)=[];
            AverageOverSweeps{iNode}(istim,:,ch,:)=mean(Traces,1,'omitnan');
            StdOverSweeps{iNode}(istim,:,ch,:)=std(Traces,[],1,'omitnan');

            if FilterFlag
                if istim==1 && ch==1
                    FilteredLFPData{iNode}=getfield(app.Variables,CurrentStream,'AllFilteredLFPData');
                end
                FilteredTraces=squeeze(FilteredLFPData{iNode}(istim,:,ch,:));
                FilteredTraces(Outliers,:)=[];
                FilteredAverageOverSweeps{iNode}(istim,:,ch,:)=mean(FilteredTraces,1,'omitnan');
                FilteredStdOverSweeps{iNode}(istim,:,ch,:)=std(FilteredTraces,[],1,'omitnan');
            end

        end
    end
end

%For recordings without outliers, averaging can be done with matrix math
%without looping
for  iNode=find(~HasOutlier)
    CurrentStream=app.Tree.CheckedNodes(iNode).Text;
    LFPData=getfield(app.Variables,CurrentStream,'LFPData');

    AverageOverSweeps{iNode}=mean(LFPData,2,'omitnan');
    StdOverSweeps{iNode}=std(LFPData,[],2,'omitnan');

    if FilterFlag
        FilteredLFPData=getfield(Variables,CurrentStream,'AllFilteredLFPData');
        FilteredAverageOverSweeps{iNode}=mean(FilteredLFPData,2,'omitnan');
        FilteredStdOverSweeps{iNde}=std(FilteredLFPData,[],2,'omitnan');
    end
end

%Write averaged values to Variables structure
for iNode=1:NumSelectedStreams
    CurrentStream=app.Tree.CheckedNodes(iNode).Text;
    app.Variables=setfield(app.Variables,CurrentStream,'AverageLFPData',AverageOverSweeps{iNode});
    app.Variables=setfield(app.Variables,CurrentStream,'LFPDataSTD',StdOverSweeps{iNode});
    if FilterFlag
        app.Variables=setfield(app.Variables,CurrentStream,'AverageFilteredLFPData',FilteredAverageOverSweeps{iNode});
        app.Variables=setfield(app.Variables,CurrentStream,'FilteredStdOverSweeps',StdOverSweeps{iNode});
    end

end

%% Remove outlier/broken channels

%Exlude channels with too much variation, signifying sweeps that are
%not 0 centered and fluctuate wildly over recordings

%Read Defined Bad Channels
if app.KnownBadChannelsCheckBox.Value
    BadChannelsString=app.BadChannelsCommaSeparatedEditField.Value;
    CommaLocations=strfind(BadChannelsString,',');

    if isempty(BadChannelsString)
        BadChannels=[];
    elseif isempty(CommaLocations)
        BadChannels=str2double(BadChannelsString);
    else
        for iComma=1:length(CommaLocations)+1
            if iComma==1
                BadChannels(iComma)=str2double(BadChannelsString(1:CommaLocations(iComma)-1));
            elseif iComma==length(CommaLocations)+1
                BadChannels(iComma)=str2double(BadChannelsString(CommaLocations(iComma-1)+1:end));
            else
                BadChannels(iComma)=str2double(BadChannelsString(CommaLocations(iComma-1)+1:CommaLocations(iComma)-1));
            end
        end
    end
    app.Variables.Flags.BadChannels=BadChannels;
else
    BadChannels=[];
end

%Get Bad Channels detected in Outlier Removal
for iNode=1:NumSelectedStreams
    CurrentStream=app.Tree.CheckedNodes(iNode).Text;
    Exclude{iNode}=getfield(app.Variables,CurrentStream,'Flags','ExcludeChannels');
    HasExclude(iNode)=~isempty(Exclude{iNode});
end

%Remove and Interpolate Bad Channels
for iNode=1:NumSelectedStreams
    CurrentStream=app.Tree.CheckedNodes(iNode).Text;
    if HasExclude(iNode) | isfield(app.Variables.Flags,'BadChannels')
        waitbar(0.9,h,strcat('Removing Broken Channel'));

        if ~isempty(Exclude{iNode}) | ~isempty(BadChannels)
            app.Variables=setfield(app.Variables,CurrentStream,'Flags','InterpolatedTraces',1);
            InterpolatedLFPs=AppInterpolateChannels(app.Variables,getfield(app.Variables,CurrentStream,'AverageLFPData'), unique([Exclude{iNode} BadChannels]),CurrentStream);
            app.Variables=setfield(app.Variables,CurrentStream,'UninterpolatedAverageLFPData',getfield(app.Variables,CurrentStream,'AverageLFPData'));
            app.Variables=setfield(app.Variables,CurrentStream,'AverageLFPData',InterpolatedLFPs);

            if FilterFlag
                InterpolatedFilteredLFPs=AppInterpolateChannels(app.Variables,getfield(app.Variables,CurrentStream,'AverageFilteredLFPData'), unique([Exclude{iNode} BadChannels]),CurrentStream);
                app.Variables=setfield(app.Variables,CurrentStream,'UninterpolatedAverageFilteredLFPData',getfield(app.Variables,CurrentStream,'AverageFilteredLFPData'));
                app.Variables=setfield(app.Variables,CurrentStream,'AverageFilteredLFPData',InterpolatedFilteredLFPs);
            end
        end
    end
end
%% Calculate CSDs
waitbar(0.95,h,strcat('Calculating CSDs'));
for iNode=1:NumSelectedStreams
    CurrentStream=app.Tree.CheckedNodes(iNode).Text;

    [csd]=CalculateCSDv3(getfield(app.Variables,CurrentStream,'AverageLFPData'),app.Variables.ElectrodeSpacing);
    app.Variables=setfield(app.Variables,CurrentStream,'CSDData',csd);
    if FilterFlag
        [Filteredcsd]=CalculateCSDv3(getfield(app.Variables,CurrentStream,'AverageFilteredLFPData'),app.Variables.ElectrodeSpacing);
        app.Variables=setfield(app.Variables,CurrentStream,'FilteredCSDData',Filteredcsd);
    end
end
%% Save data and update GUI
waitbar(0.99,h,strcat('Saving Data'));
SavedImportedData=app.Variables;
%Need to make folder to save everything in
timevector=datestr(now, 'yymmdd-HHMMSS');
f=dir(SavedImportedData.SaveFolder);
for ii=3:length(f)
    if ~isempty(strfind(f(ii).name,'ImportedData')) &&  ~isempty(strfind(f(ii).name,app.Variables.Flags.ImportVersion))
        answer=questdlg(strcat('ImportedData file already exists in ',app.Variables.SaveFolder,'. Do you want to overwrite?'),'Overwrite Data?','Overwrite','Save with Date-Time Suffix','Save with Date-Time Suffix');
        continue
    end
end
if exist('answer')
    switch answer
        case 'Save with Date-Time Suffix'
            ImportedName=strcat(app.Variables.SaveFolder,filesep,'ImportedData',timevector,'_',app.Variables.Flags.ImportVersion,'.mat');
        case 'Overwrite'
            ImportedName=strcat(app.Variables.SaveFolder,filesep,'ImportedData','_',app.Variables.Flags.ImportVersion,'.mat');
    end
else
    ImportedName=strcat(app.Variables.SaveFolder,filesep,'ImportedData','_',app.Variables.Flags.ImportVersion,'.mat');
end
save(ImportedName,'SavedImportedData','-v7.3')
waitbar(1,h,strcat('Importing Completed'));

app.Variables.CurrentPlottingVariable=1;

if DetectOutliers
    for ch=1:app.Variables.NumChannels
        VarNames{1,ch}=sprintf('Channel%d',ch);
    end
    for istim=1:length(app.Variables.AllStims)
        RowNamesVar{istim,1}=sprintf('%duA',app.Variables.AllStims(istim));
    end
    for iNode=1:NumSelectedStreams
        CurrentStream=app.Tree.CheckedNodes(iNode).Text;
        FoundOutliers=cell2table(WriteOutlierCSV(:,:,iNode),'VariableNames',VarNames,'RowNames',RowNamesVar);
        writetable(FoundOutliers,strcat(app.Variables.SaveFolder,filesep,'Found Outlier Sweeps_',CurrentStream,'.csv'),'WriteRowNames',1,'writevariablenames',1)


        if ~isempty(getfield(app.Variables,CurrentStream,'Flags','ExcludeChannels'))
            ExcludedTable=table(getfield(app.Variables,CurrentStream,'Flags','ExcludeChannels'),'VariableNames',{'ExludedChannel'});
            writetable(ExcludedTable,strcat(app.Variables.SaveFolder,filesep,'Excluded and Interpolated Channels_',CurrentStream,'.csv'))
        else
            ExcludedTable=table({'none excluded'},'VariableNames',{'ExludedChannel'});
            writetable(ExcludedTable,strcat(app.Variables.SaveFolder,filesep,'Excluded and Interpolated Channels_',CurrentStream,'.csv'))
        end
    end
end

waitbar(1,h,strcat('Importing Completed, You may continue analyzing'));
cd(app.Variables.MainFunctionFolder)