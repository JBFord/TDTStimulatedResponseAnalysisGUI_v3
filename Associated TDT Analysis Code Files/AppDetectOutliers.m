function [OutlierFlag,ExcludeChannel]=AppDetectOutliers(Variables,CurrentStream)
%Future versions of this code will output ApprovedTraces as
%linear-detrended data

data=getfield(Variables,CurrentStream,'LFPData');
time=getfield(Variables,CurrentStream,'timepts');
Fs=getfield(Variables,CurrentStream,'Fs');

OutlierFlag=zeros(size(data,1),size(data,2),size(data,3));
AutoLinearDetrend=0;
LinearTrendAlpha=0.0001;
LinearDetrended=zeros(size(data,1),size(data,2),size(data,3));
ApprovedTrace=data;

si=time(2)-time(1);
tm=(1:size(data,4))*si;
pts=size(tm,2);

firstlast=floor(pts*.05);
firstlastpts=[1:firstlast  pts-firstlast:pts];

stims=Variables.AllStims;
for s=1:length(stims)
    for ch=1:size(data,3)
        
        rawtemp=(squeeze(data(s,:,ch,:)));
        
        
        % detect whether there are any nan channels signifying not enough
        % sweeps were detected upon import
       temp=rawtemp(~isnan(rawtemp(:,1)),:);
        
%        %%%Look at 60Hz noise
%        Fs=Variables.Fs;
       f=linspace(-Fs/2,Fs/2,length(temp));
       d = designfilt('bandstopiir','FilterOrder',2, ...
           'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
           'DesignMethod','butter','SampleRate',Fs);
       for ii=1:size(temp,1)
           F(ii,:)=abs(fftshift(fft(temp(ii,:))));
           
           buttLoop(ii,:) = filtfilt(d,double(temp(ii,:)));
           
       end
       
        sdtrace(s,ch,:)=double(sum(std(temp,'omitnan')));
        AT=temp;
        %% Linear trend
        if AutoLinearDetrend
            oldSweep=temp;
            IsAdjusted=zeros(1,size(temp,1));
            %determine presence of linear trend
            for sw=1:size(temp,1)
                
                
                F=fitlm(tm,temp(sw,:));
                LMslope=table2array(F.Coefficients(2,1));
                LMpvalue=table2array(F.Coefficients(2,4));
                LMIntercept=table2array(F.Coefficients(1,1));
                if LMpvalue<=LinearTrendAlpha
                    linTrend= tm.*LMslope+LMIntercept;
                    ApprovedTrace(sw+((s-1)*length(stimvals))',ch,:)=temp(sw,:)-linTrend;
                    LinearDetrended(sw+((s-1)*length(stimvals))',ch)=1;
                    AT(sw,:)=temp(sw,:)-linTrend;
                else
                    ApprovedTrace(sw+((s-1)*length(stimvals))',ch,:)=temp(sw,:);
                    AT(sw,:)=temp(sw,:);
                end
                
            end
        end
        
        
        for sw=1:size(AT,1)
            p=polyfit(tm(firstlastpts),AT(sw,firstlastpts),1);
            slopes(sw)=p(1);
            
            p2=polyfit(tm,AT(sw,:),1);
            slopes2(sw)=p2(1);
            
            %             F{sw}=fitlm(tm,temp(sw,:));
            %             LMslope(sw)=table2array(F{sw}.Coefficients(2,1));
            %             LMpvalue(sw)=table2array(F{sw}.Coefficients(2,4));
        end
        
        
        %% Difference outlier
        meantrace=mean(AT,2,'omitnan');
        difftraces=AT-meantrace;
        difference=sum(abs(difftraces)');
        [goodtraces1,outliers1]=rmoutliers(difference,'threshold',7);
        
        [goodtraces,outliers]=rmoutliers(slopes,'threshold',7);
        [goodtraces3,outliers3]=rmoutliers(slopes2,'threshold',7);
        
         if any(outliers) || any(outliers1)
             outliers2=outliers | outliers1;
           
            OutlierFlag(s,find(outliers2),ch)=1;
            figure;
            subplot(2,1,1);
            temp2=AT;
            temp2(outliers2,:)=[];
            plot(tm,mean(temp2));
            hold on;
            plot(tm,AT(outliers2,:)');
            ylim([-.0004 .0004]);
            title(sprintf('stim = %.0f, ch = %d, slope outlier(s) = %s, diff outliers= %s',stims(s),ch,num2str(find(outliers)),num2str(find(outliers1))));
            subplot(2,1,2);
            plot(tm,temp2);
            ylim([-.0004 .0004]);
            title(sprintf('all kept traces = %s',num2str(find(~outliers2))));
            end

    end
end

%% Find Outlier/Broken Channels
AverageDeviation=mean(sdtrace,'omitnan');
figure;plot([1:16],AverageDeviation);xlabel('Channel');ylabel('Average Total STD Across Sweeps')


ExcludeChannel=[];
%Old exclusion method
% if any(AverageDeviation>=1)
%     ExcludeChannel=find(AverageDeviation>=1);
%     
% end

%New method doesn't usethreshold of Average Total STD Across Sweeps but
%instead looks for a channel that has a different Average Total STD Across
%Sweeps compared to other channels, currently only looks at greater
%channels
[~,OutlierChannels]=rmoutliers(AverageDeviation,'threshold',7);
GreaterThanMean=AverageDeviation>mean(AverageDeviation);
ExcludeChannel=find(OutlierChannels & GreaterThanMean);
if ~isempty(ExcludeChannel)
    hold on
plot(ExcludeChannel,AverageDeviation(ExcludeChannel),'*r')
end

