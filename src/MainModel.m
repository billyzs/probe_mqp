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
        varianceThreshold = 30;
        varianceFitDisplacementCuttoff = -1500;
        expFunction;
        targetDisplacement = 0;
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
            displacements = [this.mvpDriver.getDisplacementUM(),...
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
        
        function initializeCamera(this, cameraType, view)
            switch cameraType
                case 'webcam'
                    this.setCamera(CameraWebcam(1, 'MJPG_640x480'));
                case 'gentl'
                    this.setCamera(CameraPike(1));
                    %this.model.setCamera(CameraPike(1));
            end
            this.camera.setVideoParameter('FramesPerTrigger', 1);
            this.camera.setVideoParameter('TriggerFcn', @view.previewFrameCallback);
            this.camera.setVideoParameter('TriggerRepeat', Inf);
            this.camera.setVideoParameter('FrameGrabInterval', 2);
            %camera.setVideoParameter('TriggerFrameDelay', .04);
        end
        
        function setCameraActive(this, active)
            if (~isempty(this.camera))
                if (active)
                    this.camera.start();
                else
                    this.camera.stop
                end
                this.cameraActive = active;
            else
                this.cameraActive = false;
            end
        end
        
        function active = cameraIsActive(this)
            active = this.cameraActive;
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
            this.moveToImageXY(706,385)
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
            this.camera.stop();
            pause(0.1);
            this.probe.connect();
            pause(0.1);
            this.camera.start();
            pause(0.1);
            this.probe.updateNoLoadVoltage();
            %this.probeCurrentPoint();
            %return
            'Sequence'
            samplesPerSide = [2,2]; %5 x 5 sample square
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
		    this.probeCurrentPoint();
                end
            end
            %Place multi point code here
            %this.probeCurrentPoint();
        end
        
        function probeCurrentPoint(this)
            if (~this.cameraActive || isempty(this.camera) || ~this.motorsEnabled)
                return
            end
           
            %
            this.targetDisplacement
            %
            
            'Starting approach'
            % Pre devices
            
            % this.mvpDriver.moveHome();
            this.aptDriver.moveHome();
            this.setActiveMotor('National Aperture');
            this.setActiveMotorMoveMode('Relative');
            % Set parameters
            courseStep = -500;
            secPerTick = 0.0001; %sec National aperature movement time, actual 0.00008
            forceThreshold = 20; %uN
            %this.varianceThreshold = 48; %TBD
            roi = this.getROI(ROI.PROBE);
            inPiezoRange = false;
            % Get constant data points
            %this.newportDriver.setActiveAxis(3);
            x = this.homePoint(1);
            %this.newportDriver.setActiveAxis(2);
            y = this.homePoint(2);
            
            target = this.mvpDriver.ticksFromUm(this.targetDisplacement); %ticks
            
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
                    this.mvpDriver.moveHome();
                    return
                end
                'Getting Displacement'
                % Get camera image and calculate variance
                error = abs(target) - abs(this.mvpDriver.getDisplacement());
                if (error < 1)
                    inPiezoRange = true;
                else
                    'Move'
                    % Move course motion
                    % We may want some kind of move completed check here
                    % Min = 10um = 80 ticks, Max = 500um = 4032 ticks
                    %step = max(80, min(4032, 50 * (this.varianceThreshold - variance)))
                    %step = max(20, min(5000, 1 * (this.varianceThreshold - variance)^3))
                    step = max(8, 0.6 * error)
                    moveValid = this.moveActiveMotor(-step);
                    pause(step * secPerTick);
                    if (~moveValid)
                        warning('Course actuator cannot make desired move. No contact made. Returning to home.');
                        this.mvpDriver.moveHome();
                        return;
                    end
                end
                index = index+1;
            end
            % Update parameters
            fineStep = 0.5; %um
            courseStep = -20; %NA displacement units
            inContact = false;
            % Prep motors
            this.setActiveMotor('Piezo');
            this.setActiveMotorMoveMode('Relative');
            % Final approach
            while(~inContact)
                 this.probe.collectData();
                % Check if contact made and record data
                meanForce = this.probe.getMeanForce()
                data(index, :) = ...
                    [toc, meanForce, x, y,...
                    this.mvpDriver.getDisplacement(),...
                    this.aptDriver.getDisplacement()];
                if (abs(meanForce) >  forceThreshold)
                    inContact = true;
                    try
                        this.moveActiveMotor(-fineStep);
                    catch
                    end
                    break;
                end 
                % Step fine actuator
                if this.aptDriver.getDisplacement() + fineStep > 0.5 * this.aptDriver.getMaxDisplacement()
                    moveValid = false;
                else 
                    moveValid = this.moveActiveMotor(fineStep);
                end
                if (~moveValid)
                    % Fine actuator cannot make contact use course actuator
                    warning('Fine actuator cannot make desired move. Using course actuator.');
                    this.aptDriver.moveHome();
                    this.setActiveMotor('National Aperture');
                    this.setActiveMotorMoveMode('Relative');
                    stepModeValid = this.moveActiveMotor(courseStep);
                    if (~stepModeValid)
                        warning('Course actuator cannot make desired move. No contact made. Returning to home.');
                        this.mvpDriver.moveHome();
                        return;
                    end
                    this.setActiveMotor('Piezo');
                    this.setActiveMotorMoveMode('Relative');
                end
            end
            % Contact Made
            % Apply force then let settle then retract
            fineStep = 0.2; %um
            % The piezo is down as positive and negative going up
            pause(0.1);
            'Contact Made'
            for step = 1:10
                this.probe.collectData();
                meanForce = this.probe.getMeanForce()
                if (abs(meanForce) > 4 * forceThreshold)
                    warning('Force too high returning home');
                    this.aptDriver.moveHome();
                    break;
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
            figure;
            plot(data(:,6), data(:,2), '.');
            xlabel('Displacement on piezo (um)');
            ylabel('Force (uN)');
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
        function setVarianceThreshold(this, var)
            this.varianceThreshold = var;
        end
        function setVarianceFitDisplacementCuttoff(this, cuttoff)
            this.varianceFitDisplacementCuttoff = cuttoff;
        end
        % Function sets the parameters for the ExpFunction
        function setExpFunc(this, expFunction)
            this.expFunction = expFunction;
        end
        
        %Function returns the expFunction
        function expFunc = getExpFunc(this)
            if (isempty(this.expFunction))
                warning('ExpFunction no yet defined for MainModel');
            end
            expFunc = this.expFunction;
        end
        
        function enabled = getMotorsEnabled(this)
            enabled = this.motorsEnabled;
        end
        
        function setTargetDisplacement(this, displacement)
            this.targetDisplacement = displacement;
        end
        % TO DO
        % (Done) Change non-file dialogs to java 
        % (Done) Disable set ROI button in Jog mode
        % (Done) Remove dialog at end of calibration
        % (Done) Ensure that p controller works
        % Open new chip
        % Calibrate interferometer for new chip
        % Run tests
        % Add dialog for selecting probe location
        % Move device back a bit when contact is made
        % Clean up variance code in MainView
        % Implement full device test
        % Test on full device
        
    end
end