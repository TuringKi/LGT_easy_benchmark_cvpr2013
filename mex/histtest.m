

img = uint8(rand(200,200) * 255);

n = 1;
m = 10;
s = 6;

sreg = [];

sreg(1:n, 1) = rand(n, 1) * 150;
sreg(1:n, 2) = rand(n, 1) * 150;
sreg(1:n, 3) = s;
sreg(1:n, 4) = s;

b = histassemble(img, int32(sreg), 16);

reg = zeros(m, 4, n);

for i = 1:m
	reg(i, :) = sreg;
end;
r = histcompare(img, b, int32(reg), 16);
