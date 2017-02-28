

path = 'C:\Users\holo\Desktop\ApproachPics_1_20\2_10_17\';

files = dir([path '*.bmp']);
fileCount = size(files);
data = zeros(fileCount(1), 2);
index = 1;
for file = files'
    im = imread([path file.name]);
    im = im(520:995, 480:790);
    imshow(im)
    var = VarianceOfLaplacian(im);
    data(index, :) = [var str2num(file.name(1:end-4))]; 
    index = index + 1;
end
figure;
scatter(data(:,2), data(:,1));