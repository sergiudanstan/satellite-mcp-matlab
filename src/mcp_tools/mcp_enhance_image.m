function enhanced = mcp_enhance_image(image, options)
%MCP_ENHANCE_IMAGE Apply super-resolution to satellite image
%
%   enhanced = mcp_enhance_image(image) applies the EBWT-SR super-resolution
%   algorithm to enhance satellite image quality.
%
%   enhanced = mcp_enhance_image(image, options) uses custom options.
%
%   Based on the Edge-Based Wavelet Transform (EBWT-SR) research paper.
%
%   Inputs:
%       image   - Input image (path or matrix)
%       options - Optional struct with fields:
%           .scale - Upscaling factor (default: 2)
%           .method - 'ebwt' or 'bicubic' (default: 'bicubic')
%
%   Output:
%       enhanced - Enhanced image matrix
%
%   Example:
%       img = imread('low_res_satellite.jpg');
%       enhanced = mcp_enhance_image(img, struct('scale', 2));
%       imshow(enhanced);
%
%   See also: super_resolution, wavelet_transform, edge_detector

if nargin < 2
    options = struct();
end

tools = satellite_mcp_tools.getInstance();
enhanced = tools.enhance_image(image, options);

end
