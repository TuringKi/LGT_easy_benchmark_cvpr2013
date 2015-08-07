% Calculates 2D weighted affine transform
%
% Input parameters: P1 - first set of points (nx2)
%                   P2 - second set of points (nx2)
%
% Output: T - 3x3 transformation matrix
%
function [T] = waffine(P1, P2, w)

% take the minimum amount of available points
p = min([size(P1, 1), size(P2, 1)]);

if (p < 3)
    error('At least three points required.');
end;

A = zeros(2*p, 6);
b = zeros(2*p, 1);

for i = 1:p
    A(i*2-1, :) = [P1(i, 1), P1(i, 2), 0, 0, 1, 0];
    A(i*2, :) = [0, 0, P1(i, 1), P1(i, 2), 0, 1];
    b(i*2-1) = P2(i, 1);
    b(i*2) = P2(i, 2);
end;
we = ([1; 1] * w');
% solve system
x = lscov(A,b, we(:));

% build the transformation matrix
T = [x(1) x(2) x(5); x(3) x(4) x(6); 0 0 1];
