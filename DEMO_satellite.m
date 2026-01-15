function DEMO_satellite()
%DEMO_SATELLITE Unified Satellite MCP Dashboard
%
%   DEMO_satellite() launches an interactive dashboard for satellite
%   simulation with MCP integration.
%
%   Features:
%       - Satellite selection (LEO/GEO)
%       - Ground track visualization
%       - 3D orbit visualization
%       - UAV localization demo
%       - Image super-resolution demo
%       - Animation controls
%       - Screenshot/video recording
%
%   Usage:
%       setup_paths;     % Initialize paths first
%       DEMO_satellite;  % Launch dashboard
%
%   See also: satellite_mcp_tools, mcp_list_satellites, mcp_load_satellite

%% Setup
clear global DEMO_DATA;
global DEMO_DATA;

% Initialize paths if not done
if ~exist('Satellite', 'class')
    setup_paths;
end

% Reset MCP tools
satellite_mcp_tools.resetInstance();

% Initialize data structure
DEMO_DATA = struct();
DEMO_DATA.sat_id = '';
DEMO_DATA.track = [];
DEMO_DATA.is_animating = false;
DEMO_DATA.animation_timer = [];

%% Create Main Figure
fig = figure('Name', 'Satellite MCP Dashboard', ...
    'NumberTitle', 'off', ...
    'Position', [50, 50, 1400, 800], ...
    'Color', [0.94 0.94 0.94], ...
    'MenuBar', 'none', ...
    'ToolBar', 'figure', ...
    'CloseRequestFcn', @closeCallback);

DEMO_DATA.fig = fig;

%% Create Layout
% Left panel - Controls
ctrl_panel = uipanel(fig, 'Title', 'Controls', ...
    'Position', [0.01 0.01 0.22 0.98], ...
    'BackgroundColor', [0.94 0.94 0.94]);

% Right panel - Visualization
vis_panel = uipanel(fig, 'Title', 'Visualization', ...
    'Position', [0.24 0.01 0.75 0.98], ...
    'BackgroundColor', 'white');

%% Control Panel Elements
y_pos = 0.94;
spacing = 0.05;

% Title
uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', 'Satellite MCP Tools', ...
    'FontSize', 14, 'FontWeight', 'bold', ...
    'Position', [10 y_pos*380 280 30], ...
    'BackgroundColor', [0.94 0.94 0.94]);
y_pos = y_pos - spacing;

% Satellite Selection
uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', 'Select Satellite:', ...
    'HorizontalAlignment', 'left', ...
    'Position', [10 y_pos*380 120 20], ...
    'BackgroundColor', [0.94 0.94 0.94]);
y_pos = y_pos - 0.04;

DEMO_DATA.sat_dropdown = uicontrol(ctrl_panel, 'Style', 'popupmenu', ...
    'String', {'LEO (Low Earth Orbit)', 'GEO (Geostationary)'}, ...
    'Position', [10 y_pos*380 280 25], ...
    'Callback', @satSelectCallback);
y_pos = y_pos - spacing;

% Load Satellite Button
uicontrol(ctrl_panel, 'Style', 'pushbutton', ...
    'String', 'Load Satellite', ...
    'Position', [10 y_pos*380 280 30], ...
    'FontSize', 10, ...
    'Callback', @loadSatelliteCallback);
y_pos = y_pos - spacing;

% Separator
uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', '________________________', ...
    'Position', [10 y_pos*380 280 20], ...
    'BackgroundColor', [0.94 0.94 0.94]);
y_pos = y_pos - spacing;

% Satellite Info Display
uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', 'Satellite Info:', ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', ...
    'Position', [10 y_pos*380 120 20], ...
    'BackgroundColor', [0.94 0.94 0.94]);
y_pos = y_pos - 0.03;

DEMO_DATA.info_text = uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', 'No satellite loaded', ...
    'HorizontalAlignment', 'left', ...
    'Position', [10 (y_pos-0.18)*380 280 100], ...
    'BackgroundColor', [0.96 0.96 0.96]);
y_pos = y_pos - 0.28;

% Separator
uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', '________________________', ...
    'Position', [10 y_pos*380 280 20], ...
    'BackgroundColor', [0.94 0.94 0.94]);
y_pos = y_pos - spacing;

% Duration Slider
uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', 'Simulation Duration (orbits):', ...
    'HorizontalAlignment', 'left', ...
    'Position', [10 y_pos*380 200 20], ...
    'BackgroundColor', [0.94 0.94 0.94]);
y_pos = y_pos - 0.04;

