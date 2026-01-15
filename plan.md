# Satellite MCP MATLAB

## Overview
Satellite simulation suite with MCP integration for MATLAB, featuring:
- **UAV-Satellite Localization** - GPS-denied navigation via image matching
- **Image Super-Resolution** - Enhance low-res satellite imagery
- **Ground Track Visualization** - Satellite coverage mapping

Based on research papers: `satel.pdf` and `satelit.pdf`

## Project Structure
```
satellite-mcp-matlab/
├── setup_paths.m              # Path initialization
├── plan.md / tasks.md         # Documentation
├── params/
│   └── satellite_library/     # Satellite configurations
├── src/
│   ├── core/                  # Satellite, UAV classes
│   ├── orbital/               # Orbit propagation
│   ├── localization/          # Image-based positioning
│   ├── imaging/               # Super-resolution
│   ├── visualization/         # Plotting & dashboard
│   └── mcp_tools/             # MCP interface layer
├── demos/                     # Example scripts
├── data/                      # Test images
├── tests/                     # Unit tests
└── results/                   # Output files
```

## Quick Start
```matlab
setup_paths;
demo_ground_track;      % Visualize satellite orbit
demo_uav_localization;  % Test image matching
demo_super_resolution;  % Compare image quality
```

## MCP Tools
| Tool | Description |
|------|-------------|
| mcp_list_satellites | List available satellite models |
| mcp_load_satellite | Load satellite and get ID |
| mcp_propagate_orbit | Compute orbital position |
| mcp_get_ground_track | Get subsatellite points |
| mcp_localize_uav | Estimate UAV position from image |
| mcp_enhance_image | Apply super-resolution |
| mcp_visualize | Create visualizations |

## Key Algorithms

### UAV Localization (Paper 1)
- CLIP-based image-location matching
- Equal Earth Projection for GPS encoding
- Heading estimation from image orientation
- Target: ~40m position error, ~16° heading error

### Super-Resolution (Paper 2)
- Edge-based wavelet transform (EBWT)
- Canny edge detection + DWT decomposition
- Multi-modal feature fusion
- Target: +0.67 dB PSNR improvement

## See Also
- `tasks.md` - Detailed task tracking
- `demos/` - Working examples
