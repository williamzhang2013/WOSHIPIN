#include "pngfile.h"    // libpng only supports C
#include <stdio.h>
#include <stdlib.h>

/* write a png file */
void write_png(const char *file_name, png_byte *image, unsigned int width, unsigned int height, unsigned int bit_depth, unsigned int SamplesPerPixel) 
{
	FILE *fp;
	png_structp png_ptr;
	png_infop info_ptr;


	/* open the file */
	fp = fopen(file_name, "wb");
	if (fp == NULL)
	  return;

	/* Create and initialize the png_struct with the desired error handler
	 * functions.  If you want to use the default stderr and longjump method,
	 * you can supply NULL for the last three parameters.  We also check that
	 * the library version is compatible with the one used at compile time,
	 * in case we are using dynamically linked libraries.  REQUIRED.
	 */
	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

	if (png_ptr == NULL)
	{
		fclose(fp);
		return;
    }

	/* Allocate/initialize the image information data.  REQUIRED */
	info_ptr = png_create_info_struct(png_ptr);
	if (info_ptr == NULL)
	{
		fclose(fp);
		png_destroy_write_struct(&png_ptr,  (png_infopp)NULL);
		return;
	}

	/* Set error handling.  REQUIRED if you aren't supplying your own
	 * error hadnling functions in the png_create_write_struct() call.
	 */
	if (setjmp(png_ptr->jmpbuf))
    {
		/* If we get here, we had a problem reading the file */
		fclose(fp);
		png_destroy_write_struct(&png_ptr,  &info_ptr);
		return;
    }

	/* set up the output control if you are using standard C streams */
	png_init_io(png_ptr, fp);


	/* Set the image information here.  Width and height are up to 2^31,
	 * bit_depth is one of 1, 2, 4, 8, or 16, but valid values also depend on
	 * the color_type selected. color_type is one of PNG_COLOR_TYPE_GRAY,
	 * PNG_COLOR_TYPE_GRAY_ALPHA, PNG_COLOR_TYPE_PALETTE, PNG_COLOR_TYPE_RGB,
	 * or PNG_COLOR_TYPE_RGB_ALPHA.  interlace is either PNG_INTERLACE_NONE or
	 * PNG_INTERLACE_ADAM7, and the compression_type and filter_type MUST
	 * currently be PNG_COMPRESSION_TYPE_BASE and PNG_FILTER_TYPE_BASE. REQUIRED
	 */
	if(SamplesPerPixel == 1) {
	  /* we are dealing with a grayscale image */
	  png_set_IHDR(png_ptr, info_ptr, width, height, bit_depth, PNG_COLOR_TYPE_GRAY,
		   PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);
	}
	else if(SamplesPerPixel == 3) {
	  /* we are dealing with a color image */
	  png_set_IHDR(png_ptr, info_ptr, width, height, bit_depth, PNG_COLOR_TYPE_RGB,
		   PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);
	}

	/* TODO: PALETTE IMAGES
	 * set the palette if there is one.  REQUIRED for indexed-color images 
	 */
	/*
	  palette = (png_colorp)png_malloc(png_ptr, 256 * sizeof (png_color));
	  // ... set palette colors ... 
	  png_set_PLTE(png_ptr, info_ptr, palette, 256);
	*/


	/* Optionally write comments into the image 
	text_ptr[0].key = "Title";
	text_ptr[0].text = "Mona Lisa";
	text_ptr[0].compression = PNG_TEXT_COMPRESSION_NONE;
	text_ptr[1].key = "Author";
	text_ptr[1].text = "Leonardo DaVinci";
	text_ptr[1].compression = PNG_TEXT_COMPRESSION_NONE;
	text_ptr[2].key = "Description";
	text_ptr[2].text = "<long text>";
	text_ptr[2].compression = PNG_TEXT_COMPRESSION_zTXt;
	png_set_text(png_ptr, info_ptr, text_ptr, 3);
	*/

	/* Write the file header information.  REQUIRED */
	png_write_info(png_ptr, info_ptr);

	/* The easiest way to write the image (you may have a different memory
	 * layout, however, so choose what fits your needs best).  You need to
	 * use the first method if you aren't handling interlacing yourself.
	 */

	png_uint_32 k;
	//png_bytep row_pointers[height];
	png_bytep *row_pointers = (png_bytep *)malloc(height * sizeof(png_bytep *));
	
	for (k = 0; k < height; k++)
	  row_pointers[k] = (png_byte *)(image + k*width * SamplesPerPixel);

	png_write_image(png_ptr, row_pointers);
	png_write_flush(png_ptr);
	png_write_end(png_ptr, info_ptr);

	png_destroy_write_struct(&png_ptr, &info_ptr);
	fclose(fp);

	free(row_pointers);
}

