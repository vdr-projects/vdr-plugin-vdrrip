//
// templates.h
//

#ifndef __TEMPLATES_H
#define __TEMPLATES_H

#include "codecs.h"

#define TEMPLATESFILE "templates.vdrrip"
#define TDEFAULT "default"

struct TemplateData {
  char *Name;
  int FileSize;
  int FileNumbers;
  int Bitrate;
  int BitrateVideo;
  int BitrateAudio;
  int Container;
  int VCodec;
  int ACodec;
  int ScaleType;
  int Bpp;
};

class cTemplate {
 private:
  struct TemplateData *T;
  char **TNames;
  int NumTemplates;

  void Load();

 public:
  cTemplate();
  ~cTemplate();

  cCodecs *C;

  void Save();
  int New(char *n);
  void Del(int i);
  void setName(int i, char *n);
  void setFileSize(int i, int fs, int fn);
  void setBitrate(int i, int v, int a);
  int getContainer(int i);
  void setContainer(int i, int c);
  void setCodecs(int i, int v, int a);
  int getVCodec(int i);
  int getACodec(int i);
  void setBpp(int i, int b);
  void setScaleType(int i, int t);
  int getNumTemplate(char *n);
  int getNumTemplates();
  char *getName(int i);
  char *getShortname(int i);
  char **getTNames();
  int getFileSize(int i);
  int getFileNumbers(int i);
  int getBitrateVideo(int i);
  int getBitrateAudio(int i);
  int getScaleType(int i);
  int getBpp(int i);
};

#endif // __TEMPLATES_H
