function app=PeakAnalysis_v3(app)


%Do Each Stream Anlyzed
for iStream=1:length(app.Variables.Analyze.StreamsAnalyzed)
    stream=app.Variables.Analyze.StreamsAnalyzed{iStream};
    time=getfield(app.Variables,stream,'timepts');
    for iVar=1:length(app.Variables.Analyze.VariablesAnalyzed)
        variable=app.Variables.Analyze.VariablesAnalyzed{iVar};

        %Select Matlab variable analyzed
        warning('analyze filtered is hardcoded as "Off"')
        AnalyzeFiltered=0;
        if strcmp(variable,'LFPs')
            if AnalyzeFiltered
                streamvariable=getfield(app.Variables,stream,strcat('AverageFiltered',variable(1:end-1),'Data'));
            else
                streamvariable=getfield(app.Variables,stream,strcat('Average',variable(1:end-1),'Data'));
            end
        elseif strcmp(variable,'CSDs')
            if AnalyzeFiltered
                streamvariable=getfield(app.Variables,stream,strcat('Filtered',variable(1:end-1),'Data'));
            else
                streamvariable=getfield(app.Variables,stream,strcat(variable(1:end-1),'Data'));
            end
        end

        for iChan=1:length(fieldnames(getfield(app.Variables,variable)))

            CalculationVariable=squeeze(streamvariable(:,1,iChan,:));
            channame=strcat(variable(1:end-1),'_',num2str(iChan));


            if length(fieldnames(getfield(app.Variables,variable,channame,'Windows')))

                NumWindows=length(getfield(app.Variables,variable,channame,'Windows'));
                if NumWindows==1
                    NumWindows=length(fieldnames(getfield(app.Variables,variable,channame,'Windows')));
                end
            else
                NumWindows=0;
            end

            for iWin=1:NumWindows
                
                app.Variables.Results=setfield(app.Variables.Results,stream,variable,channame,{iWin},'Name',getfield(app.Variables,variable,channame,'Windows',{iWin},'Name'));
                WindowExtent=getfield(app.Variables,variable,channame,'Windows',{iWin},'Extents')/1000;
                PeakPolarity=getfield(app.Variables,variable,channame,'Windows',{iWin},'PeakPolarity');

                AnalysisWindow=CalculationVariable(:,time>=WindowExtent(1) & time<=WindowExtent(2));
                ts=time(time>=WindowExtent(1) & time<=WindowExtent(2));


                %Take maximum or minimum depending on whether ooking for a peak or trough (negative peak)
                if strcmp(PeakPolarity,'Negative')
                    [ChanPeaks,ChanLocs]=min(AnalysisWindow,[],2); %update to calculate over proper dimension
                elseif strcmp(PeakPolarity,'Positive')
                    [ChanPeaks,ChanLocs]=max(AnalysisWindow,[],2); %update to calculate over proper dimension
                end
                
                app.Variables.Results=setfield(app.Variables.Results,stream,variable,channame,{iWin},'Peaks',ChanPeaks');
                app.Variables.Results=setfield(app.Variables.Results,stream,variable,channame,{iWin},'PeakLocs',ts(ChanLocs'));
            end

        end
    end
end
end


