function satellites = mcp_list_satellites()
%MCP_LIST_SATELLITES List available satellite models
%
%   satellites = mcp_list_satellites() returns a struct array with
%   information about available satellite models.
%
%   Output fields:
%       .name        - Satellite name for loading
%       .description - Human-readable description
%       .type        - Orbit type (LEO, GEO, etc.)
%       .altitude_km - Orbital altitude [km]
%
%   Example:
%       satellites = mcp_list_satellites();
%       disp(satellites(1).name);  % 'leo'
%
%   See also: mcp_load_satellite, satellite_mcp_tools

tools = satellite_mcp_tools.getInstance();
satellites = tools.list_satellites();

end
