function metrics = image_quality(enhanced, reference, options)
%IMAGE_QUALITY Compute image quality metrics
%
%   metrics = image_quality(enhanced, reference) computes PSNR, SSIM,
%   and other quality metrics comparing enhanced image to reference.
%
%   metrics = image_quality(enhanced, reference, options) uses custom options.
%
%   Inputs:
%       enhanced  - Enhanced/super-resolved image
%       reference - Ground truth high-resolution image
%       options   - Optional struct with fields:
%           .metrics - Cell array of metrics to compute (default: all)
%
%   Output:
%       metrics - Struct with fields:
%           .psnr     - Peak Signal-to-Noise Ratio [dB]
%           .ssim     - Structural Similarity Index [-1, 1]
%           .mse      - Mean Squared Error
%           .rmse     - Root Mean Squared Error
%           .mae      - Mean Absolute Error
%           .ncc      - Normalized Cross-Correlation
%
%   See also: super_resolution, edge_detector, wavelet_transform

if nargin < 3
    options = struct();
end

% Convert to double
enhanced = im2double(enhanced);
reference = im2double(reference);

% Ensure same size
if ~isequal(size(enhanced), size(reference))
    % Resize reference to match enhanced
    reference = imresize(reference, [size(enhanced, 1), size(enhanced, 2)]);
end

% Convert to grayscale for metrics if color
if size(enhanced, 3) == 3
    enhanced_gray = rgb2gray(enhanced);
    reference_gray = rgb2gray(reference);
else
    enhanced_gray = enhanced;
    reference_gray = reference;
end

% Initialize metrics struct
metrics = struct();

% MSE - Mean Squared Error
diff = enhanced_gray - reference_gray;
metrics.mse = mean(diff(:).^2);

% RMSE - Root Mean Squared Error
metrics.rmse = sqrt(metrics.mse);

% MAE - Mean Absolute Error
metrics.mae = mean(abs(diff(:)));

% PSNR - Peak Signal-to-Noise Ratio
if metrics.mse > 0
    max_val = 1;  % Images are normalized to [0, 1]
    metrics.psnr = 10 * log10(max_val^2 / metrics.mse);
else
    metrics.psnr = Inf;
end

% SSIM - Structural Similarity Index
metrics.ssim = compute_ssim(enhanced_gray, reference_gray);

% NCC - Normalized Cross-Correlation
metrics.ncc = compute_ncc(enhanced_gray, reference_gray);

% Additional info
metrics.enhanced_size = size(enhanced);
metrics.reference_size = size(reference);

end

function ssim_val = compute_ssim(img1, img2)
%COMPUTE_SSIM Structural Similarity Index

    % Constants for stability
    K1 = 0.01;
    K2 = 0.03;
    L = 1;  % Dynamic range
    C1 = (K1 * L)^2;
    C2 = (K2 * L)^2;

    % Window for local statistics
    window_size = 11;
    sigma = 1.5;
    window = fspecial('gaussian', window_size, sigma);
    window = window / sum(window(:));

    % Local means
    mu1 = imfilter(img1, window, 'replicate');
    mu2 = imfilter(img2, window, 'replicate');

    mu1_sq = mu1.^2;
    mu2_sq = mu2.^2;
    mu1_mu2 = mu1 .* mu2;

    % Local variances and covariance
    sigma1_sq = imfilter(img1.^2, window, 'replicate') - mu1_sq;
    sigma2_sq = imfilter(img2.^2, window, 'replicate') - mu2_sq;
    sigma12 = imfilter(img1 .* img2, window, 'replicate') - mu1_mu2;

    % SSIM map
    numerator = (2 * mu1_mu2 + C1) .* (2 * sigma12 + C2);
    denominator = (mu1_sq + mu2_sq + C1) .* (sigma1_sq + sigma2_sq + C2);

    ssim_map = numerator ./ denominator;

    % Mean SSIM
    ssim_val = mean(ssim_map(:));
end

function ncc = compute_ncc(img1, img2)
%COMPUTE_NCC Normalized Cross-Correlation

    img1 = img1(:) - mean(img1(:));
    img2 = img2(:) - mean(img2(:));

    ncc = sum(img1 .* img2) / (sqrt(sum(img1.^2)) * sqrt(sum(img2.^2)) + eps);
end
