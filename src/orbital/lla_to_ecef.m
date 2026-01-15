function r_ecef = lla_to_ecef(lat, lon, alt)
%LLA_TO_ECEF Convert geodetic coordinates to ECEF
%
%   r_ecef = lla_to_ecef(lat, lon, alt) converts geodetic coordinates to
%   Earth-Centered Earth-Fixed (ECEF) frame.
%
%   Inputs:
%       lat - Geodetic latitude [deg]
%       lon - Longitude [deg]
%       alt - Altitude above WGS84 ellipsoid [km]
%
%   Output:
%       r_ecef - Position vector in ECEF frame [km] (3x1 or 3xN)
%
%   See also: ecef_to_lla, eci_to_ecef

% WGS84 ellipsoid parameters
a = 6378.137;           % Equatorial radius [km]
f = 1/298.257223563;    % Flattening
b = a * (1 - f);        % Polar radius [km]
e2 = 1 - (b/a)^2;       % First eccentricity squared

% Prime vertical radius of curvature
N = a ./ sqrt(1 - e2 * sind(lat).^2);

% ECEF coordinates
x = (N + alt) .* cosd(lat) .* cosd(lon);
y = (N + alt) .* cosd(lat) .* sind(lon);
z = (N * (1 - e2) + alt) .* sind(lat);

r_ecef = [x; y; z];

end
