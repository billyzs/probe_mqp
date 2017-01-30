classdef MainModel < handle    
    properties (SetObservable)
        %State Variables
        cameraActive = false;
        motorsEnabled = false;
        activeMotor;
        displacementUpdated = false;
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
            this.activeMotor = this.newportDriver;
            this.motorsEnabled = true;
        end
        
        function enableMotors(this)
            'Enableing...'
            drawnow('update')
            this.mvpDriver.enable();
            this.aptDriver.enable();
            this.newportDriver.enable();
            this.motorsEnabled = true;
            'Motors Enabled'
        end
        function disableMotors(this)
            this.mvpDriver.disable();
            this.aptDriver.disable();
            this.newportDriver.disable();
            this.motorsEnabled = false;
        end
        
        function setActiveMotor(this, motorStr)
            switch motorStr
                case 'National Aperture' 
                    this.activeMotor = this.mvpDriver;
                case 'Piezo'
                    this.activeMotor = this.aptDriver;
                case 'Newport XY'
                    this.activeMotor = this.newportDriver;
                otherwise
                    warning('Unexpected active motor type. Active motor unchanged.')
            end
        end
        
        
        function motor = getActiveMotor(this)
            motor = this.activeMotor;
        end
        
        function setActiveMotorMoveMode(this, moveMode)
            this.activeMotor.setMoveMode(moveMode);
        end
        
        function moveActiveMotor(this, displacement)
            if (isnumeric(displacement) && ~isempty(displacement))
                this.activeMotor.move(displacement);
                this.activeMotor.updateDisplacement(displacement);
                this.displacementUpdated = ~this.displacementUpdated;
            end
        end
        
        function numAxis = getAvailableJogAxis(this)
            numAxis = 0;
            switch this.activeMotor
                case this.mvpDriver 
                    numAxis = 1;
                case this.aptDriver
                    numAxis = 1;
                case this.newportDriver
                    numAxis = 2;
                otherwise
                    warning('Unexpected active motor type. Num Axis set to 0')
            end
        end
        
        function displacements = getDisplacements(this)
%             displacements = [this.mvpDriver.getDisplacement(),...
%                              this.aptDriver.getDisplacement(),...
%                              this.newportDriver.getDisplacement()];
            displacements = [0,...
                             0,...
                             this.newportDriver.getDisplacement()];
        end
        
        function setActiveAxis(this, axis)
           if (this.activeMotor == this.newportDriver)
               this.newportDriver.setActiveAxis(axis);
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