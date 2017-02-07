//////////////////////////////////////////////////////////////////////////
// Creates C++ MEX-file for OpenCV routine matchTemplate. 
// Here matchTemplate uses normalized cross correlation method to search 
// for matches between an image patch and an input image.
//
// Copyright 2014 The MathWorks, Inc.
//////////////////////////////////////////////////////////////////////////

#include "opencvmex.hpp"

#define _DO_NOT_EXPORT
#if defined(_DO_NOT_EXPORT)
#define DllExport  
#else
#define DllExport __declspec(dllexport)
#endif

///////////////////////////////////////////////////////////////////////////
// Check inputs
///////////////////////////////////////////////////////////////////////////
void checkInputs(int nrhs, const mxArray *prhs[])
{       
    // Check number of inputs
    if (nrhs != 1)
    {
        mexErrMsgTxt("Incorrect number of inputs. Function expects 1 inputs.");
    }
    
    if (mxGetNumberOfDimensions(prhs[0])>2)
    {
        mexErrMsgTxt("Incorrect number of dimensions. Input must be a 2d image matrix.");
    }   
    
    // Check image data type
    if (!mxIsUint8(prhs[0]))
    {
        mexErrMsgTxt("Template and image must be UINT8.");
    }
}

///////////////////////////////////////////////////////////////////////////
// Main entry point to a MEX function
///////////////////////////////////////////////////////////////////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{  
    // Check inputs to mex function
    checkInputs(nrhs, prhs);
   
    // Convert mxArray inputs into OpenCV types
    cv::Ptr<cv::Mat> imgCV = ocvMxArrayToImage_uint8(prhs[0], true);
    
    cv::Mat imgLap(imgCV->rows, imgCV->cols, CV_8U);
    
    cv::Laplacian(*imgCV, imgLap, CV_8U, 3);
    cv::Mat mean, stddev;
    cv::meanStdDev(imgLap, mean, stddev);
    cv::Mat variance(1,1,CV_32F);
    cv::pow(stddev, 2, variance);
    
    // Put the data back into the output MATLAB array
    plhs[0] = ocvMxArrayFromMat_double(variance);
}