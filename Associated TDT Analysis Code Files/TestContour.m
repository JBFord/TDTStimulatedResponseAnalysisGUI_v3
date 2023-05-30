% Make Heat Maps

handles.Variables.timepts=timepts;
for ii=1:10
   Avg(ii,:,:)=mean(data(1+(ii-1)*9:(ii)*9,:,:));
end

CSD=diff(diff(Avg,[],2),[],2)./0.1^2;
handles.Variables.NumChannels=16;

%Recreate John's variables
% dyyl=squeeze(handles.Variables.Rawcsd(9,1,:,:));
dyyl=squeeze(CSD(9,:,:));
ts=handles.Variables.timepts;
numCSDChannels=5;

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

[X1,Y1]=meshgrid(ts,[1:handles.Variables.NumChannels-2]);
% [X2,Y2]=meshgrid(ts,linspace(1,handles.Variables.NumChannels-2,numCSDChannels));
[X2,Y2]=meshgrid(ts,linspace(1,handles.Variables.NumChannels-2,numCSDChannels*size(dyyl,1)));
interp12dyyl=interp2(X1,Y1,dyyl,X2,Y2,'cubic');

OnlyCSD=interp12dyyl(:,200:end);

if 1
% figure;imagesc(ts,[1:14],interp12dyyl)
% V=[min(OnlyCSD(:))  -1 1  max(OnlyCSD(:))];
mincsd1=min(OnlyCSD(:));
maxcsd1=max(OnlyCSD(:));
numcsdsteps=100;
 V=linspace(mincsd1,maxcsd1,numcsdsteps);
contour(ts,flipud(linspace(1,14,size(interp12dyyl,1))),flipud(interp12dyyl),V,'Fill','on','LineStyle','none')
set(gca,'FontSize',18)
ylabel('Electrode #')
xlabel('Time (s)')
colormap(cm)
P=caxis;
caxis(0.8.*P)
caxis(P)

% figure;imagesc(ts,[1:14],interp12dyyl-min(interp12dyyl)+1)
% set(gca,'FontSize',18)
% ylabel('Electrode #')
% xlabel('Time (s)')
% set(gca,'ColorScale','log')
% colormap(cm)
% caxis([-5 0])

end

keyboard
%%
stimdelay=.032; %s, position of stim within sweep
prestimtime=.03; % s amount of time to display before stim
poststimtime=0.15; % s, amount of post-stim response to show, 0.030 for 0.06 ms
                        % for evoked should be higher, perhaps 0.25
lfpgain=-0.025; % a 0.025 mV, 25 uV offset between each trace, this is good for opto response
csdgain=-2; %for csd  -2 for opto small responses, -20 for evoked
colorscale =2.5; % max and min of contour plot 2.5 for small opto, up to 100 otherwise
paddingproportion=1.6; % i.e. 1.6 = 160 % of display offset
spacing=.1; % interelectrode spacing in mm
pause_dur=.2; % pause, in seconds
plottingcontour=true;
%swp=[];
numcsdsteps=50; % number of graduations in colors of contour plot
plottingzero=1; % place dotted zero lines for each channel in CSD
fillingcsd=0;  % actually fill csd middle plot with blue below line (sink) and red above line (source)
plottingcsd=0; % make plots of csd (bottom two rows).  Otherwise just lfp
zooming=0; 


maxcsd=1;
mincsd=-1;

graphcolumns=2;
j=1;
xzoom=[0 1];
si=ts(2)-ts(1);

LogCSD=0;
bluewhiteredmap=1;
%%

if plottingcontour && i <2  &&size(dyyl,1)>2 % only plot one contour, even if overlapping traces, otherwise doesn't make sense
    firstChannel = 1;
    numCSDChannels = size(dyyl,1);
    firstCSDChannel= firstChannel+1;
    lastCSDChannel = numCSDChannels + firstChannel;
    x=linspace(0,max(ts),size(dyyl,2));
    y=linspace(firstCSDChannel,lastCSDChannel,numCSDChannels); % make the y axis values for contour plot
    V=linspace(mincsd,maxcsd,numcsdsteps);
    for p=1:numCSDChannels
        ytl{p}=sprintf('%d',y(p));
    end
%     subplot(3,graphcolumns,2*graphcolumns+j);
    xsamp=xzoom/si;
    xsamp1=int32(xsamp(1));
    if (xsamp1<1)
        xsamp1=1;
    end
    xsamp2=int32(xsamp(2));
    cplot=flipud(dyyl(:,xsamp1:xsamp2));
    
    csdscale='mV/mm^2';
    mincsd1=mincsd;
    maxcsd1=maxcsd;
    
    
    paddingcsd=false;
    csdpad=5; % this is how many times to grow the max value by
    padsteps=5; % and this is number of steps in contour in this "grown" region
    if paddingcsd
        
        V=[linspace(mincsd1*csdpad,mincsd1,padsteps) linspace(mincsd1,maxcsd1,numcsdsteps) linspace(maxcsd1,maxcsd1*csdpad,padsteps)];
    end
    
    
    if LogCSD
        cplot=neglog(cplot);
        maxcsd1=log10(maxcsd);
        mincsd1=-maxcsd1;
        V=linspace(mincsd1,maxcsd1,numcsdsteps);
        csdscale=['log(' csdscale ')'];
    end
    
    % determine where the under minimum parts of the csd plot will
    % be.  Normally matlab makes them white.  we can fill them in
    % later with min color matlab already puts saturating max as
    % last max color, so this will be symmetrical
    cplotmax=max(max(cplot));
    cplotmin=min(min(cplot));
    if cplotmin*-1>cplotmax
        cplotmax=-1*cplotmin;
    end
    %
    V1=[-cplotmax mincsd maxcsd cplotmax];
    c1=contour(x(xsamp1:xsamp2),y,cplot,V1,'Fill','on','LineStyle','none');
    c3=1;
    minthisval=1e6;
    for c2=1:size(c1,2) % there should only be two contours at this point size(c1,2)
        if c3<=size(c1,2) % testing whether there are any more contours.  If not, then just skip the codes
            nextc=c1(2,c3)+1;
            thisval=c1(1,c3);
            
            if thisval<minthisval
                minthisval=thisval;
            end
            if thisval<=mincsd
                
                px{c2}=c1(1,c3+1:c3+nextc-1);
                py{c2}=c1(2,c3+1:c3+nextc-1);
            else
                break;
            end
            %fprintf(' %.2f:%d',thisval,c3)
            
            
            c3=c3+nextc;
        end
    end
    if minthisval>mincsd
        px={}; % empty px in case we have no under saturated contours;
    end
    contour(x(xsamp1:xsamp2),y,cplot,V,'Fill','on','LineStyle','none');
    t=colorbar('east');
    set(get(t,'title'),'String',csdscale)
    set(gca,'xlim',xzoom);
    set(gca,'YTick',y)
    set(gca,'YTickLabel',fliplr(ytl))
    %          set(gca, 'YTickLabel',fliplr(4:13))
    
    caxis([min(V),max(V)]);
    if bluewhiteredmap
        colormap(bluewhitered1);
    else
        colormap jet;
    end
    cm=colormap;
    for p=1:size(px,2)
        patch(px{p},py{p},cm(1,:),'LineStyle','none');
    end
    xlabel('Time (s)');
    ylabel('Electrode #')
end

caxis([])