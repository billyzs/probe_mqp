classdef CameraPike < CameraDriver
    
    properties (Access=protected)
        name = 'AVT_Pike_F100B';
    end
    properties (Access = protected)
        magnification = 1; 
        pixelSize = 0; % micrometer per pixel
    end
    methods (Access = public)
        function obj = CameraPike(seq)
            if nargin ==  0
                seq = 1;
            end
            obj@CameraDriver('gentl', seq);
        end      
    end
end