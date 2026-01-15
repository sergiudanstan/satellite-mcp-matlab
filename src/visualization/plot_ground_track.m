function h = plot_ground_track(track, options)
%PLOT_GROUND_TRACK Plot satellite ground track on world map
%
%   h = plot_ground_track(track) plots the ground track on a 2D world map.
%
%   h = plot_ground_track(track, options) uses additional options.
%
%   Inputs:
%       track   - Ground track struct from ground_track()
%       options - Optional struct with fields:
%           .ax          - Axes handle to plot on
%           .color       - Track color (default: 'r')
%           .linewidth   - Line width (default: 2)
%           .show_start  - Mark start position (default: true)
%           .show_current- Mark current position (default: true)
%           .title       - Plot title
%           .animate     - Animate the track (default: false)
%           .frame_delay - Animation delay [s] (default: 0.05)
%
%   Output:
%       h - Struct with graphics handles
%
%   See also: ground_track, plot_orbit_3d, Satellite

% Default options
if nargin < 2
    options = struct();
end

% Create figure if no axes provided
if isfield(options, 'ax') && isvalid(options.ax)
    ax = options.ax;
else
    figure('Name', 'Satellite Ground Track', 'Position', [100 100 1000 600]);
    ax = gca;
end

% Plot options
color = get_option(options, 'color', 'r');
linewidth = get_option(options, 'linewidth', 2);
show_start = get_option(options, 'show_start', true);
show_current = get_option(options, 'show_current', true);
animate = get_option(options, 'animate', false);
frame_delay = get_option(options, 'frame_delay', 0.05);

% Draw world map background
hold(ax, 'on');
draw_world_map(ax);

% Handle output struct
h = struct();
h.ax = ax;

% Split track at longitude discontinuities (wrap-around)
[segments, seg_idx] = split_track_at_discontinuity(track.lon);

if animate
    % Animated plotting
    h.track_lines = [];
    h.current_marker = [];

    for k = 1:length(track.lon)
        % Find which segment this point belongs to
        seg_num = find(seg_idx <= k, 1, 'last');
        start_idx = seg_idx(seg_num);
        end_idx = k;

        % Plot current segment up to this point
        if end_idx > start_idx
            lon_seg = track.lon(start_idx:end_idx);
            lat_seg = track.lat(start_idx:end_idx);

            if isempty(h.track_lines) || seg_num > length(h.track_lines)
                h.track_lines(seg_num) = plot(ax, lon_seg, lat_seg, '-', ...
                    'Color', color, 'LineWidth', linewidth);
            else
                set(h.track_lines(seg_num), 'XData', lon_seg, 'YData', lat_seg);
            end
        end

        % Update current position marker
        if show_current
            if isempty(h.current_marker) || ~isvalid(h.current_marker)
                h.current_marker = plot(ax, track.lon(k), track.lat(k), 'o', ...
                    'MarkerSize', 12, 'MarkerFaceColor', color, ...
                    'MarkerEdgeColor', 'w', 'LineWidth', 2);
            else
                set(h.current_marker, 'XData', track.lon(k), 'YData', track.lat(k));
            end
        end

        drawnow;
        pause(frame_delay);
    end
else
    % Static plotting - plot all segments
    h.track_lines = gobjects(length(segments), 1);
    for seg = 1:length(segments)
        idx_range = segments{seg};
        h.track_lines(seg) = plot(ax, track.lon(idx_range), track.lat(idx_range), '-', ...
            'Color', color, 'LineWidth', linewidth);
    end

    % Mark start position
    if show_start
        h.start_marker = plot(ax, track.lon(1), track.lat(1), 's', ...
            'MarkerSize', 12, 'MarkerFaceColor', 'g', ...
            'MarkerEdgeColor', 'w', 'LineWidth', 2);
    end

    % Mark current (end) position
    if show_current
        h.current_marker = plot(ax, track.lon(end), track.lat(end), 'o', ...
            'MarkerSize', 12, 'MarkerFaceColor', color, ...
            'MarkerEdgeColor', 'w', 'LineWidth', 2);
    end
