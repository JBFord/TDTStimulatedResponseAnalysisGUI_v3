function ExportAllResults_v3(app)

%Determine Variable Names of Exported Data
BaseVariableNames={ 'Stream','Variable','Channel','StimulationIntensity_uA','ChannelName','WindowName','WindowStart_sec','WindowEnd_sec'};

for iStream=1:length(app.Variables.Analyze.StreamsAnalyzed)
    stream=app.Variables.Analyze.StreamsAnalyzed{iStream};
    time=getfield(app.Variables,stream,'timepts');
    for iVar=1:length(app.Variables.Analyze.VariablesAnalyzed)
        variable=app.Variables.Analyze.VariablesAnalyzed{iVar};
        OutCell={};
        TableRow=0;
        for iChan=1:length(fieldnames(getfield(app.Variables,variable)))
            channame=strcat(variable(1:end-1),'_',num2str(iChan));
            if length(fieldnames(getfield(app.Variables,variable,channame,'Windows')))

                NumWindows=length(getfield(app.Variables,variable,channame,'Windows'));
                if NumWindows==1
                    % NumWindows=length(fieldnames(getfield(app.Variables,variable,channame,'Windows')));
                end
            else
                NumWindows=0;
            end


            for iWin=1:NumWindows
                TableRow=size(OutCell,1);
                ResultNames=fieldnames(getfield(app.Variables.Results,stream,variable,channame));
                if TableRow==0
                    VariableNames={BaseVariableNames{:},ResultNames{3:end}};
                end

                for iStim=1:app.Variables.NumStims
                    TableRow=TableRow+1;
                    OutCell{TableRow,1}=stream;
                    OutCell{TableRow,2}=variable;
                    OutCell{TableRow,3}=iChan;
                    OutCell{TableRow,4}=app.Variables.AllStims(iStim);
                    OutCell{TableRow,5}=getfield(app.Variables,variable,channame,'ChannelName');

                    for iResult=1:length(ResultNames)
                        if iResult==1
                            try
                            OutCell{TableRow,iResult+5}=getfield(app.Variables.Results,stream,variable,channame,{iWin},'WindowName');
                            catch
                                keyboard
                            end
                        elseif strcmp(ResultNames(iResult),'WindowExtents')
                            OutCell{TableRow,iResult+5}=getfield(app.Variables.Results,stream,variable,channame,{iWin},'WindowExtents',{1});
                            OutCell{TableRow,iResult+6}=getfield(app.Variables.Results,stream,variable,channame,{iWin},'WindowExtents',{2});
                        else
                            
                            OutCell{TableRow,iResult+6}=getfield(app.Variables.Results,stream,variable,channame,{iWin},ResultNames{iResult},{iStim});
                        end
                    end

                end
            end
        end

        cd(app.Variables.DataParentFolder)

        % OLD METHOD outputTable=cell2table(OutCell,'VariableNames',{ 'AnalysisChannelName','ChannelNumber','StimIntensity','WindowStart','WindowEnd','MaximumDeflection','AreaUnderCurve'});
        outputTable=cell2table(OutCell,'VariableNames',VariableNames);
        % writetable(outputTable,strcat(handles.Variables.DataParentFolder,'TDTAnalysisOutput.csv'));
        timevector=datestr(now, 'yymmdd-HHMMSS');
        SaveName=strcat(app.Variables.SaveFolder,filesep,'TDTAnalysisOutput_',stream,'_',variable,'_',timevector,'.csv');
        writetable(outputTable,SaveName);

        cd(app.Variables.MainFunctionFolder)


    end
end



