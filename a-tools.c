/* a-tools.c:
   some tools from herbert attenberger <herbsl@a-land.de>
*/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <vdr/plugin.h>

#include "a-tools.h"

char *strsub(char* s, int p, int n) {
  char *s1;
  int l;

  // let's do some checks:
  if (s == NULL) {return NULL;}

  l = strlen(s);
  if (p > l || p < 1 || n < 1) {return NULL;}
  if (p + n > l + 1) {n = l - p + 1;}

  // point s to the beginning of the substring
  s = s + p - 1;

  // allocate memory and store the substring in s1
  s1 = (char*) malloc(sizeof(char) * (n + 1));
  memmove(s1, s, sizeof(char) * n);
  s1[n] = '\0';

  return s1;
} 

char *strcol(char *s,const char *d, int c) {
  char *s1, *s2;
  int i;
  int l, l1;

  // let's do some checks:

  if (s == NULL) {return NULL;}
  if (d == NULL) {return NULL;}
  if (c < 1) {return NULL;}

  l = strlen(d);

  // point s to the beginning of the column
  for (i = 1; i < c; i++) {
    s = strstr(s, d);
    if (s == NULL) {return NULL;}
    s = s + l;
  }

  // point s1 to the end of the column
  s1 = strstr(s, d);
  if (s1 == NULL) {
    // check newline or end of string
    s1 = strchr(s, '\n');
    if (s1 == NULL) {s1 = strchr(s,'\0');}
  }

  l1 = s1 -s; // store length of column in l1

  // allocate memory and store the column in s2
  s2 = (char*) malloc(sizeof(char) * (l1 + 1));
  memmove(s2, s, sizeof(char) * l1);
  s2[l1] = '\0';

  return s2;
}

int strnumcol(const char *s, const char *d) {
  const char *s1;
  int i, l;

  // let's do some checks:
  if (s == NULL) {return 0;}
  if (d == NULL) {return 0;}

  i = 1;
  l = strlen(d);

  s1 = strstr(s, d);
  while (s1 != NULL) {
    i++;
    s1 = s1 + l;
    s1 = strstr(s1, d);
  }

  return i;
}

char *strgrep(const char *s, FILE *f) {
  char *s1 = (char *)"";
  size_t i = 0;

  // let's do some checks
  if (s == NULL) {return NULL;}

  // search the line
  while (strstr(s1, s) == NULL) {
    if (getline(&s1, &i, f) == -1) {
      dsyslog("string %s not found !", s);
      return NULL;
    }
  }

  return s1;
}

int roundValue(int i, int i1) {return i / i1 * i1;}
