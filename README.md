# satellite-mcp-matlab
> Satellite orbit simulation with MCP-integrated UAV localization and image super-resolution.

## Overview
A MATLAB simulation suite for satellite orbital mechanics with MCP (Model Context Protocol) tool integration. It provides LEO/GEO orbit propagation, ground track visualization, GPS-denied UAV localization via satellite image matching, and edge-based wavelet super-resolution for satellite imagery. All features are accessible through an interactive dashboard or MCP tool calls.

## Features
- **Orbit propagation** -- Keplerian orbital mechanics with ECI/ECEF/LLA coordinate transforms
- **Ground track visualization** -- Subsatellite point mapping for LEO and GEO satellites
- **UAV localization** -- CLIP-based image-to-location matching for GPS-denied navigation (~40 m accuracy)
- **Image super-resolution** -- Edge-Based Wavelet Transform (EBWT) with Canny detection and DWT decomposition
- **Interactive dashboard** -- Satellite selection, 3D orbit view, animation controls, and screenshot/video recording
- **MCP tool interface** -- 8 callable tools for satellite loading, propagation, localization, and visualization
- **Satellite library** -- Pre-configured LEO and GEO satellite parameter sets

## Quick Start
```matlab
cd satellite-mcp-matlab
setup_paths;
DEMO_satellite;         % Launch interactive dashboard

% Or use individual MCP tools:
mcp_list_satellites;
mcp_load_satellite('LEO_1');
mcp_get_ground_track;
mcp_localize_uav;
mcp_enhance_image;
```

## Project Structure
```
satellite-mcp-matlab/
├── setup_paths.m                 % Path initialization
├── DEMO_satellite.m              % Interactive dashboard
├── params/
│   └── satellite_library/        % Satellite orbit configurations
├── src/
│   ├── core/                     % Satellite and UAV base classes
│   ├── orbital/                  % Kepler propagation, coordinate transforms
│   ├── localization/             % Image matching, heading estimation
│   ├── imaging/                  % Super-resolution, wavelet transform
│   ├── visualization/            % Plotting and dashboard helpers
│   └── mcp_tools/                % MCP interface (8 tools)
├── data/                         % Satellite maps, aerial/test images
├── tests/                        % Unit tests
└── results/                      % Output figures and data
```

## Tests
```matlab
cd satellite-mcp-matlab
setup_paths;
% Run test scripts from tests/ directory
```

## License
MIT License - see root [LICENSE](../LICENSE)
