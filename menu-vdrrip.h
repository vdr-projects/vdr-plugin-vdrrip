//
// menu-vdrrip.h
//

#ifndef __MENU_VDRRIP_H
#define __MENU_VDRRIP_H

#include <vdr/osd.h>
#include <vdr/menuitems.h>
#if VDRVERSNUM >= 10307
#include <vdr/menu.h>
#include <vdr/skins.h>
#endif

#include "movie.h"
#include "vdrriprecordings.h"
#include "templates.h"
#include "queue.h"
#include "codecs.h"

struct MovieOSDData {
  char *Name;
  int Title;
  int Template;
  int FileSize;
  int FileNumbers;
  int BitrateVideo;
  int BitrateAudio;
  int Container;
  int VCodec;
  int ACodec;
  int AudioID;
  int ScaleWidth;
  int ScaleHeight;
  int ScaleType;
  int DVBScaleWidth;
  int DVBScaleHeight;

  //expert menu:
  int CropWidth;
  int CropHeight;
  int PPDeinterlace;
  int PPDeblock;
  int Bpp;
};

class cMenuVdrrip : public cOsdMenu {
private:
  virtual void Set();

public:
  cMenuVdrrip();
  virtual eOSState ProcessKey(eKeys Key);
};

#ifdef VDRRIP_DVD

class cMenuVdrripWarning
#if VDRVERSNUM >= 10307
  : public cMenuText {
#else
  : public cOsdMenu {
#endif
private:
  bool hadsubmenu;

  bool CheckDVD();
public:
  cMenuVdrripWarning(const char *Title, const char *Text);
  virtual eOSState ProcessKey(eKeys Key);
};

#endif //VDRRIP_DVD};

class cMenuVdrripEncode : public cOsdMenu {
private:
  virtual void Set();

  cVdrripRecordings *R;
public:
  cMenuVdrripEncode();
  ~cMenuVdrripEncode();
  virtual eOSState ProcessKey(eKeys Key);
};

class cMenuVdrripQueue : public cOsdMenu {
private:
  virtual void Set();
  void RefreshOSD();
  void SetHelpKeys();
  void AddColItem(cOsdItem *i);

  cQueue *Q;
  int NumMovie;
  bool Delete, Up, Down, Switch;
  
public:
  cMenuVdrripQueue();
  ~cMenuVdrripQueue();
  virtual eOSState ProcessKey(eKeys Key);
};

class cMenuVdrripTemplates : public cOsdMenu {
private:
  virtual void Set();
  void RefreshOSD();

  cTemplate *T;
  bool hadsubmenu;
public:
  cMenuVdrripTemplates();
  ~cMenuVdrripTemplates();
  virtual eOSState ProcessKey(eKeys Key);
};

class cMenuVdrripEditTemplate : public cOsdMenu {
private:
  virtual void Set();
  void OSDChange();
  void OSDCreate();
  void AddColItem(cOsdItem *i);
  
  cTemplate *T;
  int NumTemplate;
  struct TemplateData TempOSD, TempOSDsave;
  char *TempOSDsaveName;
  
  bool OSDupdate;
public:
  cMenuVdrripEditTemplate(cTemplate *t, int i);
  ~cMenuVdrripEditTemplate();
  virtual eOSState ProcessKey(eKeys Key);
};


class cMenuVdrripMovie : public cOsdMenu {
private:
  virtual void Set();
  void Init();
  void OSDChange();
  void OSDCreate();
  void SetHelpKeys();
  void AddColItem(cOsdItem *i);

  cMovie *M;
  struct MovieOSDData MovOSD, MovOSDsave;
  char *MovOSDsaveName;
  char *Templates;
  char *FileSize[1];
  char *MovieData[1];
  char *CropData[1];
  char *ScaleData[1];

  bool OSDupdate, Crop, CropReset, Expert;

  int CropWidthsave;
  int CropHeightsave;

  int NumStatic;

  bool hadsubmenu;

public:
  cMenuVdrripMovie(const char *p, const char *n);
  ~cMenuVdrripMovie();
  virtual eOSState ProcessKey(eKeys Key);
};

class cMenuVdrripMovieTitles : public cOsdMenu {
private:
  cMovie *M;
public:
  cMenuVdrripMovieTitles(cMovie *m);
  ~cMenuVdrripMovieTitles();
  virtual eOSState ProcessKey(eKeys Key);
};

class cMenuVdrripMovieAudio : public cOsdMenu {
private:
  cMovie *M;
public:
  cMenuVdrripMovieAudio(cMovie *m);
  ~cMenuVdrripMovieAudio();
  virtual eOSState ProcessKey(eKeys Key);
};


class cVdrripSetup {
public:
  int MaxScaleWidth;
  int MinScaleWidth;
  int CropMode;
  int CropLength;
  int Rename;
  int OggVorbis;
  int AC3;
  int Ogm;
  int Matroska;

public:
  cVdrripSetup();
  bool SetupParse(const char *Name, const char *Value);
};


class cMenuVdrripSetup : public cMenuSetupPage {
private:
  cVdrripSetup data;
protected:
  virtual void Store(void);
public:
  cMenuVdrripSetup();
};

extern cVdrripSetup VdrripSetup;

#endif //__MENU_VDRRIP_H

