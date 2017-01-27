classdef (Abstract) MotorDriver < Equipment
   % MotorDriver An abstract class used to construct actuator classes
   % Extends Equipment
    properties (Access=protected, Abstract)
        % Num The maximum displacement allowed
        maxDisplacement;
        % Num The maximum velocity allowed
        maxVelocity;
        % Num The maximum acceleration allowed
        maxAcceleration;
        % Num The current displacement
        displacement;
        % Num The current velocity
        velocity;
        % Num The current acceleration
        acceleration;
        % The movement method that will be used on move commands 
        % Relative or Absolute
        moveMode;
    end
    
    methods (Access=public, Abstract)
        % Constructors and destructors should be defined in subclasses
        
        % Function to execute a move of the given displacement
        success = doMove(this, displacement)
        % Function to set the movement method that will be used
        setMoveMode(this, moveMode)
        % Function to set the velocity to use on doMove commands
        setVelocity(this, vel)
        % Function to set the acceleration to use on doMove commands
        setAcceleration(this, accel)
        % Function to retreve the hardware calculated displacement if
        % available. Optional displacement parameter can be used as seen
        % fit.
        updateDisplacement(this, displacement)
        % Function to enable the motor hardware
        enable(this)
        % Function to disable the motor hardware
        disable(this)
        
    end
    
    methods (Access=public)
        
        % Function evalutates the validity of a given position
        function valid = isPositionValid(this, position)
            valid = 1;
            if (abs(position) > this.maxDisplacement)
                errMsg = [this.name,  '::isPositionValid::'];
                errMsg = [errMsg  'target position exceeds maxDisplacement: would be ', ...
                    + num2str(position)] + ';';
                error(errMsg);
                valid = 0;
            end
        end
        
        % Function evaluates the validity of an attempted move command
        function valid = isMoveValid(this, displacement)
            %Check if the target is valid
            switch this.moveMode
                case 'Absolute'
                    valid = isPositionValid(this.displacement);
                case 'Relative'
                    valid = isPositionValid(this.displacement + displacement);
                otherwise
                    warning('Unexpected move mode requested')
                    valid = 0;
            end
            if (~isVelocityValid(this.velocity) || ~isAccelerationValid(this.acceleration))
                warning('Move requested without valid accerlation or velocity')
                valid = 0;
            end
        end
        
        % Function evaluates the validity of a given velocity
        function valid = isVelocityValid(this, velocity)
            valid = 1;
            if (velocity > this.maxVelocity || velocity <= 0)
                errMsg = [this.name,  '::isVelocityValid::'];
                errMsg = [errMsg, 'vel exceeds maxVelocity: ', ...
                    num2str(velocity), ' vs ',  num2str(this.maxVelocity)  ';'];
                error(errMsg);
                valid = 0;
            end
        end
        
        % Function evaluates the validity of a given acceleration
        function valid = isAccelerationValid(this, acceleration)
            valid = 1;
            if (acceleration > this.maxAcceleration || acceleration <= 0)
                errMsg = [this.name,  '::isVAccelerationValid::'];
                errMsg = [errMsg  'acc exceeds maxAcceleration: ' ...
                    num2str(acceleration) ' vs ' num2str(this.maxAcceleration) ';'];
                error(errMsg);
                valid = 0;
            end
        end
        
        % Function moves the motor the given displacement. Throws exception
        function success = move(this, displacement)
            success = 0;
            try
                if(true == isMoveValid(this, displacement))
                    success = doMove(this, displacement);
                    if success 
                        this.moves = [this.moveMode,... 
                                       displacement,... 
                                       this.velocity,... 
                                       this.acceleration; this.moves]; %LIFO
                        updateDisplacement(displacement);
                    end
                    return
                end
            catch exception
                rethrow(exception);
            end
        end
        
        % Function to undo the previous move command 
        function [success, undoneMove] = undoLastMove(this)
            if (~isempty(this.moves))
                undoneMove = this.moves(1,:);
                setMoveMode(undoneMove(1,1));
                setVelocity(undoneMove(1,3));
                setAcceleration(undoneMove(1,4));

                position = undoneMove(1,2);

                if (~strcmp(this.moveMode,'Absolute'))
                    position = -position;
                end
                undoneMove(1,2) = position;
                success = doMove(position);
                this.moves = this.moves(2,:, :); % pops the lase move
            else
                undoneMove = ['Relative',0,0,0];
                success = 0;
            end
        end
        
        % Function to undo all the past move commands 
        function success = undoAll(this)
            newMoves = [];
            success = 1;
            while(success == 1)
                [success, undoneMove] = undoLastMove();
                newMoves = [undoneMove; newMoves];
            end
            this.moves = newMoves;
        end
    end
    
    methods (Access=public) % Getters and Setters
               
        function md = getMaxDisplacement(this)
            md = this.maxDisplacement;
        end
        
        function mv = getMaxVelocity(this)
            mv = this.maxVelocity;
        end
        
        function ma = getMaxAcceleration(this)
            ma = this.maxAcceleration;
        end
        
        function displacement = getDisplacement(this)
            displacement = this.displacement;
        end
        
        function acceleration = getAcceleration(this)
            acceleration = this.acceleration;
        end
        
        function velocity = getVelocity(this)
            velocity = this.velocity;
        end
        
        %===========
               
        function setMaxDisplacement(this, md)
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