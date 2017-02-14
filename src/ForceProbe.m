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
        noLoadVoltage = 2.145;
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
            activeDaqs = daqfind();
            for storedDaq = activeDaqs
                vendor = storedDaq.Vendor;
                if (strcmp(vendor.ID, 'ni'))
                    release(storedDaq)
                    delete(storedDaq)
                end
            end
            this.daqObject = daq.createSession('ni');
            this.daqObject.addAnalogInputChannel('Dev5', 'ai1', 'Voltage');
            %Sample at 1000 Hz
            this.setSampleCount(100);
            this.setSampleDuration(.1)                 
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
                delete(this.daqObject);
            end
        end
        
        function meanForce = getMeanForce(this)
            meanForce = (mean(this.dataSample(:,1)) - this.noLoadVoltage) * this.forceGain;
        end
    end
    
end