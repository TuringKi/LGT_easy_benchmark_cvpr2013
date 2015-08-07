function [wc] = wcov(values, weights)

weights = normalize(weights);

if (any( weights == 1))
    wc = 0;
    return;
end;

[x y] = size(values);

xc = bsxfun(@minus,values,wmean(values, weights));  % Remove mean

wc = (xc' * (xc .* (weights * ones(1, y)))) ./ (1 - sum(weights .^ 2));


