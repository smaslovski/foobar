/************************************************************************

    TAPTOOLS v1.0.4 - Tapefile manipulation utilities

    Copyright (C) 1996, 2005, 2009  John Elliott <jce@seasip.demon.co.uk>

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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "taputil.h"

#ifdef __PACIFIC__
#define AV0 "TAPLS"
#else
#define AV0 argv[0]
#endif

FILE *tapfile;
int count = 0;
int format = 0;

const char *filetype(byte t)
{
	switch (t)
	{
		case 0:  return "BASIC  ";
		case 1:  return "Numeric";
		case 2:  return "String ";
		case 3:  return "Bytes  ";
/*		case 4:  return "Tasword"; */
	}
	return "Unknown";
}

void show_filename(const unsigned char *s)
{
	int n;

	for (n = 0; n < 10; n++)
	{
		if (isprint(0xFF & s[n])) putchar(s[n]);
		else printf("\\0%o", s[n]);
	}
}


void show_header(byte *header)
{
	unsigned w1 = header[11] + 256 * header[12];
	unsigned w2 = header[13] + 256 * header[14];
/* Not displayed 	unsigned w3 = header[15] + 256 * header[16]; */

	switch(format)
	{
		case 0: show_filename(header + 1); 
			putchar('\n');
			break;
		case 1: printf("-r--r--r-- %s %5u ", 
					filetype(header[0]), w1);
			show_filename(header + 1);
			putchar('\n');
			break;
		case 2: switch(header[0])
		{
			case 0: printf("Program: ");
				show_filename(header + 1);
				if (w2 < 0x8000) printf(" LINE %d ", w2);
				printf("\n");
				break;
			case 1: printf("Number array: ");
				show_filename(header + 1);
				printf(" DATA %c()", w2);
				printf("\n");
				break;
			case 2: printf("Character array: ");
				show_filename(header + 1);
				printf(" DATA %c()$", w2);
				printf("\n");
				break;
			case 3: printf("Bytes: ");
				show_filename(header + 1);
				printf(" CODE %u,%u", w2, w1);
				printf("\n");
				break;
			default:printf("Unknown: ");
				show_filename(header + 1);
				printf(" Type=%u Length=%u", header[0], w1);
				printf("\n");
				break;
		}
	}

}

void show_unknown(unsigned len, unsigned type)
{
	int sna = (type == 0x53 && len == 49181);
	switch(format)
	{
		case 0:
			printf(sna ? "[Headerless .SNA snapshot]" : 
					"[Headerless]\n");
			break;
		case 1: printf("-r--r--r-- ");
			if (sna)
			     printf("Snap    %5u (Headerless .SNA snapshot)\n",
					     len);
			else printf("[0x%02x]  %5u (Headerless block)\n", 
					type,len);
			break;
		case 2: if (sna) printf("Headerless block: .SNA snapshot\n");
			else	printf("Headerless block: Type=%u length=%u\n",
					type, len);
			break;
	}

}


void show_nodata()
{
	printf("[No data block follows header]\n");
}

void listtape(const char *filename)
{
	long taplen;
	unsigned blklen, blktype;
	int c;
	byte header[18];

	tapfile = opentap(filename, "rb", NULL, &taplen);
	if (!tapfile)
	{
		fprintf(stderr, "Couldn't open %s\n", filename);
		return;
	}
	if (count > 1) printf("\n%s:\n", filename);
	while (taplen)
	{
		c = fgetc(tapfile); if (c == EOF) break; blklen = c;
		c = fgetc(tapfile); if (c == EOF) break; blklen += 256 * c;
		c = fgetc(tapfile); if (c == EOF) break; blktype = c;
		if (blklen == 0x13 && blktype == 0)
		{
			/* 17 byte header + 1 byte checksum */
another_header:		if (fread(header, 1, 18, tapfile) < 18) break;
			show_header(header);
			taplen -= (blklen + 2);
			/* Skip over the data block that we hope follows */

			c = fgetc(tapfile); if (c == EOF) break; blklen = c;
			c = fgetc(tapfile); if (c == EOF) break; blklen += 256 * c;
			c = fgetc(tapfile); if (c == EOF) break; blktype = c;
/* If this header is followed by another one, say so. */
			if (blklen == 0x13 && blktype == 0)
			{
				show_nodata();
				goto another_header;
			}
			else
			{
				/* Skip over the data block */
				fseek(tapfile, blklen - 1, SEEK_CUR);
			}
			taplen -= (blklen + 2);
		}
		else
		{
			if (blklen == 0) break; /* Can't have 0-length blocks
						   so must be EOF */
			show_unknown(blklen, blktype);
			/* Skip over the data block */
			fseek(tapfile, blklen - 1, SEEK_CUR);
			taplen -= (blklen + 2);
		}
	}
}

int main(int argc, char **argv)
{
	int n;
	int endopt = 0;

	for (n = 1; n < argc; n++)
	{
		if (!strcmp(argv[n], "--"))
		{
			endopt = 1;
			continue;
		}
		if (endopt == 0 && argv[n][0] == '-')
		{
			if (argv[n][1] == 'l' || argv[n][1] == 'L') format = 1;
			if (argv[n][1] == '3') format = 2;

			continue;
		}
		++count;
	}	
	if (count == 0) /* No real arguments */
	{
		fprintf(stderr, "Syntax: %s { -l | -3 } tapfile tapfile ...\n", AV0);
		return 0;	
	}
	for (n = 1; n < argc; n++)
	{
		if (!strcmp(argv[n], "--"))
		{
			endopt = 1;
			continue;
		}
		if (endopt == 0 && argv[n][0] == '-') continue;
		
		listtape(argv[n]);
	}
	return 0;
}
