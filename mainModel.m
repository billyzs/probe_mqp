classdef MainModel < handle    
    properties (SetObservable)
        test
        cameraActive = false;
        Expirement
    end
        
    methods
        %Set of Testing methods for MVC design practice
        function this = MainModel()
            this.reset();
        end
                
        function reset(this)
            this.test = 0;
        end
        
        function flipTest(this)
            if(this.test == 0)
                this.test = 1;
            else
                this.test = 0;
            end
        end
        
        function test = getTest(this)
            test = this.test;
        end
    end
end