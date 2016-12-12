classdef MainView < handle
    properties
        gui
        model
        controller
    end
    
    methods
        function this = MainView(controller)
            this.controller = controller;
            this.model = controller.model;
            this.gui = mainGUI('controller',this.controller);
            
            addlistener(this.model,'test','PostSet', ...
                @(src,evnt)MainView.handlePropEvents(this,src,evnt));
        end
    end
    
    methods (Static)
        function handlePropEvents(this,src,evnt)
            evntobj = evnt.AffectedObject;
            handles = guidata(this.gui);
            switch src.Name
                case 'test'
                    handles.test = evntobj.test;
                    set(handles.text_test, 'String', evntobj.test);
                    % Not sure if resetting gui data is the most efficient
                    % way to make push the changes but it seems to be
                    % required
                    guidata(gcbo,handles) 
            end
        end
    end
end

