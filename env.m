
pth = fileparts(mfilename('fullpath'));

rmpath(pth); 
rmpath([pth, '/mex']);
rmpath([pth, '/core']);
rmpath([pth, '/utils']);
rmpath([pth, '/tools']);
rmpath([pth, '/utils/KPMstats']);
rmpath([pth, '/utils/Kalman']);


addpath(pth);
addpath([pth, '/mex']);
addpath([pth, '/core']);
addpath([pth, '/utils']);
addpath([pth, '/tools']);
addpath([pth, '/utils/KPMstats']);
addpath([pth, '/utils/Kalman']);