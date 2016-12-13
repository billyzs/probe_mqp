classdef (Abstract) MotorDriver < Equipment
    properties (Access=protected, Abstract)
        defaultVelocity;
        defaultAcceleration;
        maxDisplacement;
        maxVelocity;
        maxAcceleration;
        displacement;
        moves; % moves is a n*3 Array (Stack) containing the past moves
    end
    
    properties (Access=protected)
        % sequence of moves
    end
    
    methods (Access=public, Abstract)
        % Constructors and destructors should be defined in subclasses
        
        % Specify the displacement, velocity, acceleration of a move
        success = doMove(this, displacement, velocity, acceleration)   
        enable(this)
        disable(this)
        
    end
    
    methods (Access=public)
        
        function valid = isMoveValid(this, displacement, velocity, acceleration)
            valid = 0;
            if (this.displacement + displacement < this.maxDisplacement ...
                    && velocity < this.maxVelocity... 
                    && acceleration < this.maxAcceleration)
                % do something
                valid = 1;
            else
                errMsg = this.name + '::isMoveValid::';
                if (this.displacement + displacement > this.maxDisplacement)
                    errMsg = errMsg + 'displacement exceeds maxDisplacement: would be ' ...
                        + num2str(this.displacement + displacement) + ';'; 
                end
                if (velocity < this.maxVelocity)
                     errMsg = errMsg + 'vel exceeds maxVelocity: ' + ...
                         num2str(velocity) + ' vs ' + num2str(this.maxVelocity) + ';';
                end
                if (acceleration > this.maxAcceleration)
                     errMsg = errMsg + 'acc exceeds maxAcceleration: ' + ...
                         num2str(acceleration) + ' vs ' + num2str(this.maxAcceleration) + ';';
                end
                error(errMsg);
            end
        end
        
        function success = move(this, displacement, velocity, acceleration)
            success = 0;
            try
                if(true == isMoveValid(this, displacement, velocity, acceleration))
                    success = doMove(this, displacement, velocity, acceleration);
                    if success
                        this.moves = [displacement, velocity, acceleration; this.moves]; %LIFO
                        this.displacement = this.displacement + displacement;
                    end
                    return
                end
            catch exception
                rethrow(exception);
            end
        end
        function success = defaultMove(this, displacement)
            success = move(this, displacement, this.defaultVelocity, this.defaultAcceleration);
        end
        
        function success = undoLastMove(this)
            success = doMove(-this.moves(1,1), -this.moves(1,2), -this.moves(1,3));
            this.moves = this.moves(2,:, :); % pops the lase move
        end
        function success = undoAll(this)
            newMoves = zeros(size(this.moves,1), 3);
            success = 1;
            for n = 1:size(this.moves,1)
                success = success && doMove(this, -this.moves(n,1), -this.moves(n,2), -this.moves(n,3));
                newMoves(size(this.moves,1)-n+1, :) = [-this.moves(n,1), -this.moves(n,2), -this.moves(n,3)];
            end
        end
    end
    
    methods (Access=public) % getters & setters
             
        function v = getDefaultVelocity(this)
            v = this.defaultVelocity;
        end
        
        function a = getDefaultAcceleration(this)
            a = this.defaultAcceleration;
        end
               
        function md = getMaxMaxDisplacement(this)
            md = this.maxDisplacement;
        end
        
        function mv = getMaxVelocity(this)
            mv = this.maxVelocity;
        end
        
        function ma = getMaxAcceleration(this)
            ma = this.maxAcceleration;
        end
        
        function d = getDisplacement(this)
            d = this.displacement;
        end
        
        %===========
        
        function setDefaultVelocity(this, v)
            this.defaultVelocity = v;
        end
        
        function setDefaultAcceleration(this, a)
            this.defaultAcceleration = a;
        end
               
        function setMaxMaxDisplacement(this, md)
            this.maxDisplacement = md;
        end
        
        function setMaxVelocity(this, mv)
            this.maxVelocity = mv;
        end
        
        function setMaxAcceleration(this, ma)
            this.maxAcceleration = ma;
        end
    end
end