function InterpolatedData=AppInterpolateChannels(Variables,DataToInterpolate,ExcludedChannels,CurrentStream)
%DataToInterpolate must be Stims x Sweeps x Channels x Time
% Sweeps dimension will be 1 because only averaged data should be
% interpolated
%Only using averaged data allows for outlier traces to be excluded


 
 %DO NOT USE 4D INTERPOLATION, THIS WILL NOT EXCLUDE BAD TRACES IDENTIFIED
 %USING DETECT OUTLIERS
 InterpolationDimensions=3;


% Variables.Flags.ExcludeChannels=4;
time=getfield(Variables,CurrentStream,'timepts');
channels=[1:Variables.NumChannels];
GoodChannels=channels;
GoodChannels(ExcludedChannels)=[];
stims=Variables.AllStims;
Sweeps=[1:Variables.NumSweeps];


% keyboard
% Looks like Interp3 = mean(Interp4,2), so if we want individual LFP sweep
% info, calculate Interp4LFPs, otherwise use Interp3LFPs only
switch InterpolationDimensions
%Interp2LFPS is not equal to Inter3LFPs
    case 0


    case 2
%% Two dimensional interpolation of average LFPs
% Only interpolate over channel and time
[X,Y]=meshgrid(time,GoodChannels);
[Xq,Yq]=meshgrid(time,channels);
for s=1:length(stims)
    A=squeeze(DataToInterpolate(s,1,:,:));
A(ExcludedChannels,:)=[];
% Interp2LFPs(s,:,:,:)=permute(interp2(X,Y,A,Xq,Yq,'cubic'),[3 4 1 2]);
Interp2LFPs(s,:,:,:)=(interp2(X,Y,A,Xq,Yq,'linear'));
end

InterpolatedData=permute(Interp2LFPs,[1 4 2 3]);

    case 3
%% Three dimensional interpolation of average LFPs
% Only interpolate over stim, channel and time
% [X,Y,Z]=meshgrid(GoodChannels,stims,time);
% [Xq,Yq,Zq]=meshgrid(channels,stims,time);
% B=squeeze(DataToInterpolate(:,1,:,:));
% B(:,ExcludedChannels,:)=[];
% Interp3LFPs=interp3(X,Y,Z,B,Xq,Yq,Zq,'linear');

% InterpolatedData=permute(Interp3LFPs,[1 4 2 3]);

Interp3LFPs=squeeze(DataToInterpolate);
InterpolatedData=DataToInterpolate;
InterpolatedChannels=interp3(GoodChannels,stims,time,Interp3LFPs(:,GoodChannels,:),ExcludedChannels',stims,time,'spline');
for ii=1:length(ExcludedChannels)
InterpolatedData(:,1,ExcludedChannels(ii),:)=InterpolatedChannels(:,ii,:);
end

% InterpolatedData=Interp3LFPs
end
% keyboard



