classdef MainView < handle
    properties
        model
        %Java Objects
        jFrame
        startCameraButton;
        captureImageButton;
    	captureVideoButton;
    	currentPositionTextArea;
    	positionButton;
    	probeButton;
    	returnButton;
    	saveDataButton;
        positionTextField;
        motorsEnableButton;
        moveModeComboBox;
        activeMotorComboBox;
        jogXNegButton;
        jogXPosButton;
        jogYNegButton;
        jogYPosButton;
        jogDistance = 0;
        cameraLabel;
        roiButton;
        calibrationModeButton;
        %handles
        varFig;
        %states
        systemState = SystemState.JOG;
        activeROI = ROI.PROBE;
        recordingVideo = false;
        updatingROI = false;
        hasClickedOnImage = false;
        %data
        activeImage = zeros(1000,1000, 'uint8');
        vidID;
        vidPath;
        varianceCalibrationData = zeros(500, 2);
        varianceDataIndex = 1;
    end
    
    methods
        function this = MainView(model)
            this.model = model;
           % this.gui = mainGUI('model',this.model);
            
            addlistener(this.model,'displacementUpdated','PostSet', ...
                @this.handlePropEvents);
        
            this.launchView();
        end
        
        function launchView(this)
            % Add Java library to dynamic Java classpath
            javaaddpath([pwd '\lib\Probe_MQP_Java_GUI.jar']);
            % Get example Java window from the library
            this.jFrame = probe_mqp_java_gui.MainUIJFrame();
            % Get Java buttons
            % Note: see http://UndocumentedMatlab.com/blog/matlab-callbacks-for-java-events-in-r2014a
            this.startCameraButton       = handle(this.jFrame.getStartCameraButton(),       'CallbackProperties');
            this.captureImageButton      = handle(this.jFrame.getCaptureImageButton(),      'CallbackProperties');
            this.captureVideoButton      = handle(this.jFrame.getCaptureVideoButton(),      'CallbackProperties');
            this.currentPositionTextArea = handle(this.jFrame.getCurrentPositionTextArea(), 'CallbackProperties');
            this.positionTextField       = handle(this.jFrame.getPositionTextField(),       'CallbackProperties');
            this.positionButton          = handle(this.jFrame.getPositionButton(),          'CallbackProperties');
            this.probeButton             = handle(this.jFrame.getProbeButton(),             'CallbackProperties');
            this.returnButton            = handle(this.jFrame.getReturnButton(),            'CallbackProperties');
            this.saveDataButton          = handle(this.jFrame.getSaveDataButton(),          'CallbackProperties');
            this.motorsEnableButton      = handle(this.jFrame.getMotorsEnableButton(),      'CallbackProperties'); 
            this.moveModeComboBox        = handle(this.jFrame.getMoveModeComboBox(),        'CallbackProperties');
            this.activeMotorComboBox     = handle(this.jFrame.getActiveMotorComboBox(),     'CallbackProperties');
            this.jogXNegButton           = handle(this.jFrame.getJogXNegButton(),           'CallbackProperties');
            this.jogXPosButton           = handle(this.jFrame.getJogXPosButton(),           'CallbackProperties');
            this.jogYNegButton           = handle(this.jFrame.getJogYNegButton(),           'CallbackProperties');
            this.jogYPosButton           = handle(this.jFrame.getJogYPosButton(),           'CallbackProperties');
            this.cameraLabel             = handle(this.jFrame.getCameraLabel(),             'CallbackProperties');
            this.roiButton               = handle(this.jFrame.getROIButton(),               'CallbackProperties');
            this.calibrationModeButton   = handle(this.jFrame.getCalibrationModeButton(),   'CallbackProperties');
            % Set Java object callbacks
            set(this.startCameraButton,       'ActionPerformedCallback', @this.startCameraButtonCallback);
            set(this.captureImageButton,      'ActionPerformedCallback', @this.captureImageButtonCallback);
            set(this.captureVideoButton,      'ActionPerformedCallback', @this.captureVideoButtonCallback);
            set(this.positionTextField,       'ActionPerformedCallback', @this.positionTextFieldCallback);
            set(this.positionButton,          'ActionPerformedCallback', @this.positionButtonCallback);
            set(this.probeButton,             'ActionPerformedCallback', @this.probeButtonCallback);
            set(this.returnButton,            'ActionPerformedCallback', @this.returnButtonCallback);
            set(this.saveDataButton,          'ActionPerformedCallback', @this.saveDataButtonCallback);
            set(this.motorsEnableButton,      'ActionPerformedCallback', @this.motorsEnableButtonCallback);
            set(this.moveModeComboBox,        'ActionPerformedCallback', @this.moveModeComboBoxCallback);
            set(this.activeMotorComboBox,     'ActionPerformedCallback', @this.activeMotorComboBoxCallback);
            set(this.jogXNegButton,           'ActionPerformedCallback', @this.jogXNegButtonCallback);
            set(this.jogXPosButton,           'ActionPerformedCallback', @this.jogXPosButtonCallback);
            set(this.jogYNegButton,           'ActionPerformedCallback', @this.jogYNegButtonCallback);
            set(this.jogYPosButton,           'ActionPerformedCallback', @this.jogYPosButtonCallback);
            set(this.cameraLabel,             'MouseClickedCallback',    @this.cameraLabelCallback);
            set(this.roiButton,               'ActionPerformedCallback', @this.roiButtonCallback);
            set(this.calibrationModeButton,   'ActionPerformedCallback', @this.calibrationModeButtonCallback);
           % initComboBoxes(this);
            this.setSystemState(SystemState.JOG);
            % Display the Java window
            this.jFrame.setVisible(true);
            %Needed for the deployed version of the code
            if isdeployed
                waitfor(this.jFrame);
            end
        end
        
        % GUI Action Performed Callback Functions
        function startCameraButtonCallback(this, hObject, hEventData)
            if (isempty(this.model.getCamera()))
                this.model.initializeCamera('gentl', this);
            end
            if (this.model.cameraIsActive() == false)
                this.startCameraButton.setText('Stop');
                this.model.setCameraActive(true);
            else
                this.startCameraButton.setText('Start');
                this.model.setCameraActive(false);
            end
        end
        
        function previewFrameCallback(this, obj, event)
            if (obj.FramesAvailable > 0)
                warning('off', 'imaq:peekdata:tooManyFramesRequested');
                im = peekdata(obj,1);
                warning('on', 'imaq:peekdata:tooManyFramesRequested');
                if ~isempty(im)
                    this.activeImage(:) = im(:); %Element wise copy to preallocated memory
                    this.jFrame.setVideoImage(im2java(this.activeImage));
                    if (this.recordingVideo == true)
                        fwrite(this.vidID, this.activeImage);
                    end
                end
            end
            flushdata(obj, 'trigger'); %Doesn't seem to actually impact
            %memory ussage
        end
        
        function captureImageButtonCallback(this, hObject, hEventData)
            if(this.model.cameraIsActive())
                [FileName,PathName] = uiputfile({...
                    '*.png;', 'PNG'; '*.jpg','JPEG'; '*.bmp','Bit Map';...
                    '*.tif', 'Tiff';...
                    '*.*', 'All Files (*.*)'});
                drawnow; pause(0.05);  % Use this after every dialog to prevent Matlab hang

                if (~isequal(FileName, 0) && ~isequal(PathName, 0))
                    this.model.captureImage(strcat(PathName, FileName));
                end
            end
        end
        function captureVideoButtonCallback(this, hObject, hEventData)
            if(this.model.cameraIsActive() && this.recordingVideo == false)
                [FileName,PathName] = uiputfile('*.*');
                drawnow; pause(0.05);  % Use this after every dialog to prevent Matlab hang

                if (~isequal(FileName, 0) && ~isequal(PathName, 0))
                    this.captureVideoButton.setText('Stop Recording');
                    this.vidPath = strcat(PathName, FileName);
                    this.vidID = fopen(this.vidPath,'W');
                    
                    this.recordingVideo = true;
                end   
            elseif(this.recordingVideo == true)
                this.recordingVideo = false; % Needs to happen before fclose
                % Close the file.
                fclose(this.vidID);
                selection = this.jFrame.YesNoDialog('Save File?', sprintf(['Would you like to save the video as an AVI now?\n'...
                    'Warning saving large AVI files can cause memory overloads on 32bit systems']),...
                    'Save Later', 'Save Now');
