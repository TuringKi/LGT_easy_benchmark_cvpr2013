#if !defined(_PATCHES)
#define _PATCHES

#include <string>
#include <mex.h>
#include <matrix.h>


void assemble_histogram(unsigned char* mat_im, int &W, int &H, int &rX, int &rY, int &rW, int &rH, double* histogram, int&bins);

#endif // __SKINCOLOR_H__INCLUDED_