DEMO_DATA.duration_slider = uicontrol(ctrl_panel, 'Style', 'slider', ...
    'Min', 0.5, 'Max', 3, 'Value', 1, ...
    'Position', [10 y_pos*380 200 20], ...
    'Callback', @durationCallback);

DEMO_DATA.duration_label = uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', '1.0', ...
    'Position', [220 y_pos*380 60 20], ...
    'BackgroundColor', [0.94 0.94 0.94]);
y_pos = y_pos - spacing;

% Separator
uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', '________________________', ...
    'Position', [10 y_pos*380 280 20], ...
    'BackgroundColor', [0.94 0.94 0.94]);
y_pos = y_pos - spacing;

% Visualization Buttons
uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', 'Visualization:', ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', ...
    'Position', [10 y_pos*380 120 20], ...
    'BackgroundColor', [0.94 0.94 0.94]);
y_pos = y_pos - 0.04;

uicontrol(ctrl_panel, 'Style', 'pushbutton', ...
    'String', 'Show Ground Track', ...
    'Position', [10 y_pos*380 135 30], ...
    'Callback', @groundTrackCallback);

uicontrol(ctrl_panel, 'Style', 'pushbutton', ...
    'String', 'Show 3D Orbit', ...
    'Position', [155 y_pos*380 135 30], ...
    'Callback', @orbit3DCallback);
y_pos = y_pos - 0.05;

DEMO_DATA.animate_btn = uicontrol(ctrl_panel, 'Style', 'pushbutton', ...
    'String', 'Animate', ...
    'Position', [10 y_pos*380 135 30], ...
    'Callback', @animateCallback);

uicontrol(ctrl_panel, 'Style', 'pushbutton', ...
    'String', 'Stop Animation', ...
    'Position', [155 y_pos*380 135 30], ...
    'Callback', @stopAnimationCallback);
y_pos = y_pos - spacing * 1.5;

% Screenshot/Video
uicontrol(ctrl_panel, 'Style', 'pushbutton', ...
    'String', 'Save Screenshot', ...
    'Position', [10 y_pos*380 135 30], ...
    'Callback', @screenshotCallback);

uicontrol(ctrl_panel, 'Style', 'pushbutton', ...
    'String', 'Record Video', ...
    'Position', [155 y_pos*380 135 30], ...
    'Callback', @recordVideoCallback);
y_pos = y_pos - spacing * 1.5;

% MCP Commands Info
uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', 'MCP Commands:', ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', ...
    'Position', [10 y_pos*380 120 20], ...
    'BackgroundColor', [0.94 0.94 0.94]);
y_pos = y_pos - 0.04;

mcp_info = sprintf(['mcp_list_satellites()\n' ...
    'mcp_load_satellite(name)\n' ...
    'mcp_get_ground_track(id, dur)\n' ...
    'mcp_visualize(id, type)']);

uicontrol(ctrl_panel, 'Style', 'text', ...
    'String', mcp_info, ...
    'HorizontalAlignment', 'left', ...
    'FontName', 'FixedWidth', ...
    'FontSize', 8, ...
    'Position', [10 (y_pos-0.12)*380 280 80], ...
    'BackgroundColor', [0.96 0.96 0.96]);

%% Visualization Axes
DEMO_DATA.ax = axes(vis_panel, 'Position', [0.05 0.08 0.9 0.85]);
title(DEMO_DATA.ax, 'Select and load a satellite to begin');
axis(DEMO_DATA.ax, 'off');