%                 selection = questdlg(sprintf(['Would you like to save the video as an AVI now?\n'...
%                     'Warning saving large AVI files can cause memory overloads on 32bit systems']),...
%                     'Save Later', 'Save Later', 'Save Now', 'Save Now');
                drawnow; pause(0.05);  % Use this after every dialog to prevent Matlab hang

                if selection == 1
                    this.captureVideoButton.setText('Saving...');
                    this.model.setCameraActive(false);
                    VideoFromBinary(this.vidPath, 24, [1000, 1000]);
                    this.model.setCameraActive(true);
                else
                    %Do nothing as the user has elected to save the video
                    %later
                end
                this.captureVideoButton.setText('Capture Video');
            end
        end
        function calibrationModeButtonCallback(this, hObject, hEventData)
            switch this.systemState
                case SystemState.JOG
                    this.setSystemState(SystemState.TEMPLATE_SELECTION);
                case SystemState.VARIANCE_CALIBRATION
% Delete Soon
%                     if (this.getVarianceFromUser())
%                         this.setSystemState(SystemState.JOG);
%                     end
                      this.getVarianceFromUser();
                      this.setSystemState(SystemState.JOG);
            end
        end
        
        function validInput = getVarianceFromUser(this)
%!!! Delete soon
%             prompt={'Enter the variance threshold value',...
%                 'Enter the displacement cuttoff value in um'};
%             name = 'Variance Threshold';
%             defaultans = {'30', '-1500'};
%             inputLines = 1;
%             inputWidth = 40;
%             values = inputdlg(prompt,name,...
%                 [inputLines inputWidth; inputLines inputWidth],defaultans);
%             drawnow; pause(0.05);  % Use this after every dialog to prevent Matlab hang
%             if (isequal(values, {}))
%                 validInput = false;
%                 return;
%             end
%             validInput = true;
%             this.model.setVarianceThreshold(str2double(values(1)));
%             this.model.setVarianceFitDisplacementCuttoff(str2double(values(2)));
%             
%             if (this.varianceDataIndex > 1)
%                 data = this.varianceCalibrationData(1:this.varianceDataIndex, :);
%                 columnMask = data(:,1) < str2double(values(2));
%                 data = data([columnMask, columnMask]);
%                 data = reshape(data, [],2);
%                 sizeData = size(data)
%                 if sizeData(1) < 2
%                     warning(['Not enough points (<2) collected to calculate function.'...
%                     ' Suggest recalibrating.']);
%                     return;
%                 end
%                 expFunc = ExpFunction(0,0,0);
%                 this.model.setCameraActive(false);
%                 expFunc.estimateExp( data(:,2), data(:,1), data(1,2), true);
%                 this.model.setCameraActive(true);
%                 this.model.setExpFunc(expFunc);
%                 figure
%                 hold on
%                 plot(data(:,1), expFunc.getY(data(:,1)));
%                 scatter(data(:,1), data(:,2), '.');
%                 targetDisplacement = real(expFunc.getX(str2double(values(1))));
%                 this.model.setTargetDisplacement(targetDisplacement);
                %!!!
                displacements = this.model.getDisplacements();
                this.model.setTargetDisplacement(displacements(1));
                %!!!
