function InterpolatedData=InterpolateChannels(handles,DataToInterpolate)
%DataToInterpolate must be Stims x Sweeps x Channels x Time
% Sweeps dimension will be 1 because only averaged data should be
% interpolated
%Only using averaged data allows for outlier traces to be excluded


 
 %DO NOT USE 4D INTERPOLATION, THIS WILL NOT EXCLUDE BAD TRACES IDENTIFIED
 %USING DETECT OUTLIERS
 InterpolationDimensions=2;


% handles.Variables.Flags.ExcludeChannels=4;
time=handles.Variables.timepts;
channels=[1:handles.Variables.NumChannels];
GoodChannels=channels;
GoodChannels(handles.Variables.Flags.ExcludeChannels)=[];
stims=handles.Variables.AllStims;
Sweeps=[1:handles.Variables.NumSweeps];



% Looks like Interp3 = mean(Interp4,2), so if we want individual LFP sweep
% info, calculate Interp4LFPs, otherwise use Interp3LFPs only
switch InterpolationDimensions
%Interp2LFPS is not equal to Inter3LFPs
    case 2
%% Two dimensional interpolation of average LFPs
% Only interpolate over channel and time
[X,Y]=meshgrid(time,GoodChannels);
[Xq,Yq]=meshgrid(time,channels);
for s=1:length(stims)
    A=squeeze(DataToInterpolate(s,1,:,:));
A(handles.Variables.Flags.ExcludeChannels,:)=[];
% Interp2LFPs(s,:,:,:)=permute(interp2(X,Y,A,Xq,Yq,'cubic'),[3 4 1 2]);
Interp2LFPs(s,:,:,:)=(interp2(X,Y,A,Xq,Yq,'cubic'));
end

InterpolatedData=permute(Interp2LFPs,[1 4 2 3]);

    case 3
%% Three dimensional interpolation of average LFPs
% Only interpolate over stim, channel and time
[X,Y,Z]=meshgrid(GoodChannels,stims,time);
[Xq,Yq,Zq]=meshgrid(channels,stims,time);
B=squeeze(DataToInterpolate(:,1,:,:));
B(:,handles.Variables.Flags.ExcludeChannels,:)=[];
Interp3LFPs=interp3(X,Y,Z,B,Xq,Yq,Zq,'cubic');

InterpolatedData=permute(Interp3LFPs,[1 4 2 3]);

%     case 4
% %% Four dimensional interpolation of LFP individual sweeps
% %Interpolate over stim, sweep, channel, and time
% C=handles.Variables.AllRaw;
% [X,Y,Z,P]=ndgrid(stims,Sweeps,GoodChannels,time);
% [Xq,Yq,Zq,Pq]=ndgrid(stims,Sweeps,channels,time);
% C(:,:,handles.Variables.Flags.ExcludeChannels,:)=[];
% Interp4LFPs=interpn(X,Y,Z,P,C,Xq,Yq,Zq,Pq);
end





