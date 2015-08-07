function [bp] = backproject(image, histogram)

[w, h, idim] = size(image);

s = size(histogram);

if (s(end) == 1 && length(s) > 1)
    hdim = length(s) - 1;
else
    hdim = length(s);
end;

if (hdim ~= idim)
    error('Dimensions do not match');
end;

switch hdim
    
    case 3

        I = [image(1:end/3); image(end/3+1:(end/3)*2); image((end/3)*2+1:end)] + 1;

        bp = reshape(histogram(sub2ind(size(histogram), ...
            I(1, :), I(2, :), I(3, :))), w, h);
    
    case 2

        I = [image(1:end/2); image(end/2+1:end)] + 1;

        bp = reshape(histogram(sub2ind(size(histogram), ...
            I(1, :), I(2, :))), w, h);
    
    
    case 1
    bp = histogram(image);
    
    otherwise
        bp = [];
end;

