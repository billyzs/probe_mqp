classdef MVPDriver < MotorDriver
    % MVPDrive implements MotorDriver for use with the National Aperature
    % linear stage and MVP controller
    properties (Access=protected)
        % Driver name
        name = 'MVP';
        % COM Port used for communication
        comPort; % COM1, COM2, ...
        % The address of the MVP controller
        address; % Sequence 1, 2 , 3 ... 
        
        % MotorDriver properties see parent class for description
        maxDisplacement = 50000;
        maxVelocity = 4000;
        maxAcceleration = 4000;
        displacement = 0;
        velocity = 100;
        acceleration = 100;
        
    end
    
    methods (Access=private)
        % Function to connect to MVP controller by sending Home command.
        % Also sets the stage position at 0
        function connect(this)
            this.setDisplacement(0);
            this.writeCmd('HO');
        end
        % Function to enable the motors connected to the MVP controller
        function enableMotor(this)
            this.writeCmd('EN');
        end
        % Function to parse the command string before being sent
        function cmd = parseCommand(this, c, val)
            if nargin < 3 || strcmp(val, '')
                val = '';
            else 
                val = [' ', int2str(val)];
            end
            cmd = [int2str(this.address), ' ', c, val];
        end
    end
    
    methods (Access=public)
        % Implemented Methods
        % Function to enable communication and the motors on controller
        function enable(this)
            try
                fopen(this.comPort);
                this.connect();
                this.enableMotor();
                this.writeCmd('ANO', 2350); % ANO sets the current. has to be set to 2350 per NA rep Jim Steward
            catch exception
                fclose(this.comPort);
                clear obj;
                rethrow(exception);
            end
        end
        
        % Function to disable communication with the MVP and disable motor
        function disable(this)
            if (this.isConnected())
                this.writeCmd('DI');
                fclose(this.comPort);
            end
        end
        
        % Function to set the movement method used by this controller
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
        
        % Function to set the velocity used by the motor
        function setVelocity(this, vel)
            this.writeCmd('SP', vel);
            this.velocity = vel;
        end
        
        % Function to set the acceleration used by the motor
        function setAcceleration(this, accel)
            this.writeCmd('AC', accel);
            this.velocity = accel;
        end
        
        % Function to update the displacement after a move command
        function updateDisplacement(this, displacement)
            if(nargin == 2)
                this.displacement = this.displacement + displacement;
            else
                %If the actuator provides feedback use it here
            end
        end
        
        % Function to move the motor the given displacement
        function success = doMove(this, displacement)
            success = 0;
            try
                % parse & write command
                switch this.moveMode
                    case 'Absolute'
                        this.writeCmd('LA', displacement);
                    case 'Relative'
                        this.writeCmd('LR', displacement);
                    otherwise
                        warning('Unexpected move mode requested')
                end
                
                % write move cmd and get status;
                pause(0.2); %% definitely need this pause...
                this.writeCmd('M');
                
                success = 1;
            catch exception
                rethrow(exception);
            end
        end
    
        % Constructor
        function obj = MVPDriver(addr, port)
            % the addr specified by the switches on the actual controller
            obj.address = addr; 
            if nargin > 1
                try
                    obj.comPort = serial(port,'BaudRate', 9600, 'DataBits',8,  'StopBits', 1,... 
                        'Parity', 'none','FlowControl', 'none', ...
                        'ReadAsyncMode', 'continuous', ...
                        'Terminator', 'CR', ...
                        'ByteOrder', 'littleEndian');    
                catch ME
                    fclose(obj.comPort);
                    clear obj;
                    rethrow(ME);            
                end
            end
        end
        
        % Destructor
        function delete(this)
            this.disable();
        end
        
        % Function returns true if the controller is connected
        function success = isConnected(this)
            success = false;
            try
                if( ~isempty(this.comPort) && strcmp(this.comPort.Status,'open'))
                    success = true;
                end
            catch exception
                rethrow(exception);
            end
        end
        
        %Regular Methods
        % Function writes a command to the MVP controller
        function writeCmd(this, cmd, val)
            if nargin < 3
                val = '';
            end
            cmd = this.parseCommand(cmd, val);
            try
                disp(cmd);
                assert(this.isConnected());
                fprintf(this.comPort, cmd);
                %pause(0.1);
            catch ME
                mymsg = ['Error writing command: ' cmd ' to serial port. Port is ' this.comPort.Status];
                disp(mymsg);
                % cause = MException('AcctError:NoClient', mymsg);
                % ME = addCause(ME, cause);
                rethrow(ME);
            end
        end
        
        % Function returns the active com port
        function cp = getComPort(this)
            cp = this.comPort;
        end
    end

end