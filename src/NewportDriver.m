classdef NewportDriver < MotorDriver
    %NewportDriver Class to interface with the newport stages
    %   Extends MotorDriver

    properties (Access=protected)
        % Name of the controller
        name = 'ESP';
        
        % MotorDriver properties see parent class for description
        maxDisplacement = 100;
        maxVelocity = 1;
        maxAcceleration = 1;
        displacement = 0;
        velocity = .001;
        acceleration = .001;
        
        % List of axis numbers controller by this object
        numAxis = 0;
        % Name of driver library to interface with
        driverLibrary = 'esp6000';
        % The current active axis
        activeAxis = 2;
        % Array of displacements for each axis
        displacementList = [];
    end
    
    methods (Access=private)
        % Function to establish connection to the driver library
        function connect(this)
            if (~libisloaded(this.driverLibrary))
                loadlibrary(this.driverLibrary);
            end
        end
        
        % Function to enable the motors for all axis
        function enableMotor(this)
            for axis = 1:this.numAxis
                [error] = calllib(this.driverLibrary,'esp_enable_motor', axis);
            end
        end
    end
    
    methods (Access=public)
   
        % Constructor
        function obj = NewportDriver(numAxis)
            obj.numAxis = numAxis;
            obj.displacementList = zeros(size(1:numAxis));
        end
        
        % Destructor
        function delete(this)
            if (libisloaded(this.driverLibrary))
                unloadlibrary(this.driverLibrary)
            end
        end
        
        % Function to enable the motor hardware
        function enable(this)
            try
                this.connect();
                this.enableMotor();
            catch exception
                clear obj;
                rethrow(exception);
            end
        end
        
        % Function to disable the motor hardware
        function disable(this)
            if (libisloaded(this.driverLibrary))
                for axis = 1:this.numAxis
                    [error] = calllib(this.driverLibrary,'esp_disable_motor', axis);
                end
            end
        end
        
        % Function to set the axis that will be used for move and set commands
        function setActiveAxis(this, axis)
            this.displacementList(1:this.activeAxis) = this.displacement;
            this.activeAxis = axis;
            this.displacement = this.displacementList(1:this.activeAxis);
        end
        
        % Function to execute a move of the given displacement
        function success = doMove(this, displacement)
            success = 0;
            if (libisloaded(this.driverLibrary))
                switch moveMode
                    case 'Absolute'
                        [error] = calllib(this.driverLibrary,'esp_move_absolute', this.activeAxis, displacement);
                    case 'Relative'
                        [error] = calllib(this.driverLibrary,'esp_move_relative', this.activeAxis, displacement);
                    otherwise
                        warning('Unexpected move mode requested')
                end
                % write move cmd and get status;
                success = 1;
            end
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
        
        % Function to update the displacement based on hardware feedback
        function updateDisplacement(this, displacement)
            if (nargin == 2)
                % If filtering is used with target displacement
            else
                
            end
        end
        
        % Function to set the acceleration to use on doMove commands
        function setAcceleration(this, accel)
            if (libisloaded(this.driverLibrary))
                [error] = calllib(this.driverLibrary,'esp_set_accel', this.activeAxis, accel);
            end
        end
        
        % Function to set the velocity to use on doMove commands
        function setVelocity(this, vel)
            if (libisloaded(this.driverLibrary))
                [error] = calllib(this.driverLibrary,'esp_set_speed', this.activeAxis, vel);
            end
        end
        
        % Function to get the acceleration
        function accel = getAcceleration(this)
            if (libisloaded(this.driverLibrary))
                accel = 0;
                [error, accel] = calllib(this.driverLibrary,'esp_get_accel', this.activeAxis, accel);
            end
        end
        
        % Function to get the velocity
        function vel = getVelocity(this)
            if (libisloaded(this.driverLibrary))
                vel = 0;
                [error, vel] = calllib(this.driverLibrary,'esp_get_speed', this.activeAxis, vel);
            end
        end
    end

end

