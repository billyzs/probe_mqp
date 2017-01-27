classdef APTDriver < MotorDriver
    properties (Access=private)
        % Serial Number of the peizo controller in use
        SNPiezo = 81813026;
        % Active X control interface used to communicate with controller
        actx = 'MGPIEZO.MGPiezoCtrl.1';
    end
    properties (Access = protected)
        % Equipment
        name = 'APTDriver';
        
        % MotorDriver properties see parent class for description
        maxDisplacement = 20;
        maxVelocity = 2;
        maxAcceleration = 2;
        displacement = 0;
        velocity = 1;
        acceleration = 1;
        
        % Handle to a strain guage that can be used for displacement
        hStrainGuage;
    end
    properties (Access = public)
        % Position of the active x control in a figure
        fpos = [488 342 650 840]; % figure default position
        % The figure which will hold the active x control
        gui = figure('Position', [488 342 650 840],...
           'Menu','None',...
           'Name','APT GUI');
       % Hangle to the active x control object of the peizo
        hPiezo;
    end
    
    methods (Access=public)
        % Constructor
        function obj = APTDriver(hStrainGuage)
            if (nargin == 1)
                obj.hStrainGuage = hStrainGuage;
            end
            initialize(obj);
        end
        
        % Function to intialize a connection to the active x control
        function initialize(this)
            % are these enough to initialize?
            this.hPiezo = actxcontrol(this.actx, [20 420 600 400], this.gui);
            set(this.hPiezo, 'HWSerialNum', this.SNPiezo);
        end
        
        % Function to enable the motor hardware
        function enable(this)
            try
                this.hPiezo.StartCtrl;

                this.hPiezo.Identify;
                pause(1);
            catch exception
                rethrow(exception);
            end
        end
        
        % Function to disable the motor hardware
        function disable(this)
            this.hPiezo.StopCtrl;
        end
        
        % Function to execute a move of the given displacement
        function success = doMove(this, displacement)
            switch moveMode
                case 'Absolute'
                    %Keep the input displacement
                case 'Relative'
                    displacement = this.displacement + displacement;
                otherwise
                    warning('Unexpected move mode requested')
            end
            % displacement is in um; 75 volts == 20 um
            v = min(65, (displacement / 20 * 75)); %!!! Double check this number
            this.hPiezo.SetVoltOutput(0, v); % 0 is channel ID?
            success = 1;
        end

        % Function to set the movement method that will be used
        function setMoveMode(this, moveMode)
            switch moveMode
                case 'Absolute'
                    this.moveMode = moveMode;
                case 'Relative'
                    this.moveMode = moveMode;
                otherwise
                    warning('Unexpected move mode requested')
            end
        end
        
        % Function to set the velocity to use on doMove commands
        function setVelocity(this, vel)
            this.velocity = vel; % !!! implement better once control for peizo is known
        end
        
        % Function to set the acceleration to use on doMove commands
        function setAcceleration(this, accel)
            this.acceleration = accel; % !!! implement better once control for peizo is known
        end
        
        % Function to retreve the hardware calculated displacement if
        % available. Optional displacement parameter can be used as seen
        % fit.
        function updateDisplacement(this, displacement)
            if(nargin == 2)
                % Add to here is some sort of filtering based on input will
                % be used
            end
            if (~isempty(this.hStrainGuage))
                this.displacement = this.hStrainGuage.getPosition();
            end
        end
    end
end
