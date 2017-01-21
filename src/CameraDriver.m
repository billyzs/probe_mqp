classdef (Abstract) CameraDriver < Equipment
       
    properties (Access = protected, Abstract)
        magnification; 
        pixelDensity; % micrometer per pixel
    end
    properties (Access = protected)
        videoObj;
    end
    % CameraDriver should have all the properties of VideoInput
    methods (Access = public)
        % driverName is the adapter name given by >> imaqhwinfo, 
        % usually 'gentl'. Sequence is usually 1
        function obj = CameraDriver(driverName, sequence, format)
            obj.videoObj = videoinput(driverName, sequence);
            if nargin > 2
                obj.set('VideoFormat', format);
            end
        end
        
        % Destructor; call imaqreset to be extra safe
        function delete(obj)
            delete@imaq.videoinput(obj); % call super class destructor
            imaqreset; %
        end
        
        function setMagnification(obj, m)
            obj.magnification = m;
        end
        
        function setPixelDensity(obj, pd)
            obj.pixelDensity = pd;
        end
        
        function start(obj)
            start(obj.videoObj);
        end
        
        function stop(obj)
            stop(obj.videoObj);
        end
        
        function data = getImageData(obj)
            data = getdata(obj.videoObj);
        end
        
        function setVideoParameter(obj, key, value)
            set(obj.videoObj, key, value);
        end
        
    end
    
    methods (Access=public, Static)
        function m = getMagnification(obj)
            m = obj.magnification;
        end
        
        function pd = getPixelDensity(obj)
            pd = obj.pixelDensity;
        end
    end
end