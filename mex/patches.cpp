
#include "patches.h"

void assemble_histogram(unsigned char* mat_im, int &W, int &H, int &rX, int &rY, int &rW, int &rH, double* histogram, int&bins)
{
	int rX2 = rX + rW - 1;
	int rY2 = rY + rH - 1;
	double N = 0;
	int i, j;
	int bin;

	rX = (rX < 0) ? 0 : rX;
	rY = (rY < 0) ? 0 : rY;
	rX2 = (rX2 >= W) ? W-1 : rX2;
	rY2 = (rY2 >= H) ? H-1 : rY2;

	//printf("%d %d %d %d \n", rX, rY, rX2, rY2);
	for (j = rY ; j <= rY2; j++) {
		for (i = rX ; i <= rX2; i++) {
			bin = (mat_im[j*W + i] * bins) >> 8;
			histogram[bin]++;
			N++;
		}
	}

	if (N)
		for (i = 0; i < bins; i++)
			histogram[i] /= N;
}

