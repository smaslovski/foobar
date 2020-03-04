typedef unsigned char byte;

/* Detect if a file has a +3DOS header. 
 *
 * Returns -1 if file cannot be opened.
 *          0 if no +3DOS header
 *          1 if +3DOS header
 *
 *  If 'header' is not null, it will be treated as a 128-byte buffer that
 *  will be populated with the +3DOS header (if any) of the file.
 */
int is3dos(const char *filename, byte *header);

/* Open a TAP file. 
 *
 * Pass filename and mode (rb or r+b). 
 * On return, is_zxt will be 1 if the file is ZXT, 0 if TAP.
 *            taplen will be the length of the file including any +3DOS header
 */
FILE *opentap(const char *filename, const char *mode, int *is_zxt, long *taplen);

/* For some reason best known to Hi-Tech, the Pacific C headers don't
 * include these macros */
#ifndef SEEK_SET
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
#endif

