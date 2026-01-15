function sat_id = mcp_load_satellite(sat_name, options)
%MCP_LOAD_SATELLITE Load a satellite model
%
%   sat_id = mcp_load_satellite(sat_name) loads the specified satellite
%   and returns a unique identifier for future operations.
%
%   sat_id = mcp_load_satellite(sat_name, options) uses additional options.
%
%   Inputs:
%       sat_name - Name of satellite to load ('leo', 'geo', etc.)
%       options  - Optional struct with loading options
%
%   Output:
%       sat_id - Unique identifier for the loaded satellite
%
%   Example:
%       sat_id = mcp_load_satellite('leo');
%       info = mcp_get_satellite_info(sat_id);
%
%   See also: mcp_list_satellites, mcp_get_satellite_info, satellite_mcp_tools

if nargin < 2
    options = struct();
end

tools = satellite_mcp_tools.getInstance();
sat_id = tools.load_satellite(sat_name, options);

end
