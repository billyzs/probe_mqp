classdef MainModel < handle    
    properties (SetObservable)
        %State Variables
        cameraActive = false;
        motorsEnabled = false;
        piezoPosition = 0;
        NAPosition = 0;
        %Timers
        pollingTimer;
        %Equipment
        mvpDriver;
        aptDriver;
        aptStrainGuage;
        camera;
        videoTimer;
        
    end
        
    methods
        function this = MainModel(mvpDriver, aptDriver, aptStrainGuage)
            this.mvpDriver = mvpDriver;
            this.aptDriver = aptDriver;
            this.aptStrainGuage = aptStrainGuage;
        end
        
        %function setMVPDriver(this, mvpDriver)
        %   this.mvpDriver = mvpDriver;
        %end
        
        function startPollingTimer(this)
            this.pollingTimer = timer('Period', .1, 'TasksToExecute', Inf, ...
            'ExecutionMode', 'fixedRate', 'TimerFcn', @this.pollingTimerCallback);
            start(this.pollingTimer);
        end
        function enableMotors(this)
            this.mvpDriver.enable();
            this.aptDriver.enable();
            this.motorsEnabled = true;
        end
        function disableMotors(this)
            this.mvpDriver.disable();
            this.aptDriver.disable();
            this.motorsEnabled = false;
        end
        
        function moveManualNA(this, distance)
            if (isnumeric(distance) && ~isempty(distance))
                this.mvpDriver.defaultMove(distance);
                this.NAPosition = NAPosition + distance;
            end
        end
        function moveManualPiezo(this, distance)
            if (isnumeric(distance) && ~isempty(distance))
                this.aptDriver.defaultMove(distance);
            end
        end
        
        function pollingTimerCallback(this, src, evt)
            piezoPosition = this.aptStrainGuage.getPosition();
            if (this.piezoPosition ~= piezoPosition)
                this.piezoPosition = piezoPosition;
            end
        end
        
        function camera = getCamera(this)
            camera = this.camera;
        end
        
        function setCamera(this, camera)
            this.camera = camera;
        end
        
        function captureImage(this, path)
            if (this.cameraActive == true && ~isempty(this.camera))
                im = step(this.camera);
                imwrite(im, path);
            end
        end
    end
end