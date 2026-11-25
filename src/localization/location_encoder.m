function encoded = location_encoder(lat, lon, options)
%LOCATION_ENCODER Encode GPS coordinates using Equal Earth Projection
%
%   encoded = location_encoder(lat, lon) encodes latitude/longitude using
%   the Equal Earth Projection for GPS coordinate encoding.
%
%   Based on the GNSS-denied UAV localization research paper.
%   Uses Equal Earth Projection followed by Random Fourier Features (RFF).
%
%   Inputs:
%       lat     - Latitude [deg] (scalar or vector)
%       lon     - Longitude [deg] (scalar or vector)
%       options - Optional struct with fields:
%           .projection  - 'equal_earth' or 'mercator' (default: 'equal_earth')
%           .use_rff     - Use Random Fourier Features (default: true)
%           .rff_dim     - RFF dimension (default: 256)
%           .sigma       - RFF bandwidth (default: 0.1)
%
%   Output:
%       encoded - Encoded location features
%           If use_rff=true: Nx(rff_dim) feature matrix
%           If use_rff=false: Nx2 projected coordinates
%
%   Equal Earth Projection (Šavrič et al., 2019):
%       - Equal-area pseudocylindrical projection
%       - Preserves area ratios across the map
%       - Better for location encoding than Mercator
%
%   See also: image_matcher, similarity_matrix, heading_estimator

if nargin < 3
    options = struct();
end

% Get options
projection = get_option(options, 'projection', 'equal_earth');
use_rff = get_option(options, 'use_rff', true);
rff_dim = get_option(options, 'rff_dim', 256);
sigma = get_option(options, 'sigma', 0.1);

% Ensure column vectors
lat = lat(:);
lon = lon(:);
N = length(lat);

% Convert to radians
lat_rad = deg2rad(lat);
lon_rad = deg2rad(lon);

% Apply projection
switch lower(projection)
    case 'equal_earth'
        [x, y] = equal_earth_projection(lat_rad, lon_rad);

    case 'mercator'
        [x, y] = mercator_projection(lat_rad, lon_rad);

    otherwise
        [x, y] = equal_earth_projection(lat_rad, lon_rad);
end

% Normalize coordinates to [-1, 1]
x = x / pi;  % lon range is [-pi, pi]
y = y / (pi/2);  % lat range is [-pi/2, pi/2]

projected = [x, y];

if use_rff
    % Apply Random Fourier Features for kernel approximation
    encoded = random_fourier_features(projected, rff_dim, sigma);
else
    encoded = projected;
end

end

function [x, y] = equal_earth_projection(lat, lon)
%EQUAL_EARTH_PROJECTION Equal Earth map projection
%
%   The Equal Earth projection is an equal-area pseudocylindrical
%   projection designed for world maps.

    % Equal Earth parameters
    A1 = 1.340264;
    A2 = -0.081106;
    A3 = 0.000893;
    A4 = 0.003796;

    % Parametric latitude
    theta = asin(sqrt(3) / 2 * sin(lat));

    % Powers of theta
    theta2 = theta.^2;
    theta6 = theta.^6;

    % Compute x and y
    x = (2 * sqrt(3) * lon .* cos(theta)) ./ ...
        (3 * (9 * A4 * theta2.^4 + 7 * A3 * theta6 + 3 * A2 * theta2 + A1));

    y = A4 * theta.^9 + A3 * theta.^7 + A2 * theta.^3 + A1 * theta;
end

function [x, y] = mercator_projection(lat, lon)
%MERCATOR_PROJECTION Standard Mercator projection

    % Clamp latitude to avoid infinity at poles
    lat = max(min(lat, deg2rad(85)), deg2rad(-85));

    x = lon;
    y = log(tan(pi/4 + lat/2));
end

function features = random_fourier_features(X, D, sigma)
%RANDOM_FOURIER_FEATURES Approximate RBF kernel using random features
%
%   Based on "Random Features for Large-Scale Kernel Machines"
%   (Rahimi & Recht, 2007)

    [N, d] = size(X);

    % Generate random weights (fixed seed for reproducibility)
    rng(42);
    W = randn(d, D/2) / sigma;

    % Compute random features
    XW = X * W;
    features = sqrt(2/D) * [cos(XW), sin(XW)];
end

function val = get_option(options, field, default)
    if isfield(options, field)
        val = options.(field);
    else
        val = default;
    end
end
