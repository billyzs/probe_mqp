path = 'C:\Users\holo\Desktop\ApproachPics_1_20\NoFringesGoodNeedle\';

files = dir([path '*.bmp']);
fileCount = size(files);
data = zeros(fileCount(1), 2);
index = 1;
for file = files'
    im = imread([path file.name]);
    im = im(400:975, 455:630);
    var = VarianceOfLaplacian(im);
    data(index, :) = [var str2num(file.name(1:end-4))]; 
    index = index + 1;
end
figure;
scatter(data(:,2), data(:,1));