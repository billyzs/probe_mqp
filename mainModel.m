classdef MainModel < handle    
    properties (SetObservable)
        test
        cameraActive = false;
        motorsEnabled = false;
        mvpDriver;
        %Equipment Goes here
    end
        
    methods
        function this = MainModel(mvpDriver)
            this.mvpDriver = mvpDriver;
        end
        
        %function setMVPDriver(this, mvpDriver)
        %   this.mvpDriver = mvpDriver;
        %end
        function enableMotors(this)
            this.mvpDriver.enable();
            this.motorsEnabled = true;
        end
        function disableMotors(this)
            this.mvpDriver.disable();
            this.motorsEnabled = false;
        end
        
        function moveManualNA(this, distance)
            if (isnumeric(distance) && ~isempty(distance))
                this.mvpDriver.defaultMove(distance);
            end
        end
    end
end