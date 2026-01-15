function [r_eci, v_eci, nu_new] = kepler_propagate(oe, dt, mu)
%KEPLER_PROPAGATE Propagate orbit using two-body Keplerian dynamics
%
%   [r, v, nu] = kepler_propagate(oe, dt) propagates orbital elements
%   forward by dt seconds.
%
%   [r, v, nu] = kepler_propagate(oe, dt, mu) uses custom gravitational
%   parameter mu.
%
%   Inputs:
%       oe - Orbital elements struct with fields:
%           .a     - Semi-major axis [km]
%           .e     - Eccentricity [-]
%           .i     - Inclination [rad]
%           .RAAN  - Right Ascension of Ascending Node [rad]
%           .omega - Argument of perigee [rad]
%           .nu    - True anomaly [rad]
%       dt - Time step [s]
%       mu - Gravitational parameter [km^3/s^2] (default: Earth)
%
%   Outputs:
%       r_eci  - Position vector in ECI [km] (3x1)
%       v_eci  - Velocity vector in ECI [km/s] (3x1)
%       nu_new - New true anomaly [rad]
%
%   See also: Satellite, ground_track

% Default Earth gravitational parameter
if nargin < 3
    mu = 398600.4418;  % km^3/s^2
end

% Extract orbital elements
a = oe.a;
e = oe.e;
inc = oe.i;
RAAN = oe.RAAN;
omega = oe.omega;
nu = oe.nu;

% Mean motion
n = sqrt(mu / a^3);

% Convert true anomaly to mean anomaly
E = true_to_eccentric(nu, e);
M = E - e * sin(E);

% Propagate mean anomaly
M_new = mod(M + n * dt, 2*pi);

% Solve Kepler's equation for new eccentric anomaly
E_new = solve_kepler_eq(M_new, e);

% Convert back to true anomaly
nu_new = eccentric_to_true(E_new, e);

% Compute state vectors at new position
p = a * (1 - e^2);  % Semi-latus rectum
r_mag = p / (1 + e * cos(nu_new));

% Position in perifocal frame
r_pqw = r_mag * [cos(nu_new); sin(nu_new); 0];

% Velocity in perifocal frame
h = sqrt(mu * p);
v_pqw = (mu / h) * [-sin(nu_new); e + cos(nu_new); 0];

% Rotation matrix from perifocal to ECI
R = perifocal_to_eci(RAAN, omega, inc);

% Transform to ECI
r_eci = R * r_pqw;
v_eci = R * v_pqw;

end

%% Helper functions

function E = true_to_eccentric(nu, e)
    %TRUE_TO_ECCENTRIC Convert true to eccentric anomaly
    E = 2 * atan(sqrt((1 - e) / (1 + e)) * tan(nu / 2));
    if E < 0
        E = E + 2*pi;
    end
end

function nu = eccentric_to_true(E, e)
    %ECCENTRIC_TO_TRUE Convert eccentric to true anomaly
    nu = 2 * atan(sqrt((1 + e) / (1 - e)) * tan(E / 2));
    if nu < 0
        nu = nu + 2*pi;
    end
end

function E = solve_kepler_eq(M, e)
    %SOLVE_KEPLER_EQ Solve Kepler's equation using Newton-Raphson

    % Initial guess
    if e < 0.8
        E = M;
    else
        E = pi;
    end

    % Newton-Raphson iteration
    tol = 1e-12;
    max_iter = 50;
    for iter = 1:max_iter
        f = E - e * sin(E) - M;
        fp = 1 - e * cos(E);
        dE = f / fp;
        E = E - dE;
        if abs(dE) < tol
            break;
        end
    end
end

function R = perifocal_to_eci(RAAN, omega, inc)
    %PERIFOCAL_TO_ECI Rotation matrix from perifocal to ECI frame

    cO = cos(RAAN); sO = sin(RAAN);
    co = cos(omega); so = sin(omega);
    ci = cos(inc); si = sin(inc);

    R = [cO*co - sO*so*ci, -cO*so - sO*co*ci,  sO*si;
         sO*co + cO*so*ci, -sO*so + cO*co*ci, -cO*si;
         so*si,             co*si,             ci];
end
