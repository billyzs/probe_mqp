classdef ForceProbe < Equipment
    %FORCEPROBE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access=protected)
        name
    end
    
    properties(Access=private)
        daqObject
        dataSample;% = zeros(1,500);
        forceGain = 500.3; %uN/V
        noLoadVoltage = 2.16;
        connected = false;
        dataIndex = 1;
        graphFigure;
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
            ch = this.daqObject.addAnalogInputChannel('Dev5', 'ai1', 'Voltage');
            ch.Range = [-2.5,2.5];
            %Sample at 1000 Hz
            this.setSampleCount(1000);
            this.setSampleDuration(.1);
            this.connected = true;
        end
        
        function runContinuous(this, rate, notificationCount)
            this.daqObject.addlistener('DataAvailable', @(src,event) plot(event.TimeStamps, event.Data))
            this.setSampleCount(rate);
            this.graphFigure = figure;
            figure(this.graphFigure);
            xlabel('time (seconds)');
            ylabel('Voltage (V)');
            title('Voltage from a FS-1000 LAT Probe')
            this.daqObject.NotifyWhenDataAvailableExceeds = notificationCount;
            this.daqObject.IsContinuous = true;
            this.daqObject.startBackground;
        end
        
        function handleData(this, src, event)
            figure(this.graphFigure);
%             this.dataSample(dataIndex) = sum(event.Data) / this.daqObject.NotifyWhenDataAvailableExceeds;
            plot(event.TimeStamps, event.Data);
%             dataIndex = dataIndex + 1;
%             dataSize = size(this.dataSample);
%             if (dataIndex == dataSize(2))
%                 %write to disk
%                 %flush array
%                 dataIndex = 0;
%             end
        end 
        
        function stopContinuous(this)
            stop(this.daqObject);
            this.daqObject.IsContinuous = false;
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
           % pause(0.3);
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