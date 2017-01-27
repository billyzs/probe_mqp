classdef MainModel < handle    
    properties (SetObservable)
        %State Variables
        cameraActive = false;
        motorsEnabled = false;
        piezoPosition = 0;
        NAPosition = 0;
        newportXPosition = 0;
        newportYPosition = 0;
        activeMotor = '';
        
        %Timers
        pollingTimer;
        %Equipment
        mvpDriver;
        aptDriver;
        aptStrainGuage;
        newportDriver;
        camera;
        videoTimer;
        
    end
        
    methods
        function this = MainModel(mvpDriver, aptDriver, aptStrainGuage, newportDriver)
            this.mvpDriver = mvpDriver;
            this.aptDriver = aptDriver;
            this.aptStrainGuage = aptStrainGuage;
            this.newportDriver = newportDriver;
        end
        
        %function setMVPDriver(this, mvpDriver)
        %   this.mvpDriver = mvpDriver;
        %end
        
        function startPollingTimer(this)
            this.pollingTimer = timer('Period', .5, 'TasksToExecute', Inf, ...
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
        
        function setActiveMotor(this, motorStr)
            this.activeMotor = motorStr;
        end
        
        function motorStr = getActiveMotor(this)
            motorStr = this.activeMotor;
        end
        
        function setActiveMotorPosition(this, position)
            switch this.activeMotor
                case 'National Aperture' 
                    this.moveAbsoluteNA(position);
                case 'Piezo'
                    this.moveAbsolutePiezo(position);
                case 'Newport XY'
                otherwise
                    warning('Unexpected active motor type')
            end
        end    
        
        function moveAbsoluteNA(this, distance)
            if (isnumeric(distance) && ~isempty(distance))
                this.mvpDriver.defaultMove(distance);
                this.NAPosition = this.NAPosition + distance;
            end
        end
        function moveAbsolutePiezo(this, distance)
            if (isnumeric(distance) && ~isempty(distance))
                this.aptDriver.defaultMove(distance);
            end
        end
        function moveAbsoluteNewport(this, x_pos, y_pos)
            if (isnumeric(x_pos) && ~isempty(x_pos)...
                && isnumeric(y_pos) && ~isempty(y_pos))
                this.newportDriver.move(distance);
            end
        end
        
         function setActiveAxis(this, axis)
            this.activeAxis = axis;
        end
        
        function success = doMove(this, displacement, vel, accel)
        
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
            if (this.cameraActive == true && ~isempty(this.camera) && ~isempty(path))
                im = this.camera.getImageData();
                imwrite(im, path);
            end
        end
    end
end