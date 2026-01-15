classdef satellite_mcp_tools < handle
%SATELLITE_MCP_TOOLS MCP Tools for Satellite Simulation
%
%   This class provides a centralized interface for Claude AI to interact
%   with the satellite simulation through MCP (Model Context Protocol).
%
%   The class maintains a registry of loaded satellites and provides methods
%   for querying and manipulating them.
%
%   Usage:
%       tools = satellite_mcp_tools.getInstance();
%       sat_id = tools.load_satellite('leo');
%       track = tools.get_ground_track(sat_id, 3600);
%       tools.visualize(sat_id, 'ground_track');
%
%   Singleton Pattern:
%       This class uses the singleton pattern to maintain state across
%       multiple MCP tool calls within a session.
%
%   See also: mcp_list_satellites, mcp_load_satellite, mcp_get_ground_track

    properties (Access = private)
        satellites      % Map of sat_id -> Satellite objects
        sat_states      % Map of sat_id -> state info
        next_id         % Counter for generating unique IDs
    end

    methods (Access = private)
        function obj = satellite_mcp_tools()
            % Private constructor for singleton
            obj.satellites = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.sat_states = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.next_id = 1;
        end
    end

    methods (Static)
        function obj = getInstance()
            %GETINSTANCE Get singleton instance of satellite_mcp_tools
            persistent instance;
            if isempty(instance) || ~isvalid(instance)
                instance = satellite_mcp_tools();
            end
            obj = instance;
        end

        function resetInstance()
            %RESETINSTANCE Reset the singleton instance (for testing)
            persistent instance;
            if ~isempty(instance) && isvalid(instance)
                delete(instance);
            end
            instance = [];
        end
    end

    methods
        %% Satellite Management
        function satellites_info = list_satellites(obj)
            %LIST_SATELLITES List all available satellite models
            %
            %   satellites_info = tools.list_satellites() returns a struct array
            %   with information about available satellite models.

            satellites_info = struct('name', {}, 'description', {}, 'type', {}, 'altitude_km', {});

            % LEO satellite
            try
                params = leo_sat_params();
                satellites_info(end+1) = struct(...
                    'name', 'leo', ...
                    'description', params.description, ...
                    'type', 'LEO (Low Earth Orbit)', ...
                    'altitude_km', params.altitude);
            catch
            end

            % GEO satellite
            try
                params = geo_sat_params();
                satellites_info(end+1) = struct(...
                    'name', 'geo', ...
                    'description', params.description, ...
                    'type', 'GEO (Geostationary)', ...
                    'altitude_km', params.altitude);
            catch
            end

            % Check for additional parameter files
            param_dir = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
                'params', 'satellite_library');
            if exist(param_dir, 'dir')
                files = dir(fullfile(param_dir, '*_sat_params.m'));
                for k = 1:length(files)
                    name = strrep(files(k).name, '_sat_params.m', '');
                    if ~any(strcmp({satellites_info.name}, name))
                        try
                            params = feval([name '_sat_params']);
                            satellites_info(end+1) = struct(...
                                'name', name, ...
                                'description', params.description, ...
                                'type', 'Custom', ...
                                'altitude_km', params.altitude);
                        catch
                        end
                    end
                end
            end
        end

        function sat_id = load_satellite(obj, sat_name, options)
            %LOAD_SATELLITE Load a satellite model and return its ID
            %
            %   sat_id = tools.load_satellite(sat_name) loads the specified
            %   satellite and returns a unique identifier.

            if nargin < 3
                options = struct();
            end

            % Generate unique ID
            sat_id = sprintf('sat_%d', obj.next_id);
            obj.next_id = obj.next_id + 1;

            % Create satellite
            try
                sat = Satellite(sat_name);
                obj.satellites(sat_id) = sat;

                % Initialize state
                state.name = sat.name;
                state.loaded_at = datetime('now');
                state.last_track = [];
                obj.sat_states(sat_id) = state;

            catch ME
                error('satellite_mcp_tools:LoadError', ...
                    'Failed to load satellite %s: %s', sat_name, ME.message);
            end
        end

        function unload_satellite(obj, sat_id)
            %UNLOAD_SATELLITE Remove a satellite from the registry
            if obj.satellites.isKey(sat_id)
                obj.satellites.remove(sat_id);
                obj.sat_states.remove(sat_id);
            end
        end

        function ids = get_loaded_satellites(obj)
            %GET_LOADED_SATELLITES Get IDs of all loaded satellites
            ids = obj.satellites.keys();
        end

        function sat = get_satellite(obj, sat_id)
            %GET_SATELLITE Get the Satellite object for a satellite ID
            obj.validateSatelliteId(sat_id);
            sat = obj.satellites(sat_id);
        end

        %% State Queries
        function info = get_satellite_info(obj, sat_id)
            %GET_SATELLITE_INFO Get current satellite information

            obj.validateSatelliteId(sat_id);
            sat = obj.satellites(sat_id);
            info = sat.get_info();
            info.sat_id = sat_id;
        end

        function propagate(obj, sat_id, dt)
            %PROPAGATE Propagate satellite forward in time

            obj.validateSatelliteId(sat_id);
            sat = obj.satellites(sat_id);
            sat.propagate(dt);
        end

        function reset(obj, sat_id)
            %RESET Reset satellite to initial epoch

            obj.validateSatelliteId(sat_id);
            sat = obj.satellites(sat_id);
            sat.reset();
        end

        %% Ground Track
        function track = get_ground_track(obj, sat_id, duration, dt)
            %GET_GROUND_TRACK Compute ground track for satellite
            %
            %   track = tools.get_ground_track(sat_id, duration) computes
            %   the ground track for duration seconds.

            obj.validateSatelliteId(sat_id);
            sat = obj.satellites(sat_id);

            if nargin < 4
                dt = 60;  % Default 1 minute
            end

            track = ground_track(sat, duration, dt);

            % Store last track for visualization
            state = obj.sat_states(sat_id);
            state.last_track = track;
            obj.sat_states(sat_id) = state;
        end

        %% Visualization
        function h = visualize(obj, sat_id, vis_type, options)
            %VISUALIZE Create visualization of satellite
            %
            %   h = tools.visualize(sat_id, vis_type) creates visualization.
            %
            %   vis_type options:
            %       'ground_track' - 2D ground track on world map
            %       'orbit_3d'     - 3D orbit around Earth
            %       'info'         - Display satellite info

            obj.validateSatelliteId(sat_id);

            if nargin < 3
                vis_type = 'ground_track';
            end
            if nargin < 4
                options = struct();
            end

            sat = obj.satellites(sat_id);
            state = obj.sat_states(sat_id);

            switch lower(vis_type)
                case 'ground_track'
                    % Get or compute track
                    if isempty(state.last_track)
                        track = obj.get_ground_track(sat_id, sat.get_period(), 60);
                    else
                        track = state.last_track;
                    end

                    if ~isfield(options, 'title')
                        options.title = sprintf('%s Ground Track', sat.name);
                    end
                    h = plot_ground_track(track, options);

                case 'orbit_3d'
                    % Get or compute track
                    if isempty(state.last_track)
                        track = obj.get_ground_track(sat_id, sat.get_period(), 60);
                    else
                        track = state.last_track;
                    end

                    if ~isfield(options, 'title')
                        options.title = sprintf('%s 3D Orbit', sat.name);
                    end
                    h = plot_orbit_3d(track, options);

                case 'info'
                    info = sat.get_info();
                    h = display_sat_info(info);

                otherwise
                    error('satellite_mcp_tools:InvalidVisType', ...
                        'Unknown visualization type: %s', vis_type);
            end
        end

        %% UAV Localization
        function result = localize_uav(obj, sat_id, aerial_image, ref_database, options)
            %LOCALIZE_UAV Estimate UAV position from image matching
            %
            %   result = tools.localize_uav(sat_id, aerial_img, ref_db)
            %   estimates UAV position using image matching algorithm.
            %
            %   ref_database should be a struct with:
            %       .images    - Cell array of reference images
            %       .locations - Mx2 matrix of [lat, lon]

            obj.validateSatelliteId(sat_id);

            if nargin < 5
                options = struct();
            end

            try
                % Extract features from query image
                [query_features, ~] = image_matcher(aerial_image, options);

                % If ref_database is provided, use it
                if isstruct(ref_database) && isfield(ref_database, 'images')
                    % Extract features from all reference images
                    num_refs = length(ref_database.images);
                    ref_features = zeros(num_refs, length(query_features));

                    for i = 1:num_refs
                        [ref_features(i, :), ~] = image_matcher(ref_database.images{i}, options);
                    end

                    % Compute similarity and find best match
                    [~, best_match] = similarity_matrix(query_features, ref_features, ...
                        ref_database.locations, options);

                    result.estimated_lat = best_match.weighted_lat;
                    result.estimated_lon = best_match.weighted_lon;
                    result.confidence = best_match.confidence;

                    % Estimate heading if reference image available
                    best_ref_img = ref_database.images{best_match.index};
                    [heading, heading_conf] = heading_estimator(aerial_image, best_ref_img, options);
                    result.estimated_heading = heading;
                    result.heading_confidence = heading_conf;

                    result.message = 'UAV localization completed successfully';
                    result.best_match_index = best_match.index;
                    result.top_k = best_match.top_k_locations;
                else
                    % No reference database - return extracted features only
                    result.estimated_lat = 0;
                    result.estimated_lon = 0;
                    result.estimated_heading = 0;
                    result.confidence = 0;
                    result.features = query_features;
                    result.message = 'Features extracted. Provide reference database for localization.';
                end

            catch ME
                result.estimated_lat = 0;
                result.estimated_lon = 0;
                result.estimated_heading = 0;
                result.confidence = 0;
                result.message = sprintf('Localization error: %s', ME.message);
            end
        end

        %% Image Enhancement
        function [enhanced, metrics] = enhance_image(obj, image, options)
            %ENHANCE_IMAGE Apply super-resolution to satellite image
            %
            %   enhanced = tools.enhance_image(image) applies EBWT-SR
            %   super-resolution algorithm to enhance image quality.

            if nargin < 3
                options = struct();
            end

            % Use EBWT-SR super-resolution
            [enhanced, metrics] = super_resolution(image, options);
        end
    end

    methods (Access = private)
        function validateSatelliteId(obj, sat_id)
            %VALIDATESATELLITEID Check if sat_id is valid
            if ~obj.satellites.isKey(sat_id)
                error('satellite_mcp_tools:InvalidSatelliteId', ...
                    'Satellite ID "%s" not found. Use list_satellites() to see available satellites.', sat_id);
            end
        end
    end
end

%% Helper functions

function val = get_option(options, field, default)
    if isfield(options, field)
        val = options.(field);
    else
        val = default;
    end
end

function h = display_sat_info(info)
    %DISPLAY_SAT_INFO Display satellite information

    fprintf('\n=== Satellite Information ===\n');
    fprintf('Name:           %s\n', info.name);
    fprintf('Semi-major axis: %.2f km\n', info.a);
    fprintf('Eccentricity:   %.6f\n', info.e);
    fprintf('Inclination:    %.2f deg\n', info.i_deg);
    fprintf('RAAN:           %.2f deg\n', info.RAAN_deg);
    fprintf('Arg. Perigee:   %.2f deg\n', info.omega_deg);
    fprintf('True Anomaly:   %.2f deg\n', info.nu_deg);
    fprintf('Orbital Period: %.2f min\n', info.period_min);
    fprintf('Altitude:       %.2f km\n', info.altitude_km);
    fprintf('Velocity:       %.3f km/s\n', info.velocity_kms);
    fprintf('Ground Position: %.4f lat, %.4f lon\n', info.lat, info.lon);
    fprintf('=============================\n\n');

    h = [];
end
