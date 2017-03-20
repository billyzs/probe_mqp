classdef ForceProbe < Equipment
    %FORCEPROBE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access=protected)
        name
    end
    
    properties(Access=private)
        daqObject
        dataSample
        forceGain = 500; %uN/V
        noLoadVoltage = 2.16;
        connected = false;
    end
    
    methods
        % Constructor
        function this = ForceProbe()
            this.name = 'Probe';
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
            this.daqObject.addAnalogInputChannel('Dev5', 'ai1', 'Voltage');
            %Sample at 100 Hz
            this.setSampleCount(100);
            this.setSampleDuration(.1);
            this.connected = true;
        end
        
        function runContinuous(this, rate, notificationCount)
            this.daqObject.addlistener('DataAvailable', @(src,event) plot(event.TimeStamps, event.Data))
            this.setSampleCount(rate);
            this.daqObject.NotifyWhenDataAvailableExceeds = notificationCount;
            this.daqObject.IsContinuous = true;
            figure;
            xlabel('time (seconds)');
            ylabel('Voltage (V)');
            title('Voltage from a FS-1000 LAT Probe')
            this.daqObject.startBackground;
        end
        
        function stopContinuous(this)
            stop(this.daqObject);
        end
        
        function daqObject = getDAQObject(this)
            daqObject = this.daqObject;
        end
        
        function setSampleCount(this, count)
            this.daqObject.Rate = count;
        end
        
        function samples = getSampleCount(this)
            samples = this.daqObject.Rate;
        end
        
        function setSampleDuration(this, duration)
            this.daqObject.DurationInSeconds = duration;
        end
        
        function duration = getSampleDuration(this)
            duration = this.daqObject.DurationInSeconds;
        end
        
        function [data,time] = collectData(this)
            [data,time] = this.daqObject.startForeground;
            this.dataSample = [data,time];
        end
        
        function plotData(this, dataSample)
            if (nargin == 1)
                dataSample = this.dataSample;
            end
            figure;
            scatter(dataSample(:,2), dataSample(:,1), '.');
            xlabel('time (seconds)');
            ylabel('Voltage (V)');
            title('Free-load voltage collected from a FS-1000 LAT Probe')
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
        
        function meanForce = getMeanForce(this)
            meanForce = (mean(this.dataSample(:,1)) - this.noLoadVoltage) * this.forceGain;
        end
        
        function updateNoLoadVoltage(this)
            this.collectData();
            this.noLoadVoltage = mean(this.dataSample(:,1));
        end
        function v = getNoLoadVoltage(this)
            v = this.noLoadVoltage;
        end
    end
    
end