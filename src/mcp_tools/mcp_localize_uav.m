function result = mcp_localize_uav(sat_id, aerial_image, sat_image, options)
%MCP_LOCALIZE_UAV Estimate UAV position from aerial-satellite image matching
%
%   result = mcp_localize_uav(sat_id, aerial_image, sat_image) estimates
%   the UAV position by matching an aerial image against a satellite map.
%
%   Based on the GNSS-denied UAV localization research using image matching.
%
%   Inputs:
%       sat_id      - Satellite identifier (for coverage info)
%       aerial_image - Path to aerial image or image matrix
%       sat_image   - Path to satellite map image or image matrix
%       options     - Optional struct with matching parameters
%
%   Output:
%       result - Struct with fields:
%           .estimated_lat     - Estimated latitude [deg]
%           .estimated_lon     - Estimated longitude [deg]
%           .estimated_heading - Estimated heading [deg]
%           .confidence        - Match confidence [0-1]
%           .message           - Status message
%
%   Example:
%       sat_id = mcp_load_satellite('leo');
%       result = mcp_localize_uav(sat_id, 'aerial.jpg', 'satellite.jpg');
%       fprintf('Position: %.4f, %.4f\n', result.estimated_lat, result.estimated_lon);
%
%   See also: image_matcher, location_encoder, heading_estimator

if nargin < 4
    options = struct();
end

tools = satellite_mcp_tools.getInstance();
result = tools.localize_uav(sat_id, aerial_image, sat_image, options);

end
