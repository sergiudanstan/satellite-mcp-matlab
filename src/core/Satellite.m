classdef Satellite < handle
%SATELLITE Satellite class for orbital simulation
%
%   This class represents a satellite with Keplerian orbital elements
%   and provides methods for orbit propagation and state computation.
%
%   Properties (Orbital Elements):
%       a     - Semi-major axis [km]
%       e     - Eccentricity [-]
%       i     - Inclination [rad]
%       RAAN  - Right Ascension of Ascending Node [rad]
%       omega - Argument of perigee [rad]
%       nu    - True anomaly [rad]
%
%   Usage:
%       sat = Satellite('leo');           % Load from parameter file
%       sat = Satellite(params_struct);   % Load from struct
%       [r, v] = sat.get_state_vectors(); % Get position/velocity
%       sat.propagate(3600);              % Propagate 1 hour
%
%   See also: kepler_propagate, ground_track, satellite_mcp_tools

    properties
        name            % Satellite name

        % Keplerian orbital elements
        a               % Semi-major axis [km]
        e               % Eccentricity [-]
        i               % Inclination [rad]
        RAAN            % Right Ascension of Ascending Node [rad]
        omega           % Argument of perigee [rad]
        nu              % True anomaly [rad]

        % Time reference
        epoch           % Epoch time (datetime)
        elapsed_time    % Elapsed time since epoch [s]

        % Physical properties
        mass            % Satellite mass [kg]

        % Derived properties (computed on demand)
        params          % Original parameter struct
    end

    properties (Constant)
        % Earth constants
        MU_EARTH = 398600.4418;     % Earth gravitational parameter [km^3/s^2]
        R_EARTH = 6378.137;         % Earth equatorial radius [km]
        J2 = 1.08263e-3;            % J2 perturbation coefficient
        OMEGA_EARTH = 7.2921159e-5; % Earth rotation rate [rad/s]
    end

    methods
        function obj = Satellite(input)
            %SATELLITE Constructor
            %
            %   sat = Satellite(name) loads satellite from params file
            %   sat = Satellite(params) creates from parameter struct

            if nargin < 1
                input = 'leo';
            end

            if ischar(input) || isstring(input)
                % Load from parameter file
                obj.load_from_params(input);
            elseif isstruct(input)
                % Load from struct
                obj.load_from_struct(input);
            else
                error('Satellite:InvalidInput', ...
                    'Input must be a parameter name or struct');
            end

            % Initialize time
            if isempty(obj.epoch)
                obj.epoch = datetime('now', 'TimeZone', 'UTC');
            end
            obj.elapsed_time = 0;
        end

        function load_from_params(obj, name)
            %LOAD_FROM_PARAMS Load satellite from parameter file

            % Try to find parameter file
            param_func = [name '_sat_params'];
            if exist(param_func, 'file')
                params = feval(param_func);
            else
                % Check satellite_library folder
                param_file = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
                    'params', 'satellite_library', [name '_sat_params.m']);
                if exist(param_file, 'file')
                    run(param_file);
                    params = feval(param_func);
                else
                    error('Satellite:ParamsNotFound', ...
                        'Parameter file for "%s" not found', name);
                end
            end

            obj.load_from_struct(params);
        end

        function load_from_struct(obj, params)
            %LOAD_FROM_STRUCT Load satellite from parameter struct

            obj.params = params;
            obj.name = params.name;

            % Orbital elements
            obj.a = params.a;
            obj.e = params.e;
            obj.i = params.i;
            obj.RAAN = params.RAAN;
            obj.omega = params.omega;
            obj.nu = params.nu;

            % Optional properties
            if isfield(params, 'mass')
                obj.mass = params.mass;
            else
                obj.mass = 100; % Default 100 kg
            end

            if isfield(params, 'epoch')
                obj.epoch = params.epoch;
            end
        end

        function [r_eci, v_eci] = get_state_vectors(obj)
            %GET_STATE_VECTORS Compute position and velocity in ECI frame
            %
            %   [r, v] = sat.get_state_vectors() returns:
            %       r - Position vector [km] (3x1)
            %       v - Velocity vector [km/s] (3x1)

            % Compute orbital parameters
            p = obj.a * (1 - obj.e^2);  % Semi-latus rectum
            r_mag = p / (1 + obj.e * cos(obj.nu));  % Orbital radius

            % Position in perifocal frame
            r_pqw = r_mag * [cos(obj.nu); sin(obj.nu); 0];

            % Velocity in perifocal frame
            h = sqrt(obj.MU_EARTH * p);  % Specific angular momentum
            v_pqw = (obj.MU_EARTH / h) * [-sin(obj.nu); obj.e + cos(obj.nu); 0];

            % Rotation matrix from perifocal to ECI
            R = obj.perifocal_to_eci_matrix();

            % Transform to ECI
            r_eci = R * r_pqw;
            v_eci = R * v_pqw;
        end

        function [lat, lon, alt] = get_ground_position(obj, time_offset)
            %GET_GROUND_POSITION Get subsatellite point (lat, lon, alt)
            %
            %   [lat, lon, alt] = sat.get_ground_position() returns current position
            %   [lat, lon, alt] = sat.get_ground_position(dt) returns position at t+dt

            if nargin < 2
                time_offset = 0;
            end

            % Get ECI position
            if time_offset ~= 0
                % Temporarily propagate
                original_nu = obj.nu;
                obj.propagate(time_offset);
                [r_eci, ~] = obj.get_state_vectors();
                obj.nu = original_nu;
            else
                [r_eci, ~] = obj.get_state_vectors();
            end

            % Convert ECI to ECEF
            theta = obj.OMEGA_EARTH * (obj.elapsed_time + time_offset);
            r_ecef = eci_to_ecef(r_eci, theta);

            % Convert ECEF to geodetic
            [lat, lon, alt] = ecef_to_lla(r_ecef);
        end

        function T = get_period(obj)
            %GET_PERIOD Get orbital period [s]
            T = 2 * pi * sqrt(obj.a^3 / obj.MU_EARTH);
        end

        function n = get_mean_motion(obj)
            %GET_MEAN_MOTION Get mean motion [rad/s]
            n = sqrt(obj.MU_EARTH / obj.a^3);
        end

        function propagate(obj, dt)
            %PROPAGATE Propagate orbit forward in time
            %
            %   sat.propagate(dt) propagates the orbit by dt seconds
            %   using Keplerian two-body dynamics

            % Mean motion
            n = obj.get_mean_motion();

            % Current mean anomaly
            E = obj.true_to_eccentric_anomaly(obj.nu);
            M = E - obj.e * sin(E);

            % New mean anomaly
            M_new = M + n * dt;
            M_new = mod(M_new, 2*pi);

            % Solve Kepler's equation for new eccentric anomaly
            E_new = obj.solve_kepler(M_new);

            % New true anomaly
            obj.nu = obj.eccentric_to_true_anomaly(E_new);

            % Update elapsed time
            obj.elapsed_time = obj.elapsed_time + dt;
        end

        function reset(obj)
            %RESET Reset satellite to initial epoch
            obj.nu = obj.params.nu;
            obj.elapsed_time = 0;
        end

        function info = get_info(obj)
            %GET_INFO Get satellite information struct

            [r, v] = obj.get_state_vectors();
            [lat, lon, alt] = obj.get_ground_position();

            info.name = obj.name;
            info.a = obj.a;
            info.e = obj.e;
            info.i_deg = rad2deg(obj.i);
            info.RAAN_deg = rad2deg(obj.RAAN);
            info.omega_deg = rad2deg(obj.omega);
            info.nu_deg = rad2deg(obj.nu);
            info.period_min = obj.get_period() / 60;
            info.altitude_km = norm(r) - obj.R_EARTH;
            info.velocity_kms = norm(v);
            info.lat = lat;
            info.lon = lon;
            info.ground_alt = alt;
            info.elapsed_time_s = obj.elapsed_time;
        end
    end

    methods (Access = private)
        function R = perifocal_to_eci_matrix(obj)
            %PERIFOCAL_TO_ECI_MATRIX Rotation matrix from PQW to ECI

            cO = cos(obj.RAAN); sO = sin(obj.RAAN);
            co = cos(obj.omega); so = sin(obj.omega);
            ci = cos(obj.i); si = sin(obj.i);

            R = [cO*co - sO*so*ci, -cO*so - sO*co*ci,  sO*si;
                 sO*co + cO*so*ci, -sO*so + cO*co*ci, -cO*si;
                 so*si,             co*si,             ci];
        end

        function E = true_to_eccentric_anomaly(obj, nu)
            %TRUE_TO_ECCENTRIC_ANOMALY Convert true to eccentric anomaly
            E = 2 * atan(sqrt((1 - obj.e) / (1 + obj.e)) * tan(nu / 2));
            if E < 0
                E = E + 2*pi;
            end
        end

        function nu = eccentric_to_true_anomaly(obj, E)
            %ECCENTRIC_TO_TRUE_ANOMALY Convert eccentric to true anomaly
            nu = 2 * atan(sqrt((1 + obj.e) / (1 - obj.e)) * tan(E / 2));
            if nu < 0
                nu = nu + 2*pi;
            end
        end

        function E = solve_kepler(obj, M)
            %SOLVE_KEPLER Solve Kepler's equation using Newton-Raphson
            %   M = E - e*sin(E)

            % Initial guess
            if obj.e < 0.8
                E = M;
            else
                E = pi;
            end

            % Newton-Raphson iteration
            tol = 1e-10;
            max_iter = 50;
            for iter = 1:max_iter
                f = E - obj.e * sin(E) - M;
                fp = 1 - obj.e * cos(E);
                dE = f / fp;
                E = E - dE;
                if abs(dE) < tol
                    break;
                end
            end
        end
    end
end
