function h = plot_orbit_3d(track, options)
%PLOT_ORBIT_3D Plot 3D orbit around Earth
%
%   h = plot_orbit_3d(track) plots the orbit in 3D with Earth.
%
%   h = plot_orbit_3d(track, options) uses additional options.
%
%   Inputs:
%       track   - Ground track struct with r_eci field from ground_track()
%       options - Optional struct with fields:
%           .ax          - Axes handle to plot on
%           .color       - Orbit color (default: 'r')
%           .linewidth   - Line width (default: 2)
%           .show_earth  - Draw Earth sphere (default: true)
%           .show_axes   - Draw coordinate axes (default: true)
%           .animate     - Animate the orbit (default: false)
%           .title       - Plot title
%
%   Output:
%       h - Struct with graphics handles
%
%   See also: ground_track, plot_ground_track, Satellite

% Default options
if nargin < 2
    options = struct();
end

% Create figure if no axes provided
if isfield(options, 'ax') && isvalid(options.ax)
    ax = options.ax;
else
    figure('Name', 'Satellite 3D Orbit', 'Position', [100 100 900 700]);
    ax = axes;
end

% Plot options
color = get_option(options, 'color', 'r');
linewidth = get_option(options, 'linewidth', 2);
show_earth = get_option(options, 'show_earth', true);
show_axes = get_option(options, 'show_axes', true);
animate = get_option(options, 'animate', false);

% Earth radius
R_EARTH = 6378.137;  % km

% Handle output struct
h = struct();
h.ax = ax;

hold(ax, 'on');

% Draw Earth
if show_earth
    [X, Y, Z] = sphere(50);
    h.earth = surf(ax, R_EARTH*X, R_EARTH*Y, R_EARTH*Z, ...
        'FaceColor', [0.3 0.5 0.8], ...
        'EdgeColor', 'none', ...
        'FaceAlpha', 0.8, ...
        'FaceLighting', 'gouraud');

    % Add Earth texture (simplified with patches)
    % Add equator
    theta = linspace(0, 2*pi, 100);
    h.equator = plot3(ax, R_EARTH*cos(theta), R_EARTH*sin(theta), zeros(size(theta)), ...
        'Color', [0.2 0.2 0.2], 'LineWidth', 1);
end

% Draw coordinate axes
if show_axes
    axis_len = R_EARTH * 2;
    h.x_axis = quiver3(ax, 0, 0, 0, axis_len, 0, 0, 'r', 'LineWidth', 2, 'MaxHeadSize', 0.3);
    h.y_axis = quiver3(ax, 0, 0, 0, 0, axis_len, 0, 'g', 'LineWidth', 2, 'MaxHeadSize', 0.3);
    h.z_axis = quiver3(ax, 0, 0, 0, 0, 0, axis_len, 'b', 'LineWidth', 2, 'MaxHeadSize', 0.3);
    text(ax, axis_len*1.1, 0, 0, 'X', 'FontSize', 12, 'Color', 'r');
    text(ax, 0, axis_len*1.1, 0, 'Y', 'FontSize', 12, 'Color', 'g');
    text(ax, 0, 0, axis_len*1.1, 'Z', 'FontSize', 12, 'Color', 'b');
end

% Extract orbit coordinates
if isstruct(track) && isfield(track, 'r_eci')
    x = track.r_eci(1, :);
    y = track.r_eci(2, :);
    z = track.r_eci(3, :);
else
    error('track must be a struct with r_eci field from ground_track()');
end

if animate
    % Animated plotting
    h.orbit_line = animatedline(ax, 'Color', color, 'LineWidth', linewidth);
    h.sat_marker = plot3(ax, x(1), y(1), z(1), 'o', ...
        'MarkerSize', 15, 'MarkerFaceColor', color, ...
        'MarkerEdgeColor', 'w', 'LineWidth', 2);

    for k = 1:length(x)
        addpoints(h.orbit_line, x(k), y(k), z(k));
        set(h.sat_marker, 'XData', x(k), 'YData', y(k), 'ZData', z(k));
        drawnow;
        pause(0.02);
    end
else
    % Static plot
    h.orbit_line = plot3(ax, x, y, z, '-', 'Color', color, 'LineWidth', linewidth);

    % Mark current position
    h.sat_marker = plot3(ax, x(end), y(end), z(end), 'o', ...
        'MarkerSize', 15, 'MarkerFaceColor', color, ...
        'MarkerEdgeColor', 'w', 'LineWidth', 2);

    % Mark start position
    h.start_marker = plot3(ax, x(1), y(1), z(1), 's', ...
        'MarkerSize', 12, 'MarkerFaceColor', 'g', ...
        'MarkerEdgeColor', 'w', 'LineWidth', 2);
end

% Set axis properties
axis(ax, 'equal');
xlabel(ax, 'X [km]');
ylabel(ax, 'Y [km]');
zlabel(ax, 'Z [km]');

if isfield(options, 'title')
    title(ax, options.title);
else
    title(ax, '3D Satellite Orbit');
end

grid(ax, 'on');
view(ax, 30, 20);

% Add lighting
light('Position', [1 0.5 1], 'Style', 'infinite');
lighting gouraud;

hold(ax, 'off');

end

function val = get_option(options, field, default)
    if isfield(options, field)
        val = options.(field);
    else
        val = default;
    end
end
