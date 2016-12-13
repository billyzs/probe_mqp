classdef MainView < handle
    properties
        jFrame
        model
        controller
        video_timer
        camera
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
            
            this.camera = CameraWebcam(1, 'MJPG_640x480');
            %start(c);
            % Add Java library to dynamic Java classpath
            javaaddpath([pwd '\Probe_MQP_Java_GUI.jar']);

            % Get example Java window from the library
            this.jFrame = probe_mqp_java_gui.MainUIJFrame();

            % Get Java buttons
            % Note: see http://UndocumentedMatlab.com/blog/matlab-callbacks-for-java-events-in-r2014a
            startCameraButton = handle(this.jFrame.getStartCameraButton(), 'CallbackProperties');
            %showWarnButton = handle(jFrame.getShowWarnDlgButton(), 'CallbackProperties');

            % Set Java button callbacks
            set(startCameraButton, 'ActionPerformedCallback', @this.startCameraButtonCallback);
            
            
            
            
            % Display the Java window
            this.jFrame.setVisible(true);
            %Needed for the deployed version of the code
            if isdeployed
                waitfor(this.jFrame);
            end
        end
        
        function startCameraButtonCallback(this, hObject, hEventData)
            VideoTimer(this.camera, this.jFrame);
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

