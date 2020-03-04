/************************************************************************

    TAPTOOLS v1.0.3 - Tapefile manipulation utilities

    Copyright (C) 1996, 2005  John Elliott <jce@seasip.demon.co.uk>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

*************************************************************************/

#include	<stdio.h>
#include	<string.h>
#include	<stdlib.h>
//#include "config.h"
//#ifdef HAVE_STAT_H
//#include        <stat.h>
//#endif
//#ifdef HAVE_SYS_STAT_H
#include        <sys/stat.h> 
//#endif
#include	"taputil.h"

/* Pacific C's stat() is declared to take char *, not const char *, so 
 * cast the first parameter if we're compiling with Pacific */
#ifdef __PACIFIC__
#define PACIFIC_CAST (char *)
#else
#define PACIFIC_CAST
#endif

int is3dos(const char *filename, byte *b)
{
	FILE *fp;
	int n,m;
	byte tmp[128];

	if (!b) b = tmp;
	if (!(fp = fopen(filename,"rb"))) return -1;

	if (fread(b,1,128,fp) < 128)
	{
		fclose(fp);
		return 0;
	}
	fclose(fp);

	if (memcmp(b,"PLUS3DOS\032",9)) return 0;

	for (m=n=0;n<127;n++) m+=b[n];

	return ((m & 0xFF) == b[n]);
}


FILE *opentap(const char *filename, const char *mode, int *is_zxt, long *taplen)
{
	unsigned char header[128];
	int zxt = 0;
	long len = 0;
	FILE *fp;

	switch(is3dos(filename, header))
	{
		case 1:  if (!memcmp(header+15, "TAPEFILE", 8))
			 {
/* Check for a tapefile with a +3DOS header. If found, get file length from
 * the +3DOS header because the actual file length is likely to be rounded up
 * to the nearest 128 bytes. */
				zxt = 1;	
				len =  (unsigned long)header[11]
				    + ((unsigned long)header[12] << 8)
				    + ((unsigned long)header[13] << 16)
				    + ((unsigned long)header[14] << 24);
				break;
			 }
			/* Not .ZXT format - FALL THROUGH */
		case 0:
			 {
				struct stat st;
				if (stat(PACIFIC_CAST filename, &st))
				{
					return NULL;
				}
				len = st.st_size;
				zxt = 0;
			 }
			 break;
		case -1: 
		default: return NULL;
			 
	}
	fp = fopen(filename, mode);
	if (!fp) return NULL;
	fseek(fp, zxt ? 128 : 0, SEEK_SET);
	if (is_zxt) *is_zxt = zxt;
	if (taplen) *taplen = len;

	return fp;
}

