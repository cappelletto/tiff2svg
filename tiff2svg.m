%% Pipeline structure
function [retval] = tiff2svg(filename, cmap)

% Input argumets:
% geoTIFF filename [required]
% Canvas size [optional, auto mode]
% Number of histogram bins [optional]
% Colourmap [optional]

% Assign default value to input argument cmap (colourmap)
if ~exist('cmap', 'var')
    cmap = jet(256);
end

%% Read geoTIFF -> update Canvas size
% Extract range/stats/colourmap (if available)
[A,R] = geotiffread(filename);

close all
%% Compute statistics
img_stdev = std(A,0, 'all'); % compute non-biased stdev estimation
img_min = min(A,[],'all');
img_max = max(A,[],'all');
img_avg = mean(A,'all','omitnan');
img_med = median(A,'all','omitnan');
img_kur = kurtosis(A,0,'all');
img_skw = skewness(A,0,'all');

figure
imshow(A,[]); % plot auto-stretch mode
colormap(cmap) % use here choropleth/user defined colormap for better viz

B = uint8(255*mat2gray(A)); % remap input range to [0,1] and then to [0,255]
C = ind2rgb(B, cmap);

figure 
imshow(C);

i = [0:1/255:1];
img_cmap = flip([i;i;i]');
figure
imshow(img_cmap)
colormap(cmap)

retval = A;
return


% mapshow(A + min(A),R);


canvas_size = size(A);

% Replace invalid data entries (NoData field -> NaN)
% compute canvas size (2*_range(1) so we have the same padding L and R)
canvas_width  = canvas_size(1);
canvas_height = canvas_size(2);

%% Generate background image
image = A;

% scale to canvas size
background = imresize(image, [canvas_height, canvas_width]);

%% Show image (for validation purposes)

%% Save image to PNG

%% Create SVG-writer object
% construct object and set parameters
writer = SVGWriter([canvas_width, canvas_height]);
writer.resolution = 1/50;

writer.add_comment('Canvas');
writer.add_rectangle([1, writer.canvas_size(1)-1], [1, writer.canvas_size(2)-1], 'FillColor', 'none', 'StrokeColor', 'blue', 'StrokeWidth', 2);
% sadly, some browsers might not show this. Inkscape does show the rectangle, though.

writer.add_comment('Background');
writer.add_image(background, [0, 0]);

% Apply colourmap, convert 1ch to RGB. CHeck if user-defined CM was
% supplied

%% Insert PNG ref into SVG structure
% bkg_filename = "image.png";
% writer.add_comment('Background-link');
% writer.add_imagefile(bkg_filename, [0, 0]);

%% Generate colourmap rect

%% Show colourmap for validation

%% Insert ColourMap rect into SVG

%% Compute geoTIFF histogram

%% Generate rect/Histogram group

%% Insert histogram into SVG

%% Export SVG
writer.write('example.svg');

res = A;
