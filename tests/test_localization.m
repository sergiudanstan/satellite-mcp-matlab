% location_encoder (base MATLAB, no toolboxes).
% Code before the first %% section is shared by every test.
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup_paths.m'));
plain = struct('use_rff', false);

%% Equal Earth projection matches the published reference values
% Published extents: x = 2.7066 at (0 deg, 180 deg), y = 1.3173 at the pole.
p = location_encoder([0; 90], [180; 0], plain);
x_eq = p(1, 1) * pi;
y_pole = p(2, 2) * (pi / 2);
assert(abs(x_eq - 2.7066) < 1e-3, 'equator edge x should be 2.7066');
assert(abs(y_pole - 1.3173) < 1e-3, 'pole y should be 1.3173');

%% Equator and prime meridian map to the origin without NaN
p = location_encoder(0, 0, plain);
assert(all(isfinite(p)), 'projection at (0, 0) must be finite');
assert(norm(p) < 1e-12, '(0, 0) maps to the origin');

%% Projection is finite over the whole globe and normalised to [-1, 1]
[lat, lon] = meshgrid(-90:15:90, -180:30:180);
p = location_encoder(lat(:), lon(:), plain);
assert(all(isfinite(p(:))), 'projection is finite everywhere');
assert(all(abs(p(:)) <= 1 + 1e-9), 'projected coordinates are normalised to [-1, 1]');

%% Random Fourier features have the requested size and are finite
p = location_encoder([10; 20; 30], [40; 50; 60], struct('rff_dim', 64));
assert(size(p, 1) == 3, 'one row per location');
assert(all(isfinite(p(:))), 'features are finite');
