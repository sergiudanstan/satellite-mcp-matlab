function info = mcp_propagate_orbit(sat_id, dt)
%MCP_PROPAGATE_ORBIT Propagate satellite orbit forward in time
%
%   info = mcp_propagate_orbit(sat_id, dt) propagates the satellite
%   orbit by dt seconds and returns the new state.
%
%   Inputs:
%       sat_id - Satellite identifier
%       dt     - Time step [s]
%
%   Output:
%       info - Updated satellite state (same as mcp_get_satellite_info)
%
%   Example:
%       sat_id = mcp_load_satellite('leo');
%       info = mcp_propagate_orbit(sat_id, 600);  % Propagate 10 minutes
%       fprintf('New position: %.4f lat, %.4f lon\n', info.lat, info.lon);
%
%   See also: mcp_get_satellite_info, mcp_get_ground_track, satellite_mcp_tools

tools = satellite_mcp_tools.getInstance();
tools.propagate(sat_id, dt);
info = tools.get_satellite_info(sat_id);

end
