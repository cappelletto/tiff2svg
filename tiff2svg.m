%% Pipeline structure
function [retval] = tiff2svg(filename, cmap, colorbar_width)

% Input argumets:
% geoTIFF filename [required]
% Canvas size [optional, auto mode]
% Number of histogram bins [optional]
% Colourmap [optional]

% Assign default value to input argument cmap (colourmap)
if ~exist('cmap', 'var')
    cmap = jet(256);
end

% Assign default value to input argument cmap (colourmap)
if ~exist('colorbar_width', 'var')
    colorbar_width = 10; % 10px width
end

%% Read geoTIFF -> update Canvas size
% Extract range/stats/colourmap (if available)
[geoImage,geoRef] = geotiffread(filename);

close all
%% Compute statistics
img_std = std (geoImage,0, 'all'); % compute non-biased stdev estimation
img_min = min (geoImage,[],'all');
img_max = max (geoImage,[],'all');
img_avg = mean(geoImage,'all','omitnan');
img_med = median  (geoImage,'all','omitnan');
img_kur = kurtosis(geoImage,0,'all');
img_skw = skewness(geoImage,0,'all');

% figure
% imshow(A,[]); % plot auto-stretch mode
% colormap(cmap) % use here choropleth/user defined colormap for better viz

%% Create images for input data and corresponding colormap (non-scaled)

B = uint8(255*mat2gray(geoImage));  % remap input range to [0,1] and then to [0,255]
colorImage = ind2rgb(B, cmap);      % apply colormap to indexed grayscale

% figure 
% imshow(colorImage);

i = [0:1/255:1];
colorBar = flip([i;i;i]');          % 3 px width x 255 colorbar
B = uint8(255*mat2gray(colorBar, [-1 1]));  % remap input range to [0,1] and then to [0,255]
colorBar = ind2rgb(B, cmap);

% figure
% imshow(colorBar)

%% Calculate dimensions/positions for each canvas element
% (left-to-rigt)  gap + colorbar + gap + image + gap + histogram + gap
% (top-to-bottom) gap + image + gap. 
% colorbar & histogram height = image height

gap_x = 20;         % These parameters can be user-defined as arguments
gap_y = 10;
hist_width = 100;

image_size    = size(colorImage);
colorbar_size = [image_size(1), colorbar_width];
hist_size     = [image_size(1), hist_width];

canvas_width  = gap_x + colorbar_size(2) + gap_x + image_size(2) + gap_x + hist_size(2) + gap_x;
canvas_height = gap_y + image_size(1) + gap_y;

colorbar_pos  = [gap_x, gap_y];    % top-left corner of colorbar
image_pos     = colorbar_pos + [colorbar_size(2) + gap_x, 0];    % top-left corner of image
hist_pos      = image_pos    + [image_size(2)    + gap_x, 0];    % top-left corner of histogram

% Replace invalid data entries (NoData field -> NaN)
% resize the colorbar to fit image heigth and target colorbar width
colorBar = imresize(colorBar, [colorbar_size(1), colorbar_size(2)]);


%% Show image (for validation purposes)

%% Create SVG-writer object
% construct object and set parameters
writer = SVGWriter([canvas_width, canvas_height]);
writer.resolution = 1/50;

%% Create bounding rectangles for canvas and each object
writer.add_comment('Canvas');
writer.add_rectangle([1, writer.canvas_size(1)-1], [1, writer.canvas_size(2)-1], 'FillColor', 'none', 'StrokeColor', 'blue', 'StrokeWidth', 1);
% sadly, some browsers might not show this. Inkscape does show the rectangle, though.

% Outline for colorbar
writer.add_comment('rectColorbar');
writer.add_rectangle2([colorbar_pos(1), colorbar_size(2)], [colorbar_pos(2), colorbar_size(1)], 'FillColor', 'none', 'StrokeColor', 'black', 'StrokeWidth', 1);

% Outline for image
writer.add_comment('rectImage');
writer.add_rectangle2([image_pos(1), image_size(2)], [image_pos(2), image_size(1)], 'FillColor', 'none', 'StrokeColor', 'black', 'StrokeWidth', 1);

% Outline for image
writer.add_comment('rectHistogram');
writer.add_rectangle2([hist_pos(1), hist_size(2)], [hist_pos(2), hist_size(1)], 'FillColor', 'none', 'StrokeColor', 'black', 'StrokeWidth', 1);

%% Insert images fro each object
writer.add_comment('imageColormap');
writer.add_image(colorBar, colorbar_pos);

writer.add_comment('imageMain');
writer.add_image(colorImage, image_pos);

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

retval = geoImage;
return

