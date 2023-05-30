function varargout = BatchAnalyzing(varargin)
% BATCHANALYZING MATLAB code for BatchAnalyzing.fig
%      BATCHANALYZING, by itself, creates a new BATCHANALYZING or raises the existing
%      singleton*.
%
%      H = BATCHANALYZING returns the handle to a new BATCHANALYZING or the handle to
%      the existing singleton*.
%
%      BATCHANALYZING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BATCHANALYZING.M with the given input arguments.
%
%      BATCHANALYZING('Property','Value',...) creates a new BATCHANALYZING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BatchAnalyzing_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BatchAnalyzing_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BatchAnalyzing

% Last Modified by GUIDE v2.5 04-Apr-2023 17:18:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BatchAnalyzing_OpeningFcn, ...
                   'gui_OutputFcn',  @BatchAnalyzing_OutputFcn, ...
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


% --- Executes just before BatchAnalyzing is made visible.
function BatchAnalyzing_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BatchAnalyzing (see VARARGIN)

% Choose default command line output for BatchAnalyzing
handles.output = hObject;
addpath(genpath('Associated TDT Analysis Code Files'));
handles.MainFunctionFolder=pwd;
handles.Variables=struct();
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BatchAnalyzing wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = BatchAnalyzing_OutputFcn(hObject, eventdata, handles) 
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
% SlashLocations=strfind(FolderPath,filesep);
% parentFolder=FolderPath(1:SlashLocations(end));
% StimNumLocations=strfind(FolderPath,'-');
% if str2double(FolderPath(StimNumLocations(end)+1:end))~=1
%     keyboard
% end
% BaseName=FolderPath(1:StimNumLocations(end));
parentFolder=FolderPath;

if ~isfield(handles.Variables,'parentFolder')
    FolderNumber=0;
    handles.Variables(1).parentFolder=cell([]);
else
    FolderNumber=length(handles.Variables.parentFolder);
end

handles.Variables.parentFolder{FolderNumber+1}=string(parentFolder);
% handles.Variables.BaseName{FolderNumber+1}=string(BaseName);

handles.ImportPathListListBox.String=handles.Variables.parentFolder;
guidata(hObject, handles);



% --- Executes on button press in RemoveSelectedPathButton.
function RemoveSelectedPathButton_Callback(hObject, eventdata, handles)
% hObject    handle to RemoveSelectedPathButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    FolderToRemove=handles.ImportPathListListBox.Value;

    handles.Variables.parentFolder(FolderToRemove)=[];
%     handles.Variables.BaseName(FolderToRemove)=[];


    if FolderToRemove>length(handles.Variables.parentFolder)
handles.ImportPathListListBox.Value=FolderToRemove-1;
    end
handles.ImportPathListListBox.String=handles.Variables.parentFolder;

guidata(hObject, handles);

% --- Executes on button press in BatchAnalyzeFiles.
function BatchAnalyzeFiles_Callback(hObject, eventdata, handles)
% hObject    handle to BatchAnalyzeFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
AnalyzeLFPs=handles.AnalyzeLFPBox.Value;
AnalyzeCSDs=handles.AnalyzeCSDBox.Value;
RunRaw=handles.AnalyzeRawsBox.Value;
RunBP60=handles.AnalyzeBP60Box.Value;
RunMult=handles.AnalyzeMultBox.Value;
RunFiltered=handles.AnalyzeFilteredBox.Value;

if ~AnalyzeLFPs && ~AnalyzeCSDs
    msgbox('Please select data to analyze (e.g. LFPs)')
    error('Data to analyze selection needed (e.g. LFPs)')
end


