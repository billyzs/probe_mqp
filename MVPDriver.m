classdef MVPDriver < MotorDriver
    properties (Access=protected)
        name = 'MVP';
        comPort; % COM1, COM2, ...
        address; % Sequence 1, 2 , 3 ... 
        defaultVelocity = 1000;
        defaultAcceleration = 1000;
        maxDisplacement = 4000;
        maxVelocity = 4000;
        maxAcceleration = 4000;
        displacement;
        moves = zeros(3,1); % moves is a n*3 Array (Stack) containing the past moves
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
    
    methods (Access = protected)
   
        function enable(this)
            try
                fopen(this.comport);
                this.connect();
                this.enableMotor();
                obj.writeCmd('ANO', 2350); % ANO sets the current. has to be set to 2350 per NA rep Jim Steward
            catch exception
                fclose(obj.comPort);
                clear obj;
                rethrow(exception);
            end
        end
        function disable(this)
            if (this.isConnected())
                fclose(this.comPort);
            end
        end
        function success = doMove(this, displacement, vel, accel)
            success = 0;
            try
                if nargin == 4
                    prefix = {'LA', 'SP', 'AC'};
                    cmd = [displacement, vel, accel];
                elseif nargin == 3
                    prefix = {'LA', 'SP'};
                    cmd = [displacement, vel];
                else
                    prefix = {'LA'};
                    cmd = [displacement];
                end

                % parse & write command

                for t = 1:(nargin-1)
                    this.writeCmd(char(prefix(t)), cmd(t));
                end
                % write move cmd and get status;
                pause(0.2); %% definitely need this pause...
                this.writeCmd('M');

                % this.writeCmd('M');
                % pos = fscanf(this.comPort);
                % this.writeCmd('ST');
                % status = fscanf(this.comPort);
                success = 1;
            catch exception
                rethorw(exception);
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
        
        function delete(obj)
            if (strcmp(this.comPort.Status,'open'))
                fclose(obj.comPort);
            end
        end
        
        function success = isConnnected(this)
            success = 0;
            try
                success = strcmp(this.comPort.Status,'open');
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
                assert(strcmp(this.comPort.Status,'open'));
                disp(cmd);
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
    end

end