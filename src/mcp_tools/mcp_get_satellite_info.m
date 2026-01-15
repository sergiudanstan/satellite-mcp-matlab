function info = mcp_get_satellite_info(sat_id)
%MCP_GET_SATELLITE_INFO Get satellite state and orbital information
%
%   info = mcp_get_satellite_info(sat_id) returns current satellite state.
%
%   Output fields:
%       .name        - Satellite name
%       .sat_id      - Satellite ID
%       .a           - Semi-major axis [km]
%       .e           - Eccentricity
%       .i_deg       - Inclination [deg]
%       .RAAN_deg    - RAAN [deg]
%       .omega_deg   - Argument of perigee [deg]
%       .nu_deg      - True anomaly [deg]
%       .period_min  - Orbital period [min]
%       .altitude_km - Current altitude [km]
%       .velocity_kms- Velocity [km/s]
%       .lat         - Subsatellite latitude [deg]
%       .lon         - Subsatellite longitude [deg]
%
%   Example:
%       sat_id = mcp_load_satellite('leo');
%       info = mcp_get_satellite_info(sat_id);
%       fprintf('Altitude: %.1f km\n', info.altitude_km);
%
%   See also: mcp_load_satellite, mcp_propagate_orbit, satellite_mcp_tools

tools = satellite_mcp_tools.getInstance();
info = tools.get_satellite_info(sat_id);

end
