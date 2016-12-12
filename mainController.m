classdef mainController < handle
    %mainController - The main controller for the GUI
    %   Detailed explanation goes here
    
    properties
        model
        view
    end
    
    methods
        
        function this = mainController(model)
            this.model = model;
            this.view = mainView(this);
        end
        
        function flipTest(this)
            this.model.flipTest();
        end
    end
    
end

