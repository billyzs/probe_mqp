classdef MirrorDriver < Equipment
    %MirrorDriver Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access=protected)
        name
    end
    
    properties(Access=private)
        daqObject
        connected = false;
    end
    
    methods
        % Constructor
        function this = MirrorDriver()
            this.name = 'Mirror';
        end
        % Destructor
        function delete(this)
            this.disconnect();
        end
        
        function connect(this)
            if (~isempty(this.daqObject))
                release(this.daqObject)
            end
            
            this.daqObject = daq.createSession('ni');
            this.daqObject.addDigitalChannel('Dev5', 'Port0/Line0', 'OutputOnly');
            this.connected = true;
        end
        
        function daqObject = getDAQObject(this)
            daqObject = this.daqObject;
        end
        
        function disconnect(this)
            if (~isempty(this.daqObject))
                release(this.daqObject);
            end
            this.connected = false;
        end
        
        function status = isConnected(this)
            status = this.connected;
        end
        
        function setFringesEnabled(this, enabled)
            this.daqObject.outputSingleScan(enabled);
        end
    end
    
end