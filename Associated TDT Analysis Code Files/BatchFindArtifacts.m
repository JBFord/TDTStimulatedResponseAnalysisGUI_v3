function ArtifactLocations=BatchFindArtifacts(Variables,Raw,PostWindowIndices,Fs,SweepStartIndices,iStim)

if 0
    %% FindPeaks Method
    MinDist=Variables.StimFreq/4;%seconds
    SortedRaw= sort(Raw(1,:),'descend');
    MinHeight= mean(SortedRaw(1:(3*Variables.NumSweeps)));
    
    [peak,loc]=findpeaks(Raw(1,:),'MinPeakHeight',MinHeight,'MinPeakDistance',round(MinDist*Fs));
end

%Check Sweep indices length matches expected num stims
if length(SweepStartIndices)>Variables.NumSweeps
    warning(sprintf('Number of detected sweeps is greater than number of expected sweeps\n         Only the first %d sweeps will be used for stimulation %d uA',Variables.NumSweeps,Variables.AllStims(iStim) ))
    SweepStartIndices=SweepStartIndices(1:Variables.NumSweeps);
elseif length(SweepStartIndices)<Variables.NumSweeps
    warning(sprintf('Number of detected sweeps is fewer than number of expected sweeps\n         The last %d sweeps of stimulation %d uA will contain nan data',Variables.NumSweeps-length(SweepStartIndices),Variables.AllStims(iStim) ))
    SweepStartIndices(length(SweepStartIndices):Variables.NumSweeps)=0;
end

signal=Raw(1,:);
for iloop=1:length(SweepStartIndices)
    
    if SweepStartIndices(iloop)==0
        ArtifactLocations(iloop)=0;
    else
        if iloop==length(SweepStartIndices)
            [m,ArtLoc]=max(signal(SweepStartIndices(iloop):SweepStartIndices(iloop)+PostWindowIndices));
        else
            [m,ArtLoc]=max(signal(SweepStartIndices(iloop):SweepStartIndices(iloop+1)));
        end
        ArtifactLocations(iloop)=ArtLoc+(SweepStartIndices(iloop)-1);
    end
    
end
