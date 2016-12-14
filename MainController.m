
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
        
        function setCameraActive(this, active)
            this.model.cameraActive = active;
        end
        
        function active = cameraIsActive(this)
            active = this.model.cameraActive;
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
        
        function moveManualNA(this, distance)
            this.model.moveManualNA(distance);
        end
        function moveManualPiezo(this, distance)
            this.model.moveManualPiezo(distance);
        end
        
    end
    
end

