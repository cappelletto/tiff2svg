%% Pipeline structure
function [retval] = tiff2svg(filename, cmap, colorbar_width, val_range, num_bins)

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
if ~exist('num_bins', 'var')
    num_bins = 5;
end

% Assign default value to input argument cmap (colourmap)
if ~exist('val_range', 'var')
    val_range = [-1, 1];
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

B = uint8(255*mat2gray(geoImage, val_range));  % remap input range to [0,1] and then to [0,255]
colorImage = ind2rgb(B, cmap);      % apply colormap to indexed grayscale

% figure 
% imshow(colorImage);

% col_idx = [0:1/255:1];
w = abs(diff(val_range))/255;               % colorbar delta for a minimum of 256 entries
col_idx = [val_range(1):w:val_range(2)];    % the colormap index must cover the value range
colorBar = flip([col_idx]');                % 1px width x 256 colorbar
B = uint8(255*mat2gray(colorBar, val_range));  % remap input range to [0,1] and then to [0,255]
colorBar = ind2rgb(B, cmap);

% figure
% imshow(colorBar)

%% Calculate dimensions/positions for each canvas element
% (left-to-rigt)  gap + colorbar + gap + image + gap + histogram + gap
% (top-to-bottom) gap + image + gap. 
% colorbar & histogram height = image height

gap_x = 10;         % These parameters can be user-defined as arguments
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

%% Create SVG-writer object
% construct object and set parameters
writer = SVGWriter([canvas_width, canvas_height]);
writer.resolution = 1/50;

%% Create filter definition, so it can be used in the Histogram layer
% TODO: BUG when using feBlend filter, mode screen. Filter not applied
% correctly to the layer

filter_screen = sprintf ('%s\n',...
'<defs id="defs61">',...
        '<filter',...
            'inkscape:collect="always"',...
            'style="color-interpolation-filters:sRGB"',...
            'id="filter_screen">',...
            '<feBlend inkscape:collect="always" mode="screen" in2="BackgroundImage" id="feBlend872" />',...
        '</filter>',...
        '</defs>');
writer.add_filter(filter_screen);

%% Create bounding rectangles for canvas and each object and fill with content
writer.add_comment('Canvas');
% writer.add_rectangle([1, writer.canvas_size(1)-1], [1, writer.canvas_size(2)-1], 'FillColor', 'none', 'StrokeColor', 'blue', 'StrokeWidth', 0.5);
% sadly, some browsers might not show this. Inkscape does show the rectangle, though.

%% Object: colorBar
% Outline for colorbar
writer.open_group('groupColorbar');
writer.add_comment('rectColorbar');
writer.add_rectangle2([colorbar_pos(1), colorbar_size(2)], [colorbar_pos(2), colorbar_size(1)], 'FillColor', 'none', 'StrokeColor', 'black', 'StrokeWidth', 1);
writer.add_comment('imageColormap');
writer.add_image(colorBar, colorbar_pos);
writer.close_group();

%% Object: mainImage
% Outline for image
writer.open_group('groupImage');
writer.add_comment('rectImage');
writer.add_rectangle2([image_pos(1), image_size(2)], [image_pos(2), image_size(1)], 'FillColor', 'none', 'StrokeColor', 'black', 'StrokeWidth', 1);
writer.add_comment('imageMain');
writer.add_image(colorImage, image_pos);
writer.close_group();

%% Object: Histogram
% Outline for image
writer.open_group('groupHistogramImage');
writer.add_comment('rectHistogram');
writer.add_rectangle2([hist_pos(1), hist_size(2)], [hist_pos(2), hist_size(1)], 'FillColor', 'none', 'StrokeColor', 'black', 'StrokeWidth', 1);
colorHist = imresize(colorBar, [hist_size(1), hist_size(2)]);   % this image acts as background for historam bars
writer.add_comment('imageHist');
writer.add_image(colorHist, hist_pos);
writer.close_group();

%% Populate Histogram group with hbars (rectangles)
r = abs(diff(val_range));
bin_edges = [val_range(1) : (r/(num_bins)) : val_range(2)];
[N] = histcounts (geoImage, bin_edges);
N = N/max(N);   % normalize histogram
%k=length(N)
%bar (E(1:k),N/s);
width = hist_size(1)/(num_bins);  % nominal width(max) of each bar 

%% Use different layer for histogram bins
writer.open_layer('layer1', 'layerHistogram', 'filter_screen');   % screen mode
writer.add_rectangle2([hist_pos(1), hist_size(2)], [hist_pos(2), hist_size(1)], 'FillColor', 'white', 'FillAlpha', 1.0, 'StrokeColor', 'none'); %pass-none in screen mode

writer.open_group('groupBarsHistogram');
for i=1:num_bins
    rect_pos  = [hist_pos(1)+0.5        (hist_pos(2) + (i-1)*width +0.5)];
    rect_size = [N(i)*hist_size(2)-1  (width -1)];
    % Outline for each histogram bin
%     writer.add_comment('rectHistogram');
    writer.add_rectangle2([rect_pos(1), rect_size(1)], [rect_pos(2), rect_size(2)], 'FillColor', 'black', 'FillAlpha', 1.0);
%     writer.add_rectangle2([rect_pos(1), rect_size(1)], [rect_pos(2), rect_size(2)], 'FillColor', 'black', 'FillAlpha', 0.8, StrokeColor', 'blue', 'StrokeWidth', 0.5, 'StrokeOpacity', 1);
end
writer.close_group()
writer.close_layer();


%% Insert captions, legend and lines
writer.open_layer('layer2', 'layerCaption');
%% Group for colorbar caption
writer.open_group('gCaptionColorbar');
   % add vertical tics
   l = 4;
   y = colorbar_pos(2);
   x = colorbar_pos(1)-l;

   writer.add_line([x x+l],[y y], 'StrokeColor', 'gray', 'StrokeWidth', 1.0);   % upper tic
   y = colorbar_pos(2) + colorbar_size(1)/2;
   writer.add_line([x x+l],[y y], 'StrokeColor', 'gray', 'StrokeWidth', 1.0);   % middle tic
   y = colorbar_pos(2) + colorbar_size(1);
   writer.add_line([x x+l],[y y], 'StrokeColor', 'gray', 'StrokeWidth', 1.0);   % lower tic

writer.close_group();

%% Group for image caption
writer.open_group('gCaptionImage');
writer.close_group();

%% Group for histogram caption
writer.open_group('gCaptionHistogram');
   % add vertical tics
   l = hist_size(1)-2;
   y = hist_pos(2) + hist_size(1);  % I know, this is a mess (row/col-wise indexing)
   x = hist_pos(1);

   writer.add_line([x x],[y-l y], 'StrokeColor', 'gray', 'StrokeWidth', 1.0, 'StrokeOpacity', 0.8, 'StrokeDashArray', [2 3]);   % upper tic
   x = hist_pos(1) + hist_size(2)/2;
   writer.add_line([x x],[y-l y], 'StrokeColor', 'gray', 'StrokeWidth', 1.0, 'StrokeOpacity', 0.8, 'StrokeDashArray', [2 3]);   % upper tic
   x = hist_pos(1) + hist_size(2);
   writer.add_line([x x],[y-l y], 'StrokeColor', 'gray', 'StrokeWidth', 1.0, 'StrokeOpacity', 0.8, 'StrokeDashArray', [2 3]);   % upper tic
writer.close_group();

writer.close_layer();


%% Export SVG
writer.write('example.svg');

retval = geoImage;
return

