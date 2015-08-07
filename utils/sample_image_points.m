function [values] = sample_image_points(image, center, mask)

values = [];
[w h d] = size(image);

[mw mh] = size(mask);

ox = int32(-ceil(mw / 2) + center(1));
oy = int32(-ceil(mh / 2) + center(2));

for i = 1:mw
    for j = 1:mh
        x = i + ox;
        y = j + oy;
        if (mask(i, j) &&  x > 0 && y > 0 && x <= w && y <= h)
            values(end+1, :) = image(x, y, :);
        end;
    end;
end;




