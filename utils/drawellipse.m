function [] = drawellipse(mean, covariance, color)

if any(eig(covariance) <=0)
    error('The covariance matrix must be positive definite (it has non-positive eigenvalues)')
end;

n=100; % Number of points around ellipse
p=0:pi/n:2*pi; % angles around a circle

[eigvec,eigval] = eig(covariance); % Compute eigen-stuff
xy = [cos(p'),sin(p')] * sqrt(eigval) * eigvec'; % Transformation
x = xy(:,1) + mean(1);
y = xy(:,2) + mean(2);

plot(y, x, 'color', color);