//
// vdrriprecordings.c
//

#include <stdio.h>
#include <stdlib.h>
#include <vdr/videodir.h>
#include <vdr/tools.h>

#include "vdrriprecordings.h"
#include "a-tools.h"

#define FINDRECCMD "find %s -follow -type d -regex '.*rec$'"

// --- cVdrripRecordings -----------------------

cVdrripRecordings::cVdrripRecordings() {
  Name = Date = Path = NULL;
  NumRec = 0;
  ReadRec();
}

cVdrripRecordings::~cVdrripRecordings() {
  FREE(Name);
  FREE(Date);
  FREE(Path);
}

void cVdrripRecordings::ReadRec() {
  char *cmd = NULL, *buf = NULL;
  size_t i = 0;
#if APIVERSNUM > 20101
  int colv = strnumcol(cVideoDirectory::Name(), "/");

  asprintf(&cmd, FINDRECCMD, cVideoDirectory::Name());
#else
  int colv = strnumcol(VideoDirectory, "/");

  asprintf(&cmd, FINDRECCMD, VideoDirectory);
#endif
  FILE *p = popen(cmd, "r");
  if (p) {
    while (getline(&buf, &i, p) != -1) {
     int colg;

     // search the c from *.rec and terminate the string
     int l = strlen(buf);
     while (buf[l] != 'c') {l--;}
     buf[l+1] = '\0';

     // allocate memory for Name, Date & Path - arrays
     Name = (char **)realloc(Name, ((NumRec + 1) * sizeof(char *)));
     Date = (char **)realloc(Date, ((NumRec + 1) * sizeof(char *)));
     Path = (char **)realloc(Path, ((NumRec + 1) * sizeof(char *)));

     colg = strnumcol(buf, "/");
     if ( colg - colv >= 3) {
       // this is recording with a subdir
       asprintf(&Name[NumRec], "%s_-_%s", strcol(buf, "/", colg - 2), strcol(buf, "/", colg - 1));
     } else {
       Name[NumRec] = strcol(buf, "/", colg - 1);
     }

     Date[NumRec] = strcol(strcol(buf, "/", colg), ".", 1);
     Path[NumRec] = strdup(buf);
     FREE(buf);

     NumRec++;
    } 
  } else {
    dsyslog("[vdrrip] could not open pipe to %s !", cmd);
  }
  pclose(p);
  FREE(cmd);
}

int cVdrripRecordings::getNumRec() {return NumRec;}

char *cVdrripRecordings::getName(int i) {
  if (i >= 0 && i < NumRec) {return Name[i];
  } else {return NULL;}
}

char *cVdrripRecordings::getDate(int i) {
  if (i >= 0 && i < NumRec) {return Date[i];
  } else {return NULL;}
}

char *cVdrripRecordings::getPath(int i) {
  if (i >= 0 && i < NumRec) {return Path[i];
  } else {return NULL;}
}