%             else
%                 warning(['Not enough points (<2) collected to calculate function.'...
%                     ' Suggest recalibrating.']);
%             end
        end
        
        function positionTextFieldCallback(this, hObject, hEventData)
            this.jogDistance = str2double(this.positionTextField.getText());
        end
        function positionButtonCallback(this, hObject, hEventData)
            %this.setSystemState(SystemState.PROBE);
            %return;
            % Home point located
            %this.model.setCameraActive(false);
            this.model.identifyHomePoint();
            %this.model.setCameraActive(true);
            % Move DUT to homepoint
            this.model.moveToHomeXY()
        end
        function probeButtonCallback(this, hObject, hEventData)
            this.model.startProbingSequence();
        end
        function returnButtonCallback(this, hObject, hEventData)
            this.jFrame.dispose();
            this.delete();
        end
        function saveDataButtonCallback(this, hObject, hEventData)
            im = this.model.camera.getImageData();
            roi = this.model.getROI(ROI.PROBE);
             p =im(roi(2):roi(4), roi(1):roi(3));
            VarianceOfLaplacian(p)
        end
      
        function moveModeComboBoxCallback(this, hObject, hEventData)
            moveModeStr = this.moveModeComboBox.getSelectedItem();
            this.model.setActiveMotorMoveMode(moveModeStr);
            this.updateJogButtons();
        end
        function activeMotorComboBoxCallback(this, hObject, hEventData)
            activeMotorStr = this.activeMotorComboBox.getSelectedItem();
            this.model.setActiveMotor(activeMotorStr);
            this.updateJogButtons();
        end
        
        function updateJogButtons(this)
           numAxis = this.model.getAvailableJogAxis();
           buttonStates = [false,false,false,false];
           if (strcmp(this.moveModeComboBox.getSelectedItem(), 'Relative'))
               switch numAxis
                    case 1 
                        buttonStates = [false, false, true, true];
                    case 2
                        buttonStates = [true, true, true, true];
                   otherwise
                       %remain all false
               end
           else %Absolute move mode
               switch numAxis
                    case 1 
                        buttonStates = [false, false, true, false];
                    case 2
                        buttonStates = [true, false, true, false];
                   otherwise
                       %remain all false
               end
           end
               
           this.jogXPosButton.setEnabled(buttonStates(1));
           this.jogXNegButton.setEnabled(buttonStates(2));
           this.jogYPosButton.setEnabled(buttonStates(3));
           this.jogYNegButton.setEnabled(buttonStates(4));
        end

        function jogXNegButtonCallback(this, hObject, hEventData)
            this.takeStateAction();
            this.model.setActiveAxis(this.model.X_AXIS);
            this.model.moveActiveMotor(this.jogDistance);
        end
        function jogXPosButtonCallback(this, hObject, hEventData)
            this.takeStateAction();
            this.model.setActiveAxis(this.model.X_AXIS);
            this.model.moveActiveMotor(-this.jogDistance);
        end
        function jogYNegButtonCallback(this, hObject, hEventData)
            this.takeStateAction();
            this.model.setActiveAxis(this.model.Y_AXIS);
            this.model.moveActiveMotor(-this.jogDistance);
        end
        function jogYPosButtonCallback(this, hObject, hEventData)
            this.takeStateAction();
            this.model.setActiveAxis(this.model.Y_AXIS);
            this.model.moveActiveMotor(this.jogDistance);
        end
        function takeStateAction(this)
            switch this.systemState
                case SystemState.VARIANCE_CALIBRATION
