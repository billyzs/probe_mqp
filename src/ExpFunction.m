classdef ExpFunction < handle
    %EXPFUNCTION A class representing a first order exponential function
    %   y = Ae^(Bx) + y_0
    
    properties
        a = 0;
        b = 0;
        y_0 = 0;
    end
    
    methods
        %Constructor
        function this = ExpFunction(a, b, y_0)
            this.a = a;
            this.b = b;
            this.y_0 = y_0;
        end
        
        function y = getY(this, x)
            y = this.a*exp(this.b*x) + this.y_0;
        end
         
        function x = getX(this, y)
            % x = log(y-y_0 / a) / b
            x = log((y - this.y_0) / this.a) / this.b;
        end
        
        function [ A, B, y_0] = estimateExp(this, y, x, y_0, updateSelf)
            if nargin < 5
                updateSelf = false;
            end
            %assume y = A*exp(Bx) + y_0, estimate A, B

            y_hat = log(y - y_0*0.999);

            % y_hat = log(A) +  B * x
            p = polyfit(x, y_hat, 1);

            B = p(1);
            A = exp(p(2));
            if updateSelf
                this.a = A;
                this.b = B;
                this.y_0 = y_0;
            end

        end
    end
    
end

