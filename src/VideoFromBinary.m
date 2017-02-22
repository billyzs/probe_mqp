function VideoFromBinary(path, frameRate, dimensions)
    f = fopen(path, 'r');
    if (f==-1)
        return;
    end
    vw = VideoWriter(strcat(path, '.avi'), 'Uncompressed AVI');
    vw.FrameRate = frameRate;
    open(vw)
    try
        im = uint8(fread(f, dimensions, 'uint8'));
        while(~isempty(im))
            writeVideo(vw, im);
            im = uint8(fread(f, dimensions, 'uint8'));
        end
    catch
        close(vw);
        fclose(f);
    end
    close(vw);
    fclose(f);
    delete(path);
end