end

% Set axis properties
axis(ax, 'equal');
xlim(ax, [-180 180]);
ylim(ax, [-90 90]);
xlabel(ax, 'Longitude [deg]');
ylabel(ax, 'Latitude [deg]');

if isfield(options, 'title')
    title(ax, options.title);
else
    title(ax, 'Satellite Ground Track');
end

grid(ax, 'on');
hold(ax, 'off');

end

%% Helper functions

function val = get_option(options, field, default)
    if isfield(options, field)
        val = options.(field);
    else
        val = default;
    end
end

function [segments, seg_idx] = split_track_at_discontinuity(lon)
    %SPLIT_TRACK_AT_DISCONTINUITY Split track where longitude wraps around

    N = length(lon);
    dlon = diff(lon);
    wrap_idx = find(abs(dlon) > 180);

    seg_idx = [1; wrap_idx + 1];
    segments = cell(length(seg_idx), 1);

    for k = 1:length(seg_idx)
        if k < length(seg_idx)
            segments{k} = seg_idx(k):(seg_idx(k+1)-1);
        else
            segments{k} = seg_idx(k):N;
        end
    end
end

function draw_world_map(ax)
    %DRAW_WORLD_MAP Draw simple world coastlines

    % Simple coastline data (approximate)
    % This creates a basic world outline - in production, use actual coastline data

    % Draw grid background
    fill(ax, [-180 180 180 -180], [-90 -90 90 90], [0.9 0.95 1], ...
        'EdgeColor', 'none');

    % Draw latitude/longitude grid
    for lat = -60:30:60
        plot(ax, [-180 180], [lat lat], ':', 'Color', [0.7 0.7 0.7]);
    end
    for lon = -150:30:150
        plot(ax, [lon lon], [-90 90], ':', 'Color', [0.7 0.7 0.7]);
    end

    % Draw equator
    plot(ax, [-180 180], [0 0], '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);

    % Draw prime meridian
    plot(ax, [0 0], [-90 90], '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);

    % Simple continent outlines (approximate polygons)
    % North America
    na_lon = [-170 -140 -125 -110 -100 -80 -65 -55 -80 -105 -125 -145 -165 -170];
    na_lat = [60 70 55 50 30 25 45 50 60 70 65 60 55 60];
    fill(ax, na_lon, na_lat, [0.7 0.85 0.7], 'EdgeColor', [0.4 0.6 0.4], 'LineWidth', 0.5);

    % South America
    sa_lon = [-80 -60 -35 -40 -55 -70 -75 -80];
    sa_lat = [10 5 -5 -25 -55 -45 -15 10];
    fill(ax, sa_lon, sa_lat, [0.7 0.85 0.7], 'EdgeColor', [0.4 0.6 0.4], 'LineWidth', 0.5);

    % Europe
    eu_lon = [-10 0 15 30 40 30 15 0 -10];
    eu_lat = [35 35 40 45 55 70 70 60 50];
    fill(ax, eu_lon, eu_lat, [0.7 0.85 0.7], 'EdgeColor', [0.4 0.6 0.4], 'LineWidth', 0.5);

    % Africa
    af_lon = [-15 10 40 50 35 10 -5 -15];
    af_lat = [35 35 25 10 -35 -35 5 35];
    fill(ax, af_lon, af_lat, [0.7 0.85 0.7], 'EdgeColor', [0.4 0.6 0.4], 'LineWidth', 0.5);

    % Asia
    as_lon = [40 60 80 100 120 140 145 130 105 80 60 40];
    as_lat = [40 40 25 20 25 35 50 70 75 70 65 55];
    fill(ax, as_lon, as_lat, [0.7 0.85 0.7], 'EdgeColor', [0.4 0.6 0.4], 'LineWidth', 0.5);

    % Australia
    au_lon = [115 150 155 145 130 115];
    au_lat = [-20 -20 -30 -40 -35 -20];
    fill(ax, au_lon, au_lat, [0.7 0.85 0.7], 'EdgeColor', [0.4 0.6 0.4], 'LineWidth', 0.5);
end
