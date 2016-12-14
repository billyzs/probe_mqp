classdef MainView < handle
    properties
        model
        controller
        videoTimer
        camera
        %Java Objects
        jFrame
        startCameraButton;
        captureImageButton;
    	captureVideoButton;
    	currentPositionTextArea;
    	naDistanceTextField;
    	piezoDistanceTextField;
    	positionButton;
    	probeButton;
    	returnButton;
    	saveDataButton;
    	stepActuatorsButton;
    	targetPositionTextField;
        motorsEnableButton;
    end
    
    methods
        function this = MainView(controller)
            this.controller = controller;
            this.model = controller.model;
           % this.gui = mainGUI('controller',this.controller);
            
            addlistener(this.model,'test','PostSet', ...
                @(src,evnt)MainView.handlePropEvents(this,src,evnt));
        
            this.launchView();
        end
        
        function launchView(this)
            this.camera = CameraPike(1);
            %this.camera = CameraWebcam(1, 'MJPG_640x480');
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
            this.naDistanceTextField     = handle(this.jFrame.getNADistanceTextField(),     'CallbackProperties');
            this.piezoDistanceTextField  = handle(this.jFrame.getPiezoDistanceTextField(),  'CallbackProperties');
            this.positionButton          = handle(this.jFrame.getPositionButton(),          'CallbackProperties');
            this.probeButton             = handle(this.jFrame.getProbeButton(),             'CallbackProperties');
            this.returnButton            = handle(this.jFrame.getReturnButton(),            'CallbackProperties');
            this.saveDataButton          = handle(this.jFrame.getSaveDataButton(),          'CallbackProperties');
            this.stepActuatorsButton     = handle(this.jFrame.getStepActuatorsButton(),     'CallbackProperties');
            this.targetPositionTextField = handle(this.jFrame.getTargetPositionTextField(), 'CallbackProperties');
            this.motorsEnableButton      = handle(this.jFrame.getMotorsEnableButton(),      'CallbackProperties');
            % Set Java object callbacks
            set(this.startCameraButton,       'ActionPerformedCallback', @this.startCameraButtonCallback);
            set(this.captureImageButton,      'ActionPerformedCallback', @this.captureImageButtonCallback);
            set(this.captureVideoButton,      'ActionPerformedCallback', @this.captureVideoButtonCallback);
            set(this.naDistanceTextField,     'ActionPerformedCallback', @this.naDistanceTextFieldCallback);
            set(this.piezoDistanceTextField,  'ActionPerformedCallback', @this.piezoDistanceTextFieldCallback);
            set(this.positionButton,          'ActionPerformedCallback', @this.positionButtonCallback);
            set(this.probeButton,             'ActionPerformedCallback', @this.probeButtonCallback);
            set(this.returnButton,            'ActionPerformedCallback', @this.returnButtonCallback);
            set(this.saveDataButton,          'ActionPerformedCallback', @this.saveDataButtonCallback);
            set(this.stepActuatorsButton,     'ActionPerformedCallback', @this.stepActuatorsButtonCallback);
            set(this.targetPositionTextField, 'ActionPerformedCallback', @this.targetPositionTextFieldCallback);
            set(this.motorsEnableButton,      'ActionPerformedCallback', @this.motorsEnableButtonCallback);
            
            
            % Display the Java window
            this.jFrame.setVisible(true);
            %Needed for the deployed version of the code
            if isdeployed
                waitfor(this.jFrame);
            end
        end
        % GUI Action Performed Callback Functions
        function startCameraButtonCallback(this, hObject, hEventData)
            if (this.controller.cameraIsActive() == false)
                this.startCameraButton.setText('Stop');
                this.videoTimer = VideoTimer(this.camera, this.jFrame);
                this.controller.setCameraActive(true);
            else
                this.startCameraButton.setText('Start');
                this.videoTimer.stopVideo();
                this.controller.setCameraActive(false);
            end
        end
        function captureImageButtonCallback(this, hObject, hEventData)
        end
        function captureVideoButtonCallback(this, hObject, hEventData)
        end
        function naDistanceTextFieldCallback(this, hObject, hEventData)
        end
        function piezoDistanceTextFieldCallback(this, hObject, hEventData)
        end
        function positionButtonCallback(this, hObject, hEventData)
        end
        function probeButtonCallback(this, hObject, hEventData)
        end
        function returnButtonCallback(this, hObject, hEventData)
        end
        function saveDataButtonCallback(this, hObject, hEventData)
        end
        function stepActuatorsButtonCallback(this, hObject, hEventData)
            if (this.controller.getMotorsEnabled())
                distanceStr = this.naDistanceTextField.getText();
                distance = str2num(distanceStr)
                this.controller.moveManual(distance);
            end
        end
        function targetPositionTextFieldCallback(this, hObject, hEventData)
        end
        function motorsEnableButtonCallback(this, hObject, hEventData)
            if (this.controller.getMotorsEnabled())
                'disable'
                this.controller.disableMotors();
                this.motorsEnableButton.setText('Motors Disabled');
            else
                'enable'
                this.controller.enableMotors();
                this.motorsEnableButton.setText('Motors Enabled');
            end
        end
    end
    
    methods (Static)
        function handlePropEvents(this,src,evnt)
            evntobj = evnt.AffectedObject;
            handles = guidata(this.gui);
            switch src.Name
                case 'test'
                    handles.test = evntobj.test;
                    set(handles.text_test, 'String', evntobj.test);
                    % Not sure if resetting gui data is the most efficient
                    % way to make push the changes but it seems to be
                    % required
                    guidata(gcbo,handles) 
            end
        end
    end
end

