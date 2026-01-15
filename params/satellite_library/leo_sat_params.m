function params = leo_sat_params()
%LEO_SAT_PARAMS Low Earth Orbit satellite parameters (ISS-like)
%
%   params = leo_sat_params() returns orbital parameters for a
%   typical Low Earth Orbit satellite similar to ISS.
%
%   Orbit characteristics:
%       - Altitude: ~408 km
%       - Inclination: 51.6 degrees (ISS-like)
%       - Period: ~92 minutes
%       - Near-circular orbit
%
%   See also: geo_sat_params, Satellite

params = struct();

% Satellite identification
params.name = 'LEO-1';
params.description = 'Low Earth Orbit imaging satellite (ISS-like orbit)';

% Keplerian orbital elements
params.a = 6786.137;        % Semi-major axis [km] (408 km altitude)
params.e = 0.0001;          % Eccentricity (near-circular)
params.i = deg2rad(51.6);   % Inclination [rad] (ISS-like)
params.RAAN = deg2rad(0);   % Right Ascension of Ascending Node [rad]
params.omega = deg2rad(0);  % Argument of perigee [rad]
params.nu = deg2rad(0);     % True anomaly [rad] (initial position)

% Physical properties
params.mass = 500;          % Mass [kg]

% Imaging properties
params.swath_width = 100;   % Ground swath width [km]
params.resolution = 0.5;    % Ground resolution [m/pixel]
params.fov = deg2rad(30);   % Field of view [rad]

% Computed properties
params.altitude = params.a - 6378.137;  % Altitude [km]
params.period = 2 * pi * sqrt(params.a^3 / 398600.4418);  % Period [s]

end
