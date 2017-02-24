classdef MainView < handle
    properties
        model
        controller
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
        roiTypeComboBox;
        calibrationModeButton;
        %handles
        videoWriter;
        varFig;
        %states
        systemState = SystemState.JOG;
        activeROI = ROI.PROBE;
        recordingVideo = false;
        updatingROI = false;
        hasClickedOnImage = false;
        overlayShapes = [];
        roiShapeIndex = 0;
        %data
        activeImage = zeros(1000,1000, 'uint8');
        displayImage = zeros(1000,1000,3,'uint8');
        vidID;
        vidPath;
        varianceCalibrationData = zeros(500, 2);
        varianceDataIndex = 1;
    end
    
    methods
        function this = MainView(controller)
            this.controller = controller;
            this.model = controller.model;
           % this.gui = mainGUI('controller',this.controller);
            
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
            this.roiTypeComboBox         = handle(this.jFrame.getROITypeComboBox(),         'CallbackProperties');
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
            set(this.roiTypeComboBox,         'ActionPerformedCallback', @this.roiTypeComboBoxCallback);
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
        
        function initComboBoxes(this)
            %The moveMode and ActiveMotor boxes are currently in Java. Move
            %when available
            this.roiTypeComboBox.removeAllItems();
            roiTypes = this.controller.getAvailableROIs();
            for roiType = roiTypes
                this.roiTypeComboBox.addItem(java.lang.String(roiType));
            end
        end
        
        % GUI Action Performed Callback Functions
        function startCameraButtonCallback(this, hObject, hEventData)
            if (isempty(this.controller.getCamera()))
                this.controller.initializeCamera('gentl');
            end
            if (this.controller.cameraIsActive() == false)
                this.startCameraButton.setText('Stop');
                this.controller.getCamera().start();
                this.controller.setCameraActive(true);
            else
                this.startCameraButton.setText('Start');
                this.controller.getCamera().stop();
                this.controller.setCameraActive(false);
            end
        end
        
        function applyDrawingOverlays(this)
            for shape = this.overlayShapes;
                this.displayImage = insertShape(this.activeImage,shape.type,shape.dimensions,...
                    'LineWidth',shape.lineWidth,'Opacity',shape.opacity,...
                    'Color', shape.color);
            end
            if (isempty(this.overlayShapes))
                this.displayImage = this.activeImage;
            end
        end
        
        function previewFrameCallback(this, obj, event)
            if (obj.FramesAvailable > 0)
                im = getdata(obj,1);
                this.activeImage(:) = im(:); %Element wise copy to preallocated memory
                %this.applyDrawingOverlays();
                this.jFrame.setVideoImage(im2java(this.activeImage));
                if (this.recordingVideo == true)
                    fwrite(this.vidID, this.activeImage);
                end
            end
            flushdata(obj, 'trigger');
        end
        
        function captureImageButtonCallback(this, hObject, hEventData)
            if(this.controller.cameraIsActive())
                [FileName,PathName] = uiputfile();
                this.controller.captureImage(strcat(PathName, FileName));
                %this.controller.captureImage();
            end
        end
        function captureVideoButtonCallback(this, hObject, hEventData)
            if(this.controller.cameraIsActive() && this.recordingVideo == false)
                [FileName,PathName] = uiputfile();
                if (~isempty(FileName) && ~isempty(PathName))
                    this.captureVideoButton.setText('Stop Recording');
                    this.vidPath = strcat(PathName, FileName);
                    this.vidID = fopen(this.vidPath,'W');
                    
                    this.recordingVideo = true;
                end   
            elseif(this.recordingVideo == true)
                
                % Close the file.
                fclose(this.vidID);
                this.captureVideoButton.setText('Saving...');
                this.controller.setCameraActive(false);
                VideoFromBinary(this.vidPath, 24, [1000, 1000]);
                this.controller.setCameraActive(true);
                this.captureVideoButton.setText('Capture Video');
                this.recordingVideo = false;
            end
            
        end
        function calibrationModeButtonCallback(this, hObject, hEventData)
            switch this.systemState
                case SystemState.JOG
                    this.setSystemState(SystemState.TEMPLATE_SELECTION);
                case SystemState.VARIANCE_CALIBRATION
                    this.setSystemState(SystemState.JOG);
            end
        end
        function positionTextFieldCallback(this, hObject, hEventData)
            this.jogDistance = str2double(this.positionTextField.getText());
        end
        function positionButtonCallback(this, hObject, hEventData)
            %this.setSystemState(SystemState.PROBE);
            %return;
            % Home point located
            %this.controller.setCameraActive(false);
            this.controller.identifyHomePoint();
            %this.controller.setCameraActive(true);

            homePoint = this.controller.getHomePoint();
            roiShape = Shape('Circle', [homePoint(1) homePoint(2) 3], 1, 'green', 1);
            this.overlayShapes = [this.overlayShapes roiShape];
            % Move DUT to homepoint
            this.controller.moveToHomeXY()
        end
        function probeButtonCallback(this, hObject, hEventData)
            this.controller.startProbingSequence();
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
            this.controller.setActiveMotorMoveMode(moveModeStr);
            this.updateJogButtons();
        end
        function activeMotorComboBoxCallback(this, hObject, hEventData)
            activeMotorStr = this.activeMotorComboBox.getSelectedItem();
            this.controller.setActiveMotor(activeMotorStr);
            this.updateJogButtons();
        end
        
        function updateJogButtons(this)
           numAxis = this.controller.getAvailableJogAxis();
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
            this.controller.setActiveAxis(this.model.X_AXIS);
            this.controller.moveActiveMotor(this.jogDistance);
        end
        function jogXPosButtonCallback(this, hObject, hEventData)
            this.takeStateAction();
            this.controller.setActiveAxis(this.model.X_AXIS);
            this.controller.moveActiveMotor(-this.jogDistance);
        end
        function jogYNegButtonCallback(this, hObject, hEventData)
            this.takeStateAction();
            this.controller.setActiveAxis(this.model.Y_AXIS);
            this.controller.moveActiveMotor(-this.jogDistance);
        end
        function jogYPosButtonCallback(this, hObject, hEventData)
            this.takeStateAction();
            this.controller.setActiveAxis(this.model.Y_AXIS);
            this.controller.moveActiveMotor(this.jogDistance);
        end
        function takeStateAction(this)
            switch this.systemState
                case SystemState.VARIANCE_CALIBRATION
                    if (isempty(this.varFig))
                        this.varFig = figure;
                    end
                    figure(this.varFig);
                    displacements = this.controller.getDisplacements();
                    roi = this.controller.getROI(ROI.PROBE);
                    probeImg = this.activeImage(roi(2):roi(4), roi(1):roi(3));
                    this.varianceCalibrationData(this.varianceDataIndex, 1) = displacements(1);
                    this.varianceCalibrationData(this.varianceDataIndex, 2) = VarianceOfLaplacian(probeImg);
                    plot(this.varianceCalibrationData(:,1), this.varianceCalibrationData(:,2));
                    title('Variance vs NA Displacement');
                    xlabel('Displacement');
                    ylabel('Variance of Laplacian');
                    this.varianceDataIndex = this.varianceDataIndex + 1;
            end 
        end
        function motorsEnableButtonCallback(this, hObject, hEventData)
            if (this.controller.getMotorsEnabled())
                this.controller.disableMotors();
                this.motorsEnableButton.setText('Motors Disabled');
            else
                this.controller.enableMotors();
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
            roi = this.controller.getROI(roiType);
            if (~this.hasClickedOnImage)
                roi(1) = hEventData.getX();
                roi(2) = hEventData.getY();
                this.controller.setROI(roiType, roi);
                this.hasClickedOnImage = true;
                this.roiButton.setEnabled(false);
            elseif (this.hasClickedOnImage)
                roi(3) = hEventData.getX();
                roi(4) = hEventData.getY();
                this.controller.setROI(roiType, roi);
