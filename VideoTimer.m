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
            this.timer = timer('Period', .03, 'TasksToExecute', Inf, ...
            'ExecutionMode', 'fixedRate', 'TimerFcn', @this.frameCallback);
            start(this.timer);
        end
        function frameCallback(this,src,evt)
            im = step(this.cameraDriver);
            RGB = im2double(im);
            imJava = im2java(RGB);
            this.jFrame.setVideoImage(imJava);
        end
        function stopVideo(this)
            stop(this.timer);
        end
    end
    
end

