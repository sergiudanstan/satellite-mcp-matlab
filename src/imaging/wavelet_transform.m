function [coeffs, info] = wavelet_transform(image, options)
%WAVELET_TRANSFORM Discrete Wavelet Transform for image processing
%
%   coeffs = wavelet_transform(image) computes 2D DWT decomposition.
%
%   [coeffs, info] = wavelet_transform(image, options) returns coefficient
%   structure and decomposition info.
%
%   Based on EBWT-SR paper for satellite image super-resolution.
%   Decomposes image into LL, LH, HL, HH sub-bands.
%
%   Inputs:
%       image   - Grayscale image
%       options - Optional struct with fields:
%           .wavelet - Wavelet type: 'haar', 'db1', 'db2', 'sym2' (default: 'haar')
%           .level   - Decomposition level (default: 1)
%           .mode    - Signal extension mode (default: 'symmetric')
%
%   Outputs:
%       coeffs - Struct with fields:
%           .LL - Approximation coefficients (low-low)
%           .LH - Horizontal detail (low-high)
%           .HL - Vertical detail (high-low)
%           .HH - Diagonal detail (high-high)
%           .all - Full coefficient vector [LL, LH, HL, HH]
%       info   - Decomposition information struct
%
%   See also: wavelet_inverse, edge_detector, super_resolution

if nargin < 2
    options = struct();
end

% Convert to double grayscale
if size(image, 3) == 3
    image = rgb2gray(image);
end
image = im2double(image);

% Get options
wavelet_type = get_option(options, 'wavelet', 'haar');
level = get_option(options, 'level', 1);

% Get image size
[M, N] = size(image);

% Ensure even dimensions for wavelet transform
if mod(M, 2) == 1
    image = image(1:end-1, :);
    M = M - 1;
end
if mod(N, 2) == 1
    image = image(:, 1:end-1);
    N = N - 1;
end

% Get wavelet filters
[Lo_D, Hi_D, Lo_R, Hi_R] = get_wavelet_filters(wavelet_type);

% Perform 2D DWT
% Row filtering
L = conv2(image, Lo_D', 'same');
H = conv2(image, Hi_D', 'same');

% Downsample rows
L = L(1:2:end, :);
H = H(1:2:end, :);

% Column filtering
LL = conv2(L, Lo_D, 'same');
LH = conv2(L, Hi_D, 'same');
HL = conv2(H, Lo_D, 'same');
HH = conv2(H, Hi_D, 'same');

% Downsample columns
LL = LL(:, 1:2:end);
LH = LH(:, 1:2:end);
HL = HL(:, 1:2:end);
HH = HH(:, 1:2:end);

% Store coefficients
coeffs.LL = LL;
coeffs.LH = LH;
coeffs.HL = HL;
coeffs.HH = HH;
coeffs.all = [LL(:); LH(:); HL(:); HH(:)];

% Store info
info.original_size = [M, N];
info.coeff_size = size(LL);
info.wavelet = wavelet_type;
info.level = level;
info.Lo_D = Lo_D;
info.Hi_D = Hi_D;
info.Lo_R = Lo_R;
info.Hi_R = Hi_R;

end

function [Lo_D, Hi_D, Lo_R, Hi_R] = get_wavelet_filters(wavelet_type)
%GET_WAVELET_FILTERS Get wavelet decomposition and reconstruction filters

    switch lower(wavelet_type)
        case {'haar', 'db1'}
            % Haar wavelet
            Lo_D = [1 1] / sqrt(2);
            Hi_D = [-1 1] / sqrt(2);
            Lo_R = [1 1] / sqrt(2);
            Hi_R = [1 -1] / sqrt(2);

        case 'db2'
            % Daubechies 2
            Lo_D = [0.4830 0.8365 0.2241 -0.1294];
            Hi_D = [-0.1294 -0.2241 0.8365 -0.4830];
            Lo_R = [-0.1294 0.2241 0.8365 0.4830];
            Hi_R = [-0.4830 0.8365 -0.2241 -0.1294];

        case 'sym2'
            % Symlet 2
            Lo_D = [-0.1294 0.2241 0.8365 0.4830];
            Hi_D = [-0.4830 0.8365 -0.2241 -0.1294];
            Lo_R = [0.4830 0.8365 0.2241 -0.1294];
            Hi_R = [-0.1294 -0.2241 0.8365 -0.4830];

        otherwise
            % Default to Haar
            Lo_D = [1 1] / sqrt(2);
            Hi_D = [-1 1] / sqrt(2);
            Lo_R = [1 1] / sqrt(2);
            Hi_R = [1 -1] / sqrt(2);
    end
end

function val = get_option(options, field, default)
    if isfield(options, field)
        val = options.(field);
    else
        val = default;
    end
end
