// ------------------------------------------------------------------------------
// NAME			: MEX_GetOpticalFlow.cpp
// AUTHOR		: Marco Zuliani
// DATE			: 02-05-06
// VERSION		: v1.0
// DESCRIPTION	: computes the optical flow at the specified points
// NOTES		: see MEX_GetOpticalFlow.m
// ------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////////
// Code conditional compilation falgs
////////////////////////////////////////////////////////////////////////////////////

//#define MEXGETOPTICALFLOW_DEBUG

////////////////////////////////////////////////////////////////////////////////////
// Internal constants
////////////////////////////////////////////////////////////////////////////////////
#define MEXGETOPTICALFLOW_MAX_ITERATIONS 20
#define MEXGETOPTICALFLOW_MAX_RESIDUE 1e5

////////////////////////////////////////////////////////////////////////////////////
// Includes
////////////////////////////////////////////////////////////////////////////////////


#include "opencv/cv.h"
#include "mex.h"


// TODO: Add you supporting functions here


//--------------------------------------------------------------
// function: MEX_GetOpticalFlow - Entry point from Matlab environment (via 
//   mexFucntion(), below)
// INPUTS:
//   nlhs - number of left hand side arguments (outputs)
//   plhs[] - pointer to table where created matrix pointers are
//            to be placed
//   nrhs - number of right hand side arguments (inputs)
//   prhs[] - pointer to table of input matrices
// 
//
// Parameters: first image, second image, x, y, window, levels
//
//
//
//--------------------------------------------------------------
void MEX_GetOpticalFlow( int nlhs, mxArray *plhs[], int nrhs, const mxArray  *prhs[] )
{
  	// Check for proper number of input and output arguments
	if(nrhs < 6) mexErrMsgTxt("6 input arguments required.");
	if(nlhs < 2) mexErrMsgTxt("2 output arguments required.");
	
	if (mxGetClassID(prhs[0]) != mxUINT8_CLASS)
		mexErrMsgTxt("The first input image must be uint8");
	
	if (mxGetClassID(prhs[1]) != mxUINT8_CLASS)
		mexErrMsgTxt("The second input image must be uint8");

	// get point data
	int N = mxGetN(prhs[2]);
	if ( N != mxGetN(prhs[3]) ) mexErrMsgTxt("X1 and X2_0 should have the same number of columns");

	// get image data
	int N_dims = mxGetNumberOfDimensions(prhs[0]);
	if ( N_dims > 2 ) mexErrMsgTxt("The first input image must be single channel");
	CvSize I1_size = cvSize(mxGetM(prhs[0]), mxGetN(prhs[0]));


	// create a IPL wrapper around the image passed from the workspace
	IplImage *I1 = cvCreateImageHeader(I1_size, IPL_DEPTH_8U, 1);
	// assign the pointer
	cvSetData(I1, mxGetData(prhs[0]), I1_size.width);

	N_dims = mxGetNumberOfDimensions(prhs[1]);
	if ( N_dims > 2 ) mexErrMsgTxt("The second input image must be single channel");
	CvSize I2_size = cvSize(mxGetM(prhs[1]), mxGetN(prhs[1]));

	// create a IPL wrapper around the image passed from the workspace
	IplImage *I2 = cvCreateImage(I2_size, IPL_DEPTH_8U, 1);
	// assign the pointer
	cvSetData(I2, mxGetData(prhs[1]), I2_size.width);

	// convert point coordinates to 32 bit floats 
	// (with index shift and axis exchange to adapt to OpenCv convention)
	CvPoint2D32f *X1 = (CvPoint2D32f *)mxCalloc(N, sizeof(CvPoint2D32f));
	CvPoint2D32f *X2 = (CvPoint2D32f *)mxCalloc(N, sizeof(CvPoint2D32f));

	double *ptr_X1 = mxGetPr(prhs[2]);
	double *ptr_Y1 = mxGetPr(prhs[3]);
	int h, k;
	for(k = 0, h = 0; h < N; h++)
	{
		X1[h].y = (float)ptr_X1[k]-1.0;
		X1[h].x = (float)ptr_Y1[k]-1.0;
		X2[h].y = (float)ptr_X1[k]-1.0;
		X2[h].x = (float)ptr_Y1[k++]-1.0;
	}

	// get the window semisize
	int win_semi_size = (int)mxGetScalar(prhs[4]);

	// get the number of pyramid levels
	int L = (int)mxGetScalar(prhs[5]);

#ifdef MEXGETOPTICALFLOW_DEBUG
	mexPrintf("\nComputing optical flow for %d points", N);
	mexPrintf("\nWindow size = %d pixels", 2*win_semi_size+1);
	mexPrintf("\nNumber of pyramid levels = %d", L);
	mexPrintf("\nI1(:)' = [%d %d %d %d...]", 
		(unsigned char)I1->imageData[0], 
		(unsigned char)I1->imageData[1], 
		(unsigned char)I1->imageData[2], 
		(unsigned char)I1->imageData[3]);
	mexPrintf("\nI2(:)' = [%d %d %d %d...]", 
		(unsigned char)I2->imageData[0], 
		(unsigned char)I2->imageData[1], 
		(unsigned char)I2->imageData[2], 
		(unsigned char)I2->imageData[3]);
#endif

	// prepare the output
	plhs[0] = mxCreateDoubleMatrix(2, N, mxREAL);
	int dims[2];
	dims[0] = 1;
	dims[1] = N;
	plhs[1] = mxCreateNumericArray(2, dims, mxLOGICAL_CLASS, mxREAL);

	// call OpenCV routine: we assume to have initial guesses for the  position of the points that will be tracked
	CvTermCriteria termination = 
		cvTermCriteria(CV_TERMCRIT_ITER | CV_TERMCRIT_EPS, 
		MEXGETOPTICALFLOW_MAX_ITERATIONS, 
		MEXGETOPTICALFLOW_MAX_RESIDUE);

	cvCalcOpticalFlowPyrLK(I1, I2, NULL, NULL, 
		X1, X2,
		N, cvSize(win_semi_size, win_semi_size), 
		L, (char *)mxGetData(plhs[1]), NULL, termination, CV_LKFLOW_INITIAL_GUESSES);

	// copy back the new position of the features
	double *ptr_X2 = mxGetPr(plhs[0]);
	for(k = 0, h = 0; h < N; h++)
	{
		ptr_X2[k++] = (float)X2[h].y+1.0;
		ptr_X2[k++] = (float)X2[h].x+1.0;
	}

	// free memory
	mxFree(X1);
	mxFree(X2);
	// do not remove the data! That's matlab's business
	cvReleaseImageHeader(&I1);
	cvReleaseImageHeader(&I2);
} // end MEX_GetOpticalFlow()


  //--------------------------------------------------------------
  // mexFunction - Entry point from Matlab. From this C function,
  //   simply call the C++ application function, above.
  //--------------------------------------------------------------
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[] )
{
   MEX_GetOpticalFlow(nlhs, plhs, nrhs, prhs);
}
