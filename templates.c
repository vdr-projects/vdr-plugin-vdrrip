// templates.c

#include <stdio.h>
#include <stdlib.h>
#include <vdr/plugin.h>

#include "templates.h"
#include "codecs.h"
#include "a-tools.h"


cTemplate::cTemplate() {
  C = NULL;
  T = NULL;
  TNames = NULL;

  C = new cCodecs();
  Load();
}

cTemplate::~cTemplate() {
  for (int c = 0; c < NumTemplates; c++) {FREE(T[c].Name);}
  FREE(T);
  FREE(TNames);

  DELETE(C);
}

void cTemplate::Load() {
  char *buf = NULL;
  size_t i = 0;
  bool d  = false;
  int c = 0;

  FILE *f = fopen(AddDirectory(cPlugin::ConfigDirectory(), TEMPLATESFILE), "r");
  if (f) {
    // read Template-Data
    while (getline(&buf, &i, f) != -1) {
      // reserve memory for templates
      T = (struct TemplateData*)realloc(T, (c + 1) * sizeof(struct TemplateData));
      T[c].Name         = strcol(buf, ";", 1);
      T[c].FileSize     = atoi(strcol(buf, ";", 2));
      T[c].FileNumbers  = atoi(strcol(buf, ";", 3));
      T[c].BitrateVideo = atoi(strcol(buf, ";", 4));
      T[c].BitrateAudio = atoi(strcol(buf, ";", 5));
      T[c].VCodec       = C->getNumVCodec(strcol(buf, ";", 6));
      T[c].ACodec       = C->getNumACodec(strcol(buf, ";", 7));
      // migrate from version 0.0.9
      char *s = NULL;
      s = strcol(buf, ";", 8);
      if (s) {T[c].ScaleType = atoi(s);
      } else {T[c].ScaleType = 0;}
      FREE(s);
      s = strcol(buf, ";", 9);
      if (s) {T[c].Bpp = atoi(s);
      } else {T[c].Bpp = 20;}
      FREE(s);
      // migrate from version 0.1.1
      s = strcol(buf, ";", 10);
      if (s) {T[c].Container = C->getNumContainer(s);
      } else {T[c].Container = C->getNumContainer("avi");}
      FREE(s);
      
      // search for default Templates
      if (strcmp(T[c].Name, TDEFAULT) == 0) {d = true;}

      FREE(buf);
      c++;
    }
    fclose(f);
  } else {
    dsyslog("[vdrrip] could not open file %s !", TEMPLATESFILE);
    isyslog("[vdrrip] try to create %s with default settings !", TEMPLATESFILE);
  }

  NumTemplates = c;

  //create default Templates
  if (! d) {New(TDEFAULT);}
}

void cTemplate::Save() {
  FILE *f;

  f = fopen(AddDirectory(cPlugin::ConfigDirectory(), TEMPLATESFILE), "w");
  if (f) {
    for (int c = 0; c < NumTemplates; c++) {
      if (strcmp(T[c].Name, "delete") != 0) {
        fprintf(f, "%s;%i;%i;%i;%i;%s;%s;%i;%i;%s\n", T[c].Name,
	        T[c].FileSize, T[c].FileNumbers, T[c].BitrateVideo,
		T[c].BitrateAudio, C->getVCodec(T[c].VCodec),
		C->getACodec(T[c].ACodec), T[c].ScaleType, T[c].Bpp,
		C->getContainer(T[c].Container));
      }
    }
    fclose(f);
    Load();

  } else {
    dsyslog("[vdrrip] could not save %s !", TEMPLATESFILE);
  }
}

int cTemplate::getNumTemplates() {return NumTemplates;}

int cTemplate::getNumTemplate(char *t) {
  int c;

  if (t) {
    for (c = 0; c < NumTemplates; c++) {
      if (strcmp(T[c].Name, t) == 0) return c;
    }
  }
  return -1;
}

char **cTemplate::getTNames() {
  int c;
  
  TNames = (char **)malloc(NumTemplates * sizeof(char *));
  for (c = 0; c < NumTemplates; c++) {
    TNames[c] = T[c].Name;
  }
  return TNames;
}

int cTemplate::New(char *n) {
  T = (struct TemplateData*)realloc(T, ((NumTemplates + 1) * sizeof(struct TemplateData)));
  T[NumTemplates].Name         = strdup(n);
  T[NumTemplates].FileSize     = 700;
  T[NumTemplates].FileNumbers  = 1;
  T[NumTemplates].BitrateVideo = -1;
  T[NumTemplates].Container    = C->getNumContainer("avi");
  T[NumTemplates].VCodec       = C->getNumVCodec("lavc");
  T[NumTemplates].ACodec       = C->getNumACodec("copy");
  T[NumTemplates].ScaleType    = 0;
  T[NumTemplates].Bpp          = 20;
  T[NumTemplates].BitrateAudio = 96;

  NumTemplates++;
  Save();

  return NumTemplates - 1;
}

