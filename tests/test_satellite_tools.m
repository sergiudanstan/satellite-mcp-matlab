% Satellite class and MCP tool registry (base MATLAB, no toolboxes).
% Code before the first %% section is shared by every test.
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup_paths.m'));
satellite_mcp_tools.resetInstance();
tools = satellite_mcp_tools.getInstance();

%% Library lists the LEO and GEO satellites
sats = mcp_list_satellites();
names = {sats.name};
assert(ismember('leo', names) && ismember('geo', names), 'leo and geo are listed');
assert(all([sats.altitude_km] > 0), 'every listed satellite has a positive altitude');

%% Satellite period follows Kepler's third law
sat = Satellite('leo');
expected = 2 * pi * sqrt(sat.a^3 / Satellite.MU_EARTH);
assert(abs(sat.get_period() - expected) < 1e-9, 'period matches 2*pi*sqrt(a^3/mu)');
assert(abs(sat.get_period() - 5.5e3) < 200, 'LEO period is about 92 minutes');

%% Propagating one period returns the satellite to its start
sat = Satellite('leo');
nu0 = sat.nu;
sat.propagate(sat.get_period());
d = abs(angle(exp(1i * (sat.nu - nu0))));
assert(d < 1e-6, 'true anomaly repeats after one period');
assert(abs(sat.elapsed_time - sat.get_period()) < 1e-9, 'elapsed time is accumulated');
sat.reset();
assert(sat.elapsed_time == 0 && abs(sat.nu - nu0) < 1e-12, 'reset restores the epoch state');

%% Unknown satellite name is an error
threw = false;
try
        Satellite('no_such_satellite');
catch ME
        threw = strcmp(ME.identifier, 'Satellite:ParamsNotFound');
end
assert(threw, 'unknown satellite raises Satellite:ParamsNotFound');

%% MCP load, info, propagate and ground track work end to end
sat_id = mcp_load_satellite('leo');
assert(ismember(sat_id, tools.get_loaded_satellites()), 'loaded satellite is registered');
info0 = mcp_get_satellite_info(sat_id);
assert(abs(info0.altitude_km - 408) < 5, 'info reports the LEO altitude');
tools.propagate(sat_id, 600);
info1 = tools.get_satellite_info(sat_id);
assert(info1.elapsed_time_s == 600, 'propagate advances the clock');
assert(info1.nu_deg ~= info0.nu_deg, 'propagate moves the satellite');
track = mcp_get_ground_track(sat_id, 3600, 60);
assert(numel(track.lat) == 61, '3600 s at 60 s steps gives 61 samples');
assert(all(abs(track.lat) <= 52), 'latitude respects the inclination (geodetic, so slightly above it)');
tools.unload_satellite(sat_id);
assert(~ismember(sat_id, tools.get_loaded_satellites()), 'unloaded satellite is gone');
