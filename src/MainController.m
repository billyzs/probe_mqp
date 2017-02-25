
classdef MainController < handle
    %mainController - The main controller for the GUI
    %   Detailed explanation goes here
    
    properties
        model
        view
    end
    
    methods
        
        function this = MainController(model)
            
            this.model = model;
            this.view = MainView(this);
        end
        
        function delete(this)
            this.model.delete();
        end
        
        function setCameraActive(this, active)
            this.model.cameraActive = active;
        end
        
        function active = cameraIsActive(this)
            active = this.model.cameraActive;
        end
        
        function camera = getCamera(this)
            camera = this.model.getCamera();
        end
        
        function initializeCamera(this, cameraType)
            switch cameraType
                case 'webcam'
                    this.model.setCamera(CameraWebcam(1, 'MJPG_640x480'));
                case 'gentl'
                    this.model.setCamera(CameraPike(1));
                    %this.model.setCamera(CameraPike(1));
            end
            viewHandle = this.view;
            camera = this.model.getCamera();
            camera.setVideoParameter('FramesPerTrigger', 1);
            camera.setVideoParameter('TriggerFcn', @viewHandle.previewFrameCallback);
            camera.setVideoParameter('TriggerRepeat', Inf);
            %camera.setVideoParameter('FrameGrabInterval', 2);
            %camera.setVideoParameter('TriggerFrameDelay', .04);
        end
        
        function captureImage(this, path)
            this.model.captureImage(path);
        end
        
        function enableMotors(this)
            this.model.enableMotors();
        end
        
        function disableMotors(this)
            this.model.disableMotors();
        end
        
        function enabled = getMotorsEnabled(this)
            enabled = this.model.motorsEnabled;
        end
        
        function moveActiveMotor(this, displacement)
            this.model.moveActiveMotor(displacement);
        end
        
        function setActiveMotorMoveMode(this, moveMode)
            this.model.setActiveMotorMoveMode(moveMode);
        end
        
        function numAxis = getAvailableJogAxis(this)
            numAxis = this.model.getAvailableJogAxis();
        end
        
        function motor = getActiveMotor(this)
            motor = this.model.getActiveMotor();
        end
        
        function setActiveMotor(this, motorStr)
            this.model.setActiveMotor(motorStr);
        end
        
        function setActiveAxis(this, axis)
            this.model.setActiveAxis(axis);
        end
        
        function displacements = getDisplacements(this)
            displacements = this.model.getDisplacements();
        end
        
        function updateTemplateFromROI(this)
            this.model.updateTemplateFromROI();
        end
        
        function loadTemplate(this, path)
            this.model.loadTemplate(path);
        end
        
        function identifyHomePoint(this)
            this.model.identifyHomePoint();
        end
        
        function homepoint = getHomePoint(this)
            homepoint = this.model.getHomePoint();
        end
        
        function setROI(this, type, roi)
            this.model.setROI(type, roi);
        end
        
        function roi = getROI(this, type)
            roi = this.model.getROI(type);
        end
        
        function moveToHomeXY(this)
            this.model.moveToHomeXY();
        end
        
        function startProbingSequence(this)
            this.model.startProbingSequence();
        end
        
        function enableProbe(this)
            this.model.enableProbe();
        end
        
        function disableProbe(this)
            this.model.disableProbe();
        end
        
        function setVarianceThreshold(this, var)
            this.model.setVarianceThreshold(var);
        end
    end
    
end

