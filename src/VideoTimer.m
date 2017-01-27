classdef VideoTimer < handle
    
    properties
        timer
        cameraDriver
        jFrame
    end
    
    methods
        function this = VideoTimer(camDriver, jFrame)
            this.cameraDriver = camDriver;
            this.jFrame = jFrame;
            this.timer = timer('Name', 'videoTimer', 'Period', .03, 'TasksToExecute', Inf, ...
            'ExecutionMode', 'fixedRate', 'TimerFcn', {@this.frameCallback, this});
            start(this.cameraDriver);
            start(this.timer);
        end
        function frameCallback(args, evt, this)
            im = step(this.cameraDriver);
            RGB = im2double(im);
            imJava = im2java(RGB);
            this.jFrame.setVideoImage(imJava);
        end
        function stopVideo(this)
            %stop(this.timer);
            stop(this.cameraDriver);
        end
    end
    
end

