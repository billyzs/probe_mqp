classdef MainView < handle
    properties
        model
        controller
        videoTimer
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
    	targetPositionTextField;
        motorsEnableButton;
        moveModeComboBox;
        activeMotorComboBox;
        jogXNegButton;
        jogXPosButton;
        jogYNegButton;
        jogYPosButton;
        jogDistance = 0;
        cameraLabel;
        probeROIButton;
        %handles
        videoWriter;
        %states
        recordingVideo = false;
        updatingProbeROI = false;
        probeROI = [0,0,1000,1000] %!!! This should be updated based on camera width
        hasClickedOnImage = false;
        overlayShapes = [];
        roiShapeIndex = 0;
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
            javaaddpath([pwd '\Probe_MQP_Java_GUI.jar']);
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
            this.targetPositionTextField = handle(this.jFrame.getTargetPositionTextField(), 'CallbackProperties');
            this.motorsEnableButton      = handle(this.jFrame.getMotorsEnableButton(),      'CallbackProperties'); 
            this.moveModeComboBox        = handle(this.jFrame.getMoveModeComboBox(),        'CallbackProperties');
            this.activeMotorComboBox     = handle(this.jFrame.getActiveMotorComboBox(),     'CallbackProperties');
            this.jogXNegButton           = handle(this.jFrame.getJogXNegButton(),           'CallbackProperties');
            this.jogXPosButton           = handle(this.jFrame.getJogXPosButton(),           'CallbackProperties');
            this.jogYNegButton           = handle(this.jFrame.getJogYNegButton(),           'CallbackProperties');
            this.jogYPosButton           = handle(this.jFrame.getJogYPosButton(),           'CallbackProperties');
            this.cameraLabel             = handle(this.jFrame.getCameraLabel(),             'CallbackProperties');
            this.probeROIButton          = handle(this.jFrame.getProbeROIButton(),          'CallbackProperties');
            % Set Java object callbacks
            set(this.startCameraButton,       'ActionPerformedCallback', @this.startCameraButtonCallback);
            set(this.captureImageButton,      'ActionPerformedCallback', @this.captureImageButtonCallback);
            set(this.captureVideoButton,      'ActionPerformedCallback', @this.captureVideoButtonCallback);
            set(this.positionTextField,       'ActionPerformedCallback', @this.positionTextFieldCallback);
            set(this.positionButton,          'ActionPerformedCallback', @this.positionButtonCallback);
            set(this.probeButton,             'ActionPerformedCallback', @this.probeButtonCallback);
            set(this.returnButton,            'ActionPerformedCallback', @this.returnButtonCallback);
            set(this.saveDataButton,          'ActionPerformedCallback', @this.saveDataButtonCallback);
            set(this.targetPositionTextField, 'ActionPerformedCallback', @this.targetPositionTextFieldCallback);
            set(this.motorsEnableButton,      'ActionPerformedCallback', @this.motorsEnableButtonCallback);
            set(this.moveModeComboBox,        'ActionPerformedCallback', @this.moveModeComboBoxCallback);
            set(this.activeMotorComboBox,     'ActionPerformedCallback', @this.activeMotorComboBoxCallback);
            set(this.jogXNegButton,           'ActionPerformedCallback', @this.jogXNegButtonCallback);
            set(this.jogXPosButton,           'ActionPerformedCallback', @this.jogXPosButtonCallback);
            set(this.jogYNegButton,           'ActionPerformedCallback', @this.jogYNegButtonCallback);
            set(this.jogYPosButton,           'ActionPerformedCallback', @this.jogYPosButtonCallback);
            set(this.cameraLabel,             'MouseClickedCallback',    @this.cameraLabelCallback);
            set(this.probeROIButton,          'MouseClickedCallback',    @this.probeROIButtonCallback);
            
            % Display the Java window
            this.jFrame.setVisible(true);
            %Needed for the deployed version of the code
            if isdeployed
                waitfor(this.jFrame);
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
        
        function image = applyDrawingOverlays(this, image)
            for shape = this.overlayShapes;
                image = insertShape(image,shape.type,shape.dimensions,...
                    'LineWidth',shape.lineWidth,'Opacity',shape.opacity,...
                    'Color', shape.color);
            end
        end
        
        function previewFrameCallback(this, obj, event)
            flushdata(obj);
            im = getdata(obj);
            imOverlayed = this.applyDrawingOverlays(im);
            imJava = im2java(imOverlayed);
            this.jFrame.setVideoImage(imJava);
            if (this.recordingVideo == true)
                writeVideo(this.videoWriter, im);
            end
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
                    this.videoWriter = VideoWriter(strcat(PathName, FileName));
                    open(this.videoWriter)
                    this.recordingVideo = true;
                end   
            elseif(this.recordingVideo == true)
                this.captureVideoButton.setText('Capture Video');
                % Close the file.
                close(this.videoWriter)
                this.recordingVideo = false;
            end
            
        end
        function positionTextFieldCallback(this, hObject, hEventData)
            this.jogDistance = str2num(this.positionTextField.getText());
        end
        function positionButtonCallback(this, hObject, hEventData)
        end
        function probeButtonCallback(this, hObject, hEventData)
            this.controller.setTemplate(this.probeROI);
            this.controller.identifyHomePoint();
            homePoint = this.controller.getHomePoint();
            roiShape = Shape('Circle', [homePoint(1) homePoint(2) 3], 1, 'green', 1);
            this.overlayShapes = [this.overlayShapes roiShape];
        end
        function returnButtonCallback(this, hObject, hEventData)
        end
        function saveDataButtonCallback(this, hObject, hEventData)
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
        %!!! (A) Edit from A to B
        function jogXNegButtonCallback(this, hObject, hEventData)
            this.controller.setActiveAxis(2);
            this.controller.moveActiveMotor(-this.jogDistance);
        end
        function jogXPosButtonCallback(this, hObject, hEventData)
            this.controller.setActiveAxis(2);
            this.controller.moveActiveMotor(this.jogDistance);
        end
        function jogYNegButtonCallback(this, hObject, hEventData)
            this.controller.setActiveAxis(3);
            this.controller.moveActiveMotor(-this.jogDistance);
        end
        function jogYPosButtonCallback(this, hObject, hEventData)
            this.controller.setActiveAxis(3);
            this.controller.moveActiveMotor(this.jogDistance);
        end
        %!!! Need a way to select 
        function jogButtonCallback(this, hObject, hEventData) %!!! edit this----
            if (this.controller.getMotorsEnabled())
                this.controller.moveManualNA(distance);
            end
        end
        function stepPiezoButtonCallback(this, hObject, hEventData) %!!! edit this ----
            if (this.controller.getMotorsEnabled())
                distanceStr = this.piezoDistanceTextField.getText();
                distance = str2num(distanceStr);
                this.controller.moveManualPiezo(distance);
            end
        end
        function targetPositionTextFieldCallback(this, hObject, hEventData)
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
            if (this.updatingProbeROI && ~this.hasClickedOnImage)
                this.probeROI(1) = hEventData.getX();
                this.probeROI(2) = hEventData.getY();
                this.hasClickedOnImage = true;
            elseif (this.updatingProbeROI && this.hasClickedOnImage)
                this.probeROI(3) = hEventData.getX();
                this.probeROI(4) = hEventData.getY();
                %Draw rectangle
                p1 = [this.probeROI(1) this.probeROI(2)];
                p2 = [this.probeROI(3) this.probeROI(2)];
                p3 = [this.probeROI(3) this.probeROI(4)];
                p4 = [this.probeROI(1) this.probeROI(4)];
                roiShape = Shape('Polygon', [p1 p2 p3 p4], 5, 'green', 1);
                overlayListSize = size(this.overlayShapes);
                if (this.roiShapeIndex < 1 || this.roiShapeIndex > overlayListSize(2))
                    this.overlayShapes = [this.overlayShapes roiShape];
                    this.roiShapeIndex = overlayListSize(2) + 1 ;
                else
                    this.overlayShapes(this.roiShapeIndex) = roiShape;
                end
                
                this.hasClickedOnImage = false;
            else
                this.updatingProbeROI = false;
                this.hasClickedOnImage = false;
            end
            this.probeROI
        end
        function probeROIButtonCallback(this, hObject, hEventData)
            if (this.updatingProbeROI)
                this.updatingProbeROI = false;
                this.probeROIButton.setText('Set Probe ROI');
            else
                this.updatingProbeROI = true;
                this.probeROIButton.setText('Save ROI');
            end
        end
        %destructor
         function delete(this)
            if (this.controller.cameraIsActive())
                this.controller.getCamera.stop();
            end
        end
    end
    
    
    methods
        function handlePropEvents(this,src,evnt)
            displacements = this.controller.getDisplacements();
                    str = strcat(strcat('NA = ', num2str(displacements(1))),...
                                 strcat(' PI = ', num2str(displacements(2))),...
                                 strcat(' NP = ', num2str(displacements(3))));
                    this.currentPositionTextArea.setText(str);
        end
    end
end

