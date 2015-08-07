
// mex -L . -lpatches -lm histcompare.cpp

#include <stdio.h>
#include <ctype.h>
#include <time.h>
#include <string>
#include <math.h>
#include "mex.h"
#include "matrix.h"
#include "patches.h"

using namespace std;


void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[] ) {
	int N_dims, W, H, N, M;
	if( nrhs < 4 ) mexErrMsgTxt("Four input argument required.");
	if( nlhs < 1 ) mexErrMsgTxt("One output argument required.");

	if (mxGetClassID(prhs[0]) != mxUINT8_CLASS)
		mexErrMsgTxt("The first input image must be uint8");
	
	if (mxGetClassID(prhs[1]) != mxDOUBLE_CLASS)
		mexErrMsgTxt("The second input image must be uint32");

	if (mxGetClassID(prhs[2]) != mxINT32_CLASS)
		mexErrMsgTxt("The second input image must be uint32");

	N_dims = mxGetNumberOfDimensions(prhs[0]);
	if ( N_dims != 2 ) mexErrMsgTxt("The first input image must be single channel");
	W = mxGetM(prhs[0]);
	H = mxGetN(prhs[0]);

	int bins = (int)mxGetScalar(prhs[3]);

	N_dims = mxGetNumberOfDimensions(prhs[1]);
	if ( N_dims > 2 ) mexErrMsgTxt("The first input image must be single channel");
	N = mxGetM(prhs[1]);
	if (mxGetN(prhs[1]) != bins)
		mexErrMsgTxt("Bins!");

	N_dims = mxGetNumberOfDimensions(prhs[2]);
	if ( N_dims > 2 ) {
		if (N_dims != 3)
			mexErrMsgTxt("The first input image must be single channel");
		const mwSize *size = mxGetDimensions(prhs[2]);
		M = size[0];
		if (size[1] != 4)
			mexErrMsgTxt("Four coordinates required");
		if (N != size[2])
			mexErrMsgTxt("Illegal region number");
	} else {
		M = mxGetM(prhs[2]);
		if (mxGetN(prhs[2]) != 4)
			mexErrMsgTxt("Four coordinates required");
		if (N != 1)
			mexErrMsgTxt("Illegal histogram number");
	}



	double *histograms = (double *)mxGetPr(prhs[1]);
	int *points = (int*)mxGetPr(prhs[2]);

	double *histogram = new double[bins];

	plhs[0] = mxCreateDoubleMatrix(N, M, mxREAL);
	double *result = (double*) mxGetPr(plhs[0]);

	for (int k = 0; k < N; k++) {
		for (int i = 0; i < M; i++) {
			int rX = points[i + (k*4*M)]-1;
			int rY = points[i + (k*4*M)+M]-1;
			int rW = points[i + (k*4*M)+M*2];
			int rH = points[i + (k*4*M)+M*3];
//printf("%d %d %d %d \n", rX, rY, rW, rH);
			for (int j = 0; j < bins; j++)
				histogram[j] = 0;
			assemble_histogram((unsigned char *)mxGetData(prhs[0]), W, H, rX, rY, rW, rH, histogram, bins);
			double sum = 0;

			for (int j = 0; j < bins; j++) {
				sum += sqrt( histogram[j] * histograms[k + j*N]);
			}

			result[k + i*N] = sum;
		}
	}

	delete [] histogram;

}