%!!! Delete soon
%                     if (~isempty(this.varFig) && ishandle(this.varFig) ...
%                             && strcmp(get(this.varFig, 'type'), 'figure'))
%                         figure(this.varFig);
%                     else
%                         this.varFig = figure;
%                     end
%                     displacements = this.model.getDisplacements();
%                     roi = this.model.getROI(ROI.PROBE);
%                     probeImg = this.activeImage(roi(2):roi(4), roi(1):roi(3));
%                     this.varianceCalibrationData(this.varianceDataIndex, 1) = displacements(1);
%                     this.varianceCalibrationData(this.varianceDataIndex, 2) = VarianceOfLaplacian(probeImg);
%                     plot(this.varianceCalibrationData(:,1), this.varianceCalibrationData(:,2), '.');
%                     title('Variance vs NA Displacement');
%                     xlabel('Displacement (um)');
%                     ylabel('Variance of Laplacian');
%                     this.varianceDataIndex = this.varianceDataIndex + 1;
            end 
        end
        function motorsEnableButtonCallback(this, hObject, hEventData)
            if (this.model.getMotorsEnabled())
                this.model.disableMotors();
                this.motorsEnableButton.setText('Motors Disabled');
            else
                this.model.enableMotors();
                this.motorsEnableButton.setText('Motors Enabled');
            end
        end
        function cameraLabelCallback(this, hObject, hEventData)
            if (~this.updatingROI)
                return;
            end
            switch this.systemState
                case SystemState.TEMPLATE_SELECTION
                    roiType = ROI.TEMPLATE;
                case SystemState.PROBE_REGION_SELECTION
                    roiType = ROI.PROBE;
                otherwise
                    roiType = ROI.IMAGE;
            end
            roi = this.model.getROI(roiType);
            if (~this.hasClickedOnImage)
                roi(1) = hEventData.getX();
                roi(2) = hEventData.getY();
                this.model.setROI(roiType, roi);
                this.hasClickedOnImage = true;
                this.roiButton.setEnabled(false);
            elseif (this.hasClickedOnImage)
                roi(3) = hEventData.getX();
                roi(4) = hEventData.getY();
                this.model.setROI(roiType, roi);
                this.hasClickedOnImage = false;
                this.roiButton.setEnabled(true);
            end
        end
        
        function roiButtonCallback(this, hObject, hEventData)
            
            if (this.updatingROI)
                this.updatingROI = false;
                this.roiButton.setText('Set ROI');
                switch this.systemState
                    case SystemState.TEMPLATE_SELECTION
                        this.model.updateTemplateFromROI();
                        this.setSystemState(SystemState.PROBE_REGION_SELECTION);
                    case SystemState.PROBE_REGION_SELECTION
                        this.jFrame.MsgDialog('Contact Step', sprintf(['Probe Selection Completed\n'...
                        'Use the jog buttons to make contact with the device.']));
