/* a-tools.h:
   some tools from herbert attenberger <herbsl@a-land.de>
*/

#ifndef __A_TOOLS_H
#define __A_TOOLS_H

#include <stdio.h>

#define FREE(x) if (x) {free(x); x = NULL;}
#define DELETE(x) if (x) {delete x; x = NULL;}

char *strsub(char *s, int p, int numbers);

char *strcol(char *s, char *d, int c);

int strnumcol(const char *s, char *d);

char *strgrep(char *s, FILE *f);

int roundValue(int i, int i1);

#endif //__A_TOOLS_H
