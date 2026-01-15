function [edges, magnitude, direction] = edge_detector(image, options)
%EDGE_DETECTOR Canny edge detection for satellite images
%
%   edges = edge_detector(image) detects edges using Canny algorithm.
%
%   [edges, magnitude, direction] = edge_detector(image, options) also
%   returns gradient magnitude and direction.
%
%   Based on EBWT-SR paper for satellite image super-resolution.
%
%   Inputs:
%       image   - Grayscale or RGB image
%       options - Optional struct with fields:
%           .threshold  - Edge threshold [low, high] (default: auto)
%           .sigma      - Gaussian smoothing sigma (default: 1)
%           .method     - 'canny', 'sobel', 'prewitt' (default: 'canny')
%
%   Outputs:
%       edges     - Binary edge map
%       magnitude - Gradient magnitude
%       direction - Gradient direction [rad]
%
%   See also: wavelet_transform, super_resolution

if nargin < 2
    options = struct();
end

% Convert to grayscale if needed
if size(image, 3) == 3
    gray = rgb2gray(image);
else
    gray = image;
end

% Convert to double
gray = im2double(gray);

% Get options
sigma = get_option(options, 'sigma', 1);
method = get_option(options, 'method', 'canny');

% Gaussian smoothing
if sigma > 0
    h = fspecial('gaussian', ceil(6*sigma), sigma);
    smoothed = imfilter(gray, h, 'replicate');
else
    smoothed = gray;
end

% Compute gradients using Sobel operators
Gx = [-1 0 1; -2 0 2; -1 0 1];
Gy = [-1 -2 -1; 0 0 0; 1 2 1];

grad_x = imfilter(smoothed, Gx, 'replicate');
grad_y = imfilter(smoothed, Gy, 'replicate');

% Gradient magnitude and direction
magnitude = sqrt(grad_x.^2 + grad_y.^2);
direction = atan2(grad_y, grad_x);

% Edge detection
switch lower(method)
    case 'canny'
        if isfield(options, 'threshold')
            edges = edge(gray, 'canny', options.threshold, sigma);
        else
            edges = edge(gray, 'canny', [], sigma);
        end

    case 'sobel'
        if isfield(options, 'threshold')
            edges = edge(gray, 'sobel', options.threshold);
        else
            edges = edge(gray, 'sobel');
        end

    case 'prewitt'
        if isfield(options, 'threshold')
            edges = edge(gray, 'prewitt', options.threshold);
        else
            edges = edge(gray, 'prewitt');
        end

    otherwise
        edges = edge(gray, 'canny');
end

end

function val = get_option(options, field, default)
    if isfield(options, field)
        val = options.(field);
    else
        val = default;
    end
end
