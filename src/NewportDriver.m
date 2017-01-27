classdef NewportDriver < MotorDriver
    %NEWPORTDRIVER Class to interface with the newport stages
    %   Detailed explanation goes here

    properties (Access=protected)
        name = 'ESP';
        defaultVelocity = 10;
        defaultAcceleration = 10;
        maxDisplacement = 40;
        maxVelocity = 10;
        maxAcceleration = 10;
        displacement;
        moves = zeros(1,3); % moves is a n*3 Array (Stack) containing the past moves
        axisList = [];
        driverLibrary = 'esp6000';
        activeAxis = 1;
    end
    
    methods (Access=private)
        function connect(this)
            if (~libisloaded(this.driverLibrary))
                loadlibrary(this.driverLibrary);
            end
        end
        function enableMotor(this)
            for axis = this.axisList
                [error] = calllib(this.driverLibrary,'esp_enable_motor', axis);
            end
        end
    end
    
    methods (Access=public)
   
        % constructor
        function obj = NewportDriver(axisList)
            obj.axisList = axisList;
        end
        
        function delete(this)
            if (libisloaded(this.driverLibrary))
                unloadlibrary(this.driverLibrary)
            end
        end
        
        function enable(this)
            try
                this.connect();
                this.enableMotor();
            catch exception
                clear obj;
                rethrow(exception);
            end
        end
        function disable(this)
            if (libisloaded(this.driverLibrary))
                for axis = this.axisList
                    [error] = calllib(this.driverLibrary,'esp_disable_motor', axis);
                end
            end
        end
        
        function setActiveAxis(this, axis)
            this.activeAxis = axis;
        end
        
        function success = doMove(this, displacement, vel, accel)
            success = 0;
            if (libisloaded(this.driverLibrary))
                if nargin == 4
                    setAcceleration(this, this.activeAxis, accel)
                end
                if nargin >= 3
                    setVelocity(this, this.activeAxis, vel)
                end
                % write move cmd and get status;
                [error] = calllib(this.driverLibrary,'esp_move_relative', this.activeAxis, displacement);

                success = 1;
            end
        end
        
        function setAcceleration(this, axis, accel)
            if (libisloaded(this.driverLibrary))
                [error] = calllib(this.driverLibrary,'esp_set_accel', axis, accel);
            end
        end
        function setVelocity(this, axis, vel)
            if (libisloaded(this.driverLibrary))
                [error] = calllib(this.driverLibrary,'esp_set_speed', axis, vel);
            end
        end
        function accel = getAcceleration(this, axis)
            if (libisloaded(this.driverLibrary))
                accel = 0;
                [error, accel] = calllib(this.driverLibrary,'esp_get_accel', axis, accel);
            end
        end
        function vel = getVelocity(this, axis)
            if (libisloaded(this.driverLibrary))
                vel = 0;
                [error, vel] = calllib(this.driverLibrary,'esp_get_speed', axis, vel);
            end
        end
    end

end

