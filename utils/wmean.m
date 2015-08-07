function [wm] = wmean(values, weights)

[x y] = size(values);

wm = sum(values .* (weights * ones(1, y))) ./ sum(weights);
