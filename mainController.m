
classdef MainController < handle
    %mainController - The main controller for the GUI
    %   Detailed explanation goes here
    
    properties
        model
        view
    end
    
    methods
        
        function this = MainController(model)
            
            this.model = model;
            this.view = MainView(this);
        end
        
        function flipTest(this)
            this.model.flipTest();
        end
    end
    
end

