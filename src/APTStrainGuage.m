classdef APTStrainGuage < handle
    
    properties(Access = private)
        fig;
        hActiveX;
        serialNumber;
        mode;
    end
    
    properties(Access = private, Constant)
        CHAN1_ID = 0;
        DISPUNITS_POSITION = 1;
        DISPUNITS_VOLTAGE = 2;
        DISPUNITS_FORCE = 3;
    end
    
    methods(Access = public)
        function this = APTStrainGuage(serialNumber)
            this.fig = this.createFigure();
            this.setSerialNumber(serialNumber);
            this.resetControl();
        end
        
        function identify(this)
            this.hActiveX.Identify;
            pause(1);
            this.setMode('position');
        end
        
        function setSerialNumber(this, serialNumber)
            this.serialNumber = serialNumber;
        end
        
        function resetControl(this)
            this.hActiveX = actxcontrol('MGPIEZO.MGPiezoCtrl.1',...
                                        [20 20 600 400], this.fig);
            this.hActiveX.StartCtrl;
            set(this.hActiveX,'HWSerialNum', this.serialNumber);
        end
        
        function setMode(this, mode)
            switch mode
                case 'force'
                    this.hActiveX.SG_SetDispMode(this.CHAN1_ID, this.DISPUNITS_FORCE);
                    this.mode = this.DISPUNITS_FORCE;
                case 'voltage'
                    this.hActiveX.SG_SetDispMode(this.CHAN1_ID, this.DISPUNITS_VOLTAGE);
                    this.mode = this.DISPUNITS_VOLTAGE;
                case 'position'
                    this.hActiveX.SG_SetDispMode(this.CHAN1_ID, this.DISPUNITS_POSITION);
                    this.mode = this.DISPUNITS_POSITION;
            end
        end
        
        function pos = getPosition(this)
            if (this.mode ~= this.DISPUNITS_POSITION)
                this.setMode('position');
            end
            [channel, pos] = this.hActiveX.SG_GetReading(this.CHAN1_ID, 0);
        end
        function volt = getVoltage(this)
            if (this.mode ~= this.DISPUNITS_VOLTAGE)
                this.setMode('voltage');
            end
            [channel, volt] = this.hActiveX.SG_GetReading(this.CHAN1_ID, 0);
        end
        function force = getForce(this)
            if (this.mode ~= this.DISPUNITS_FORCE)
                this.setMode('force');
            end
            [channel, force] = this.hActiveX.SG_GetReading(this.CHAN1_ID, 0);
        end
    end
    
    methods(Access = private)
        function fig = createFigure(this)
            fpos    = get(0,'DefaultFigurePosition'); % figure default position
            fpos(3) = 640; % figure window size;Width
            fpos(4) = 480; % Height
            
            fig = figure('Position', fpos, 'Menu','None','Name','APT GUI', 'Visible','Off');
        end
    end
    
end
