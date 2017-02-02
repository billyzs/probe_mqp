classdef Shape
    %SHAPE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        type;
        dimensions
        lineWidth
        color
        opacity
    end
    
    methods
         % Constructor
        function this = Shape(type, dim, lineWidth, color, opacity)
            this.type = type;
            this.dimensions = dim;
            this.lineWidth = lineWidth;
            this.color = color;
            this.opacity = opacity;
        end
    end
    
end

