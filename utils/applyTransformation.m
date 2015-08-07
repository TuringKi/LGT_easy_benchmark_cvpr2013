function [t] = applyTransformation(points, A)

t = A * [points, ones(size(points, 1), 1)]';

t = t(1:2, :)';

