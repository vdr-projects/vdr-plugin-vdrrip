/* codecs.c */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vdr/plugin.h>

#include "codecs.h"
#include "menu-vdrrip.h"
#include "a-tools.h"

#define MENCCMD "%s %s help 2>/dev/null"
#define VCODECS "lavc, xvid, divx4"
#define ACODECS "lame, copy, ogg-vorbis"

extern const char *MEncoder;

// --- cCodecs ------------------------------------------------------------

cCodecs::cCodecs() {
  VCodecs = ACodecs = Containers = NULL;

  queryCodecs((char *)VCODECS, (char *)ACODECS);
  queryContainers();
}

cCodecs::~cCodecs() {
  FREE(VCodecs);
  FREE(ACodecs);
  FREE(Containers);
}

void cCodecs::queryCodecs(char *v, char *a) {
  char *buf = NULL, *cmd = NULL;
  size_t i = 0;
  int c, c1, nvc, nac;

  // get number of codecs
  nvc = strnumcol(v, ", ");
  nac = strnumcol(a, ", ");

  // reserve memory for arrays
  VCodecs = (char**)malloc(nvc * sizeof(char*));
  ACodecs = (char**)malloc(nac * sizeof(char*)); 

  // read codecs in arryas
  for (c = 0; c < nvc; c++) {
    VCodecs[c] = strcol(v, ", ", c + 1);
  }
  for (c = 0; c < nac; c++) {
    ACodecs[c] = strcol(a, ", ", c + 1);
  }

  // detect available video codecs with mencoder,
  // move them to the beginning of the array and
  // save the number of supported codecs in NumVCodecs
  c1 = 0;

  NumVCodecs = 0;
  asprintf(&cmd, MENCCMD, MEncoder, "-ovc");
  FILE *p = popen(cmd, "r");
  if (p) {
    while (getline(&buf, &i, p) != -1) {
      for (c = c1; c < nvc; c++) {
        if (strstr(buf, VCodecs[c])) {
          // move found video codec to VCodecs[i1]
          char *tmp = VCodecs[c1];
          VCodecs[c1] = VCodecs[c];
	  VCodecs[c] = tmp;
          c1++;
	  NumVCodecs++;
        }
      }
    }
  }
  pclose(p);
  FREE(cmd);

  // detect available audio codecs with mencoder,
  // move them to the beginning of the array and
  // save the number of supported codecs in NumACodecs
  c1 = 0;

  NumACodecs = 0;
  asprintf(&cmd, MENCCMD, MEncoder, "-oac");
  p = popen(cmd, "r");
  if (p) {
    while (getline(&buf, &i, p) != -1) {
      for (c = c1; c < nac; c++) {
        if (strstr(buf, ACodecs[c])) {
          // switch found audio codec with ACodecs[i1]
          char *tmp = ACodecs[c1];
          ACodecs[c1] = ACodecs[c];
	  ACodecs[c] = tmp;
	  c1++;
	  NumACodecs++;
        }
      }
    }
  }
  pclose(p);
  FREE(cmd);

  if (VdrripSetup.OggVorbis == 1) {
    ACodecs[NumACodecs] = strdup("ogg-vorbis");
    NumACodecs++;
  }

  FREE(buf);
}

void cCodecs::queryContainers() {
  NumContainers = 1;
  int i = 1;
  if (VdrripSetup.Ogm == 1) {NumContainers++;}
  if (VdrripSetup.Matroska == 1) {NumContainers++;}

  Containers = (char**)malloc(NumContainers * sizeof(char*));

  Containers[0] = (char *)"avi";
  
  if (VdrripSetup.Ogm == 1) {
    Containers[i] = (char *)"ogm";
    i++;}
    
  if (VdrripSetup.Matroska == 1) {Containers[i] = (char *)"matroska";}
}


int cCodecs::getNumVCodecs() {return NumVCodecs;}

int cCodecs::getNumACodecs() {return NumACodecs;}

int cCodecs::getNumContainers() {return NumContainers;}

char **cCodecs::getVCodecs() {return VCodecs;}

char **cCodecs::getACodecs() {return ACodecs;}

char **cCodecs::getContainers() {return Containers;}

char *cCodecs::getVCodec(int i) {return VCodecs[i];}

char *cCodecs::getACodec(int i) {return ACodecs[i];}

char *cCodecs::getContainer(int i) {return Containers[i];}

int cCodecs::getNumVCodec(const char *v) {
  int i = 0;

  // check if there are video codecs available
  if (NumVCodecs == 0) {
    dsyslog("[vdrrip] fatal error: no video codec found !");
    return -2;
  }

  while (strcmp(v, VCodecs[i]) != 0) {
    i++;
    if (i == NumVCodecs) {
      dsyslog("[vdrrip] video codec %s not found !", v);
      return -1;
    }
  }

  return i;
}

int cCodecs::getNumACodec(const char *a) {
  int i = 0;

  // check if there are audio codecs available
  if (NumACodecs == 0) {
    dsyslog("[vdrrip] fatal error: no audio codec found !");
    return -2;
  }

  while (strcmp(a, ACodecs[i]) != 0) {
    i++;
    if (i == NumACodecs) {
      dsyslog("[vdrrip] audio codec %s not found !", a);
      return -1;
    }
  }

  return i;
}

int cCodecs::getNumContainer(const char *c) {
  int i = 0;

  while (strcmp(c, Containers[i]) != 0) {
    i++;
    if (i == NumContainers) {
      dsyslog("[vdrrip] container %s not found !", c);
      return -1;
    }
  }

  return i;
}
