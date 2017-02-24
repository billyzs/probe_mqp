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
        probe;
        %Data
        template; % This can be preallocated as can the probe image
        homePoint = [0,0]; %The DUT location in the image in px
        roiList;
        homeOffset = [0,0]; %The location of the DUT relative to its starting configuration in mm
        probeImage;
        varianceThreshold;
    end
    properties (Constant)
        %Constants
        X_AXIS = 3;
        Y_AXIS = 2;
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
            %Define used ROI types
            defaultROI =[1 1 1000 1000]; %If possible this should be based on camera width
            %Index corresponds to order of ROI enum.
            % PROBE, TEMPLATE, IMAGE
            this.roiList = {defaultROI defaultROI defaultROI};
        end
        
        % Destructor
        function delete(this)
            this.mvpDriver.delete();
            this.aptDriver.delete();
            this.aptStrainGuage.delete();
            this.newportDriver.delete();
            this.camera.delete();
            this.probe.delete();
        end
        
        function setROI(this, type, roi)
            if (~isequal(size(roi), [1 4]))
                warning('Chosen ROI is not a 1x4 matrix');
            end
            this.roiList{type}(:) = roi(:); %Element wise copy
        end
        
        function roi = getROI(this, type)
            roi = this.roiList(type);
            roi = roi{1};
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
                this.displacementUpdated = ~this.displacementUpdated; %Filliping this bit triggers a listener
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
            displacements = [this.mvpDriver.getDisplacement(),...
                              this.aptDriver.getDisplacement(),...
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
        
        function updateTemplateFromROI(this)
            roi = this.getROI(ROI.TEMPLATE);
            im = this.camera.getImageData();
            this.template = im(roi(2):roi(4), roi(1):roi(3));
        end
        
        function loadTemplate(this, path)
            this.template = imread(path);
        end
        
        function identifyHomePoint(this)
            point = this.getHomePointFromImage();
            this.homePoint(:) = point(:);          
        end
        
        function point = getHomePointFromImage(this)
            img = this.camera.getImageData();
            % Invoke mex function to search for matches between an image patch and an
            % input image.
            result = matchTemplateOCV(this.template, img);
            % Mark peak location
            [~, idx] = max(abs(result(:)));
            [y, x] = ind2sub(size(result),idx(1));
            templateSize = size(this.template);
            point = [x + templateSize(2) /2, y + templateSize(1) /2];
        end
        
        function homePoint = getHomePoint(this)
            homePoint = this.homePoint;
        end
        
        function moveToHomeXY(this)
            this.homeOffset = [0, 0];
            this.moveToImageXY(312,468)
            %Here would be where we check if the movement was successful
        end
        
        %This needs to be changed so that it will work with chaning DUT
        %locations Currently it depends on a static home point;
        function status = moveToImageXY(this, x,y, numIter)
            if nargin < 4
                numIter = 3;
            end
            status = false;
            if (this.cameraActive == false || isempty(this.camera))
                return
            end
            this.setActiveMotor('Newport XY');
            this.setActiveMotorMoveMode('Relative');
            point = this.getHomePointFromImage();
            this.homePoint(:) = point(:);
            for i = 1:numIter % should have done moving after this many iterations
                delta = this.getDistanceComponentsMM(this.homePoint, [x, y]);
                this.setActiveAxis(this.Y_AXIS);
                this.moveActiveMotor(delta(2));
                pause(1);
                this.setActiveAxis(this.X_AXIS);
                this.moveActiveMotor(delta(1));
                pause(1);
                this.homeOffset = this.homeOffset + [delta(1), delta(2)];
                %Wait for movement to complete
                % tic;
                % while(~this.newportDriver.moveComplete([this.X_AXIS, this.Y_AXIS]))
                    % think we need a busy wait here; when I stepped this
                    % part it worked just fine; 
                % pause(2);    
                % end
                % toc;
                point = this.getHomePointFromImage();
                this.homePoint(:) = point(:);
                %If location within tolerance to target, stop; else do up
                %to 3 moves
                squaredErrPixel = sum(([x,y] - point).^2);
                if  sqrt(squaredErrPixel) < 3 % pixels
                    disp('successfully moved to specified location');
                    status = true;
                    break;
                end
            end
            if ~status
                sprintf('failed to move to x=%d, y=%d in %d iterations; error is %f pixels', [x, y, numIter, squaredErrPixel])
            end
        end
        
        function delta = getDistanceComponentsMM(this, p1, p2)
            delta = -(arrayfun(@this.pxToUm,(p2 - p1)) / 1000); % -([dx, dy]um /(um / mm)))
        end

        function um = umToPx(this, p)
            um = (1 / this.camera.getPixelSize()) * p; % (1 / (um/px)) * [dx, dy]
        end
        
        function px = pxToUm(this, p)
            px = this.camera.getPixelSize() * p; % (um/px) * [dx, dy]
        end
        
        function startProbingSequence(this)
            this.probe.connect();
            this.probe.updateNoLoadVoltage();
            this.probeCurrentPoint();
            return
            'Sequence'
            samplesPerSide = [5,5]; %5 x 5 sample square
            regionDim = [300, 300]; %um
            buffer = 30; %um
            searchDim = regionDim - buffer;
            center = [searchDim(1)/2, searchDim(2)/2];
            
            pxSteps = arrayfun(@this.umToPx, searchDim ./ samplesPerSide);

            %Gets the number of steps from the center to the upper left
            %corner of a NxM square of points;
            this.homePoint
            stepsToStartPoint = floor(samplesPerSide / 2) - (0.5 * ~mod(samplesPerSide, 2));
            startPoint = this.homePoint + (stepsToStartPoint .* pxSteps);
            for sampleX = 0:(samplesPerSide(1)-1)
                for sampleY = 0:(samplesPerSide(2)-1)
                    target = startPoint - ([sampleX, sampleY] .* pxSteps);
                    this.moveToImageXY(target(1),target(2));
                    this.homePoint(:) = target(:);
                    pause(0.5); %!!!
                end
            end
            %Place multi point code here
            %this.probeCurrentPoint();
        end
        
        function probeCurrentPoint(this)
            if (~this.cameraActive || isempty(this.camera) || ~this.motorsEnabled)
                return
            end
           
            'Starting approach'
            % Pre devices
            
            % this.mvpDriver.moveHome();
            this.aptDriver.moveHome();
            this.setActiveMotor('National Aperture');
            this.setActiveMotorMoveMode('Relative');
            % Set parameters
            courseStep = -500;
            forceThreshold = 20; %uN
            this.varianceThreshold = 33; %TBD
            roi = this.getROI(ROI.PROBE);
            inPiezoRange = false;
            % Get constant data points
            %this.newportDriver.setActiveAxis(3);
            x = this.homePoint(1);
            %this.newportDriver.setActiveAxis(2);
            y = this.homePoint(2);
            
            % Create data object
            data = zeros(100,6); % Sec, uN, x in um, y in um, z coarse, z fine
            index = 1;
            % Start approach timer
            timeout = 1000;
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
                data(index, :) = [toc, meanForce, x, y,...
                            this.mvpDriver.getDisplacement(),...
                            this.aptDriver.getDisplacement()];
                'Comparing Force'
                % Check if contact made early and abort if so
                if (abs(meanForce) >  forceThreshold)
                    warning('Early contact made')
                    return
                end
                'Getting Image'
                % Get camera image and calculate variance
                im = this.camera.getImageData();
                this.probeImage = im(roi(2):roi(4), roi(1):roi(3));
                'Variance'
                variance = VarianceOfLaplacian(this.probeImage)
                if (variance > this.varianceThreshold)
                    inPiezoRange = true;
                else
                    'Move'
                    % Move course motion
                    % We may want some kind of move completed check here
                    step = max(20, min(5000, 20 + 1 * (this.varianceThreshold - variance)^3));
                    moveValid = this.moveActiveMotor(-step);
                    if (~moveValid)
                        warning('Course actuator cannot make desired move. No contact made. Returning to home.');
                        this.mvpDriver.moveHome();
                        return;
                    end
                end
                index = index+1;
            end
            
            % Update parameters
            fineStep = 1; %um
            courseStep = 10; %NA displacement units
            inContact = false;
            % Prep motors
            this.setActiveMotor('Piezo');
            this.setActiveMotorMoveMode('Relative');
            % Final approach
            while(~inContact)
                % Step fine actuator
                if this.aptDriver.getDisplacement() + fineStep > this.aptDriver.getMaxDisplacement()
                    moveValid = false;
                else 
                    moveValid = this.moveActiveMotor(fineStep);
                end
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
                this.probe.collectData();
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
            fineStep = 0.2; %um
            % The piezo is down as positive and negative going up
            pause(0.1);
            
            for step = 1:10
                this.probe.collectData();
                meanForce = this.probe.getMeanForce();
                if (meanForce > 3 * forceThreshold)
                    warning('Force too high returning home');
                    this.aptDriver.moveHome();
                    return;
                end
                data(index, :) = ...
                    [toc, meanForce, x, y,...
                    this.mvpDriver.getDisplacement(),...
                    this.aptDriver.getDisplacement()];
                this.moveActiveMotor(fineStep);
                index = index + 1;
            end

            % Retract and complete sample
            this.aptDriver.moveHome();
            pause(.1);
            %this.mvpDriver.moveHome();
            this.disableProbe();
            % Complete
            % Do something with data !!!
        end
        
        function showLiveForce(this)
            if (~this.probe.isConnected())
                this.probe.connect();
            end
            mydaq = this.probe.getDAQObject();
            mydaq.addlistener('DataAvailable',@plotData); 
            

            %Proper way to run test of 1000 samples / 1 sec
            mydaq.Rate = 10;
            mydaq.DurationInSeconds = 20;
            figure;
            mydaq.startBackground;
        end
        
        function closeLiveForceDisplay(this)
            if (~this.probe.isConnected())
                return
            end
            mydaq = this.probe.getDAQObject();
            mydaq.stopBackground;
        end
        
        % TO DO
        % Done: Add probe object to MainModel and intialize is
        % Done: Add moveHome method to MotorDriver
        % Done: Confirm Relative motion on piezo
        % Done: Confirm getDisplacement on NA and Piezo
        % Done: Get X and Y location for national aperature stages
        % Done: Clean up approach function
        % Split code into functions
        % Done: Sorta Do ne: Develop testing method that can be done with the needle.
        % Attach probe and get images of probe over device and on approach
        % Implement Billy's probe auto detection method in matlab
        % Develop method for moving to next X,Y probing location
        % Fix national aperature displacement readings
        
    end
end