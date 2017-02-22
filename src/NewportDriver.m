classdef NewportDriver < MotorDriver
    %NewportDriver Class to interface with the newport stages
    %   Extends MotorDriver and implements required methods

    properties (Access=protected)
        % Name of the controller
        name = 'ESP';
        
        % MotorDriver properties see parent class for description
        % Newport Displacements are in mm and time units in sec
        % Vel = mm/s
        % Accl = mm/s^2
        maxDisplacement = 100;
        maxVelocity = 5;
        maxAcceleration = 20;
        displacement = 0;
        velocity = 0.5;
        acceleration = 10;
        
        % List of axis numbers controller by this object
        numAxis = 0;
        % Name of driver library to interface with
        driverLibrary = 'esp6000';
        % The current active axis
        activeAxis = 2;
        % Array of displacements for each axis
        displacementList = [];
        %The movement mode that will be used. "Absolute" or "Relative"
        moveMode = 'Relative';
    end
    
    methods (Access=private)
        % Function to establish connection to the driver library
        function connect(this)
            if (~libisloaded(this.driverLibrary))
                [notfound,warnings] = loadlibrary(this.driverLibrary);
                [error] = calllib(this.driverLibrary,'esp_init_system');
                this.catchAndPrintError(error);
            end
        end
        
        % Function to enable the motors for all axis
        function enableMotor(this)
            for axis = 1:this.numAxis
                [error] = calllib(this.driverLibrary,'esp_enable_motor', axis);
                this.catchAndPrintError(error);
            end
        end
    end
    
    methods (Access=public)
   
        % Constructor
        function obj = NewportDriver(numAxis, xAxis, yAxis)
            if numAxis <= 0
                error('Must be at least one axis on newport driver');
            end
            obj.numAxis = numAxis;
            obj.displacementList = zeros(1,numAxis);
        end
        
        % Destructor
        function delete(this)
            this.disable();
            if (libisloaded(this.driverLibrary))
                unloadlibrary(this.driverLibrary)
            end
        end
        
        % Function to enable the motor hardware
        function enable(this)
            try
                this.connect();
                this.enableMotor();
                for axis = 1:this.numAxis
                    this.setActiveAxis(axis);
                    this.setVelocity(this.velocity)
                    this.setAcceleration(this.acceleration)
                end
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
                    this.catchAndPrintError(error);
                end
            end
        end
        
        % Function to set the axis that will be used for move and set commands
        function setActiveAxis(this, axis)
            this.displacementList(this.activeAxis) = this.displacement;
            this.activeAxis = axis;
            this.displacement = this.displacementList(this.activeAxis);
        end
        
        % Function to execute a move of the given displacement
        function success = doMove(this, displacement)
            success = 0;
            error = 0;
            if (libisloaded(this.driverLibrary))
                switch this.moveMode
                    case 'Absolute'
                        [error] = calllib(this.driverLibrary,'esp_move_absolute', this.activeAxis, displacement);
                    case 'Relative'
                        [error] = calllib(this.driverLibrary,'esp_move_relative', this.activeAxis, displacement);
                    otherwise
                        warning('Unexpected move mode requested')
                end
                this.catchAndPrintError(error);
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
            end
            if (isnumeric(displacement))
                [error, displacement] = calllib(this.driverLibrary,'esp_get_position', this.activeAxis, displacement);
                this.displacement = displacement;
                this.catchAndPrintError(error);
            end
        end
        
        % Function to set the acceleration to use on doMove commands
        function setAcceleration(this, accel)
            if (libisloaded(this.driverLibrary))
                [error] = calllib(this.driverLibrary,'esp_set_accel', this.activeAxis, accel);
                this.catchAndPrintError(error);
            end
        end
        
        % Function to set the velocity to use on doMove commands
        function setVelocity(this, vel)
            if (libisloaded(this.driverLibrary))
                [error] = calllib(this.driverLibrary,'esp_set_speed', this.activeAxis, vel);
                this.catchAndPrintError(error);
            end
        end
        
        % Function to get the acceleration
        function accel = getAcceleration(this)
            if (libisloaded(this.driverLibrary))
                accel = 0;
                [error, accel] = calllib(this.driverLibrary,'esp_get_accel', this.activeAxis, accel);
                this.catchAndPrintError(error);
            end
        end
        
        % Function to get the velocity
        function vel = getVelocity(this)
            if (libisloaded(this.driverLibrary))
                vel = 0;
                [error, vel] = calllib(this.driverLibrary,'esp_get_speed', this.activeAxis, vel);
                this.catchAndPrintError(error);
            end
        end
        
        %Function to check if there is an error message and return it
        function [errorStr, errorNum, timeStamp] = catchErrors(this, errorExists)
            errorStr = '';
            errorPtr = libpointer('cstring', errorStr);
            errorNum = -1;
            timeStamp = -1;
            if (errorExists)
                [errorcode, errorStr, errorNum, timeStamp] = ...
                    calllib(this.driverLibrary,'esp_get_error_string',...
                    errorPtr, errorNum, timeStamp);
            end
        end
        
        %Function to print error messages in readable format
        function printError(this, errorStr, errorNum, timeStamp)
            if (errorNum ~= -1)
                warning(['Error: ' num2str(errorNum) ' Time: ' timeStamp errorStr]);
            end
        end
        
        %Function to catch and print and error for convienance
        function catchAndPrintError(this, errorExists)
            [errorStr, errorNum, timeStamp] = this.catchErrors(errorExists);
            printError(this, errorStr, errorNum, timeStamp)
        end
    end

end

