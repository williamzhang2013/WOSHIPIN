#ifndef PNG_FILE_H
#define PNG_FILE_H

#include "png.h"
#include <stdio.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif
  

  /* write a png file */
  void write_png(const char *file_name, png_byte *image, unsigned int width, unsigned int height, unsigned int bit_depth, unsigned int SamplesPerPixel);



  
#ifdef __cplusplus
}		/* extern "C" */
#endif	/* __cplusplus */


#endif /* PNG_FILE */