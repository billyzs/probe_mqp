classdef MVPDriver < MotorDriver
    properties (Access=protected)
        name = 'MVP';
        comPort; % COM1, COM2, ...
        address; % Sequence 1, 2 , 3 ... 
        defaultVelocity = 100;
        defaultAcceleration = 100;
        maxDisplacement = 40000;
        maxVelocity = 4000;
        maxAcceleration = 4000;
        displacement;
        moves = zeros(1,3); % moves is a n*3 Array (Stack) containing the past moves
    end
    
    methods (Access=private)
        function connect(this)
            this.writeCmd('HO');
        end
        function enableMotor(this)
            this.writeCmd('EN');
        end
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
        
        function disable(this)
            if (this.isConnected())
                fclose(this.comPort);
            end
        end
        
        function setMoveMode(this, moveMode)
            switch moveMode
                case 'Absolute'
                    %!!! need to figure out which commands will make this
                    %work
                    this.moveMode = moveMode;
                case 'Relative'
                    this.moveMode = moveMode;
                otherwise
                    warning('Unexpected move mode requested')
            end
        end
        
        function setVelocity(this, vel)
            this.writeCmd('SP', vel);
            this.velocity = vel;
        end
        
        function setAcceleration(this, accel)
            this.writeCmd('AC', accel);
            this.velocity = accel;
        end
        
        function success = doMove(this, displacement)
            success = 0;
            try
                % parse & write command
                this.writeCmd('LA', displacement);
                
                % write move cmd and get status;
                pause(0.2); %% definitely need this pause...
                this.writeCmd('M');
                
                success = 1;
            catch exception
                rethrow(exception);
            end
        end
        
    end
    
    methods (Access=public)
        % constructor
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
        
        function delete(this)
            if (~isempty(this.comPort) && strcmp(this.comPort.Status,'open'))
                fclose(this.comPort);
            end
        end
        
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
        
        function cp = getComPort(this)
            cp = this.comPort;
        end
    end

end