classdef CameraWebcam < CameraDriver
    
    properties (Access=protected)
        name = 'Webcam';
    end
    properties (Access = protected)
        magnification = 1; 
        pixelSize = 0; % micrometer per pixel
    end
    methods (Access = public)
        function obj = CameraWebcam(seq, format)
            if nargin ==  0
                seq = 1;
            end
            obj@CameraDriver('winvideo', seq);
        end      
    end
end