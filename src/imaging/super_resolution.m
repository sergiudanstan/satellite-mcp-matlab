function [enhanced, metrics] = super_resolution(image, options)
%SUPER_RESOLUTION Edge-Based Wavelet Transform Super-Resolution (EBWT-SR)
%
%   enhanced = super_resolution(image) enhances image resolution using
%   the EBWT-SR algorithm.
%
%   [enhanced, metrics] = super_resolution(image, options) also returns
%   quality metrics.
%
%   Based on the EBWT-SR research paper for satellite image super-resolution.
%   Combines edge detection with wavelet transform for improved detail.
%
%   Algorithm:
%       1. Detect edges using Canny detector
%       2. Decompose image using DWT (LL, LH, HL, HH)
%       3. Upscale approximation (LL) using bicubic interpolation
%       4. Enhance detail coefficients using edge information
%       5. Reconstruct high-resolution image
%
%   Inputs:
%       image   - Input low-resolution image
%       options - Optional struct with fields:
%           .scale      - Upscaling factor (default: 2)
%           .wavelet    - Wavelet type (default: 'haar')
%           .edge_sigma - Edge detection sigma (default: 1)
%           .edge_weight- Weight for edge enhancement (default: 0.5)
%           .method     - 'ebwt' or 'bicubic' (default: 'ebwt')
%
%   Outputs:
%       enhanced - Super-resolved image
%       metrics  - Struct with quality metrics (if reference available)
%
%   See also: edge_detector, wavelet_transform, image_quality

if nargin < 2
    options = struct();
end

% Get options
scale = get_option(options, 'scale', 2);
wavelet_type = get_option(options, 'wavelet', 'haar');
edge_sigma = get_option(options, 'edge_sigma', 1);
edge_weight = get_option(options, 'edge_weight', 0.5);
method = get_option(options, 'method', 'ebwt');

% Convert to double
if ischar(image)
    image = imread(image);
end
image = im2double(image);

% Check if color or grayscale
is_color = size(image, 3) == 3;

if strcmpi(method, 'bicubic')
    % Simple bicubic interpolation
    enhanced = imresize(image, scale, 'bicubic');
    metrics = struct('method', 'bicubic', 'scale', scale);
    return;
end

% EBWT-SR Algorithm
if is_color
    % Process each channel separately
    enhanced = zeros(size(image, 1) * scale, size(image, 2) * scale, 3);
    for c = 1:3
        enhanced(:, :, c) = ebwt_sr_channel(image(:, :, c), scale, wavelet_type, edge_sigma, edge_weight);
    end
else
    enhanced = ebwt_sr_channel(image, scale, wavelet_type, edge_sigma, edge_weight);
end

% Clip to valid range
enhanced = max(0, min(1, enhanced));

% Return metrics
metrics.method = 'ebwt';
metrics.scale = scale;
metrics.wavelet = wavelet_type;
metrics.edge_weight = edge_weight;

end

function enhanced = ebwt_sr_channel(channel, scale, wavelet_type, edge_sigma, edge_weight)
%EBWT_SR_CHANNEL Apply EBWT-SR to single channel

    [M, N] = size(channel);
    new_M = M * scale;
    new_N = N * scale;

    % Step 1: Edge detection
    [edges, magnitude, ~] = edge_detector(channel, struct('sigma', edge_sigma));

    % Normalize magnitude
    magnitude = magnitude / (max(magnitude(:)) + eps);

    % Step 2: Wavelet decomposition
    [coeffs, ~] = wavelet_transform(channel, struct('wavelet', wavelet_type));

    % Step 3: Upscale approximation coefficients (LL) to target size
    LL_up = imresize(coeffs.LL, [new_M, new_N], 'bicubic');

    % Step 4: Upscale edge information to target size
    edges_up = imresize(double(edges), [new_M, new_N], 'nearest');
    magnitude_up = imresize(magnitude, [new_M, new_N], 'bicubic');

    % Upscale detail coefficients to target size
    LH_up = imresize(coeffs.LH, [new_M, new_N], 'bicubic');
    HL_up = imresize(coeffs.HL, [new_M, new_N], 'bicubic');
    HH_up = imresize(coeffs.HH, [new_M, new_N], 'bicubic');

    % Enhance details using edge information
    edge_enhancement = edge_weight * magnitude_up .* edges_up;

    LH_enhanced = LH_up + edge_enhancement * 0.5;
    HL_enhanced = HL_up + edge_enhancement * 0.5;
    HH_enhanced = HH_up + edge_enhancement * 0.3;

    % Step 5: Reconstruct image
    % Combine approximation and detail
    enhanced = LL_up;
    enhanced = enhanced + 0.3 * LH_enhanced;
    enhanced = enhanced + 0.3 * HL_enhanced;
    enhanced = enhanced + 0.2 * HH_enhanced;

    % Direct bicubic for blending
    bicubic_up = imresize(channel, [new_M, new_N], 'bicubic');

    % Blend EBWT result with bicubic
    blend_weight = 0.6;
    enhanced = blend_weight * enhanced + (1 - blend_weight) * bicubic_up;

    % Edge-aware sharpening
    enhanced = enhanced + 0.1 * edge_enhancement;
end

function val = get_option(options, field, default)
    if isfield(options, field)
        val = options.(field);
    else
        val = default;
    end
end
