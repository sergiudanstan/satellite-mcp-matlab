function [features, info] = image_matcher(image, options)
%IMAGE_MATCHER Extract features from aerial/satellite images for matching
%
%   features = image_matcher(image) extracts features for location matching.
%
%   [features, info] = image_matcher(image, options) also returns info.
%
%   Based on the GNSS-denied UAV localization research paper.
%   Extracts features suitable for matching aerial UAV images with
%   satellite reference maps.
%
%   Inputs:
%       image   - Aerial or satellite image (path or matrix)
%       options - Optional struct with fields:
%           .method      - 'histogram', 'hog', 'edge', 'combined' (default: 'combined')
%           .resize      - Target size [height, width] (default: [224, 224])
%           .normalize   - Normalize features (default: true)
%
%   Outputs:
%       features - Feature vector (1xD)
%       info     - Struct with extraction info
%
%   See also: location_encoder, similarity_matrix, heading_estimator

if nargin < 2
    options = struct();
end

% Load image if path
if ischar(image)
    image = imread(image);
end
image = im2double(image);

% Get options
method = get_option(options, 'method', 'combined');
target_size = get_option(options, 'resize', [224, 224]);
do_normalize = get_option(options, 'normalize', true);

% Resize image
image = imresize(image, target_size);

% Convert to grayscale for feature extraction
if size(image, 3) == 3
    gray = rgb2gray(image);
else
    gray = image;
end

% Extract features based on method
switch lower(method)
    case 'histogram'
        features = extract_histogram_features(gray, image);

    case 'hog'
        features = extract_hog_features(gray);

    case 'edge'
        features = extract_edge_features(gray);

    case 'combined'
        % Combine multiple feature types
        f_hist = extract_histogram_features(gray, image);
        f_hog = extract_hog_features(gray);
        f_edge = extract_edge_features(gray);
        features = [f_hist, f_hog, f_edge];

    otherwise
        features = extract_histogram_features(gray, image);
end

% Normalize features
if do_normalize
    features = features / (norm(features) + eps);
end

% Info
info.method = method;
info.image_size = target_size;
info.feature_dim = length(features);
info.normalized = do_normalize;

end

function features = extract_histogram_features(gray, color_image)
%EXTRACT_HISTOGRAM_FEATURES Histogram-based features

    % Grayscale histogram
    num_bins = 32;
    hist_gray = histcounts(gray(:), num_bins, 'Normalization', 'probability');

    % Color histogram if available
    if size(color_image, 3) == 3
        hist_r = histcounts(color_image(:,:,1), num_bins, 'Normalization', 'probability');
        hist_g = histcounts(color_image(:,:,2), num_bins, 'Normalization', 'probability');
        hist_b = histcounts(color_image(:,:,3), num_bins, 'Normalization', 'probability');
        features = [hist_gray, hist_r, hist_g, hist_b];
    else
        features = hist_gray;
    end
end

function features = extract_hog_features(gray)
%EXTRACT_HOG_FEATURES Histogram of Oriented Gradients

    % Compute gradients
    [Gx, Gy] = imgradientxy(gray);
    magnitude = sqrt(Gx.^2 + Gy.^2);
    direction = atan2(Gy, Gx);

    % Quantize directions into bins
    num_bins = 9;
    bin_size = pi / num_bins;

    % Cell size for HOG
    cell_size = 16;
    [M, N] = size(gray);
    num_cells_y = floor(M / cell_size);
    num_cells_x = floor(N / cell_size);

    features = [];

    for cy = 1:num_cells_y
        for cx = 1:num_cells_x
            % Cell boundaries
            y1 = (cy-1) * cell_size + 1;
            y2 = cy * cell_size;
            x1 = (cx-1) * cell_size + 1;
            x2 = cx * cell_size;

            % Extract cell
            mag_cell = magnitude(y1:y2, x1:x2);
            dir_cell = direction(y1:y2, x1:x2);

            % Compute histogram
            hist_cell = zeros(1, num_bins);
            for b = 1:num_bins
                bin_low = -pi + (b-1) * bin_size;
                bin_high = bin_low + bin_size;
                mask = (dir_cell >= bin_low) & (dir_cell < bin_high);
                hist_cell(b) = sum(mag_cell(mask));
            end

            % Normalize cell histogram
            hist_cell = hist_cell / (sum(hist_cell) + eps);
            features = [features, hist_cell];
        end
    end
end

function features = extract_edge_features(gray)
%EXTRACT_EDGE_FEATURES Edge-based features

    % Detect edges
    edges = edge(gray, 'canny');

    % Edge density in grid cells
    cell_size = 32;
    [M, N] = size(gray);
    num_cells_y = floor(M / cell_size);
    num_cells_x = floor(N / cell_size);

    features = zeros(1, num_cells_y * num_cells_x);
    idx = 1;

    for cy = 1:num_cells_y
        for cx = 1:num_cells_x
            y1 = (cy-1) * cell_size + 1;
            y2 = cy * cell_size;
            x1 = (cx-1) * cell_size + 1;
            x2 = cx * cell_size;

            cell_edges = edges(y1:y2, x1:x2);
            features(idx) = mean(cell_edges(:));
            idx = idx + 1;
        end
    end

    % Edge direction histogram
    [~, ~, dir] = edge_detector(gray, struct('method', 'sobel'));
    dir_hist = histcounts(dir(edges), 8, 'Normalization', 'probability');
    features = [features, dir_hist];
end

function val = get_option(options, field, default)
    if isfield(options, field)
        val = options.(field);
    else
        val = default;
    end
end
