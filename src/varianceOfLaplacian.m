function [ variance ] = varianceOfLaplacian( image , H)
% computes the variance of Laplacian on a given image
%   input: image and Laplacian kernel
%   return: double

if nargin == 1
    H = fspecial('laplacian'); % use default Laplacian kernel 
end
variance = var(reshape(imfilter(double(image), H), [], 1));
end

