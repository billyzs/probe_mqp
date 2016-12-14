classdef APTDriver < MotorDriver
    properties (Access=private)
        SNPiezo = 81813026;
        SNStrain = 84813062;
        actx = 'MGPIEZO.MGPiezoCtrl.1';
    end
    properties (Access = protected)
        % Equipment
        name = 'APTDriver';
        
        % MotorDriver
        defaultVelocity = 0.1;
        defaultAcceleration = 0.1 ;
        maxDisplacement = 20;
        maxVelocity = 2;
        maxAcceleration = 2;
        displacement = 0;
        moves = [0,0 0];
    end
    properties (Access = public)
        fpos = [488 342 650 840]; % figure default position
        gui = figure('Position', [488 342 650 840],...
           'Menu','None',...
           'Name','APT GUI'); % figure that holds the gui
        hPiezo;
        hStrain; % the strainGauge object
    end
    
    methods (Access=public)
        function initialize(this)
            % are these enough to initialize?
            this.hPiezo = actxcontrol(this.actx, [20 420 600 400], this.gui);
            set(this.hPiezo, 'HWSerialNum', this.SNPiezo);
            % this.hStrain = actxcontrol(this.actx, [20 20 600 400 ], this.gui);
            % set(this.hStrain, 'HWSerialNum', this.SNStrain);
        end
        function enable(this)
            try
                this.hPiezo.StartCtrl;
                % this.hStrain.StartCtrl;
                % what does this do?
                this.hPiezo.Identify;
                % this.hStrain.Identify;
                pause(1);
            catch exception
                rethrow(exception);
            end
        end
        function disable(this)
            this.hPiezo.StopCtrl;
            % this.hStrain.StopCtrl;
        end
        function obj = APTDriver()
            initialize(obj);
        end
        function success = doMove(this, displacement, velocity, acceleration)
            % displacement is in um; 75 volts == 20 um 
            v = min(65, (displacement / 20 * 75)); 
            this.hPiezo.SetVoltOutput(0, v); % 0 is channel ID?
            success = 1;
        end
    end
end
