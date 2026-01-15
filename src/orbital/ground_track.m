function track = ground_track(sat, duration, dt, options)
%GROUND_TRACK Compute satellite ground track over time
%
%   track = ground_track(sat, duration) computes the ground track
%   (subsatellite points) for the given duration [s].
%
%   track = ground_track(sat, duration, dt) uses time step dt [s].
%
%   track = ground_track(sat, duration, dt, options) uses additional options.
%
%   Inputs:
%       sat      - Satellite object or orbital elements struct
%       duration - Total propagation time [s]
%       dt       - Time step [s] (default: 60)
%       options  - Optional struct with fields:
%           .include_velocity - Include ground velocity (default: false)
%           .include_coverage - Include swath coverage (default: false)
%
%   Output:
%       track - Struct with fields:
%           .time    - Time vector [s] (Nx1)
%           .lat     - Latitude [deg] (Nx1)
%           .lon     - Longitude [deg] (Nx1)
%           .alt     - Altitude [km] (Nx1)
%           .r_eci   - ECI positions [km] (3xN)
%           .v_eci   - ECI velocities [km/s] (3xN)
%
%   See also: Satellite, kepler_propagate, plot_ground_track

% Default parameters
if nargin < 3 || isempty(dt)
    dt = 60;  % 1 minute default
end

if nargin < 4
    options = struct();
end

% Earth constants
OMEGA_EARTH = 7.2921159e-5;  % rad/s

% Time vector
t = 0:dt:duration;
N = length(t);

% Preallocate output
track.time = t(:);
track.lat = zeros(N, 1);
track.lon = zeros(N, 1);
track.alt = zeros(N, 1);
track.r_eci = zeros(3, N);
track.v_eci = zeros(3, N);

% Handle Satellite object vs struct
if isa(sat, 'Satellite')
    oe.a = sat.a;
    oe.e = sat.e;
    oe.i = sat.i;
    oe.RAAN = sat.RAAN;
    oe.omega = sat.omega;
    oe.nu = sat.nu;
    initial_time = sat.elapsed_time;
else
    oe = sat;
    initial_time = 0;
end

% Propagate and compute ground track
for k = 1:N
    % Propagate to current time
    [r_eci, v_eci, nu_new] = kepler_propagate(oe, t(k));

    % Store ECI state
    track.r_eci(:, k) = r_eci;
    track.v_eci(:, k) = v_eci;

    % Greenwich sidereal angle (approximate)
    theta = OMEGA_EARTH * (initial_time + t(k));

    % Convert ECI to ECEF
    r_ecef = eci_to_ecef(r_eci, theta);

    % Convert ECEF to geodetic
    [lat, lon, alt] = ecef_to_lla(r_ecef);

    track.lat(k) = lat;
    track.lon(k) = lon;
    track.alt(k) = alt;
end

% Wrap longitude to [-180, 180]
track.lon = wrapTo180(track.lon);

% Optional: compute ground velocity
if isfield(options, 'include_velocity') && options.include_velocity
    track.ground_speed = zeros(N, 1);
    for k = 2:N
        dlat = track.lat(k) - track.lat(k-1);
        dlon = track.lon(k) - track.lon(k-1);
        % Handle wrap-around
        if abs(dlon) > 180
            dlon = dlon - sign(dlon) * 360;
        end
        % Approximate ground distance [km]
        R = 6378.137;
        dx = R * cosd(track.lat(k)) * deg2rad(dlon);
        dy = R * deg2rad(dlat);
        dist = sqrt(dx^2 + dy^2);
        track.ground_speed(k) = dist / dt;  % km/s
    end
    track.ground_speed(1) = track.ground_speed(2);
end

% Optional: compute swath coverage
if isfield(options, 'include_coverage') && options.include_coverage
    if isa(sat, 'Satellite') && isfield(sat.params, 'swath_width')
        track.swath_width = sat.params.swath_width * ones(N, 1);
    else
        track.swath_width = 100 * ones(N, 1);  % Default 100 km
    end
end

end

function lon = wrapTo180(lon)
    %WRAPTO180 Wrap longitude to [-180, 180]
    lon = mod(lon + 180, 360) - 180;
end
