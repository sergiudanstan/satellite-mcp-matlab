# Satellite MCP MATLAB - Tasks

Based on research papers:
1. **GNSS-denied UAV Localization** (satel.pdf) - Image-based positioning
2. **EBWT-SR** (satelit.pdf) - Satellite image super-resolution

---

## Phase 1: Core Infrastructure
- [x] Create setup_paths.m
- [x] Create Satellite.m class (orbital elements, state vectors)
- [x] Create leo_sat_params.m (ISS-like orbit)
- [x] Create geo_sat_params.m (geostationary)
- [ ] Create UAV.m class (position, heading, camera)

## Phase 2: Orbital Mechanics & Ground Track
- [x] Implement kepler_propagate.m (two-body problem)
- [x] Implement ground_track.m (subsatellite point)
- [x] Implement eci_to_ecef.m (coordinate transform)
- [x] Implement lla_to_ecef.m, ecef_to_lla.m (lat/lon/alt conversion)
- [x] Create plot_orbit_3d.m (3D visualization with Earth)
- [x] Create plot_ground_track.m (2D world map overlay)
- [x] Create DEMO_satellite.m (unified dashboard)

## Phase 3: UAV-Satellite Localization (Paper 1)
- [x] Implement image_matcher.m (feature extraction)
- [x] Implement location_encoder.m (Equal Earth Projection + RFF)
- [x] Implement heading_estimator.m (orientation from similarity)
- [x] Implement similarity_matrix.m (image-location correlation)

## Phase 4: Image Super-Resolution (Paper 2)
- [x] Implement edge_detector.m (Canny edge detection)
- [x] Implement wavelet_transform.m (DWT: LL, LH, HL, HH)
- [x] Implement super_resolution.m (EBWT-SR edge-wavelet fusion)
- [x] Implement image_quality.m (PSNR, SSIM, NCC metrics)

## Phase 5: MCP Integration
- [x] Create satellite_mcp_tools.m (singleton manager)
- [x] Create mcp_list_satellites.m
- [x] Create mcp_load_satellite.m
- [x] Create mcp_propagate_orbit.m
- [x] Create mcp_get_satellite_info.m
- [x] Create mcp_get_ground_track.m
- [x] Create mcp_localize_uav.m
- [x] Create mcp_enhance_image.m
- [x] Create mcp_visualize.m
- [x] Create DEMO_satellite.m (unified interactive dashboard)

## Phase 6: Git Repository
- [x] Initialize git repo
- [x] Create .gitignore
- [x] Create private GitHub repo
- [x] Push to remote

---

## Key Equations (from Papers)

### UAV Localization (Paper 1)
- Equal Earth Projection for GPS coordinates
- Feature Similarity Matrix: `FSM = β * F_image · F_location'`
- Heading normalization: `H_norm = 0.00025(sin(θ) + 1)`

### Super-Resolution (Paper 2)
- Wavelet decomposition: LL, LH, HL, HH sub-bands
- Multi-modal fusion: `F = Canny_edges + Σ Wavelet_coefficients`
- Quality metrics: PSNR, SSIM, NCC

---

## Progress Log

| Date | Task | Status |
|------|------|--------|
| 2026-01-15 | Initial project setup and core infrastructure | Complete |
| 2026-01-15 | Orbital mechanics and visualization | Complete |
| 2026-01-15 | MCP tools integration | Complete |
| 2026-01-15 | Image processing (EBWT-SR, localization) | Complete |
| 2026-01-15 | DEMO_satellite unified dashboard | Complete |
