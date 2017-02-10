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
        probe;
        %Data
        template;
        homePoint = [0,0];
        roiDictionary;
        homeOffset = [0,0];
    end
        
    methods
        function this = MainModel(mvpDriver, aptDriver, aptStrainGuage, newportDriver, probe)
            this.mvpDriver = mvpDriver;
            this.aptDriver = aptDriver;
            this.aptStrainGuage = aptStrainGuage;
            this.newportDriver = newportDriver;
            this.activeMotor = this.newportDriver;
            this.motorsEnabled = true;
            this.probe = probe;
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
        
        function enableProbe(this)
            this.probe.connect();
        end
        
        function disableProbe(this)
            this.probe.disconnect();
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
        
        function success = moveActiveMotor(this, displacement)
            success = false;
            if (isnumeric(displacement) && ~isempty(displacement))
                success = this.activeMotor.move(displacement);
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
        
        function setHomeOffset(this, offset)
            if (size(offset) ~= 2)
                error('setHomeOffset should take in a 2 element matrix of x and y'); 
            end
            this.homeOffset = offset;
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
            this.homeOffset = [delta(1), delta(2)];
            %Here would be where we check if the movement was successful
        end
        
        function delta = getDistanceComponentsMM(this, p1, p2)
            delta = -((p2 - p1) * (this.camera.getPixelSize() / 1000));
        end
        
        function startProbingSequence(this)
            this.probeCurrentPoint();
            %Place multi point code here
            %loop
                % probeCurrentPoint
            % return data
        end
        
        function probeCurrentPoint(this)
            if (~this.cameraActive || isempty(this.camera) || ~this.motorsEnabled)
                return
            end
           
            'Starting approach'
            % Pre devices
            this.enableProbe();
            this.mvpDriver.moveHome();
            this.aptDriver.moveHome();
            this.setActiveMotor('National Aperture');
            this.setActiveMotorMoveMode('Relative');
            % Set parameters
            courseStep = -500;
            variance = 0;
            forceThreshold = 10000;
            varianceThreshold = 54;
            roi = this.getROI('Probe');
            inPiezoRange = false;
            % Get constant data points
            this.newportDriver.setActiveAxis(3);
            x = this.newportDriver.getDisplacement() - this.homeOffset(1);
            this.newportDriver.setActiveAxis(2);
            y = this.newportDriver.getDisplacement() - this.homeOffset(2);
            
            % Create data object
            data = zeros(100,6); % Sec, uN, x in um, y in um, z course, z fine
            index = 1;
            'Starting approach'
            % Start approach timer
            timeout = 30;
            tic;
            % Course actuation
            while(~inPiezoRange)
                if (toc >  timeout)
                    warning('Approach timedout');
                    return
                end
                'Getting Force'
                % Record data
                this.probe.collectData();
                meanForce = this.probe.getMeanForce();
                meanForce
                values = [toc, meanForce, x, y,...
                            this.mvpDriver.getDisplacement(),...
                            this.aptDriver.getDisplacement()]
                size(values)
                x
                y
                this.mvpDriver.getDisplacement()
                this.aptDriver.getDisplacement()
                data(index, :) = ...
                    [toc, meanForce, x, y,...
                    this.mvpDriver.getDisplacement(),...
                    this.aptDriver.getDisplacement()];
                'Comparing Force'
                % Check if contact made early and abort if so
                if (meanForce >  forceThreshold)
                    warning('Early contact made')
                    return
                end
                'Getting Image'
                % Get camera image and calculate variance
                im = this.camera.getImageData();
                probeIm = im(roi(2):roi(4), roi(1):roi(3));
                'Variance'
                variance = VarianceOfLaplacian(probeIm)
                if (variance > varianceThreshold)
                    inPiezoRange = true;
                else
                    'Move'
                    % Move course motion
                    % We may want some kind of move completed check here
                    moveValid = this.moveActiveMotor(courseStep);
                    if (~moveValid)
                        warning('Course actuator cannot make desired move. No contact made. Returning to home.');
                        this.mvpDriver.moveHome();
                        return;
                    end
                end
                index = index+1;
            end
            
            'Done'
            return
            % Update parameters
            fineStep = 1;
            courseStep = 100;
            inContact = false;
            % Prep motors
            this.setActiveMotor('Piezo');
            this.setActiveMotorMoveMode('Relative');
            % Final approach
            while(~inContact)
                % Step fine actuator
                moveValid = this.moveActiveMotor(fineStep);
                if (~moveValid)
                    % Fine actuator cannot make contact use course actuator
                    warning('Fine actuator cannot make desired move. Using course actuator.');
                    this.aptDriver.moveHome();
                    this.setActiveMotor('National Aperture');
                    stepModeValid = this.moveActiveMotor(courseStep);
                    if (~stepModeValid)
                        warning('Course actuator cannot make desired move. No contact made. Returning to home.');
                        this.mvpDriver.moveHome();
                        return;
                    end
                    this.setActiveMotor('Piezo');
                    this.setActiveMotorMoveMode('Relative');
                end
                % Check if contact made and record data
                meanForce = this.probe.getMeanForce();
                data(index, :) = ...
                    [toc, meanForce, x, y,...
                    this.mvpDriver.getDisplacement(),...
                    this.aptDriver.getDisplacement()];
                if (meanForce >  forceThreshold)
                    inContact = true;
                end 
            end
            % Contact Made
            % Apply force then let settle then retract
            waitTime = 1;
            for stepDirection = [1,-1,0]
                while(tic < waitTime + tic)
                    meanForce = this.probe.getMeanForce();
                    data(index, :) = ...
                        [toc + contactTime, meanForce, x, y,...
                        this.mvpDriver.getDisplacement(),...
                        this.aptDriver.getDisplacement()];
                end
                this.moveActiveMotor(stepSize * stepDirection);
            end

            % Retract and complete sample
            this.mvpDriver.moveHome();
            this.aptDriver.moveHome();
            this.disableProbe();
            % Complete
            % Do something with data !!!
        end
        
        % TO DO
        % Done: Add probe object to MainModel and intialize is
        % Done: Add moveHome method to MotorDriver
        % Confirm Relative motion on piezo
        % Confirm getDisplacement on NA and Piezo
        % Done: Get X and Y location for national aperature stages
        % Done: Clean up approach function
        % Split code into functions
        % Develop testing method that can be done with the needle.
        % Attach probe and get images of probe over device and on approach
        % Implement Billy's probe auto detection method in matlab
        % Develop method for moving to next X,Y probing location
        % Fix national aperature displacement readings
        
    end
end