%                         msgbox(sprintf(['Probe Selection Completed\n'...
%                         'Use the jog buttons to make contact with the device.']),'Contact Step');
                        drawnow; pause(0.05);  % Use this after every dialog to prevent Matlab hang
                        this.setSystemState(SystemState.VARIANCE_CALIBRATION);
                        %ROI for the probe should already be set at this
                        %point
                end
            else
                this.updatingROI = true;
                this.roiButton.setText('Save ROI');
            end
        end
        
        %destructor
         function delete(this)
            if (this.model.cameraIsActive())
                this.model.setCameraActive(false);
            end
            try
                fclose(this.vidID);
            catch
            end
            this.model.delete();
            CleanUpMemory()
         end
         
        function handlePropEvents(this,src,evnt)
            displacements = this.model.getDisplacements();
                    str = strcat(strcat('NA = ', num2str(displacements(1))),...
                                 strcat(' PI = ', num2str(displacements(2))),...
                                 strcat(' NP = ', num2str(displacements(3))));
                    this.currentPositionTextArea.setText(str);
        end
        
        function setSystemState(this, systemState)
            if (~isenum(systemState) || nargin < 2)
                error('setSystemState: Input is not an enum');
            end
            this.systemState = systemState;
            this.setButtonsForSystemState();
            switch this.systemState
                case SystemState.JOG
                    %No additional actions needed for jog mode
                    this.startJogSequence();
                case SystemState.TEMPLATE_SELECTION
                    this.startCalibration();
                case SystemState.PROBE_REGION_SELECTION
                    this.startProbeSelction();
                case SystemState.VARIANCE_CALIBRATION
                    this.startVarianceCalibration();
                case SystemState.PROBE
                    this.startProbeSequence();
            end
        end
        
        function startJogSequence(this)
            this.calibrationModeButton.setText('Calibrate');
        end
        
        function startVarianceCalibration(this)
            this.calibrationModeButton.setText('Finish Calibration');
            this.varianceCalibrationData(:) = 0;
            this.varianceDataIndex = 1;
        end
        
        function startProbeSelction(this)
            this.roiButton.setEnabled(      true);
            this.updatingROI = false; %User will click SetROI to start update
            this.hasClickedOnImage = false;
            this.roiButton.setText('Set Probe ROI');
            this.jFrame.MsgDialog('Probe Selection', sprintf(['Template Selection Completed\n'...
                'Select the probe in the image.']));
%             msgbox(sprintf(['Template Selection Completed\n'...
%                 'Select the probe in the image.']),'Probe Selection');
            drawnow; pause(0.05);  % Use this after every dialog to prevent Matlab hang
        end
        
        function startCalibration(this)
            if this.model.cameraIsActive() == false
            	this.startCameraButtonCallback();
            end