% Status bar
DEMO_DATA.status = uicontrol(fig, 'Style', 'text', ...
    'String', 'Ready. Select a satellite and click "Load Satellite".', ...
    'Position', [10 5 1380 20], ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', [0.9 0.9 0.9]);

fprintf('\n=== Satellite MCP Dashboard ===\n');
fprintf('Select a satellite type and click "Load Satellite" to begin.\n\n');

end

%% Callback Functions

function satSelectCallback(~, ~)
    % Satellite selection changed
end

function loadSatelliteCallback(~, ~)
    global DEMO_DATA;

    % Get selection
    idx = get(DEMO_DATA.sat_dropdown, 'Value');
    names = {'leo', 'geo'};
    sat_name = names{idx};

    % Update status
    set(DEMO_DATA.status, 'String', sprintf('Loading %s satellite...', upper(sat_name)));
    drawnow;

    try
        % Load satellite via MCP
        DEMO_DATA.sat_id = mcp_load_satellite(sat_name);

        % Get info
        info = mcp_get_satellite_info(DEMO_DATA.sat_id);

        % Update info display
        info_str = sprintf(['Name: %s\n' ...
            'Altitude: %.0f km\n' ...
            'Period: %.1f min\n' ...
            'Inclination: %.1f deg\n' ...
            'Position: %.2f, %.2f'], ...
            info.name, info.altitude_km, info.period_min, ...
            info.i_deg, info.lat, info.lon);
        set(DEMO_DATA.info_text, 'String', info_str);

        % Compute initial ground track (1 orbit)
        duration = info.period_min * 60;  % Convert to seconds
        DEMO_DATA.track = mcp_get_ground_track(DEMO_DATA.sat_id, duration, 30);

        % Show ground track
        groundTrackCallback([], []);

        set(DEMO_DATA.status, 'String', sprintf('Loaded %s satellite (ID: %s)', info.name, DEMO_DATA.sat_id));

        fprintf('Satellite loaded: %s\n', info.name);
        fprintf('  Altitude: %.0f km\n', info.altitude_km);
        fprintf('  Period: %.1f minutes\n', info.period_min);
        fprintf('  Use MCP tools: mcp_get_ground_track(''%s'', duration)\n\n', DEMO_DATA.sat_id);

    catch ME
        set(DEMO_DATA.status, 'String', sprintf('Error: %s', ME.message));
        fprintf('Error loading satellite: %s\n', ME.message);
    end
end

function durationCallback(src, ~)
    global DEMO_DATA;
    val = get(src, 'Value');
    set(DEMO_DATA.duration_label, 'String', sprintf('%.1f', val));
end

function groundTrackCallback(~, ~)
    global DEMO_DATA;

    if isempty(DEMO_DATA.sat_id)
        set(DEMO_DATA.status, 'String', 'Please load a satellite first.');
        return;
    end

    set(DEMO_DATA.status, 'String', 'Computing ground track...');
    drawnow;

    try
        % Get duration from slider
        orbits = get(DEMO_DATA.duration_slider, 'Value');
        info = mcp_get_satellite_info(DEMO_DATA.sat_id);
        duration = orbits * info.period_min * 60;

        % Compute track
        DEMO_DATA.track = mcp_get_ground_track(DEMO_DATA.sat_id, duration, 30);

        % Clear axes and plot
        cla(DEMO_DATA.ax);
        options.ax = DEMO_DATA.ax;
        options.title = sprintf('%s Ground Track (%.1f orbits)', info.name, orbits);
        plot_ground_track(DEMO_DATA.track, options);

        set(DEMO_DATA.status, 'String', sprintf('Ground track computed: %d points over %.1f minutes', ...
            length(DEMO_DATA.track.time), duration/60));

    catch ME
        set(DEMO_DATA.status, 'String', sprintf('Error: %s', ME.message));
    end
end

function orbit3DCallback(~, ~)
    global DEMO_DATA;

    if isempty(DEMO_DATA.sat_id)
        set(DEMO_DATA.status, 'String', 'Please load a satellite first.');
        return;
    end

    set(DEMO_DATA.status, 'String', 'Rendering 3D orbit...');
    drawnow;

    try
        info = mcp_get_satellite_info(DEMO_DATA.sat_id);

        % Make sure we have track data
        if isempty(DEMO_DATA.track)
            orbits = get(DEMO_DATA.duration_slider, 'Value');
            duration = orbits * info.period_min * 60;
            DEMO_DATA.track = mcp_get_ground_track(DEMO_DATA.sat_id, duration, 30);
        end

        % Clear axes and plot 3D
        cla(DEMO_DATA.ax);
        options.ax = DEMO_DATA.ax;
        options.title = sprintf('%s 3D Orbit', info.name);
        plot_orbit_3d(DEMO_DATA.track, options);

        set(DEMO_DATA.status, 'String', '3D orbit rendered.');

    catch ME
        set(DEMO_DATA.status, 'String', sprintf('Error: %s', ME.message));
    end
end

function animateCallback(~, ~)
    global DEMO_DATA;

    if isempty(DEMO_DATA.sat_id)
        set(DEMO_DATA.status, 'String', 'Please load a satellite first.');
        return;
    end

    if DEMO_DATA.is_animating
        set(DEMO_DATA.status, 'String', 'Animation already running.');
        return;
    end

    set(DEMO_DATA.status, 'String', 'Animating ground track...');
    drawnow;

    try
        info = mcp_get_satellite_info(DEMO_DATA.sat_id);
        orbits = get(DEMO_DATA.duration_slider, 'Value');
        duration = orbits * info.period_min * 60;

        % Compute fresh track for animation
        DEMO_DATA.track = mcp_get_ground_track(DEMO_DATA.sat_id, duration, 30);

        % Clear axes
        cla(DEMO_DATA.ax);

        % Animate
        options.ax = DEMO_DATA.ax;
        options.animate = true;
        options.frame_delay = 0.03;
        options.title = sprintf('%s Ground Track (Animating)', info.name);

        DEMO_DATA.is_animating = true;
        plot_ground_track(DEMO_DATA.track, options);
        DEMO_DATA.is_animating = false;

        set(DEMO_DATA.status, 'String', 'Animation complete.');

    catch ME
        DEMO_DATA.is_animating = false;
        set(DEMO_DATA.status, 'String', sprintf('Error: %s', ME.message));
    end
end

function stopAnimationCallback(~, ~)
    global DEMO_DATA;
    DEMO_DATA.is_animating = false;
    set(DEMO_DATA.status, 'String', 'Animation stopped.');
end

function screenshotCallback(~, ~)
    global DEMO_DATA;

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    filename = fullfile(pwd, 'results', sprintf('satellite_screenshot_%s.png', timestamp));

    % Ensure results directory exists
    if ~exist(fullfile(pwd, 'results'), 'dir')
        mkdir(fullfile(pwd, 'results'));
    end

    try
        saveas(DEMO_DATA.fig, filename);
        set(DEMO_DATA.status, 'String', sprintf('Screenshot saved: %s', filename));
        fprintf('Screenshot saved: %s\n', filename);
    catch ME
        set(DEMO_DATA.status, 'String', sprintf('Error saving: %s', ME.message));
    end
end

function recordVideoCallback(~, ~)
    global DEMO_DATA;

    if isempty(DEMO_DATA.sat_id)
        set(DEMO_DATA.status, 'String', 'Please load a satellite first.');
        return;
    end

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    filename = fullfile(pwd, 'results', sprintf('satellite_video_%s.mp4', timestamp));

    % Ensure results directory exists
    if ~exist(fullfile(pwd, 'results'), 'dir')
        mkdir(fullfile(pwd, 'results'));
    end

    set(DEMO_DATA.status, 'String', 'Recording video...');
    drawnow;

    try
        info = mcp_get_satellite_info(DEMO_DATA.sat_id);
        orbits = get(DEMO_DATA.duration_slider, 'Value');
        duration = orbits * info.period_min * 60;

        % Compute track
        track = mcp_get_ground_track(DEMO_DATA.sat_id, duration, 30);

        % Create video writer
        v = VideoWriter(filename, 'MPEG-4');
        v.FrameRate = 30;
        open(v);

        % Animate and capture
        cla(DEMO_DATA.ax);
        hold(DEMO_DATA.ax, 'on');
        draw_world_map_simple(DEMO_DATA.ax);

        N = length(track.time);
        for k = 1:N
            % Update plot
            if k > 1
                plot(DEMO_DATA.ax, track.lon(k-1:k), track.lat(k-1:k), 'r-', 'LineWidth', 2);
            end

            % Current position marker
            if k > 1 && isvalid(DEMO_DATA.ax)
                delete(findobj(DEMO_DATA.ax, 'Tag', 'current_pos'));
            end
            plot(DEMO_DATA.ax, track.lon(k), track.lat(k), 'ro', ...
                'MarkerSize', 10, 'MarkerFaceColor', 'r', 'Tag', 'current_pos');

            title(DEMO_DATA.ax, sprintf('%s Ground Track - t=%.1f min', info.name, track.time(k)/60));

            drawnow;
            frame = getframe(DEMO_DATA.fig);
            writeVideo(v, frame);
        end

        close(v);
        hold(DEMO_DATA.ax, 'off');

        set(DEMO_DATA.status, 'String', sprintf('Video saved: %s', filename));
        fprintf('Video saved: %s\n', filename);

    catch ME
        set(DEMO_DATA.status, 'String', sprintf('Error recording: %s', ME.message));
    end
end

function closeCallback(~, ~)
    global DEMO_DATA;

    % Stop any animation
    if ~isempty(DEMO_DATA) && isfield(DEMO_DATA, 'is_animating')
        DEMO_DATA.is_animating = false;
    end

    % Close figure
    delete(gcf);
end

function draw_world_map_simple(ax)
    % Draw simple world map background
    fill(ax, [-180 180 180 -180], [-90 -90 90 90], [0.9 0.95 1], 'EdgeColor', 'none');
    plot(ax, [-180 180], [0 0], '-', 'Color', [0.5 0.5 0.5]);
    plot(ax, [0 0], [-90 90], '-', 'Color', [0.5 0.5 0.5]);
    axis(ax, 'equal');
    xlim(ax, [-180 180]);
    ylim(ax, [-90 90]);
    xlabel(ax, 'Longitude [deg]');
    ylabel(ax, 'Latitude [deg]');
    grid(ax, 'on');
end
