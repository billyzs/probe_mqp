classdef (Abstract) CameraDriver < Equipment
       
    properties (Access = protected, Abstract)
        magnification; 
        pixelSize; % micrometer per pixel
    end
    properties (Access = protected)
        videoObj;
    end
    % CameraDriver should have all the properties of VideoInput
    methods (Access = public)
        % driverName is the adapter name given by >> imaqhwinfo, 
        % usually 'gentl'. Sequence is usually 1
        function obj = CameraDriver(driverName, sequence, format)
            if nargin > 2
                obj.videoObj = videoinput(driverName, sequence, format);
            else
                obj.videoObj = videoinput(driverName, sequence);
            end
        end
        
        % Destructor; call imaqreset to be extra safe
        function delete(this)
            delete(this.videoObj);
            imaqreset; %
        end
        
        function setMagnification(obj, m)
            obj.magnification = m;
        end
        
        function setPixelSize(obj, pd)
            obj.pixelSize = pd;
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
        
        function videoInput = getVideoInput(obj)
            videoInput = obj.videoObj;
        end
        
        function m = getMagnification(obj)
            m = obj.magnification;
        end
        
        function pd = getPixelSize(obj)
            pd = obj.pixelSize;
        end
    end
end