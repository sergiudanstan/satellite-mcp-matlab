function params = geo_sat_params()
%GEO_SAT_PARAMS Geostationary satellite parameters
%
%   params = geo_sat_params() returns orbital parameters for a
%   geostationary satellite.
%
%   Orbit characteristics:
%       - Altitude: ~35,786 km
%       - Inclination: 0 degrees (equatorial)
%       - Period: 24 hours (sidereal day)
%       - Circular orbit
%       - Stationary relative to ground
%
%   See also: leo_sat_params, Satellite

params = struct();

% Satellite identification
params.name = 'GEO-1';
params.description = 'Geostationary communications/weather satellite';

% Keplerian orbital elements
params.a = 42164.137;       % Semi-major axis [km] (35,786 km altitude)
params.e = 0.0;             % Eccentricity (circular)
params.i = deg2rad(0);      % Inclination [rad] (equatorial)
params.RAAN = deg2rad(0);   % Right Ascension of Ascending Node [rad]
params.omega = deg2rad(0);  % Argument of perigee [rad]
params.nu = deg2rad(0);     % True anomaly [rad] (initial position)

% Physical properties
params.mass = 3000;         % Mass [kg]

% Coverage properties
params.longitude = -100;    % Subsatellite longitude [deg] (over Americas)
params.coverage_radius = 8500; % Ground coverage radius [km]

% Imaging properties (weather satellite)
params.swath_width = 5000;  % Ground swath width [km]
params.resolution = 1000;   % Ground resolution [m/pixel]
params.fov = deg2rad(17.4); % Field of view [rad] (full Earth disk)

% Computed properties
params.altitude = params.a - 6378.137;  % Altitude [km]
params.period = 2 * pi * sqrt(params.a^3 / 398600.4418);  % Period [s]

end
