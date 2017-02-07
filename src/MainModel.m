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
        %Data
        template;
        homePoint = [0,0];
        roiDictionary;     
    end
        
    methods
        function this = MainModel(mvpDriver, aptDriver, aptStrainGuage, newportDriver)
            this.mvpDriver = mvpDriver;
            this.aptDriver = aptDriver;
            this.aptStrainGuage = aptStrainGuage;
            this.newportDriver = newportDriver;
            this.activeMotor = this.newportDriver;
            this.motorsEnabled = true;
            %Define unsed ROI types
            keySet =   {'Probe', 'Template', 'Image'};
            defaultROI =[1 1 1000 1000]; %If possible this should be based on camera width
            valueSet = {defaultROI, defaultROI, defaultROI};
            this.roiDictionary = containers.Map(keySet, valueSet);
        end
        
        function setROI(this, type, roi)
            if (~isequal(size(roi), [1 4]))
                warning('Chosen ROI is not a 1x4 matrix');
            end
            this.roiDictionary(type) = roi;
        end
        
        function roiTypes = getAvailableROIs(this)
            roiTypes = keys(this.roiDictionary);
        end
        
        function roi = getROI(this, type)
            roi = this.roiDictionary(type);
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
% I can't remember what this was for but it is not done
%!!!            displacements = [this.mvpDriver.getDisplacement(),...
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
        
        function setTemplate(this, roi)
            im = this.camera.getImageData();
            this.template = im(roi(2):roi(4), roi(1):roi(3));%imcrop(im,[roi(1) roi(2) roi(3)-roi(1) roi(4)-roi(2)]);          
        end
        
        function identifyHomePoint(this)
            img = this.camera.getImageData();
            %% Compute
            % Invoke mex function to search for matches between an image patch and an
            % input image.
            result = matchTemplateOCV(this.template, img);
            % Mark peak location
            [~, idx] = max(abs(result(:)));
            [y, x] = ind2sub(size(result),idx(1));
            templateSize = size(this.template);
            this.homePoint(1) = x + templateSize(2) /2;
            this.homePoint(2) = y + templateSize(1) /2;
            %[this.homePoint(1), this.homePoint(2)] = template_matching(this.template, img);
           
        end
        
        function homePoint = getHomePoint(this)
            homePoint = this.homePoint;
        end
        
        function moveToHomeXY(this)
            if (this.cameraActive == false || isempty(this.camera))
                return
            end
            % Should be half camera width and resolution
            delta = this.getDistanceComponentsMM(this.homePoint, [500, 500]);
            this.setActiveMotor('Newport XY');
            this.setActiveMotorMoveMode('Relative');
            this.setActiveAxis(2);
            this.moveActiveMotor(delta(2));
            this.setActiveAxis(3);
            this.moveActiveMotor(delta(1));
            %Here would be where we check if the movement was successful
        end
        
        function delta = getDistanceComponentsMM(this, p1, p2)
            delta = -((p2 - p1) * (this.camera.getPixelSize() / 1000));
        end
        
        function startProbingSequence(this)
            if (this.cameraActive == false || isempty(this.camera) || ~this.motorsEnabled)
                return
            end
            
            this.moveHome('National Aperture');
            this.moveHome('Piezo');
            this.setActiveMotor('National Aperture');
            this.setActiveMotorMoveMode('Relative');
            stepSize = 500;
            % Should we also check the probe here?
            while(varianceOfLaplacian() < threshold)
                meanForce = this.probe.getMeanForce();
                if (meanForce >  thresholdForce)
                    %Stop!!!
                    return
                end
                this.moveActiveMotor(stepSize)
            end
            
        end
        
        %Helper function for setting a motor position back to zero
        function moveHome(this, motorStr)
            switch motorStr
                case 'National Aperture' 
                    this.setActiveMotor('National Aperture');
                    this.setActiveMotorMoveMode('Absolute');
                    this.moveActiveMotor(0);
                case 'Piezo'
                    this.setActiveMotor('Piezo');
                    this.setActiveMotorMoveMode('Absolute');
                    this.moveActiveMotor(0);
                case 'Newport XY'
                    this.setActiveMotor('Newport XY');
                    this.setActiveMotorMoveMode('Absolute');
                    this.setActiveAxis(2);
                    this.moveActiveMotor(0);
                    this.setActiveAxis(3);
                    this.moveActiveMotor(0);
                otherwise
                    warning('Unexpected active motor type. Active motor unchanged.')
            end
        end
    end
end