%                 %Draw rectangle
%                 p1 = [roi(1) roi(2)];
%                 p2 = [roi(3) roi(2)];
%                 p3 = [roi(3) roi(4)];
%                 p4 = [roi(1) roi(4)];
%                 roiShape = Shape('Polygon', [p1 p2 p3 p4], 5, 'green', 1);
%                 overlayListSize = size(this.overlayShapes);
%                 if (this.roiShapeIndex < 1 || this.roiShapeIndex > overlayListSize(2))
%                     this.overlayShapes = [this.overlayShapes roiShape];
%                     this.roiShapeIndex = overlayListSize(2) + 1 ;
%                 else
%                     this.overlayShapes(this.roiShapeIndex) = roiShape;
%                 end
                
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
                        this.controller.updateTemplateFromROI();
                        this.setSystemState(SystemState.PROBE_REGION_SELECTION);
                    case SystemState.PROBE_REGION_SELECTION
                        msgbox(sprintf(['Probe Selection Completed\n'...
                        'Use the jog buttons to make contact with the device.']),'Contact Step');
                        this.setSystemState(SystemState.VARIANCE_CALIBRATION);
                        %ROI for the probe should already be set at this
                        %point
                end
            else
                this.updatingROI = true;
                this.roiButton.setText('Save ROI');
            end
        end
        
        function roiTypeComboBoxCallback(this, hObject, hEventData)
        end
        
        
        %destructor
         function delete(this)
            if (this.controller.cameraIsActive())
                this.controller.getCamera.stop();
            end
            try
                fclose(this.vidID);
            catch
            end
            this.controller.delete();
            CleanUpMemory()
         end
         
        function handlePropEvents(this,src,evnt)
            displacements = this.controller.getDisplacements();
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
        end
        
        function startProbeSelction(this)
            this.roiButton.setEnabled(      true);
            this.updatingROI = false; %User will click SetROI to start update
            this.hasClickedOnImage = false;
            this.roiButton.setText('Set Probe ROI');
            msgbox(sprintf(['Template Selection Completed\n'...
                'Select the probe in the image.']),'Probe Selection');
        end
        
        function startCalibration(this)
            if this.controller.cameraIsActive() == false
            	this.startCameraButtonCallback();
            end
            selection = questdlg(sprintf(['A Template Image is needed would you like to:\n'...
            'Load existing template from file or indicate template on camera feed?']),...
            'Template Selection', 'Load Template', 'Select From Feed', 'Select From Feed');
            if strcmp(selection, 'Load Template')
                [FileName,PathName,FilterIndex] = uigetfile({...
                    '*.png; *.jpg; *.bmp; *.tiff; *.tif',...
                    'Images (*.png, *.jpg, *.bmp, *.tiff, *.tif)';...
                    '*.*', 'All Files (*.*)'},'Load Template');
                this.controller.loadTemplate([PathName FileName]);
                this.roiButton.setEnabled(      false);
                this.setSystemState(SystemState.PROBE_REGION_SELECTION);
            else %Select From Feed
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
                    this.roiButton.setEnabled(              true);
                    this.roiTypeComboBox.setEnabled(        true);
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
                    this.roiTypeComboBox.setEnabled(        false);
                    this.calibrationModeButton.setEnabled(  false);
                case SystemState.VARIANCE_CALIBRATION
                    this.startCameraButton.setEnabled(      false);
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
                    this.roiTypeComboBox.setEnabled(        false);
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
                    this.roiTypeComboBox.setEnabled(        false);
                    this.calibrationModeButton.setEnabled(  true);
            end
        end
    end
end

