function track = mcp_get_ground_track(sat_id, duration, dt)
%MCP_GET_GROUND_TRACK Compute satellite ground track
%
%   track = mcp_get_ground_track(sat_id, duration) computes the ground
%   track (subsatellite points) for the specified duration.
%
%   track = mcp_get_ground_track(sat_id, duration, dt) uses custom time step.
%
%   Inputs:
%       sat_id   - Satellite identifier
%       duration - Total propagation time [s]
%       dt       - Time step [s] (default: 60)
%
%   Output:
%       track - Struct with fields:
%           .time  - Time vector [s]
%           .lat   - Latitude [deg]
%           .lon   - Longitude [deg]
%           .alt   - Altitude [km]
%           .r_eci - ECI positions [km] (3xN)
%           .v_eci - ECI velocities [km/s] (3xN)
%
%   Example:
%       sat_id = mcp_load_satellite('leo');
%       track = mcp_get_ground_track(sat_id, 5400);  % 90 minutes
%       plot(track.lon, track.lat);
%
%   See also: mcp_visualize, plot_ground_track, satellite_mcp_tools

if nargin < 3
    dt = 60;
end

tools = satellite_mcp_tools.getInstance();
track = tools.get_ground_track(sat_id, duration, dt);

end
