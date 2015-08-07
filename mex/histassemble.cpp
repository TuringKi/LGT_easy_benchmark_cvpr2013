
// mex -L . -lpatches histassemble.cpp
// gcc -I /opt/matlab/extern/include -L/opt/matlab/bin/glnx86 -lmx -lmex -lmat -lm patches.cpp -shared -o libpatches.so -L .

#include <stdio.h>
#include <ctype.h>
#include <time.h>
#include <string>
#include "mex.h"
#include "matrix.h"
#include "patches.h"

using namespace std;


void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[] ) {
	int N_dims, W, H, N;

	if( nrhs < 3 ) mexErrMsgTxt("Three input argument required.");
	if( nlhs < 1 ) mexErrMsgTxt("One output argument required.");

	if (mxGetClassID(prhs[0]) != mxUINT8_CLASS)
		mexErrMsgTxt("The first input image must be uint8");
	
	if (mxGetClassID(prhs[1]) != mxINT32_CLASS)
		mexErrMsgTxt("The second input image must be uint32");

	N_dims = mxGetNumberOfDimensions(prhs[0]);
	if ( N_dims > 2 ) mexErrMsgTxt("The first input image must be single channel");
	W = mxGetM(prhs[0]);
	H = mxGetN(prhs[0]);

	N_dims = mxGetNumberOfDimensions(prhs[1]);
	if ( N_dims > 2 ) mexErrMsgTxt("The first input image must be single channel");
	N = mxGetM(prhs[1]);
	if (mxGetN(prhs[1]) != 4)
		mexErrMsgTxt("Four coordinates required");

	int bins = (int)mxGetScalar(prhs[2]);
	int *points = (int*)mxGetPr(prhs[1]);

	double *histogram = new double[bins];

	plhs[0] = mxCreateDoubleMatrix(N, bins, mxREAL);
	double *result = (double*) mxGetPr(plhs[0]);

	for (int i = 0; i < N; i++) {
		int rX = points[i]-1;
		int rY = points[i+N]-1;
		int rW = points[i+N*2];
		int rH = points[i+N*3];
		for (int j = 0; j < bins; j++)
			histogram[j] = 0;
		assemble_histogram((unsigned char *)mxGetData(prhs[0]), W, H, rX, rY, rW, rH, histogram, bins);
		for (int j = 0; j < bins; j++) {
			//mexPrintf("\n %d %f", j, histogram[j]);
			result[i + j*N] = histogram[j];
		}
	}

	delete [] histogram;

}

