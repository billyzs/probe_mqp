function varargout = mainGUI(varargin)
    % mainGUI MATLAB code for mainGUI.fig
    %      mainGUI, by itself, creates a new mainGUI or raises the existing
    %      singleton*.
    %
    %      H = mainGUI returns the handle to a new mainGUI or the handle to
    %      the existing singleton*.
    %
    %      mainGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in mainGUI.M with the given input arguments.
    %
    %      mainGUI('Property','Value',...) creates a new mainGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before mainGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to mainGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help mainGUI

    % Last Modified by GUIDE v2.5 12-Dec-2016 15:26:33

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @mainGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @mainGUI_OutputFcn, ...
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
end

    % --- Executes just before mainGUI is made visible.
function mainGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to mainGUI (see VARARGIN)

    % Choose default command line output for mainGUI
    handles.output = hObject;

    % get handle to the controller
    for i = 1:2:length(varargin)
        switch varargin{i}
            case 'controller'
                handles.controller = varargin{i+1};
            otherwise
                error('unknown input')
        end
    end

    %Assign default test value
    handles.test = 0;
    %Push the default value to the GUI
    set(handles.text_test, 'String', handles.test);
    % Create video object
    % Putting the object into manual trigger mode and then
    % starting the object will make GETSNAPSHOT return faster
    % since the connection to the camera will already have
    % been established.
    try 
        handles.video = videoinput('winvideo');
        set(handles.startStopCamera,'Enable','on');
    catch ex
        set(handles.startStopCamera,'Enable','off');
    end    
    
    % Update handles structure
    guidata(hObject, handles);

    
    % UIWAIT makes mainGUI wait for user response (see UIRESUME)
    % NOT SURE IF THIS MATTERS BUT IT WAS NOT WORKING !!!
     %uiwait(handles.mainGUI, 15);
end

% --- Outputs from this function are returned to the command line.
function varargout = mainGUI_OutputFcn(hObject, eventdata, handles)
    % varargout cell array for returning output args (see VARARGOUT);
    % hObject handle to figure
    % eventdata reserved - to be defined in a future version of MATLAB
    % handles structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    handles.output = hObject;
    varargout{1} = handles.output;
end


% --- Executes on button press in startStopCamera.
function startStopCamera_Callback(hObject, eventdata, handles)
    % hObject handle to startStopCamera (see GCBO)
    % eventdata reserved - to be defined in a future version of MATLAB
    % handles structure with handles and user data (see GUIDATA)

    % Start/Stop Camera
    if strcmp(get(handles.startStopCamera,'String'),'Start Camera')
        % Camera is off. Change button string and start camera.
        set(handles.startStopCamera,'String','Stop Camera')
        start(handles.video)
        
   
        axes(handles.cameraAxes);
        preview(handles.video, hImage)
        %preview(handles.video)
        set(handles.startAcquisition,'Enable','on');
        set(handles.captureImage,'Enable','on');
        
    else
        % Camera is on. Stop camera and change button string.
        set(handles.startStopCamera,'String','Start Camera')
        stop(handles.video)
        set(handles.startAcquisition,'Enable','off');
        set(handles.captureImage,'Enable','off');
    end
end

% --- Executes on button press in captureImage.
function captureImage_Callback(hObject, eventdata, handles)
    % hObject    handle to captureImage (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % frame = getsnapshot(handles.video);
    frame = get(get(handles.cameraAxes,'children'),'cdata'); % The current displayed frame
    save('testframe.mat', 'frame');
    disp('Frame saved to file ''testframe.mat''');
end


% --- Executes on button press in startAcquisition.
function startAcquisition_Callback(hObject, eventdata, handles)
    % hObject    handle to startAcquisition (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Start/Stop acquisition
    if strcmp(get(handles.startAcquisition,'String'),'Start Acquisition')
        % Camera is not acquiring. Change button string and start acquisition.
        set(handles.startAcquisition,'String','Stop Acquisition');
        trigger(handles.video);
    else
        % Camera is acquiring. Stop acquisition, save video data,
        % and change button string.
        stop(handles.video);
        disp('Saving captured video...');

        videodata = getdata(handles.video);
        save('testvideo.mat', 'videodata');
        disp('Video saved to file ''testvideo.mat''');

        start(handles.video); % Restart the camera
        set(handles.startAcquisition,'String','Start Acquisition');
    end
end

% --- Executes when user attempts to close mainGUI.
function mainGUI_CloseRequestFcn(hObject, eventdata, handles)
    % hObject    handle to mainGUI (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: delete(hObject) closes the figure
    delete(hObject);
    delete(imaqfind);

end

% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
    % hObject    handle to pushbutton5 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    %A comparison like this would normally be moved to the model I think
    handles.controller.flipTest();
end


% --- Executes on button press in position_btn.
function position_btn_Callback(hObject, eventdata, handles)
    % hObject    handle to position_btn (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in probe_btn.
function probe_btn_Callback(hObject, eventdata, handles)
    % hObject    handle to probe_btn (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in return_btn.
function return_btn_Callback(hObject, eventdata, handles)
    % hObject    handle to return_btn (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in save_data_btn.
function save_data_btn_Callback(hObject, eventdata, handles)
    % hObject    handle to save_data_btn (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

end

function distance_text_field_Callback(hObject, eventdata, handles)
    % hObject    handle to distance_text_field (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of distance_text_field as text
    %        str2double(get(hObject,'String')) returns contents of distance_text_field as a double
end

% --- Executes during object creation, after setting all properties.
function distance_text_field_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to distance_text_field (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function na_position_text_field_Callback(hObject, eventdata, handles)
    % hObject    handle to na_position_text_field (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of na_position_text_field as text
    %        str2double(get(hObject,'String')) returns contents of na_position_text_field as a double
end

% --- Executes during object creation, after setting all properties.
function na_position_text_field_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to na_position_text_field (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function peizo_voltage_text_field_Callback(hObject, eventdata, handles)
    % hObject    handle to peizo_voltage_text_field (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of peizo_voltage_text_field as text
    %        str2double(get(hObject,'String')) returns contents of peizo_voltage_text_field as a double
end

% --- Executes during object creation, after setting all properties.
function peizo_voltage_text_field_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to peizo_voltage_text_field (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on button press in position_checkbox.
function position_checkbox_Callback(hObject, eventdata, handles)
    % hObject    handle to position_checkbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of position_checkbox
end

% --- Executes on button press in probe_checkbox.
function probe_checkbox_Callback(hObject, eventdata, handles)
    % hObject    handle to probe_checkbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of probe_checkbox
end

% --- Executes on button press in return_checkbox.
function return_checkbox_Callback(hObject, eventdata, handles)
    % hObject    handle to return_checkbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of return_checkbox
end

% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
    % hObject    handle to checkbox4 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of checkbox4
end
