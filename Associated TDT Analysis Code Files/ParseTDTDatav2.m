function [Sweeps,SweepTime]=ParseTDTDatav2(data,NumSweeps,TraceTime,PreWindowIndices,PostWindowIndices,ArtifactLocations)

%Check for situations where number of detected sweeps is fewer than
%expected sweeps
NaNSweeps=ArtifactLocations==0;
        
        for iSweep=1:NumSweeps
            if NaNSweeps(iSweep)
                Sweeps(iSweep,:,:)=nan(size(Sweeps(1,:,:)));
            else
            Sweeps(iSweep,:,:)=permute(data(:,ArtifactLocations(iSweep)-PreWindowIndices:ArtifactLocations(iSweep)+PostWindowIndices),[3 2 1]);
            end
        end

        
        SweepTime=TraceTime(ArtifactLocations(iSweep)-PreWindowIndices:ArtifactLocations(iSweep)+PostWindowIndices);
