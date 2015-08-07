Basic comments and instructions for running LGT example code. This version of
the tracking algorithm was published in IEEE Transactions on Pattern Analysis
and Machine Intelligence. Compared to the previous ICCV 2011 code this one is
cleaner and is also more true to the (updated) theory.

=== Release log ===

 * 18-03-2013 - Initial release

=== Regarding coding style ===

This code is not very nice and there are two reasons for that: 
    - it is an academic code (an excuse that it is just a test applies here)
    - it is written mostly in Matlab (yes, that is a reason)

If you would like to see a nice looking and fast code you will have to wait
for a C++ version. The code is actually ready but we cannot release it at the 
moment because of project negotiations. It is not entirely identical but it is
much nicer (and faster).

=== Compiling and running ===

Disclaimer: the code was developed and tested only on Linux based systems.

You need OpenCV installed (at the moment it works with version 2.1 and above).
The code was tested with Matlab versions 2009b, 2010b and 2012a. 
It does not work in Octave.

First go to the mex subfolder and run LGTCompileMex.m from Matlab. If your
OpenCV library is installed properly, you should get mex files. Add all 
the folders to Matlab path.

Download the test sequences from the webpage, extract them somewhere. In Matlab
set the sequence global variable to the path to the desired sequence and then
run LGTExample script to see an example of the tracking.

If you have any questions or problems contact me via luka.cehovin@fri.uni-lj.si

=== Citing ===

If you use this code in an academic paper you have to refer to it by citing the following
paper:

@article {cehovin2012tpami,
	author = {Luka \v{C}ehovin and Matej Kristan and Ale\v{s} Leonardis},
	journal = {Pattern Analysis and Machine Intelligence, IEEE Transactions on}, 
	title = {Robust Visual Tracking using an Adaptive Coupled-layer Visual Model},
	year = {2013},
	doi = {10.1109/TPAMI.2012.145},
	ISSN = {0162-8828},
	month = {April},
	volume = {35},
	number = {4},
	pages = {941-953}, 
}

