function app=CalculateResults_v2(app)

%Do Each Stream Anlyzed
for iStream=1:length(app.Variables.Analyze.StreamsAnalyzed)
    stream=app.Variables.Analyze.StreamsAnalyzed{iStream};
    time=getfield(app.Variables,stream,'timepts');
    for iVar=1:length(app.Variables.Analyze.VariablesAnalyzed)
        variable=app.Variables.Analyze.VariablesAnalyzed{iVar};

        %Select Matlab variable analyzed
        % warning('analyze filtered is hardcoded as "Off"')
        AnalyzeFiltered=app.AnalyzeFilteredDataCheckBox.Value;
        % AnalyzeFiltered=0;
        if strcmp(variable,'LFPs')
            if AnalyzeFiltered
                streamvariable=getfield(app.Variables,stream,strcat('AverageFiltered',variable(1:end-1),'Data'));
            else
                streamvariable=getfield(app.Variables,stream,strcat('Average',variable(1:end-1),'Data'));
                streamvariable=app.Variables.(stream).(['Average',variable(1:end-1),'Data']);
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
                % if NumWindows==1
                %     NumWindows=length(fieldnames(getfield(app.Variables,variable,channame,'Windows')));
                % end
            else
                NumWindows=0;
            end

            for iWin=1:NumWindows
                
                app.Variables.Results.(stream).(variable).(channame)(iWin).WindowName =    app.Variables.(variable).(channame).Windows(iWin).Name;
                % app.Variables.Results=setfield(app.Variables.Results,stream,variable,channame,iWin,'WindowName',app.Variables.(variable).(channame).Windows(iWin).Name);
                WindowExtent=app.Variables.(variable).(channame).Windows(iWin).Extents/1000;
                PeakPolarity=app.Variables.(variable).(channame).Windows(iWin).PeakPolarity;
                AreaPolarity=app.Variables.(variable).(channame).Windows(iWin).AreaPolarity;
                app.Variables.Results.(stream).(variable).(channame)(iWin).WindowExtents =  WindowExtent;

                AnalysisWindow=CalculationVariable(:,time>=WindowExtent(1) & time<=WindowExtent(2));
                ts=time(time>=WindowExtent(1) & time<=WindowExtent(2));


                %Peak
                if sum(strcmp(app.Variables.Analyze.QuantificationsAnalyzed,'Peak'))

                    %Take maximum or minimum depending on whether ooking for a peak or trough (negative peak)
                    if strcmp(PeakPolarity,'Negative')
                        [ChanPeaks,ChanLocs]=min(AnalysisWindow,[],2); %update to calculate over proper dimension
                    elseif strcmp(PeakPolarity,'Positive')
                        [ChanPeaks,ChanLocs]=max(AnalysisWindow,[],2); %update to calculate over proper dimension
                    end

                    app.Variables.Results=setfield(app.Variables.Results,stream,variable,channame,{iWin},'Peaks',ChanPeaks');
                    app.Variables.Results=setfield(app.Variables.Results,stream,variable,channame,{iWin},'PeakLocs',ts(ChanLocs'));
                end

                %Area
                if sum(strcmp(app.Variables.Analyze.QuantificationsAnalyzed,'Area'))
                    if strcmp(AreaPolarity,'Negative')
                        AUCSignalToAnalyze=AnalysisWindow;
                        AUCSignalToAnalyze(find( (AnalysisWindow)>0))=0;
                    elseif strcmp(AreaPolarity,'Positive')
                        AUCSignalToAnalyze=AnalysisWindow;
                        AUCSignalToAnalyze(find( (AnalysisWindow)<0))=0;
                    elseif strcmp(AreaPolarity,'Total')
                        AUCSignalToAnalyze=AnalysisWindow;
                    elseif strcmp(AreaPolarity,'Rectified')
                        AUCSignalToAnalyze=abs(AnalysisWindow);
                    end

                    AUC=trapz(ts,AUCSignalToAnalyze,2); %mV/mm2*s
                    app.Variables.Results=setfield(app.Variables.Results,stream,variable,channame,{iWin},'Area',AUC');

                end

                %Derivatives
                if sum(strcmp(app.Variables.Analyze.QuantificationsAnalyzed,'MaximumFirstDerivative')) | sum(strcmp(app.Variables.Analyze.QuantificationsAnalyzed,'MaximumSecondDerivative'))
                    dt=mean(diff(time));
                    timediff=0.001; %
                    diffindices=round(timediff/dt);
                    diffwindow=diffindices*dt;

                    %Calculate Derivatives
                    FirstDerivative=(CalculationVariable(:,diffindices+1:end)-CalculationVariable(:,1:end-diffindices))./diffwindow;
                    FDTime=time(round(diffindices/2):end-round(diffindices/2));
                    SecondDerivative=(FirstDerivative(:,diffindices+1:end)-FirstDerivative(:,1:end-diffindices))./diffwindow;
                    SDTime=FDTime(round(diffindices/2):end-round(diffindices/2));

                    %Calculate max derivatives
                    if strcmp(PeakPolarity,'Negative')
                        MaxFD=min(FirstDerivative(:,FDTime>=WindowExtent(1) & FDTime<=WindowExtent(2)),[],2);
                        MaxSD=max(SecondDerivative(:,SDTime>=WindowExtent(1) & SDTime<=WindowExtent(2)),[],2);
                    elseif strcmp(PeakPolarity,'Positive')
                        MaxFD=max(FirstDerivative(:,FDTime>=WindowExtent(1) & FDTime<=WindowExtent(2)),[],2);
                        MaxSD=min(SecondDerivative(:,SDTime>=WindowExtent(1) & SDTime<=WindowExtent(2)),[],2);
                    end


                    %First Derivatice
                    if sum(strcmp(app.Variables.Analyze.QuantificationsAnalyzed,'MaximumFirstDerivative'))
                        app.Variables.Results=setfield(app.Variables.Results,stream,variable,channame,{iWin},'MaxFirstDerivative',MaxFD');
                    end
                    %Second Derivatice
                    if sum(strcmp(app.Variables.Analyze.QuantificationsAnalyzed,'MaximumSecondDerivative'))
                        app.Variables.Results=setfield(app.Variables.Results,stream,variable,channame,{iWin},'MaxSecondDerivative',MaxSD');
                    end
                end
            end


        end

    end
end
end



