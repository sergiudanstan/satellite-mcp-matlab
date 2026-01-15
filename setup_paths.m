%% SETUP_PATHS - Initialize Satellite MCP MATLAB paths
%
% Run this script to add all necessary folders to the MATLAB path.
% This must be run before using any satellite simulation functions.
%
% Usage:
%   >> setup_paths
%   >> DEMO_satellite  % Launch the unified dashboard
%
% See also: DEMO_satellite, satellite_mcp_tools

% Get the root directory of the project
rootDir = fileparts(mfilename('fullpath'));

% Add all subdirectories to the path
addpath(rootDir);
addpath(fullfile(rootDir, 'src', 'core'));
addpath(fullfile(rootDir, 'src', 'orbital'));
addpath(fullfile(rootDir, 'src', 'localization'));
addpath(fullfile(rootDir, 'src', 'imaging'));
addpath(fullfile(rootDir, 'src', 'visualization'));
addpath(fullfile(rootDir, 'src', 'mcp_tools'));
addpath(fullfile(rootDir, 'params'));
addpath(fullfile(rootDir, 'params', 'satellite_library'));
addpath(fullfile(rootDir, 'data'));
addpath(fullfile(rootDir, 'tests'));

% Create output directories if they don't exist
resultsDir = fullfile(rootDir, 'results');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

dataDir = fullfile(rootDir, 'data');
if ~exist(fullfile(dataDir, 'satellite_maps'), 'dir')
    mkdir(fullfile(dataDir, 'satellite_maps'));
end
if ~exist(fullfile(dataDir, 'aerial_images'), 'dir')
    mkdir(fullfile(dataDir, 'aerial_images'));
end
if ~exist(fullfile(dataDir, 'test_images'), 'dir')
    mkdir(fullfile(dataDir, 'test_images'));
end

% Display confirmation
fprintf('Satellite MCP MATLAB paths initialized.\n');
fprintf('Root directory: %s\n', rootDir);
fprintf('\nAvailable commands:\n');
fprintf('  DEMO_satellite       - Launch unified dashboard\n');
fprintf('  mcp_list_satellites  - List available satellite models\n');
fprintf('  mcp_load_satellite   - Load a satellite model\n');
fprintf('  mcp_get_ground_track - Compute ground track\n');
fprintf('  mcp_localize_uav     - UAV position from image\n');
fprintf('  mcp_enhance_image    - Apply super-resolution\n');
fprintf('\n');
