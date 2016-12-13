classdef (Abstract) CameraDriver < imaq.VideoDevice & Equipment
       
    properties (Access = protected, Abstract)
        magnification; 
        pixelDensity; % micrometer per pixel
    end
    % CameraDriver should have all the properties of VideoInput
    methods (Access = public)
        % driverName is the adapter name given by >> imaqhwinfo, 
        % usually 'gentl'. Sequence is usually 1
        function obj = CameraDriver(driverName, sequence, format)
            obj@imaq.VideoDevice(driverName, sequence, format);
        end
        
        % Destructor; call imaqreset to be extra safe
        function delete(obj)
            delete@imaq.VideoDevice(obj); % call super class destructor
            imaqreset; %
        end
        
        function setMagnification(obj, m)
            obj.magnification = m;
        end
        
        function setPixelDensity(obj, pd)
            obj.pixelDensity = pd;
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