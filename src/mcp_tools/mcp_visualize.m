function h = mcp_visualize(sat_id, vis_type, options)
%MCP_VISUALIZE Create satellite visualization
%
%   h = mcp_visualize(sat_id, vis_type) creates the specified visualization.
%
%   h = mcp_visualize(sat_id, vis_type, options) uses additional options.
%
%   Inputs:
%       sat_id   - Satellite identifier
%       vis_type - Type of visualization:
%                  'ground_track' - 2D ground track on world map (default)
%                  'orbit_3d'     - 3D orbit around Earth
%                  'info'         - Display satellite info in console
%       options  - Optional struct with visualization settings:
%                  .color     - Track color
%                  .linewidth - Line width
%                  .animate   - Animate the visualization
%                  .title     - Custom title
%
%   Output:
%       h - Graphics handles struct
%
%   Example:
%       sat_id = mcp_load_satellite('leo');
%       mcp_get_ground_track(sat_id, 5400);  % Compute track
%       mcp_visualize(sat_id, 'ground_track');
%       mcp_visualize(sat_id, 'orbit_3d');
%
%   See also: mcp_get_ground_track, plot_ground_track, plot_orbit_3d

if nargin < 2
    vis_type = 'ground_track';
end

if nargin < 3
    options = struct();
end

tools = satellite_mcp_tools.getInstance();
h = tools.visualize(sat_id, vis_type, options);

end
