 
classdef (Abstract) Equipment < handle
    %EQUIPMENT The canonical class for all actual lab equipments that 
    % would be used
    %   For example, Motor Drivers, Piezos, Interferometers, Cameras
    
    properties (Abstract, Access=protected) % I don't think the order of the modifiers matter
        name; % char array
    end
    
    methods (Access=public)
        % Equipment should have their own constructor and destructors.
        % Not specified here. 
            
        function myName = getName(this)
            % returns the name 
            myName = this.name;
        end
        
    end
    
end