%!!! delete soon
%             selection = questdlg(sprintf(['A Template Image is needed would you like to:\n'...
%             'Load existing template from file or indicate template on camera feed?']),...
%             'Template Selection', 'Load Template', 'Select From Feed', 'Select From Feed');
%             
            selection = this.jFrame.YesNoDialog('Template Selection', sprintf(['A Template Image is needed would you like to:\n'...
                'Load existing template from file or indicate template on camera feed?']),...
                'Load Template', 'Select From Feed'); % 0 = yes, 1 = no, -1 = cancel
            drawnow; pause(0.05);  % Use this after every dialog to prevent Matlab hang
            selectFromFeed = false;
            if selection == 0
                'Load Template'
                [FileName,PathName,FilterIndex] = uigetfile({...
                    '*.png; *.jpg; *.bmp; *.tiff; *.tif',...
                    'Images (*.png, *.jpg, *.bmp, *.tiff, *.tif)';...
                    '*.*', 'All Files (*.*)'},'Load Template');
                 drawnow; pause(0.05);  % Use this after every dialog to prevent Matlab hang
                if (~isequal(FileName, 0) && ~isequal(PathName, 0))
                    this.model.loadTemplate([PathName FileName]);
                    this.roiButton.setEnabled(      false);
                    this.setSystemState(SystemState.PROBE_REGION_SELECTION);
                    selectFromFeed = false;
                else
                    selectFromFeed = true;
                end
            else
                selectFromFeed = true;
            end
            if (selectFromFeed) %Select From Feed.
                this.roiButton.setEnabled(      true);
                this.updatingROI = false; %User will click SetROI to start update
                this.hasClickedOnImage = false;
                this.roiButton.setText('Set Tempalte ROI');
            end
        end
        
        function startProbeSequence(this)
        end
        
        function setButtonsForSystemState(this)
            switch this.systemState
                case SystemState.JOG
                    this.startCameraButton.setEnabled(      true);
                    this.captureImageButton.setEnabled(     true);
                    this.captureVideoButton.setEnabled(     true);
                    this.currentPositionTextArea.setEnabled(true);
                    this.positionTextField.setEnabled(      true);
                    this.positionButton.setEnabled(         true);
                    this.probeButton.setEnabled(            true);
                    this.returnButton.setEnabled(           true);
                    this.saveDataButton.setEnabled(         true);
                    this.motorsEnableButton.setEnabled(     true);
                    this.moveModeComboBox.setEnabled(       true);
                    this.activeMotorComboBox.setEnabled(    true);
                    this.jogXNegButton.setEnabled(          true);
                    this.jogXPosButton.setEnabled(          true);
                    this.jogYNegButton.setEnabled(          true);
                    this.jogYPosButton.setEnabled(          true);
                    this.cameraLabel.setEnabled(            true);
                    this.roiButton.setEnabled(              false);
                    this.calibrationModeButton.setEnabled(  true);
                case {SystemState.TEMPLATE_SELECTION, SystemState.PROBE_REGION_SELECTION}
                    this.startCameraButton.setEnabled(      false);
                    this.captureImageButton.setEnabled(     true);
                    this.captureVideoButton.setEnabled(     true);
                    this.currentPositionTextArea.setEnabled(true);
                    this.positionTextField.setEnabled(      false);
                    this.positionButton.setEnabled(         false);
                    this.probeButton.setEnabled(            false);
                    this.returnButton.setEnabled(           true);
                    this.saveDataButton.setEnabled(         false);
                    this.motorsEnableButton.setEnabled(     true);
                    this.moveModeComboBox.setEnabled(       false);
                    this.activeMotorComboBox.setEnabled(    false);
                    this.jogXNegButton.setEnabled(          false);
                    this.jogXPosButton.setEnabled(          false);
                    this.jogYNegButton.setEnabled(          false);
                    this.jogYPosButton.setEnabled(          false);
                    this.cameraLabel.setEnabled(            true);
                    this.roiButton.setEnabled(              false);
                    this.calibrationModeButton.setEnabled(  false);
                case SystemState.VARIANCE_CALIBRATION
                    this.startCameraButton.setEnabled(      true);
                    this.captureImageButton.setEnabled(     true);
                    this.captureVideoButton.setEnabled(     true);
                    this.currentPositionTextArea.setEnabled(true);
                    this.positionTextField.setEnabled(      true);
                    this.positionButton.setEnabled(         false);
                    this.probeButton.setEnabled(            false);
                    this.returnButton.setEnabled(           true);
                    this.saveDataButton.setEnabled(         false);
                    this.motorsEnableButton.setEnabled(     true);
                    this.moveModeComboBox.setEnabled(       true);
                    this.activeMotorComboBox.setEnabled(    true);
                    this.jogXNegButton.setEnabled(          false);
                    this.jogXPosButton.setEnabled(          false);
                    this.jogYNegButton.setEnabled(          false);
                    this.jogYPosButton.setEnabled(          false);
                    this.cameraLabel.setEnabled(            true);
                    this.roiButton.setEnabled(              false);
                    this.calibrationModeButton.setEnabled(  true);
                case SystemState.PROBE
                    this.startCameraButton.setEnabled(      true);
                    this.captureImageButton.setEnabled(     true);
                    this.captureVideoButton.setEnabled(     true);
                    this.currentPositionTextArea.setEnabled(true);
                    this.positionTextField.setEnabled(      false);
                    this.positionButton.setEnabled(         false);
                    this.probeButton.setEnabled(            true);
                    this.returnButton.setEnabled(           true);
                    this.saveDataButton.setEnabled(         false);
                    this.motorsEnableButton.setEnabled(     true);
                    this.moveModeComboBox.setEnabled(       false);
                    this.activeMotorComboBox.setEnabled(    false);
                    this.jogXNegButton.setEnabled(          false);
                    this.jogXPosButton.setEnabled(          false);
                    this.jogYNegButton.setEnabled(          false);
                    this.jogYPosButton.setEnabled(          false);
                    this.cameraLabel.setEnabled(            true);
                    this.roiButton.setEnabled(              false);
                    this.calibrationModeButton.setEnabled(  true);
            end
        end
    end
end

