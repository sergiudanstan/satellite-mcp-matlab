function [heading, confidence] = heading_estimator(image, ref_image, options)
%HEADING_ESTIMATOR Estimate UAV heading from image orientation
%
%   heading = heading_estimator(image, ref) estimates the UAV heading angle
%   by comparing image orientation with reference satellite image.
%
%   [heading, confidence] = heading_estimator(image, ref, options) also
%   returns confidence measure.
%
%   Based on the GNSS-denied UAV localization research paper.
%   Estimates heading by finding rotation that maximizes similarity.
%   H_norm = 0.00025 * (sin(theta) + 1)
%
%   Inputs:
%       image     - Query aerial image
%       ref_image - Reference satellite image at estimated location
%       options   - Optional struct with fields:
%           .angle_range   - Range of angles to test [deg] (default: 0:10:350)
%           .method        - 'correlation', 'features' (default: 'correlation')
%           .resize        - Resize images to this size (default: [128, 128])
%
%   Outputs:
%       heading    - Estimated heading angle [deg] (0 = North, clockwise)
%       confidence - Confidence in heading estimate [0-1]
%
%   See also: image_matcher, similarity_matrix, location_encoder

if nargin < 3
    options = struct();
end

% Get options
angle_range = get_option(options, 'angle_range', 0:10:350);
method = get_option(options, 'method', 'correlation');
target_size = get_option(options, 'resize', [128, 128]);

% Load images if paths
if ischar(image)
    image = imread(image);
end
if ischar(ref_image)
    ref_image = imread(ref_image);
end

% Convert to grayscale
if size(image, 3) == 3
    image = rgb2gray(image);
end
if size(ref_image, 3) == 3
    ref_image = rgb2gray(ref_image);
end

% Convert to double and resize
image = im2double(imresize(image, target_size));
ref_image = im2double(imresize(ref_image, target_size));

% Test different rotation angles
num_angles = length(angle_range);
similarities = zeros(num_angles, 1);

for k = 1:num_angles
    angle = angle_range(k);

    % Rotate query image
    rotated = imrotate(image, angle, 'bilinear', 'crop');

    % Compute similarity
    switch lower(method)
        case 'correlation'
            similarities(k) = compute_ncc(rotated, ref_image);

        case 'features'
            % Extract and compare features
            f1 = extract_simple_features(rotated);
            f2 = extract_simple_features(ref_image);
            similarities(k) = dot(f1, f2) / (norm(f1) * norm(f2) + eps);

        otherwise
            similarities(k) = compute_ncc(rotated, ref_image);
    end
end

% Find best angle
[max_sim, best_idx] = max(similarities);
best_angle = angle_range(best_idx);

% Refine with finer search
fine_range = best_angle + (-5:1:5);
fine_similarities = zeros(length(fine_range), 1);

for k = 1:length(fine_range)
    angle = fine_range(k);
    rotated = imrotate(image, angle, 'bilinear', 'crop');

    switch lower(method)
        case 'correlation'
            fine_similarities(k) = compute_ncc(rotated, ref_image);
        case 'features'
            f1 = extract_simple_features(rotated);
            f2 = extract_simple_features(ref_image);
            fine_similarities(k) = dot(f1, f2) / (norm(f1) * norm(f2) + eps);
        otherwise
            fine_similarities(k) = compute_ncc(rotated, ref_image);
    end
end

[~, fine_best_idx] = max(fine_similarities);
heading = mod(fine_range(fine_best_idx), 360);

% Confidence based on peak sharpness
sorted_sim = sort(fine_similarities, 'descend');
if length(sorted_sim) >= 2
    confidence = (sorted_sim(1) - sorted_sim(2)) / (sorted_sim(1) + eps);
    confidence = max(0, min(1, confidence));
else
    confidence = sorted_sim(1);
end

% Apply heading normalization from paper
% H_norm = 0.00025 * (sin(theta) + 1)
% This is used for encoding, not for the output heading
heading_normalized = 0.00025 * (sind(heading) + 1);

end

function ncc = compute_ncc(img1, img2)
%COMPUTE_NCC Normalized Cross-Correlation

    % Center images
    img1 = img1 - mean(img1(:));
    img2 = img2 - mean(img2(:));

    % Compute NCC
    ncc = sum(img1(:) .* img2(:)) / ...
          (sqrt(sum(img1(:).^2)) * sqrt(sum(img2(:).^2)) + eps);
end

function features = extract_simple_features(img)
%EXTRACT_SIMPLE_FEATURES Simple feature extraction

    % Gradient histogram
    [Gx, Gy] = imgradientxy(img);
    magnitude = sqrt(Gx.^2 + Gy.^2);
    direction = atan2(Gy, Gx);

    % Histogram of gradients
    num_bins = 16;
    hist_dir = histcounts(direction(:), num_bins, 'Normalization', 'probability');
    hist_mag = histcounts(magnitude(:), num_bins, 'Normalization', 'probability');

    % Intensity histogram
    hist_int = histcounts(img(:), num_bins, 'Normalization', 'probability');

    features = [hist_dir, hist_mag, hist_int];
end

function val = get_option(options, field, default)
    if isfield(options, field)
        val = options.(field);
    else
        val = default;
    end
end
