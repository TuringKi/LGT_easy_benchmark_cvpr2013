function [new, mask] = patchOperation(matrix, patch, point, operation, debug)

if nargin < 5
    debug = 0;
end;

if nargin < 4
    operation = '+';
end;

[w1, h1, d2] = size(matrix);
[w2, h2, d2] = size(patch);

point = int16(point);

xd1 = uint16(min([w1, max([point(1), 1])]));
xd2 = uint16(min([w1, max([point(1) + w2 - 1, 1])]));
yd1 = uint16(min([h1, max([point(2), 1])]));
yd2 = uint16(min([h1, max([point(2) + h2 - 1, 1])])); 

xs1 = uint16(min([w2, max([-point(1) + 2, 1])]));
xs2 = uint16(min([w2, max([-point(1) + w1 + 1, 1])]));
ys1 = uint16(min([h2, max([-point(2) + 2, 1])]));
ys2 = uint16(min([h2, max([-point(2) + h1 + 1, 1])])); 

if (xd1 > xd2 || yd1 > yd2)
    new = matrix;
    return;
end;

new = matrix;

% [a1, b1] = size(new(xd1:xd2, yd1:yd2));
% [a2, b2] = size(patch(xs1:xs2, ys1:ys2));
% 
% if (a1 ~= a2 || b1 ~= b2)
%     [w1 w2 h1 h2]
%     point
%     [xd1 xd2 yd1 yd2]
%     [xs1 xs2 ys1 ys2]
%     [a1 a2 b1 b2]
% end;

if debug
    disp('Debug info');
    [xd1 xd2 yd1 yd2]
    [xs1 xs2 ys1 ys2]
    point
    [w1 w2 h1 h2]
    [a1, b1] = size(new(xd1:xd2, yd1:yd2));
    [a2, b2] = size(patch(xs1:xs2, ys1:ys2));
    [a1 a2 b1 b2]
end;

switch (operation)
    case '-'
        new(xd1:xd2, yd1:yd2, :) = new(xd1:xd2, yd1:yd2, :) - patch(xs1:xs2, ys1:ys2, :);
    case '+'
        new(xd1:xd2, yd1:yd2, :) = new(xd1:xd2, yd1:yd2, :) + patch(xs1:xs2, ys1:ys2, :);
    case '*'
        new(xd1:xd2, yd1:yd2, :) = new(xd1:xd2, yd1:yd2, :) .* patch(xs1:xs2, ys1:ys2, :);
    case '/'
        new(xd1:xd2, yd1:yd2, :) = new(xd1:xd2, yd1:yd2, :) ./ patch(xs1:xs2, ys1:ys2, :);
    case '='
        new(xd1:xd2, yd1:yd2, :) = patch(xs1:xs2, ys1:ys2, :);
    case '<'
        new(xd1:xd2, yd1:yd2, :) = (new(xd1:xd2, yd1:yd2, :) - patch(xs1:xs2, ys1:ys2, :)) > 0;
end;

if (nargout > 1)
    mask = zeros(w1, h1);
    mask(xd1:xd2, yd1:yd2) = 1;
end;

