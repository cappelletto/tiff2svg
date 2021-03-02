%% Pipeline structure

% Read geoTIFF

% Extract range/stats/colourmap

% Replace invalida data entries

% Apply colourmap, convert 1ch to RGB

% Generate img

% Show image (for validation purposes)

% Save image to PNG

% Create SVG

% Insert PNG ref into SVG structure

% Generate colourmap rect

% Show colourmap for validation

% Insert ColourMap rect into SVG

% Compute geoTIFF histogram

% Generate rect/Histogram group

% Insert histogram into SVG

% Export SVG




% Example SVG file

%% construct two sample polygons

% xy pairs
poly1 = [[350, 75];
         [379,161];
         [469,161];
         [397,215];
         [423,301];
         [350,250];
         [277,301];
         [303,215];
         [231,161];
         [321,161]];
poly2 = [[850, 75.0];
         [958,137.5];
         [958,262.5];
         [850,325.0];
         [742,262.6];
         [742,137.5]];
polygons = [polyshape(poly1), polyshape(poly2)];
[polygons_xrange, polygons_yrange] = polygons.boundingbox;

% compute canvas size (2*_range(1) so we have the same padding L and R)
canvas_width  = diff(polygons_xrange) + 2*polygons_xrange(1);
canvas_height = diff(polygons_yrange) + 2*polygons_yrange(1);

%% create a background image

im = zeros([3, 3, 3], 'uint8');
im(:, :, 1) = [127, 127, 127;   0,   0,   0; 255, 255, 255]; % red
im(:, :, 2) = [  0, 127, 255;   0, 127, 255;   0, 127, 255]; % green
im(:, :, 3) = [  0, 127, 255; 127,   0, 127; 255, 127,   0]; % blue

% scale to canvas size
background = imresize(im, [canvas_height, canvas_width]);

%% use SVGWriter

% construct object and set parameters
writer = SVGWriter([canvas_width, canvas_height]);
writer.resolution = 1/50;

writer.add_comment('Description');
writer.add_description('2polygons');

writer.add_comment('Canvas');
writer.add_rectangle([1, writer.canvas_size(1)-1], [1, writer.canvas_size(2)-1], 'FillColor', 'none', 'StrokeColor', 'blue', 'StrokeWidth', 2);
% sadly, some browsers might not show this. Inkscape does show the rectangle, though.

% writer.add_comment('Background');
% writer.add_image(background, [0, 0]);

bkg_filename = "image.png";
writer.add_comment('Background-link');
writer.add_imagefile(bkg_filename, [0, 0]);

writer.add_comment('Outline');
writer.add_rectangle(polygons_xrange, polygons_yrange, 'FillColor', 'none', 'StrokeColor', 'red', 'StrokeWidth', 1);

writer.add_comment('Line');
writer.add_line(polygons_xrange, polygons_yrange, 'FillColor', 'none', 'StrokeColor', 'yellow', 'StrokeWidth', 3);

writer.add_comment('Polygons');
for poly = transpose(polygons(:))
    writer.add_polygon(poly, 'FillColor', 'lime', 'StrokeColor', 'blue', 'StrokeWidth', 1);
end

writer.write('example.svg');