for iFolder=1:length(handles.Variables.parentFolder)
    iBatch=handles;
    iParentFolder=handles.Variables.parentFolder{iFolder};

    cd(iParentFolder)
    FolderContents=dir;

    PotentialImport=[];
    PotentialImportDate=[];
    PotentialImportTime=[];

    PotentialName=[];
    PotentialNameDate=[];
    PotentialNameTime=[];

    PotentialWindow=[];
    PotentialWindowDate=[];
    PotentialWindowTime=[];

    for iContent=3:length(FolderContents)
        name=FolderContents(iContent).name;

        %Find Most recent data
        if strfind(name,'ImportedData')
            PotentialImport=iContent;
            PotentialImportDate=[PotentialImportDate str2double(name(end-16:end-11))];
            PotentialImportTime=[PotentialImportTime str2double(name(end-9:end-4))];
        end

        %Find Most recent Names
        if strfind(name,'ChannelNames')
            PotentialName=iContent;
            PotentialNameDate=[PotentialNameDate str2double(name(end-16:end-11))];
            PotentialNameTime=[PotentialNameTime str2double(name(end-9:end-4))];
        end

        %Find Most recent Windows
        if strfind(name,'AnalysisWindows')
            PotentialWindow=iContent;
            PotentialWindowDate=[PotentialWindowDate str2double(name(end-16:end-11))];
            PotentialWindowTime=[PotentialWindowTime str2double(name(end-9:end-4))];
        end


    end
    if isempty(PotentialImport)
        msgbox(sprintf('No imported data file found in %s',iParentFolder))
    end
    if isempty(PotentialName)
        msgbox(sprintf('No channel name file found in %s',iParentFolder))
    end
    if isempty(PotentialWindow)
        msgbox(sprintf('No analysis window file found in %s',iParentFolder))
    end
if isempty(PotentialWindow) | isempty(PotentialName) | isempty(PotentialImport)
    continue
end
keyboard
    [mImport]=max(PotentialImportDate);
    SecondTierPotentialImportTime= PotentialImportTime(PotentialImportDate==mImport);
    SecondTierPotentialImport= PotentialImport(PotentialImportDate==mImport);
    [~,useImport]=max(SecondTierPotentialImportTime);
    ImportFile=FolderContents(SecondTierPotentialImport(useImport)).name;


    [mName]=max(PotentialNameDate);
    SecondTierPotentialNameTime= PotentialNameTime(PotentialNameDate==mName);
    SecondTierPotentialName= PotentialName(PotentialNameDate==mName);
    [~,useName]=max(SecondTierPotentialNameTime);
    NameFile=FolderContents(SecondTierPotentialName(useName)).name;


    [mWindow]=max(PotentialWindowDate);
    SecondTierPotentialWindowTime= PotentialWindowTime(PotentialWindowDate==mWindow);
    SecondTierPotentialWindow= PotentialWindow(PotentialWindowDate==mWindow);
    [~,useWindow]=max(SecondTierPotentialWindowTime);
    WindowFile=FolderContents(SecondTierPotentialWindow(useWindow)).name;







    BatchAnalyzeFcn(iBatch,ImportFile,NameFile,WindowFile)

end


% --- Executes on button press in PeakBox.
function PeakBox_Callback(hObject, eventdata, handles)
% hObject    handle to PeakBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PeakBox


% --- Executes on button press in AreaBox.
function AreaBox_Callback(hObject, eventdata, handles)
% hObject    handle to AreaBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AreaBox


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in AnalyzeLFPBox.
function AnalyzeLFPBox_Callback(hObject, eventdata, handles)
% hObject    handle to AnalyzeLFPBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AnalyzeLFPBox


% --- Executes on button press in AnalyzeCSDBox.
function AnalyzeCSDBox_Callback(hObject, eventdata, handles)
% hObject    handle to AnalyzeCSDBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AnalyzeCSDBox


% --- Executes on button press in AnalyzeRawsBox.
function AnalyzeRawsBox_Callback(hObject, eventdata, handles)
% hObject    handle to AnalyzeRawsBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AnalyzeRawsBox


% --- Executes on button press in AnalyzeBP60Box.
function AnalyzeBP60Box_Callback(hObject, eventdata, handles)
% hObject    handle to AnalyzeBP60Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AnalyzeBP60Box


% --- Executes on button press in AnalyzeMultBox.
function AnalyzeMultBox_Callback(hObject, eventdata, handles)
% hObject    handle to AnalyzeMultBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AnalyzeMultBox


% --- Executes on button press in AnalyzeFilteredBox.
function AnalyzeFilteredBox_Callback(hObject, eventdata, handles)
% hObject    handle to AnalyzeFilteredBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AnalyzeFilteredBox
