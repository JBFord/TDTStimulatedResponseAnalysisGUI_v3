function app=GetDataFromTDT(app,Stream)

FilterFlag=app.Variables.Flags.ImportFilterFlag;

if FilterFlag
    HP=app.Variables.HighPassFilter;
    LP=app.Variables.LowPassFilter;
end

for iStim=1:app.Variables.NumStims
    %Load in data
    LoadName=strcat(app.Variables.BaseName,num2str(iStim));
    data=SEV2mat(LoadName,'EventName',Stream);
    LFPData=getfield(data,Stream,'data');
    Fs=getfield(data,Stream,'fs');
    dt=1/Fs;
    TraceTime=[0:dt:dt*(length(LFPData(1,:))-1)];

            WindowLength=app.Variables.SweepChopDuration; %sec
            PreArtifactWindow=WindowLength*0.005; %sec
            PostArtifactWindow=WindowLength-PreArtifactWindow;

    WindowIndices=floor(WindowLength*Fs);
    PreWindowIndices=floor(PreArtifactWindow*Fs);
    PostWindowIndices=WindowIndices-PreWindowIndices;


    %Determine when sweeps start
    Epocs=TDTbin2mat(LoadName,'TYPE',{'epocs'});
    SweepStarts=Epocs.epocs.EpcV.onset;
    SweepStartIndices=round(SweepStarts.*Fs);


    %%%%%%%% Raw Data Parsing
    ArtifactLocations=AppFindArtifacts(app.Variables,LFPData,PostWindowIndices,Fs,SweepStartIndices,iStim);

    %Chop up into sweeps base on artifact timing
    [Sweeps,SweepTime]=ParseTDTDatav2(LFPData,app.Variables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,ArtifactLocations);

    %Combine all sweeps across stims into a single variable
    AllLFPData(iStim,:,:,:)=permute(Sweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
    AllLFPTime(iStim,:,:,:)=permute(SweepTime,[4 1 3 2]);
    AllArtifactLocations(iStim,:)=ArtifactLocations;


    if app.Variables.Flags.ImportFilterFlag
        Filtered=zeros(app.Variables.NumChannels,size(LFPData,2));
        for jj=1:app.Variables.NumChannels
            Filtered(jj,:)=transpose(filtfilt2((LFPData(jj,:)),HP,LP,Fs, 1));
        end
        FilteredArtifactLocations=AppFindArtifacts(app.Variables,Filtered,PostWindowIndices,Fs,SweepStartIndices,iStim);
        [FilteredSweeps,FilteredSweepTime]=ParseTDTDatav2(Filtered,app.Variables.NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,FilteredArtifactLocations);

        %Combine all sweeps across stims into a single variable
        AllFiltered(iStim,:,:,:)=permute(FilteredSweeps,[4 1 3 2]);  %Rows are stims, columns are sweeps, depth is channel, 4th dimension is time
        AllFilteredArtifactLocations(iStim,:)=FilteredArtifactLocations;
    end
    end

    timepts=AllLFPTime(1,:)-AllLFPTime(1,PreWindowIndices+1);


    app.Variables=setfield(app.Variables,Stream,'LFPData',AllLFPData);
    app.Variables=setfield(app.Variables,Stream,'AllLFPTime',AllLFPTime);

    app.Variables=setfield(app.Variables,Stream,'timepts',timepts);
    app.Variables=setfield(app.Variables,Stream,'Fs',Fs);
    app.Variables=setfield(app.Variables,Stream,'dt',dt);
    app.Variables=setfield(app.Variables,Stream,'WindowLength',WindowLength);
    app.Variables=setfield(app.Variables,Stream,'PreArtifactWindow',PreArtifactWindow);
    app.Variables=setfield(app.Variables,Stream,'PostArtifactWindow',PostArtifactWindow);
    app.Variables=setfield(app.Variables,Stream,'WindowIndices',WindowIndices);

    app.Variables=setfield(app.Variables,Stream,'PreWindowIndices',PreWindowIndices);
    app.Variables=setfield(app.Variables,Stream,'PostWindowIndices',PostWindowIndices);
    app.Variables=setfield(app.Variables,Stream,'PostArtifactWindow',PostArtifactWindow);
    app.Variables=setfield(app.Variables,Stream,'AllArtifactLocations',AllArtifactLocations);

    if app.Variables.Flags.ImportFilterFlag
        app.Variables=setfield(app.Variables,Stream,'AllFilteredLFPData',AllFiltered);
        app.Variables=setfield(app.Variables,Stream,'AllFilteredLFPArtifactLocations',AllFilteredArtifactLocations);
    end
end

