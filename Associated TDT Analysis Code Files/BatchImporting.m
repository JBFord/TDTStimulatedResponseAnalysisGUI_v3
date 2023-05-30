function varargout = BatchImporting(varargin)
% BATCHIMPORTING MATLAB code for BatchImporting.fig
%      BATCHIMPORTING, by itself, creates a new BATCHIMPORTING or raises the existing
%      singleton*.
%
%      H = BATCHIMPORTING returns the handle to a new BATCHIMPORTING or the handle to
%      the existing singleton*.
%
%      BATCHIMPORTING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BATCHIMPORTING.M with the given input arguments.
%
%      BATCHIMPORTING('Property','Value',...) creates a new BATCHIMPORTING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BatchImporting_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BatchImporting_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BatchImporting

% Last Modified by GUIDE v2.5 04-Apr-2023 15:24:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BatchImporting_OpeningFcn, ...
                   'gui_OutputFcn',  @BatchImporting_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before BatchImporting is made visible.
function BatchImporting_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BatchImporting (see VARARGIN)

% Choose default command line output for BatchImporting
handles.output = hObject;
addpath(genpath('Associated TDT Analysis Code Files'));
handles.MainFunctionFolder=pwd;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BatchImporting wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = BatchImporting_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in ImportPathListListBox.
function ImportPathListListBox_Callback(hObject, eventdata, handles)
% hObject    handle to ImportPathListListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ImportPathListListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ImportPathListListBox


% --- Executes during object creation, after setting all properties.
function ImportPathListListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ImportPathListListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AddBatchPathButton.
function AddBatchPathButton_Callback(hObject, eventdata, handles)
% hObject    handle to AddBatchPathButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


FolderPath=uigetdir;
SlashLocations=strfind(FolderPath,filesep);
parentFolder=FolderPath(1:SlashLocations(end));
StimNumLocations=strfind(FolderPath,'-');
if str2double(FolderPath(StimNumLocations(end)+1:end))~=1
    keyboard
end
BaseName=FolderPath(1:StimNumLocations(end));

if ~isfield(handles.Variables,'parentFolder')
    FolderNumber=0;
    try
    handles.Variables(1).parentFolder=cell([]);
    catch
        handles.Variables=setfield(handles.Variables,'parentFolder',{});
    end
else
    FolderNumber=length(handles.Variables.parentFolder);
end

handles.Variables.parentFolder{FolderNumber+1}=string(parentFolder);
handles.Variables.BaseName{FolderNumber+1}=string(BaseName);

handles.ImportPathListListBox.String=handles.Variables.parentFolder;
guidata(hObject, handles);


% --- Executes on button press in RemoveSelectedPathButton.
function RemoveSelectedPathButton_Callback(hObject, eventdata, handles)
    % hObject    handle to RemoveSelectedPathButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    FolderToRemove=handles.ImportPathListListBox.Value;

    handles.Variables.parentFolder(FolderToRemove)=[];
    handles.Variables.BaseName(FolderToRemove)=[];


    if FolderToRemove>length(handles.Variables.parentFolder)
handles.ImportPathListListBox.Value=FolderToRemove-1;
    end
handles.ImportPathListListBox.String=handles.Variables.parentFolder;

guidata(hObject, handles);


% --- Executes on button press in ImportButton.
function ImportButton_Callback(hObject, eventdata, handles)
% hObject    handle to ImportButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tic
set(handles.ImportCompletedText,'Visible','off');
handles.Variables.NumSweeps=str2double(handles.NumSweepBox.String);
handles.Variables.NumStims=str2double(handles.NumStimsBox.String);
handles.Variables.NumChannels=str2double(handles.NumChanBox.String);
handles.Variables.SweepChopDuration=str2double(handles.SweepChopBox.String);

StimValueString=handles.StimValuesBox.String;
CommaLocations=strfind(StimValueString,',');
for iComma=1:length(CommaLocations)+1
    if iComma==1
        AllStims(iComma)=str2double(StimValueString(1:CommaLocations(iComma)-1));
    elseif iComma==length(CommaLocations)+1
        AllStims(iComma)=str2double(StimValueString(CommaLocations(iComma-1)+1:end));
    else
        AllStims(iComma)=str2double(StimValueString(CommaLocations(iComma-1)+1:CommaLocations(iComma)-1));
    end
end
handles.Variables.AllStims=AllStims;

%Flags
handles.Variables.Flags.DetectOutliers=handles.OutlierDetectBox.Value;
handles.Variables.Flags.ImportMult=handles.ImportMultBox.Value;
handles.Variables.Flags.ImportBP60=handles.ImportBP60Box.Value;

NumCores=feature('numcores');

% if NumCores>1
h=waitbar(0,'Importing: 0 Folders Completed');

parfor iFolder=1:length(handles.Variables.parentFolder)

    iBatch=handles.Variables;
    iParentFolder=handles.Variables.parentFolder{iFolder};
    iBaseName=handles.Variables.BaseName{iFolder};

    BatchImportTDTData(iBatch,hObject,eventdata,handles,iParentFolder{1},iBaseName{1});

