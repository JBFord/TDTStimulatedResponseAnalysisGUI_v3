function MakeHeatmaps(handles)
minX=str2double(handles.MinPlotTime.String)/1000;
maxX=str2double(handles.MaxPlotTime.String)/1000;
WindowString={['[',handles.MinPlotTime.String,' to ',handles.MaxPlotTime.String,' ms]']};

timepts=handles.Variables.timepts;
PreArtifactWindowLengthIndices=handles.Variables.PreArtifactWindowLengthIndices;

smoothnessparameter=0;
PlotFiltered=handles.MakeFilteredPlotBox.Value;

MakeRawPlots=handles.MakeRawPlotButton.Value;
MakeBP60Plots=handles.MakeBP60PlotButton.Value;
MakeMultPlots=handles.MakeMultPlotButton.Value;

SaveAsPNG=handles.PNGFormatBox.Value;
SaveAsSVG=handles.SVGFormatBox.Value;

%This is just a stand-in code that assumes all data is on Gladstone's Hive,
% need to incorporate way to switch between mac and PC if data is not on
% Hive
if ispc & strcmp(handles.Variables.Flags.OS,'mac')
    SaveFolder=handles.Variables.SaveFolder;
    SaveFolder=strrep(SaveFolder,'/Volumes/','\\hive.gladstone.internal\');
    SaveFolder=strrep(SaveFolder,'/','\');
    cd(SaveFolder)
elseif ismac & strcmp(handles.Variables.Flags.OS,'pc')
    SaveFolder=handles.Variables.SaveFolder;
    SaveFolder=strrep(SaveFolder,'\\hive.gladstone.internal\','/Volumes/');
    SaveFolder=strrep(SaveFolder,'\','/');
    cd(SaveFolder)
else
    SaveFolder=handles.Variables.SaveFolder;
    cd(SaveFolder)
end

if PlotFiltered
    if MakeRawPlots
        stream='Raw';
        CSDs=handles.Variables.FilteredRawcsd;
    elseif MakeBP60Plots
        stream='BP60';
        CSDs=handles.Variables.FilteredBP60csd;
    elseif MakeMultPlots
        stream='Mult';
        CSDs=handles.Variables.FilteredMultcsd;
    end
else

    if MakeRawPlots
        stream='Raw';
        CSDs=handles.Variables.Rawcsd;
    elseif MakeBP60Plots
        stream='BP60';
        CSDs=handles.Variables.BP60csd;
    elseif MakeMultPlots
        stream='Mult';
        CSDs=handles.Variables.Multcsd;
    end
end



%define colormap
for ii=1
    
cm=[  0         0    0.5000
         0    0.0323    0.5323
         0    0.0645    0.5645
         0    0.0968    0.5968
         0    0.1290    0.6290
         0    0.1613    0.6613
         0    0.1935    0.6935
         0    0.2258    0.7258
         0    0.2581    0.7581
         0    0.2903    0.7903
         0    0.3226    0.8226
         0    0.3548    0.8548
         0    0.3871    0.8871
         0    0.4194    0.9194
         0    0.4516    0.9516
         0    0.4839    0.9839
    0.0323    0.5161    1.0000
    0.0968    0.5484    1.0000
    0.1613    0.5806    1.0000
    0.2258    0.6129    1.0000
    0.2903    0.6452    1.0000
    0.3548    0.6774    1.0000
    0.4194    0.7097    1.0000
    0.4839    0.7419    1.0000
    0.5484    0.7742    1.0000
    0.6129    0.8065    1.0000
    0.6774    0.8387    1.0000
    0.7419    0.8710    1.0000
    0.8065    0.9032    1.0000
    0.8710    0.9355    1.0000
    0.9355    0.9677    1.0000
    1.0000    1.0000    1.0000
    1.0000    1.0000    1.0000
    1.0000    0.9355    0.9355
    1.0000    0.8710    0.8710
    1.0000    0.8065    0.8065
    1.0000    0.7419    0.7419
    1.0000    0.6774    0.6774
    1.0000    0.6129    0.6129
    1.0000    0.5484    0.5484
    1.0000    0.4839    0.4839
    1.0000    0.4194    0.4194
    1.0000    0.3548    0.3548
    1.0000    0.2903    0.2903
    1.0000    0.2258    0.2258
    1.0000    0.1613    0.1613
    1.0000    0.0968    0.0968
    1.0000    0.0323    0.0323
    0.9839         0         0
    0.9516         0         0
    0.9194         0         0
    0.8871         0         0
    0.8548         0         0
    0.8226         0         0
    0.7903         0         0
    0.7581         0         0
    0.7258         0         0
    0.6935         0         0
    0.6613         0         0
    0.6290         0         0
    0.5968         0         0
    0.5645         0         0
    0.5323         0         0
    0.5000         0         0];
end


% Interpolate CSDs
ChannelUpsample=10;
CSDChannels=transpose(1:1:handles.Variables.NumChannels-2);
dChannel=CSDChannels(2)-CSDChannels(1);
[OldTimepts,OldChan]=meshgrid(timepts,CSDChannels);

NewChannels=[CSDChannels(1):dChannel/ChannelUpsample:CSDChannels(end)];
[NewTimepts,NewChan]=meshgrid(timepts,NewChannels);

for jj=1:handles.Variables.NumChannels-2
        CSDticklocs=jj;
        CSDticklabels{jj}=jj;
end
%% Plot Heat Maps
for StimPlot=1:handles.Variables.NumStims


CSDuninterpMap=squeeze(CSDs(StimPlot,1,:,:));
CSDMap=griddata(OldTimepts,OldChan,CSDuninterpMap,NewTimepts,NewChan);

mid=median(CSDuninterpMap(:));
CSDscaleMax=max(max(CSDuninterpMap(:,timepts>0.0015 & timepts<0.5)));
CSDscaleMin=min(min(CSDuninterpMap(:,timepts>0.0015 & timepts<0.5)));
CSDscale=max(abs([CSDscaleMin CSDscaleMax]));

    f=figure;  
imagesc(timepts,NewChannels,CSDMap);colormap(cm);caxis([mid-(0.1*CSDscale) mid+(0.1*CSDscale)]);set(gca,'Ydir','normal')
      xlim([minX maxX])
    ylim([0 15])
    ylabel('CSD Electrode')
    yticks(fliplr(CSDticklocs))
    yticklabels(fliplr(CSDticklabels))
    title(strcat('CSD Plot, ',stream,' stream, Stim=',num2str(handles.Variables.AllStims(StimPlot)),' uA'))
    b.Parent.YAxis.FontSize=16;



    if SaveAsPNG
        SaveName=strcat(sprintf('CSD Plot, %s, Stim=%d uA, %s',stream,handles.Variables.AllStims(StimPlot)),WindowString{1},'.png');
        SavePath=strcat(SaveFolder,filesep,SaveName);
        saveas(f,SavePath)
    end

    if SaveAsPNG
        SaveName=strcat(sprintf('CSD Plot, %s, Stim=%d uA, %s',stream,handles.Variables.AllStims(StimPlot)),WindowString{1},'.svg');
        plot2svg(SaveName)
    end

    close
end
