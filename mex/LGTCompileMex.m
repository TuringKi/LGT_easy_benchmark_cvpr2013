
mex histassemble.cpp patches.cpp
mex histcompare.cpp patches.cpp
%mex -lopencv_video -lopencv_core OpticalFlowLKHier.cpp
mex ndHistc.c
mex -lopencv_core2410 -lopencv_video2410 -L"C:\lib\opencv\build\x64\vc10\lib" -I"C:\lib\opencv\build\include" OpticalFlowLKHier.cpp