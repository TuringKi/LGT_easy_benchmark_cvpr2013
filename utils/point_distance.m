function [d] = point_distance(positions, origin)
a = size(positions, 1);
d = zeros(a, 1);
for i = 1 :  a
    p1 = positions(i,:);
    d(i) = sqrt(sum((p1 - origin) .^ 2));
end
end