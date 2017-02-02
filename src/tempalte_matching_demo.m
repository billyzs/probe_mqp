img = imread('../messedUP.png');
img = rgb2gray(img);
[i_ssd, i_ncc] = template_matching(template, img);
[x, y] = find(i_ssd == max(i_ssd(:)));
