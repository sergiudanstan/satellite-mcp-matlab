# Satellite MCP MATLAB - Tasks

Based on research papers:
1. **GNSS-denied UAV Localization** (satel.pdf) - Image-based positioning
2. **EBWT-SR** (satelit.pdf) - Satellite image super-resolution

---

## Phase 1: Core Infrastructure
- [ ] Create setup_paths.m
- [ ] Create Satellite.m class (orbital elements, state vectors)
- [ ] Create leo_sat_params.m (ISS-like orbit)
- [ ] Create geo_sat_params.m (geostationary)
- [ ] Create UAV.m class (position, heading, camera)

## Phase 2: Orbital Mechanics & Ground Track
- [ ] Implement kepler_propagate.m (two-body problem)
- [ ] Implement ground_track.m (subsatellite point)
- [ ] Implement eci_to_ecef.m (coordinate transform)
- [ ] Implement lla_to_ecef.m (lat/lon/alt conversion)
- [ ] Create plot_orbit_3d.m (3D visualization with Earth)
- [ ] Create plot_ground_track.m (2D world map overlay)
- [ ] Create demo_ground_track.m

## Phase 3: UAV-Satellite Localization (Paper 1)
- [ ] Implement image_matcher.m (feature extraction)
- [ ] Implement location_encoder.m (Equal Earth Projection + RFF)
- [ ] Implement heading_estimator.m (orientation from similarity)
- [ ] Implement similarity_matrix.m (image-location correlation)
- [ ] Create demo_uav_localization.m

## Phase 4: Image Super-Resolution (Paper 2)
- [ ] Implement edge_detector.m (Canny edge detection)
- [ ] Implement wavelet_transform.m (DWT: LL, LH, HL, HH)
- [ ] Implement super_resolution.m (edge-wavelet fusion)
- [ ] Implement image_quality.m (PSNR, SSIM metrics)
- [ ] Create demo_super_resolution.m

## Phase 5: MCP Integration
- [ ] Create satellite_mcp_tools.m (singleton manager)
- [ ] Create mcp_list_satellites.m
- [ ] Create mcp_load_satellite.m
- [ ] Create mcp_propagate_orbit.m
- [ ] Create mcp_get_ground_track.m
- [ ] Create mcp_localize_uav.m
- [ ] Create mcp_enhance_image.m
- [ ] Create mcp_visualize.m
- [ ] Create satellite_dashboard.m (interactive GUI)
- [ ] Create demo_mcp_interaction.m

---

## Key Equations (from Papers)

### UAV Localization (Paper 1)
- Equal Earth Projection for GPS coordinates
- Feature Similarity Matrix: `FSM = β * F_image · F_location'`
- Heading normalization: `H_norm = 0.00025(sin(θ) + 1)`

### Super-Resolution (Paper 2)
- Wavelet decomposition: LL, LH, HL, HH sub-bands
- Multi-modal fusion: `F = Canny_edges + Σ Wavelet_coefficients`
- Quality metrics: PSNR, SSIM, LPIPS

---

## Progress Log

| Date | Task | Status |
|------|------|--------|
| | | |
