function r_ecef = eci_to_ecef(r_eci, theta)
%ECI_TO_ECEF Convert ECI coordinates to ECEF
%
%   r_ecef = eci_to_ecef(r_eci, theta) converts position vector from
%   Earth-Centered Inertial (ECI) to Earth-Centered Earth-Fixed (ECEF)
%   frame.
%
%   Inputs:
%       r_eci - Position vector in ECI frame [km] (3x1 or 3xN)
%       theta - Greenwich Mean Sidereal Time angle [rad]
%
%   Output:
%       r_ecef - Position vector in ECEF frame [km] (3x1 or 3xN)
%
%   The transformation accounts for Earth's rotation:
%       r_ecef = Rz(-theta) * r_eci
%
%   See also: ecef_to_eci, ecef_to_lla, lla_to_ecef

% Rotation matrix about z-axis (Earth rotation)
c = cos(theta);
s = sin(theta);

Rz = [c,  s, 0;
     -s,  c, 0;
      0,  0, 1];

% Transform
r_ecef = Rz * r_eci;

end
