function [lat, lon, alt] = ecef_to_lla(r_ecef)
%ECEF_TO_LLA Convert ECEF coordinates to geodetic latitude/longitude/altitude
%
%   [lat, lon, alt] = ecef_to_lla(r_ecef) converts position vector from
%   Earth-Centered Earth-Fixed (ECEF) to geodetic coordinates.
%
%   Input:
%       r_ecef - Position vector in ECEF frame [km] (3x1 or 3xN)
%
%   Outputs:
%       lat - Geodetic latitude [deg]
%       lon - Longitude [deg]
%       alt - Altitude above WGS84 ellipsoid [km]
%
%   Uses iterative algorithm for geodetic latitude calculation.
%
%   See also: lla_to_ecef, eci_to_ecef

% WGS84 ellipsoid parameters
a = 6378.137;           % Equatorial radius [km]
f = 1/298.257223563;    % Flattening
b = a * (1 - f);        % Polar radius [km]
e2 = 1 - (b/a)^2;       % First eccentricity squared

% Extract coordinates
x = r_ecef(1, :);
y = r_ecef(2, :);
z = r_ecef(3, :);

% Longitude (straightforward)
lon = atan2d(y, x);

% Distance from z-axis
p = sqrt(x.^2 + y.^2);

% Iterative calculation of geodetic latitude
lat = atan2d(z, p * (1 - e2));  % Initial guess

for iter = 1:10
    N = a ./ sqrt(1 - e2 * sind(lat).^2);  % Prime vertical radius
    lat_new = atan2d(z + e2 * N .* sind(lat), p);
    if max(abs(lat_new - lat)) < 1e-10
        break;
    end
    lat = lat_new;
end

% Altitude
N = a ./ sqrt(1 - e2 * sind(lat).^2);
alt = p ./ cosd(lat) - N;

% Handle polar singularity
polar = abs(p) < 1e-10;
if any(polar)
    lat(polar) = sign(z(polar)) * 90;
    alt(polar) = abs(z(polar)) - b;
end

end
