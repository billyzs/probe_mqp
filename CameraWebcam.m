classdef CameraWebcam < CameraDriver
    
    properties (Constant, Access=protected)
        name = 'Webcam';
    end
    properties (Access = protected)
        magnification = 1; 
        pixelDensity = 0; % micrometer per pixel
    end
    methods (Access = public)
        function obj = CameraWebcam(seq, format)
            if nargin ==  0
                seq = 1;
            end
            obj@CameraDriver('winvideo', seq, format);
        end      
    end
end