end
% 
% else
% h=waitbar(0,'Importing: 0 Folders Completed');
% for iFolder=1:length(handles.Variables.parentFolder)
% 
%     iBatch=handles.Variables;
%     iParentFolder=handles.Variables.parentFolder{iFolder};
%     iBaseName=handles.Variables.BaseName{iFolder};
% 
% %     BatchImportTDTData(iBatch,hObject,eventdata,handles,iParentFolder{1},iBaseName{1});
%     BatchImportTDTData_Parallel(iBatch,hObject,eventdata,handles,iParentFolder{1},iBaseName{1});
% waitbar((iFolder)/length(handles.Variables.parentFolder),h,strcat('Importing : ',num2str((iFolder)),' out of ',num2str(length(handles.Variables.parentFolder)),' Folders Completed'));
% end
CompletionTime=toc;
set(handles.ImportCompletedText,'Visible','on');
waitbar(1,h,strcat('Importing Completed: ',num2str(length(handles.Variables.parentFolder)),' Folders Imported over ',num2str(CompletionTime/60),' minutes' ));

% end
guidata(hObject, handles);




% --- Executes on button press in FilterCheckBox.
function FilterCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to FilterCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
FilterOption=get(hObject,'Value');
if FilterOption
    set(handles.HPText,'Visible','on')
    set(handles.HPStat,'Visible','on')
    set(handles.LPText,'Visible','on')
    set(handles.LPStat,'Visible','on')
else
    set(handles.HPText,'Visible','off')
    set(handles.HPStat,'Visible','off')
    set(handles.LPText,'Visible','off')
    set(handles.LPStat,'Visible','off')
end
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of FilterCheckBox



function HPText_Callback(hObject, eventdata, handles)
% hObject    handle to HPText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of HPText as text
%        str2double(get(hObject,'String')) returns contents of HPText as a double


% --- Executes during object creation, after setting all properties.
function HPText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to HPText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LPText_Callback(hObject, eventdata, handles)
% hObject    handle to LPText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LPText as text
%        str2double(get(hObject,'String')) returns contents of LPText as a double


% --- Executes during object creation, after setting all properties.
function LPText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LPText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in OffsetButton.
function OffsetButton_Callback(hObject, eventdata, handles)
% hObject    handle to OffsetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OffsetButton



function ElecSpacingBox_Callback(hObject, eventdata, handles)
% hObject    handle to ElecSpacingBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ElecSpacingBox as text
%        str2double(get(hObject,'String')) returns contents of ElecSpacingBox as a double


% --- Executes during object creation, after setting all properties.
function ElecSpacingBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ElecSpacingBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in OutlierDetectBox.
function OutlierDetectBox_Callback(hObject, eventdata, handles)
% hObject    handle to OutlierDetectBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OutlierDetectBox


% --- Executes on button press in ImportBP60Box.
function ImportBP60Box_Callback(hObject, eventdata, handles)
% hObject    handle to ImportBP60Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Variables.Flags.ImportBP60=get(hObject,'Value');
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of ImportBP60Box


% --- Executes on button press in ImportMultBox.
function ImportMultBox_Callback(hObject, eventdata, handles)
% hObject    handle to ImportMultBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Variables.Flags.ImportMult=get(hObject,'Value');
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of ImportMultBox



function NumChanBox_Callback(hObject, eventdata, handles)
% hObject    handle to NumChanBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
NumChannels=str2double(get(hObject,'String'));
handles.Variables.NumChannels=NumChannels;
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of NumChanBox as text
%        str2double(get(hObject,'String')) returns contents of NumChanBox as a double


% --- Executes during object creation, after setting all properties.
function NumChanBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NumChanBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NumStimsBox_Callback(hObject, eventdata, handles)
% hObject    handle to NumStimsBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NumStimsBox as text
%        str2double(get(hObject,'String')) returns contents of NumStimsBox as a double


% --- Executes during object creation, after setting all properties.
function NumStimsBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NumStimsBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
NumStims=str2double(get(hObject,'String'));
handles.Variables.NumStims=NumStims;
guidata(hObject, handles);
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NumSweepBox_Callback(hObject, eventdata, handles)
% hObject    handle to NumSweepBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
NumSweeps=str2double(get(hObject,'String'));
handles.Variables.NumSweeps=NumSweeps;
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of NumSweepBox as text
%        str2double(get(hObject,'String')) returns contents of NumSweepBox as a double


% --- Executes during object creation, after setting all properties.
function NumSweepBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NumSweepBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StimValuesBox_Callback(hObject, eventdata, handles)
% hObject    handle to StimValuesBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
StimValueString=get(hObject,'String');
CommaLocations=strfind(StimValueString,',');
for iComma=1:length(CommaLocations)+1
    if iComma==1
        AllStims(iComma)=str2double(StimValueString(1:CommaLocations(iComma)-1));
    elseif iComma==length(CommaLocations)+1
        AllStims(iComma)=str2double(StimValueString(CommaLocations(iComma-1)+1:end));
    else
        AllStims(iComma)=str2double(StimValueString(CommaLocations(iComma-1)+1:CommaLocations(iComma)-1));
    end
end
handles.Variables.AllStims=AllStims;
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of StimValuesBox as text
%        str2double(get(hObject,'String')) returns contents of StimValuesBox as a double


% --- Executes during object creation, after setting all properties.
function StimValuesBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StimValuesBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SweepChopBox_Callback(hObject, eventdata, handles)
% hObject    handle to SweepChopBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ChopDuration=str2double(get(hObject,'String'));
handles.Variables.SweepChopDuration=ChopDuration;
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of SweepChopBox as text
%        str2double(get(hObject,'String')) returns contents of SweepChopBox as a double


% --- Executes during object creation, after setting all properties.
function SweepChopBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SweepChopBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
