classdef mvpController < handle
    properties
        comPort % COM1, COM2, ...
        address % Sequence 1, 2 , 3 ... 
    end
    methods
        % constructor
        function obj = mvpController(addr, port)
            obj.address = addr;
            obj.comPort = serial(port,'BaudRate', 9600, 'DataBits',8,  'StopBits', 1,... 
            'Parity', 'none','FlowControl', 'none', ...
            'ReadAsyncMode', 'continuous', ...
            'Terminator', 'CR', ...
            'ByteOrder', 'littleEndian');     
            try
                fopen(obj.comPort);
                
                obj.writeCmd('HO');
                obj.writeCmd('EN');
                obj.writeCmd('ANO', 2350); % ANO sets the current. has to be set to 2350 per NA rep Jim Steward
                
            catch ME
                fclose(obj.comPort);
                clear obj;
                rethrow(ME);            
            end
        end
        function delete(obj)
            fclose(obj.comPort);
        end
        function cmd = parseCommand(this, c, val)
            if nargin < 3 || strcmp(val, '')
                val = '';
            else 
                val = [' ', int2str(val)];
            end
            cmd = [int2str(this.address), ' ', c, val];

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
                mymsg = ['Error writing command ' cmd ' to serial port. Port is ' this.comPort.Status];
                % disp(mymsg);
                % cause = MException('AcctError:NoClient', mymsg);
                % ME = addCause(ME, cause);
                rethrow(ME);
            end
        end
  
        function [moved, pos, status] = move(this, displacement, vel, accel)
            %TODO return only moved
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
            pos = 0; 
            status = '';
            % this.writeCmd('M');
            % pos = fscanf(this.comPort);
            % this.writeCmd('ST');
            % status = fscanf(this.comPort);
            moved = 1;            
        end
        
        function connect(this)
            this.writeCmd('HO');
        end
        
        function enableMotor(this)
            this.writeCmd('EN');
        end
        
        function 
        
    end
end
        