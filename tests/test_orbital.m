% Orbital mechanics and coordinate transforms (base MATLAB, no toolboxes).
% Script-based tests: code before the first %% section is shared by every
% test, each %% section is one test and a failing assert fails it.
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup_paths.m'));
mu = 398600.4418;

%% lla_to_ecef puts the equator/prime meridian on the x axis at the equatorial radius
r = lla_to_ecef(0, 0, 0);
assert(norm(r - [6378.137; 0; 0]) < 1e-9, 'equator point should be [a;0;0]');

%% lla_to_ecef puts the pole at the WGS84 polar radius
r = lla_to_ecef(90, 0, 0);
b = 6378.137 * (1 - 1/298.257223563);
assert(abs(r(3) - b) < 1e-6, 'pole z should be the polar radius');
assert(abs(r(1)) < 1e-6 && abs(r(2)) < 1e-6, 'pole x,y should be zero');

%% ecef_to_lla inverts lla_to_ecef
lat = [0, 30, -45, 60, -80, 89];
lon = [0, 120, -75, 179, -179, 10];
alt = [0, 400, 35786, 10, 800, 0];
[lat2, lon2, alt2] = ecef_to_lla(lla_to_ecef(lat, lon, alt));
assert(max(abs(lat2 - lat)) < 1e-6, 'latitude round trip');
assert(max(abs(lon2 - lon)) < 1e-6, 'longitude round trip');
assert(max(abs(alt2 - alt)) < 1e-5, 'altitude round trip');

%% eci_to_ecef rotates about z and preserves length
r_eci = [7000; 1000; 2000];
r0 = eci_to_ecef(r_eci, 0);
assert(norm(r0 - r_eci) < 1e-12, 'zero rotation is the identity');
r_q = eci_to_ecef([1; 0; 0], pi/2);
assert(norm(r_q - [0; -1; 0]) < 1e-12, 'ECEF lags ECI: x axis maps to -y after a quarter turn');
r_t = eci_to_ecef(r_eci, 1.234);
assert(abs(norm(r_t) - norm(r_eci)) < 1e-9, 'rotation preserves norm');
assert(abs(r_t(3) - r_eci(3)) < 1e-12, 'rotation about z leaves z unchanged');

%% kepler_propagate: circular orbit has constant radius and circular speed
oe = struct('a', 6786.137, 'e', 0, 'i', deg2rad(51.6), 'RAAN', 0, 'omega', 0, 'nu', 0);
for t = [0 600 1800 4000]
        [r, v] = kepler_propagate(oe, t);
        assert(abs(norm(r) - oe.a) < 1e-6, 'circular orbit radius is constant');
        assert(abs(norm(v) - sqrt(mu / oe.a)) < 1e-9, 'circular orbit speed is sqrt(mu/a)');
        assert(abs(dot(r, v)) < 1e-6, 'velocity is perpendicular to radius on a circle');
end

%% kepler_propagate: one full period returns to the start state
oe = struct('a', 6786.137, 'e', 0, 'i', deg2rad(51.6), 'RAAN', 0, 'omega', 0, 'nu', 0);
T = 2 * pi * sqrt(oe.a^3 / mu);
[r0, v0] = kepler_propagate(oe, 0);
[r1, v1] = kepler_propagate(oe, T);
assert(norm(r1 - r0) < 1e-4, 'position repeats after one period');
assert(norm(v1 - v0) < 1e-7, 'velocity repeats after one period');

%% kepler_propagate: eccentric orbit conserves energy and angular momentum
oe = struct('a', 12000, 'e', 0.3, 'i', deg2rad(30), 'RAAN', deg2rad(40), ...
        'omega', deg2rad(60), 'nu', deg2rad(20));
[r0, v0] = kepler_propagate(oe, 0);
eps0 = norm(v0)^2 / 2 - mu / norm(r0);
h0 = cross(r0, v0);
assert(abs(eps0 + mu / (2 * oe.a)) < 1e-9, 'vis-viva: specific energy is -mu/(2a)');
for t = [500 2500 7000 15000]
        [r, v] = kepler_propagate(oe, t);
        assert(abs((norm(v)^2 / 2 - mu / norm(r)) - eps0) < 1e-8, 'energy is conserved');
        assert(norm(cross(r, v) - h0) < 1e-6, 'angular momentum is conserved');
end

%% ground_track: GEO satellite stays over one point on the equator
sat = geo_sat_params();
track = ground_track(sat, 6 * 3600, 600);
assert(max(abs(track.lat)) < 1e-6, 'GEO latitude stays at zero');
assert(max(abs(track.lon - track.lon(1))) < 0.05, 'GEO longitude is fixed to the rotating Earth');
assert(all(abs(track.alt - 35786) < 1), 'GEO altitude is about 35786 km');

%% ground_track: LEO latitude is bounded by the orbit inclination
sat = leo_sat_params();
track = ground_track(sat, sat.period, 30);
assert(abs(max(track.lat) - 51.6) < 0.5, 'maximum latitude is the inclination');
assert(abs(min(track.lat) + 51.6) < 0.5, 'minimum latitude is minus the inclination');
% Geodetic altitude swings by about +-21 km with latitude on an oblate Earth.
assert(all(abs(track.alt - 408) < 25), 'LEO altitude stays near 408 km');
assert(all(track.lon >= -180 & track.lon <= 180), 'longitude is wrapped to [-180, 180]');
assert(numel(track.time) == numel(track.lat), 'one latitude per time step');