void cTemplate::Del(int i) {
  if (i >= 0 && i < NumTemplates) {
    isyslog("add delete flag on template %s", T[i].Name);
    T[i].Name = strdup("delete");
    Save();
  }
}

void cTemplate::setName(int i, char *n) {
  if (i >= 0 && i < NumTemplates) {
    T[i].Name = strdup(n);
    Save();
  }
}

void cTemplate::setFileSize(int i, int fs, int fn) {
  if (i >= 0 && i < NumTemplates) {
    T[i].FileSize     = fs;
    T[i].FileNumbers  = fn;
    T[i].BitrateVideo = -1;
    Save();
  }
}

void cTemplate::setBitrate(int i, int v, int a) {
  if (i >= 0 && i < NumTemplates) {
    T[i].BitrateVideo = v;
    T[i].BitrateAudio = a;
    if (! (T[i].BitrateVideo == -1)) {T[i].FileSize = -1;}
    Save();
  }
}

void cTemplate::setContainer(int i, int c) {
  if (i >= 0 && i < NumTemplates) {
    if (c >= 0 && c < C->getNumContainers()) {T[i].Container = c;
    } else {
      dsyslog("[vdrrip] unknown container, falling back to avi !");
      T[i].Container = C->getNumContainer("avi");
    }
    Save();
  }
}

void cTemplate::setCodecs(int i, int v, int a) {
  if (i >= 0 && i < NumTemplates) {
    // validate video codec
    if (v >= 0 && v < C->getNumVCodecs()) {T[i].VCodec = v;
    } else {
      dsyslog("[vdrrip] unknown video codec, falling back to %s !",
              C->getVCodec(0));
      T[i].VCodec = 0;
    }
  
    // validate audio codec
    if (a >= 0 && a < C->getNumACodecs()) {
      if (strcmp(C->getContainer(T[i].Container), "avi") == 0 && strcmp(C->getACodec(a), "ogg-vorbis") == 0) {
        dsyslog("[vdrrip] avi couldn't contain ogg-vorbis audio, falling back to copy !");
        T[i].ACodec = C->getNumACodec("copy");
      } else {T[i].ACodec = a;}
    } else {
      dsyslog("[vdrrip] unknown audio codec, falling back to copy !"),
      T[i].ACodec = C->getNumACodec("copy");
    }

    Save();
  }
}

void cTemplate::setBpp(int i, int b) {
  if (i >= 0 && i < NumTemplates) {
    T[i].Bpp = b;
    Save();
  }
}

void cTemplate::setScaleType(int i, int t) {
  if (i >= 0 && i < NumTemplates) {
    T[i].ScaleType = t;
    Save();
  }
}

char *cTemplate::getName(int i) {
  if (i >= 0 && i < NumTemplates) {return T[i].Name;
  } else {return NULL;}
}

char *cTemplate::getShortname(int i) {
  if (i >= 0 && i < NumTemplates) {
    if (strlen(T[i].Name) > 20) {
      char *s, *s1;
      s = strsub(T[i].Name,1 , 17);
      asprintf(&s1, "%s...", s);
      return s1;
    } else {return T[i].Name;}
  } else {return NULL;}
}

int cTemplate::getFileSize(int i) {
  if (i >= 0 && i < NumTemplates) {return T[i].FileSize;
  } else {return 0;}
}

int cTemplate::getFileNumbers(int i) {
  if (i >= 0 && i < NumTemplates) {return T[i].FileNumbers;
  } else {return 0;}
}

int cTemplate::getBitrateVideo(int i) {
  if (i >= 0 && i < NumTemplates) {return T[i].BitrateVideo;
  } else {return 0;}
}

int cTemplate::getBitrateAudio(int i) {
  if (i >= 0 && i < NumTemplates) {return T[i].BitrateAudio;
  } else {return 0;}
}

int cTemplate::getContainer(int i) {
  if (i >= 0 && i < NumTemplates) {return T[i].Container;
  } else {return 0;}
}

int cTemplate::getVCodec(int i) {
  if (i >= 0 && i < NumTemplates) {return T[i].VCodec;
  } else {return 0;}
}

int cTemplate::getACodec(int i) {
  if (i >= 0 && i < NumTemplates) {return T[i].ACodec;
  } else {return 0;}
}

int cTemplate::getScaleType(int i) {
  if (i >= 0 && i < NumTemplates) {return T[i].ScaleType;
  } else {return 0;}
}

int cTemplate::getBpp(int i) {
  if (i >= 0 && i < NumTemplates) {return T[i].Bpp;
  } else {return 1;}
}

