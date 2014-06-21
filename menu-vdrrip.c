//
// menu-vdrrip.c
//

#include <vdr/plugin.h>
#include <vdr/videodir.h>
#if VDRVERSNUM >= 10307
#include <vdr/interface.h>
#include <vdr/status.h>
#endif

#ifdef VDRRIP_DVD
#ifdef NEW_IFO_READ
  #include <stdint.h>
  #include <dvdread/ifo_read.h>
  #include <dvdread/ifo_types.h>
#else
  #include <dvdnav/ifo_read.h>
#endif
#endif //VDRRIP_DVD

#include "menu-vdrrip.h"
#include "movie.h"
#include "a-tools.h"
#include "templates.h"
#include "queue.h"
#include "vdrriprecordings.h"

#define MINQUANT 2
#define MAXQUANT 15

#define NUMSCALETYPES 4
#define NUMPPDEINT 6

static const char *ScaleTypes[] = { "off", "auto", "dvb", "manual" };
static const char *DVBScaleWidths[] = { "352", "480", "544", "688", "704", "720" };
static const char *DVBScaleHeights[] = { "288", "576" };
static const char *CropModes[] = { "crop width & height", "crop only height"};
static const char *PPDeint[] = { "off", "fd", "lb", "li", "ci", "md", };
static const char *PPDeintDescriptions[] = { "off", "fd (FFmpeg deinterlacing)", "lb (linear blend)", "li (linear interpolating)", "ci (cubic interpolating)", "md (median deinterlacing)" };

// --- cMenuVdrrip ---------------------------------------------------------

cMenuVdrrip::cMenuVdrrip():cOsdMenu("Vdrrip") {Set();}

void cMenuVdrrip::Set() {
  Clear();

  Add(new cOsdItem(tr("encode vdr-recording"), osUser1));

#ifdef VDRRIP_DVD
  Add(new cOsdItem(tr("encode dvd"), osUser2)); 
#endif //VDRRIP_DVD

  Add(new cOsdItem(tr("edit encoding queue"), osUser3)); 
  Add(new cOsdItem(tr("edit templates"), osUser4));
}

eOSState cMenuVdrrip::ProcessKey(eKeys Key) {

  eOSState state = cOsdMenu::ProcessKey(Key);

  switch (state) {
    case osUser1: {
      AddSubMenu(new cMenuVdrripEncode);
      break;
    }

#ifdef VDRRIP_DVD
    case osUser2: {
      const char *s = "Most DVDs are encrypted with CSS (Contents "
      "Scrambling System). Copying of encrypted DVDs is illegal in "
      "many countries. This program is not meant for those who intend "
      "on breaking copyright laws. Every illegal use of this software "
      "is strictly prohibited. In no way I will be held responsible "
      "if you do. "
      "Be aware to check your countries law !";

      AddSubMenu(new cMenuVdrripWarning("Warning", s));
      break;
    }
#endif

    case osUser3: {
      AddSubMenu(new cMenuVdrripQueue);
      break;
    }
  
    case osUser4: {
      AddSubMenu(new cMenuVdrripTemplates);
      break;
    }

    default: break;
  }
  
  return state;
}


// --- cMenuVdrripWarning ----------------------------------------------------------
 
# ifdef VDRRIP_DVD

cMenuVdrripWarning::cMenuVdrripWarning(const char *Title, const char *Text)
#if VDRVERSNUM >= 10307
:cMenuText(Title, "")
#else
:cOsdMenu(Title)
#endif
{
  bool warning;
  warning = true;
  //warning = false;

  if (warning) {
#if VDRVERSNUM >= 10307
    SetText(Text);
#else
    Add(new cMenuTextItem(Text, 1, 2, Setup.OSDwidth - 2, MAXOSDITEMS, clrWhite, clrBackground, fontOsd));
#endif
    SetHelp(tr("back"), tr("accept"), NULL, NULL);
    hadsubmenu = false;
  } else {
    if (CheckDVD()) AddSubMenu(new cMenuVdrripMovie("dvd://", ""));
    hadsubmenu = true;
  }
}
                                                                                
eOSState cMenuVdrripWarning::ProcessKey(eKeys Key)
{
  eOSState state = cOsdMenu::ProcessKey(Key);

  if (HasSubMenu()) {
    hadsubmenu = true;
    return osContinue;
  }

  if (hadsubmenu) {return osBack;}
  
  switch (Key) {
#if VDRVERSNUM >= 10307
    // cMenuText::ProcessKey don't handle submenus
    case kUp|k_Repeat:
    case kUp:
    case kDown|k_Repeat:
    case kDown:
    case kLeft|k_Repeat:
    case kLeft:
    case kRight|k_Repeat:
    case kRight:
      DisplayMenu()->Scroll(NORMALKEY(Key) == kUp || NORMALKEY(Key) == kLeft,
                            NORMALKEY(Key) == kLeft || NORMALKEY(Key) == kRight);
      cStatus::MsgOsdTextItem(NULL, NORMALKEY(Key) == kUp);
      return osContinue;
#endif

    case kRed: return osBack;

    case kGreen: {
      if (CheckDVD()) AddSubMenu(new cMenuVdrripMovie("dvd://", ""));
      break;
    }

    default: break;
  }
  
  return state;
}

bool cMenuVdrripWarning::CheckDVD() {
  dvd_reader_t *dvd = NULL;
  ifo_handle_t *ifo_zero = NULL;
  ifo_handle_t *ifo_tmp = NULL;

#if VDRVERSNUM >= 10307
  Skins.Message(mtStatus, tr("checking dvd..."));
  Skins.Flush();
#else
  Interface->Status(tr("checking dvd..."));
  Interface->Flush();
#endif

  if (access(DVD, R_OK) == -1) {
    char *s = NULL;
    asprintf(&s, "No read privileges on %s !", DVD);
#if VDRVERSNUM >= 10307
    Skins.Message(mtError, s);
#else
    Interface->Error(s);
#endif
    FREE(s);
    return false;
  }

  dvd = DVDOpen(DVD);

  if (dvd) {
    ifo_zero = ifoOpen(dvd, 0);
    if (ifo_zero) {
      for (int i = 1; i < ifo_zero->vts_atrt->nr_of_vtss; i++) {
        ifo_tmp = ifoOpen(dvd, i);
        if (ifo_tmp) ifoClose(ifo_tmp);
	else {
	  char *s = NULL;
	  asprintf(&s, "Can't open ifo %d !", i);
#if VDRVERSNUM >= 10307
	  Skins.Message(mtError, s);
#else
	  Interface->Error(s);
#endif
	  FREE(s);
          DVDClose(dvd);
	  return false;
        }
      }
      ifoClose(ifo_zero);
      DVDClose(dvd);
      return true;
    } else {
      DVDClose(dvd);
#if VDRVERSNUM >= 10307
      Skins.Message(mtError, "Can't open main ifo from dvd !");
#else
      Interface->Error("Can't open main ifo from dvd !");
#endif
      return false;
    }
  }
 
  char *s = NULL;
  asprintf(&s, "Can 't open %s !", DVD);
#if VDRVERSNUM >= 10307
  Skins.Message(mtError, s);
#else
  Interface->Error(s);
#endif
  FREE(s);
  return false;
}

#endif //VDRRIP_DVD

// --- cMenuVdrripEncode ----------------------------------------------------

cMenuVdrripEncode::cMenuVdrripEncode():cOsdMenu(tr("encode vdr-recording")) {
  R = NULL;
  
#if VDRVERSNUM >= 10307
  Skins.Message(mtStatus, tr("scanning recordings..."));
  Skins.Flush();
#else
  Interface->Status(tr("scanning recordings..."));
  Interface->Flush();
#endif

  R = new cVdrripRecordings;
  Set();
}

cMenuVdrripEncode::~cMenuVdrripEncode() {
  DELETE(R);
}

void cMenuVdrripEncode::Set() {
  char *s = NULL;
  int i;

  for (i = 0; i < R->getNumRec(); i++) {
    asprintf(&s, "%s   %s", R->getDate(i), R->getName(i));
    Add(new cOsdItem(s));
    FREE(s);
  }
}

eOSState cMenuVdrripEncode::ProcessKey(eKeys Key) {

  eOSState state = cOsdMenu::ProcessKey(Key);

  if (HasSubMenu()) return osContinue;

  if (Key == kOk) AddSubMenu(new cMenuVdrripMovie(R->getPath(Current()), R->getName(Current())));
 
  return state;
}


// --- cMenuVdrripQueue ----------------------------------------------------

cMenuVdrripQueue::cMenuVdrripQueue():cOsdMenu(tr("edit encoding queue")) {
  Q = NULL;
  Q = new cQueue;
  NumMovie = 0;
  Set();
}

cMenuVdrripQueue::~cMenuVdrripQueue() {
  DELETE(Q);
}

void cMenuVdrripQueue::Set() {
  char *s = NULL, *s1 = NULL;
  int c;
  struct QueueData *q;

  for (c = 0; c < Q->getNumMovies(); c++) {
    q = Q->getData(c);

    asprintf(&s,  "%s%s - %s:", (strstr(q->Dir, "dvd://")) ? "DVD": "VDR", (q->Preview == 1) ? " (preview)": "", q->Name);
    asprintf(&s1, "- %s, %ix%i MB, %s:%i kbit/s, %s:%i kbit/s", q->Container, q->FileNumbers, q->FileSize, q->VCodec, q->BitrateVideo, q->ACodec, q->BitrateAudio);
    if (c == 0 && Q->IsEncoding()) {
      AddColItem(new cOsdItem(s));
      AddColItem(new cOsdItem(s1));
      AddColItem(new cOsdItem(Q->getQueueStat()));
    } else {
      Add(new cOsdItem(s));
      Add(new cOsdItem(s1));
    }
    FREE(s);
    FREE(s1);
  }

  if (Q->getLockStat()) {
#if VDRVERSNUM >= 10307
    Skins.Message(mtError, tr("the queuefile is locked by the queuehandler !"));
#else
    Interface->Error(tr("the queuefile is locked by the queuehandler !"));
#endif
  }

  SetHelpKeys();
}

eOSState cMenuVdrripQueue::ProcessKey(eKeys Key) {

  eOSState state = cOsdMenu::ProcessKey(Key);

  if (HasSubMenu()) return osContinue;

  if (Q->IsEncoding()) {
    NumMovie = (Current() - 1) / 2;
    if (NumMovie < 0) NumMovie = 0;
  } else NumMovie = Current() / 2;

  SetHelpKeys();

  switch (Key) {

    case kRed: {
      if (Delete) {
        char *buf = NULL;
        asprintf(&buf, tr("delete movie %s from queue ?"), Q->getShortname(NumMovie));
        if (Interface->Confirm(buf)) {
	  Q->Del(NumMovie);
	  RefreshOSD();
        }
        FREE(buf);
      }
      break;
    }

    case kGreen: {
      if (Up) {
	Q->Up(NumMovie);
        RefreshOSD();
      }
      break;
    }

    case kYellow: {
      if (Down) {
        Q->Down(NumMovie);
        RefreshOSD();
      }
      break;
    }

    case kBlue: {
      if (Switch) {
        Q->Switch(NumMovie);
        RefreshOSD();
      }
      break;
    }
		   
    default: break;
  }
		 
  return state;
}

void cMenuVdrripQueue::RefreshOSD() {
  int i = Current();
  Clear();
  Set();
  SetCurrent(Get(i));
  SetHelpKeys();
  Display();
}

void cMenuVdrripQueue::SetHelpKeys() {
  if (Q->getLockStat() || Q->getNumMovies() == 0 || (NumMovie == 0 && Q->IsEncoding())) {
    Delete = Up = Down = Switch = false;
  } else {
    Delete = true;
    Switch = true;

    // up-Key:
    if (NumMovie >= 1 && NumMovie < Q->getNumMovies()) {
      (NumMovie == 1 && Q->IsEncoding()) ? Up = false : Up = true;
    } else {Up = false;}

    // down-key
    if (NumMovie >= 0 && NumMovie < Q->getNumMovies() - 1) {
      (NumMovie == 0 && Q->IsEncoding()) ? Down = false : Down = true;
    } else {Down = false;}
  }
  
  SetHelp(Delete ? tr("delete") : NULL, Up ? tr("up") : NULL, Down ? tr("down") : NULL, Switch ? tr("switch mode") : NULL);
}

void cMenuVdrripQueue::AddColItem(cOsdItem *i) {
#if VDRVERSNUM < 10307
#ifdef clrScrolLine
   i->SetColor(clrScrolLine, clrBackground);
#else
   i->SetColor(clrCyan, clrBackground);
#endif
#endif

  Add(i);
}
  
// --- cMenuVdrripTemplates -------------------------------------------------

cMenuVdrripTemplates::cMenuVdrripTemplates():cOsdMenu(tr("edit templates")) {
 
  T = new cTemplate();

  Set();
  SetHelp(tr("edit"), tr("new"), tr("delete"), NULL);
}

cMenuVdrripTemplates::~cMenuVdrripTemplates() {
  DELETE(T);
}

void cMenuVdrripTemplates::Set() {
  for (int i = 0; i < T->getNumTemplates(); i++) {
    Add(new cOsdItem(T->getName(i)));
  }

  hadsubmenu = false;
}

eOSState cMenuVdrripTemplates::ProcessKey(eKeys Key) {

  eOSState state = cOsdMenu::ProcessKey(Key);

  if (HasSubMenu()) {
    hadsubmenu = true;
    return osContinue;
  }

  if (hadsubmenu) {RefreshOSD();}

  switch (Key) {
    case kOk: {
      AddSubMenu(new cMenuVdrripEditTemplate(T, Current()));
      break;
    }

    case kRed: {
      AddSubMenu(new cMenuVdrripEditTemplate(T, Current()));
      break;
    }

    case kGreen: {
      AddSubMenu(new cMenuVdrripEditTemplate(T, T->New("new")));
      break;
    }

    case kYellow: {
      char *buf;
      asprintf(&buf, tr("delete template %s ?"), T->getShortname(Current()));
      if (Interface->Confirm(buf)) {T->Del(Current());}
      FREE(buf);
      RefreshOSD();
      break;
    }

    default: break;
  }

  return state;
}

void cMenuVdrripTemplates::RefreshOSD() {
  int i = Current();
  Clear();
  Set();
  SetCurrent(Get(i));
  Display();
}



// --- cMenuVdrripEditTemplate -----------------------------------------------

cMenuVdrripEditTemplate::cMenuVdrripEditTemplate(cTemplate *t, int i):cOsdMenu(tr("edit template"), 15) {
  T = t;
  NumTemplate = i;
  TempOSDsaveName = NULL;
  OSDupdate = true;

  SetHelp(tr("ABC/abc"), tr("Overwrite"), tr("Delete"), NULL);
  Set();
}

cMenuVdrripEditTemplate::~cMenuVdrripEditTemplate() {
  FREE(TempOSDsaveName);
}

void cMenuVdrripEditTemplate::Set() {

  // get data
  TempOSD.Name         = T->getName(NumTemplate);
  TempOSD.FileSize     = T->getFileSize(NumTemplate);
  TempOSD.FileNumbers  = T->getFileNumbers(NumTemplate);
  TempOSD.BitrateAudio = T->getBitrateAudio(NumTemplate);
  TempOSD.BitrateVideo = T->getBitrateVideo(NumTemplate);
  TempOSD.Container    = T->getContainer(NumTemplate);
  TempOSD.VCodec       = T->getVCodec(NumTemplate);
  TempOSD.ACodec       = T->getACodec(NumTemplate);
  TempOSD.ScaleType    = T->getScaleType(NumTemplate);
  TempOSD.Bpp          = T->getBpp(NumTemplate);

  // save data
  FREE(TempOSDsaveName);
  TempOSDsaveName = strdup(TempOSD.Name);
  TempOSDsave     = TempOSD;

  // rebuild osd
  int i = Current();
  Clear();
  OSDCreate();
  SetCurrent(Get(i));
  Display();
}

void cMenuVdrripEditTemplate::OSDCreate() {
  
  Add(new cMenuEditStrItem(tr("Name"), TempOSD.Name, 32, FileNameChars));
  Add(new cMenuEditIntItem(tr("FileSize"), &TempOSD.FileSize, -1, 9999));
  Add(new cMenuEditIntItem(tr("FileNumbers"), &TempOSD.FileNumbers, 1, 99));
  Add(new cMenuEditIntItem(tr("BitrateVideo"), &TempOSD.BitrateVideo, -1, 99999));
  if (strcmp(T->C->getACodec(TempOSD.ACodec), "copy") == 0 ) {  
    AddColItem(new cMenuEditIntItem(tr("BitrateAudio"), &TempOSD.BitrateAudio, TempOSD.BitrateAudio, TempOSD.BitrateAudio));
  } else {
    Add(new cMenuEditIntItem(tr("BitrateAudio"), &TempOSD.BitrateAudio, 1, 9999));
  }
  Add(new cMenuEditStraItem(tr("Container"), &TempOSD.Container,
                            T->C->getNumContainers(), T->C->getContainers()));	
  Add(new cMenuEditStraItem(tr("Video-Codec"), &TempOSD.VCodec, 
			    T->C->getNumVCodecs(), T->C->getVCodecs()));
  Add(new cMenuEditStraItem(tr("Audio-Codec"), &TempOSD.ACodec,
			    T->C->getNumACodecs(), T->C->getACodecs()));
  Add(new cMenuEditIntItem(tr("Bpp-Value (*100)"), &TempOSD.Bpp, 1, 99));
  Add(new cMenuEditStraItem(tr("ScaleType"), &TempOSD.ScaleType,
	                    NUMSCALETYPES, ScaleTypes));
}

void cMenuVdrripEditTemplate::OSDChange() {

  if (TempOSD.FileSize != TempOSDsave.FileSize || TempOSD.FileNumbers != TempOSDsave.FileNumbers) {
    T->setFileSize(NumTemplate, TempOSD.FileSize, TempOSD.FileNumbers);
    T->Save();
    Set();

  } else if (TempOSD.BitrateVideo != TempOSDsave.BitrateVideo || TempOSD.BitrateAudio != TempOSDsave.BitrateAudio) {
    T->setBitrate(NumTemplate, TempOSD.BitrateVideo, TempOSD.BitrateAudio);
    T->Save();
    Set();
    
  } else if (TempOSD.VCodec != TempOSDsave.VCodec) {
    T->setCodecs(NumTemplate, TempOSD.VCodec, TempOSD.ACodec);
    T->Save();
    Set();

  } else if (TempOSD.ACodec != TempOSDsave.ACodec) {
    if (strcmp(T->C->getContainer(TempOSD.Container), "avi") == 0 &&
	strcmp(T->C->getACodec(TempOSD.ACodec), "ogg-vorbis") == 0) {
      // avi couldn't contain ogg-vorbis audio
      T->setCodecs(NumTemplate, TempOSD.VCodec, TempOSDsave.ACodec);
    } else {
      T->setCodecs(NumTemplate, TempOSD.VCodec, TempOSD.ACodec);
    }
    T->Save();
    Set();

  } else if (TempOSD.Container != TempOSDsave.Container) {
    if (strcmp(T->C->getContainer(TempOSD.Container), "avi") == 0 &&
	strcmp(T->C->getACodec(TempOSD.ACodec), "ogg-vorbis") == 0) {
      // avi couldn't contain ogg-vorbis audio
      T->setContainer(NumTemplate, TempOSDsave.Container);
    } else {
      T->setContainer(NumTemplate, TempOSD.Container);
    }
    T->Save();
    Set();
    
  } else if (TempOSD.ScaleType != TempOSDsave.ScaleType) {
    T->setScaleType(NumTemplate, TempOSD.ScaleType);
    T->Save();
    Set();

  } else if (TempOSD.Bpp != TempOSDsave.Bpp) {
    T->setBpp(NumTemplate, TempOSD.Bpp);
    T->Save();
    Set();
    
  } else if (strcmp(TempOSD.Name, TempOSDsaveName) != 0) {
    T->setName(NumTemplate, TempOSD.Name);
    T->Save();
  }
}

eOSState cMenuVdrripEditTemplate::ProcessKey(eKeys Key) {

  eOSState state = cOsdMenu::ProcessKey(Key);

  if (Current() == 0) {
    SetHelp(tr("ABC/abc"), tr("Overwrite"), tr("Delete"), NULL);
  } else {
    SetHelp(NULL, NULL, NULL, NULL);

    switch (Key) {
      case k0 ... k9: {
        OSDupdate = false;
        break;
      }

      default: {
        OSDupdate = true;
	break;
      }
    }
  }

  if (OSDupdate) {OSDChange();}
  
  return state;
}

void cMenuVdrripEditTemplate::AddColItem(cOsdItem *i) {
#if VDRVERSNUM < 10307
#ifdef clrScrolLine
   i->SetColor(clrScrolLine, clrBackground);
#else
   i->SetColor(clrCyan, clrBackground);
#endif
#endif

  Add(i);
}

// --- cMenuVdrripMovie ------------------------------------------------------

cMenuVdrripMovie::cMenuVdrripMovie(const char *p, const char *n):cOsdMenu(tr("encode movie"), 15) {
  M = NULL;
  MovOSDsaveName = NULL;
  FileSize[0] = MovieData[0] = CropData[0] = ScaleData[0] = NULL;
  
#if VDRVERSNUM >= 10307
  Skins.Message(mtStatus, tr("reading movie-data..."));
  Skins.Flush();
#else
  Interface->Status(tr("reading movie-data..."));
  Interface->Flush();
#endif

  M = new cMovie(p, n);
  Init(); 
  Set();
} 

cMenuVdrripMovie::~cMenuVdrripMovie() {
  DELETE(M);

  FREE(MovOSDsaveName);
  FREE(FileSize[0]);
  FREE(MovieData[0]);
  FREE(CropData[0]);
  FREE(ScaleData[0]);
}

void cMenuVdrripMovie::Init() {

  OSDupdate = true; 
  Expert    = false;
  Crop      = false;
  CropReset = false;


  // set DVBScaleWidth & DVBScaleHeight
  MovOSD.DVBScaleWidth  = 0;
  MovOSD.DVBScaleHeight = 0;

  if (M->getScaleType() == 2) {
    for (int i = 0; i < 6; i++) {
      if (atoi(DVBScaleWidths[i]) == M->getScaleWidth()) {
	MovOSD.DVBScaleWidth = i;
      }
    }
    
    for (int i = 0; i < 2; i++) {
      if (atoi(DVBScaleHeights[i]) == M->getScaleHeight()) {
	MovOSD.DVBScaleHeight = i;
      }
    }
  }    

  CropWidthsave  = -1;
  CropHeightsave = -1;

  MovOSD.PPDeinterlace = 0;
  MovOSD.PPDeblock = 0;

  NumStatic = 0;
}

void cMenuVdrripMovie::Set() {

  //get movie data
  MovOSD.Name           = M->getName();
  MovOSD.Template       = M->getNumTemplate();
#ifdef VDRRIP_DVD
  if (M->isDVD()) MovOSD.Title = M->getDVDTitle();
#endif //VDRRIP_DVD
  MovOSD.FileSize       = M->getFileSize();
  MovOSD.FileNumbers    = M->getFileNumbers();
  MovOSD.BitrateAudio   = M->getBitrateAudio();
  MovOSD.BitrateVideo   = M->getBitrateVideo();
  MovOSD.Container      = M->getContainer();
  MovOSD.VCodec         = M->getVCodec();
  MovOSD.ACodec         = M->getACodec();
  MovOSD.AudioID        = M->getAudioID();
  MovOSD.ScaleType      = M->getScaleType();
  MovOSD.ScaleWidth     = M->getScaleWidth();
  MovOSD.ScaleHeight    = M->getScaleHeight();

  MovOSD.CropWidth      = M->getCropWidth();
  MovOSD.CropHeight     = M->getCropHeight();
  if (M->getPPValues()) {
    if (strstr(M->getPPValues(), "fd")) MovOSD.PPDeinterlace = 1;
    else if (strstr(M->getPPValues(), "lb")) MovOSD.PPDeinterlace = 2;
    else if (strstr(M->getPPValues(), "li")) MovOSD.PPDeinterlace = 3;
    else if (strstr(M->getPPValues(), "ci")) MovOSD.PPDeinterlace = 4;
    else if (strstr(M->getPPValues(), "md")) MovOSD.PPDeinterlace = 5;
    else MovOSD.PPDeinterlace = 0;

    if (strstr(M->getPPValues(), "hb/vb/dr/al")) MovOSD.PPDeblock = 1;
    else MovOSD.PPDeblock = 0;
  } else {
    MovOSD.PPDeinterlace = 0;
    MovOSD.PPDeblock = 0;
  }
  MovOSD.Bpp           = (int)M->getBpp();

  // save data
  FREE(MovOSDsaveName);
  MovOSDsaveName = strdup(MovOSD.Name);
  MovOSDsave     = MovOSD;

  // rebuild osd
  int current = Current();
  Clear();
  OSDCreate();
  SetCurrent(Get(current));
  Display();

  SetHelpKeys();
}


void cMenuVdrripMovie::SetHelpKeys() {
  if (Current() == 0) {
    SetHelp(tr("ABC/abc"), tr("Overwrite"), tr("Delete"), NULL);
  } else {
    (MovOSD.ScaleType == 1) | (MovOSD.ScaleType == 3) ? Crop = true : Crop = false;
    (MovOSD.CropWidth == -1) && (MovOSD.CropHeight == -1) ? CropReset = false :
                                                        CropReset = true;

    SetHelp(tr("add to queue"), 
	    Crop ? CropReset ? tr("reset boarders") : tr("crop boarders") : NULL,
	    Expert ? tr("expert modus(off)") : tr("expert modus(on)"),
	    NULL);
  }
}




void cMenuVdrripMovie::OSDCreate() {
  char *s = NULL, *l = NULL;
  cOsdItem *i;

  Add(new cMenuEditStrItem(tr("Name"), MovOSD.Name, 32, FileNameChars));

  // Templates:
  i = new cMenuEditStraItem(tr("Template"), &MovOSD.Template, M->T->getNumTemplates(), M->T->getTNames());
  (M->T->getNumTemplates() > 1) ? Add(i) : AddColItem(i);
  FREE(s);

#ifdef VDRRIP_DVD
  if (M->isDVD()) {
    i = new cMenuEditIntItem(tr("Title*") , &MovOSD.Title, 1, M->getNumDVDTitles());
    (M->getNumDVDTitles() > 1) ? Add(i) : AddColItem(i);
    FREE(s);
  }
#endif //VDRRIP_DVD
  
  // FileSize+Numbers
  if (M->getLength() == -1) {
    FREE(FileSize[0]);
    asprintf(&FileSize[0], "%s", tr("unknown"));
    asprintf(&s, "%s", tr("FileSize"));    
    AddColItem(new cMenuEditStraItem(s, &NumStatic, 1, FileSize));
    asprintf(&s, "%s", tr("FileNumbers"));    
    AddColItem(new cMenuEditIntItem(s, &MovOSD.FileNumbers, 1, 1));
    FREE(s);
    l = strdup("Len: ?");
  } else {
    Add(new cMenuEditIntItem(tr("FileSize"), &MovOSD.FileSize, 1, 9999));
    asprintf(&l, "Len: %i", M->getLength());
    Add(new cMenuEditIntItem(tr("FileNumbers"), &MovOSD.FileNumbers, 1, 99));
  }

  // MovieData:
  asprintf(&MovieData[0], "%i:%i(Asp: %1.2f %s Fps: %1.2f)", M->getWidth(),
           M->getHeight(), M->getAspect(), l, M->getFps() / 100);
  AddColItem(new cMenuEditStraItem(tr("MovieData"), &NumStatic, 1,
    MovieData));
  FREE(l);

  // CropData:
  if (M->getCropWidth() == -1 && M->getCropHeight() == -1) {
    if (M->getScaleType() == 0 || M->getScaleType() == 2) {
      asprintf(&CropData[0], "%s", tr("not used"));
    } else {
      asprintf(&CropData[0], "%s", tr("unknown"));
    }
  } else {
    asprintf(&CropData[0], "%i:%i(Asp: %1.2f)", M->getCropWidth(),
      M->getCropHeight(), M->getCalcAspect());
  }
  AddColItem(new cMenuEditStraItem(tr("CropData"), &NumStatic, 1, CropData));
  

  // Bitrate Video
  Add(new cMenuEditIntItem(tr("BitrateVideo"), &MovOSD.BitrateVideo,
    150, 99999));

  // check, if there is a audio-codec available
  if (MovOSD.ACodec != -1) {
    if (strcmp(M->C->getACodec(MovOSD.ACodec), "copy") == 0 ) {
      AddColItem(new cMenuEditIntItem(tr("BitrateAudio"),
        &MovOSD.BitrateAudio, MovOSD.BitrateAudio, MovOSD.BitrateAudio));
      FREE(s);
    } else {
      Add(new cMenuEditIntItem(tr("BitrateAudio"), &MovOSD.BitrateAudio,
        32, 999));
    }
  }

  // Container Format
  i = new cMenuEditStraItem(tr("Container"), &MovOSD.Container,
    M->C->getNumContainers(), M->C->getContainers());
  (M->C->getNumContainers() > 1) ? Add(i) : AddColItem(i);
  FREE(s);

  // check, if there is a video-codec available 
  if (MovOSD.VCodec != -1) {
    Add(new cMenuEditStraItem(tr("Video-Codec"), &MovOSD.VCodec, 
      M->C->getNumVCodecs(), M->C->getVCodecs()));
    Add(new cMenuEditStraItem(tr("Audio-Codec"), &MovOSD.ACodec, 
      M->C->getNumACodecs(), M->C->getACodecs()));
  } 

  // Audio-Stream
  asprintf(&s, "%s %i*", tr("Audio-Str."), M->getAudioID(MovOSD.AudioID));
  i = new cMenuEditStraItem(s, &MovOSD.AudioID, M->getNumAudioID(),
    M->getAudioData());
  FREE(s);
  (M->getNumAudioID() > 1) ? Add(i) : AddColItem(i);

  // ScaleType
  Add(new cMenuEditStraItem(tr("ScaleType"), &MovOSD.ScaleType,
    NUMSCALETYPES, ScaleTypes));

  switch (MovOSD.ScaleType) {
    case 0: { //ScaleType off
      break;
    }

    case 1: { //ScaleType auto
      asprintf(&ScaleData[0], "%i:%i(Asp: %1.2f Bpp: %1.3f)", M->getScaleWidth(), M->getScaleHeight(), (double)M->getScaleWidth() / (double)M->getScaleHeight(), M->getResBpp());
      AddColItem(new cMenuEditStraItem(tr("ScaleData"), &NumStatic, 1,
	ScaleData));
      Add(new cMenuEditIntItem(tr("Bpp-Value (*100)"), &MovOSD.Bpp, 1, 99));
      break;
    }

    case 2: { //ScaleType dvb
      Add(new cMenuEditStraItem(tr("ScaleWidth"), &MovOSD.DVBScaleWidth, 6, DVBScaleWidths));
      Add(new cMenuEditStraItem(tr("ScaleHeight"), &MovOSD.DVBScaleHeight, 2, DVBScaleHeights));
      break;
    }

    case 3: { //ScaleType manual
      Add(new cMenuEditIntItem(tr("ScaleWidth"), &MovOSD.ScaleWidth, 1, 9999));
      Add(new cMenuEditIntItem(tr("ScaleHeight"), &MovOSD.ScaleHeight, 1, 9999));
      break;
    }

    default:
      break;
  }

  //expert menu:
  if (Expert) {
    AddColItem(new cOsdItem(tr("------ expert settings: ------")));
    if (MovOSD.CropWidth != -1 && MovOSD.CropHeight != -1) {
      AddColItem(new cOsdItem(tr("- adjust crop values:")));
      Add(new cMenuEditIntItem(tr("CropWidth"), &MovOSD.CropWidth, 0, M->getWidth()));
      Add(new cMenuEditIntItem(tr("CropHeight"), &MovOSD.CropHeight, 0, M->getHeight()));
    }
      asprintf(&s, tr("- postprocessing Filters(%s):"), M->getPPValues() ? M->getPPValues() : "off");
      AddColItem(new cOsdItem(s));
      FREE(s);
      Add(new cMenuEditStraItem("deinterlacing", &MovOSD.PPDeinterlace, NUMPPDEINT, PPDeintDescriptions));
      Add(new cMenuEditBoolItem("deblocking", &MovOSD.PPDeblock, "off", "on"));
  }

  hadsubmenu = false;
}


void cMenuVdrripMovie::OSDChange() {

  if (MovOSD.Template != MovOSDsave.Template) {
    // save old crop values
    if (M->getScaleType() == 1 || M->getScaleType() == 3) {
      CropWidthsave  = M->getCropWidth();
      CropHeightsave = M->getCropHeight();
    }
    M->setNumTemplate(MovOSD.Template);
    // restore old crop values
    if (M->getScaleType() == 1 || M->getScaleType() == 3) {
      M->setCropValues(CropWidthsave, CropHeightsave);
    }
    M->saveMovieData();
    Set();

#ifdef VDRRIP_DVD
  } else if (M->isDVD() && MovOSD.Title != MovOSDsave.Title && MovOSD.Title > 0) {
#if VDRVERSNUM >= 10307
    Skins.Message(mtStatus, tr("reading audio-data from dvd..."));
    Skins.Flush();
#else
    Interface->Status(tr("reading audio-data from dvd..."));
    Interface->Flush();
#endif
    M->setDVDTitle(MovOSD.Title, true);
    M->saveMovieData();
    Set();
#endif //VDRRIP_DVD
  
  } else if ((MovOSD.FileSize != MovOSDsave.FileSize ||
             MovOSD.FileNumbers != MovOSDsave.FileNumbers) &&
             MovOSD.FileNumbers > 0) {
    M->setFileSize(MovOSD.FileSize, MovOSD.FileNumbers);
    M->saveMovieData();
    Set();

  } else if (MovOSD.BitrateVideo != MovOSDsave.BitrateVideo) {
    M->setBitrate(MovOSD.BitrateVideo, MovOSD.BitrateAudio);
    M->saveMovieData();
    Set();
    
  } else if (MovOSD.BitrateAudio != MovOSDsave.BitrateAudio) {
    M->setBitrate(-1 , MovOSD.BitrateAudio);
    M->saveMovieData();
    Set();

  } else if (MovOSD.Container != MovOSDsave.Container) {
    if (strcmp(M->C->getContainer(MovOSD.Container), "avi") == 0 &&
	strcmp(M->C->getACodec(MovOSD.ACodec), "ogg-vorbis") == 0) {
      // avi couldn't contain ogg-vorbis audio
      M->setContainer(MovOSDsave.Container);
    } else {
      M->setContainer(MovOSD.Container);
    }
    M->saveMovieData();
    Set();
          
  } else if (MovOSD.VCodec != MovOSDsave.VCodec) {
    M->setCodecs(MovOSD.VCodec, MovOSD.ACodec);
    M->saveMovieData();
    Set();

  } else if (MovOSD.ACodec != MovOSDsave.ACodec) {
    if (strcmp(M->C->getContainer(MovOSD.Container), "avi") == 0 &&
	strcmp(M->C->getACodec(MovOSD.ACodec), "ogg-vorbis") == 0) {
      // avi couldn't contain ogg-vorbis audio
      M->setCodecs(MovOSD.VCodec, MovOSDsave.ACodec);
    } else {
      M->setCodecs(MovOSD.VCodec, MovOSD.ACodec);
    }
    M->saveMovieData();
    Set();

  } else if (MovOSD.AudioID != MovOSDsave.AudioID) {
    M->setAudioID(MovOSD.AudioID);
    M->saveMovieData();
    Set();

  } else if (MovOSD.ScaleType != MovOSDsave.ScaleType) {
    // restore - save old crop values
    if (MovOSDsave.ScaleType == 1 || MovOSDsave.ScaleType == 3) {
      CropWidthsave  = M->getCropWidth();
      CropHeightsave = M->getCropHeight();
      M->setScaleType(MovOSD.ScaleType);
    } else {
      M->setScaleType(MovOSD.ScaleType);
      M->setCropValues(CropWidthsave, CropHeightsave);
    }
    M->saveMovieData();
    Set();

  } else if (MovOSD.ScaleWidth  != MovOSDsave.ScaleWidth ||
  MovOSD.ScaleHeight != MovOSDsave.ScaleHeight) {
    M->setScale(MovOSD.ScaleWidth, MovOSD.ScaleHeight);
    M->saveMovieData();
    Set();

  } else if (MovOSD.DVBScaleWidth  != MovOSDsave.DVBScaleWidth ||
  MovOSD.DVBScaleHeight != MovOSDsave.DVBScaleHeight) {
    M->setScale(atoi(DVBScaleWidths[MovOSD.DVBScaleWidth]),
                    atoi(DVBScaleHeights[MovOSD.DVBScaleHeight]));
    M->saveMovieData();
    Set();

  } else if (MovOSD.CropWidth != MovOSDsave.CropWidth || MovOSD.CropHeight != MovOSDsave.CropHeight) {
    if (MovOSD.CropWidth <= MovOSDsave.CropWidth) {
      MovOSD.CropWidth = roundValue(MovOSD.CropWidth, 16);
    } else {MovOSD.CropWidth = roundValue(MovOSD.CropWidth, 16) + 16;}
    
    if (MovOSD.CropHeight <= MovOSDsave.CropHeight) {
      MovOSD.CropHeight = roundValue(MovOSD.CropHeight, 16);
    } else {MovOSD.CropHeight = roundValue(MovOSD.CropHeight, 16) + 16;} 

    M->setCropValues(MovOSD.CropWidth, MovOSD.CropHeight);
    M->saveMovieData();
    Set();

  } else if (MovOSD.PPDeinterlace != MovOSDsave.PPDeinterlace || MovOSD.PPDeblock != MovOSDsave.PPDeblock) {
    if (MovOSD.PPDeinterlace == 0 && MovOSD.PPDeblock == 0) M->setPPValues(NULL);
    else if (MovOSD.PPDeinterlace == 0 && MovOSD.PPDeblock == 1) M->setPPValues("hb/vb/dr/al");
    else if (MovOSD.PPDeinterlace >= 1 && MovOSD.PPDeblock == 0) M->setPPValues(PPDeint[MovOSD.PPDeinterlace]);
    else {
      char *pp = NULL;
      asprintf(&pp, "%s/hb/vb/dr/al", PPDeint[MovOSD.PPDeinterlace]);
      dsyslog(pp);
      M->setPPValues(pp);
      FREE(pp);
    }
    M->saveMovieData();
    Set();

  } else if (MovOSD.Bpp != MovOSDsave.Bpp) {
    M->setBpp(MovOSD.Bpp);
    M->saveMovieData();
    Set();

  } else if (strcmp(MovOSD.Name, MovOSDsaveName) != 0) {
    M->setName(MovOSD.Name);
    M->saveMovieData();
  }
}

eOSState cMenuVdrripMovie::ProcessKey(eKeys Key) {

  eOSState state = cOsdMenu::ProcessKey(Key);

  if (HasSubMenu()) {
    hadsubmenu = true;  
    return osContinue;
  }

  if (hadsubmenu) {
    Set();
    return osContinue;
  }

  SetHelpKeys();

  if (Current() != 0) {

    switch (Key) {
      case k0 ... k9: {
        OSDupdate = false;
        break;
      }

      case kRed: {
	int p;
	Interface->Confirm(tr("<ok> for preview-mode")) ? p = 1 : p = 0;
        if (Interface->Confirm(tr("add movie to encoding queue ?"))) {
	  cQueue *Q;
          struct QueueData *q;
	  Q = new cQueue;
          q = (struct QueueData*)malloc(sizeof(struct QueueData));

          q->Dir          = M->getDir();
          q->Name         = M->getName();
          q->FileSize     = M->getFileSize();
          q->FileNumbers  = M->getFileNumbers();
          q->VCodec       = M->C->getVCodec(M->getVCodec());
          q->BitrateVideo = M->getBitrateVideo();
          q->MinQuant     = MINQUANT;
          q->MaxQuant     = MAXQUANT;
          q->CropWidth    = M->getCropWidth();
          q->CropHeight   = M->getCropHeight();
          q->CropPosX     = M->getCropPosX();
          q->CropPosY     = M->getCropPosY();
          q->ScaleWidth   = M->getScaleWidth();
          q->ScaleHeight  = M->getScaleHeight();
          q->ACodec       = M->C->getACodec(M->getACodec());
          q->BitrateAudio = M->getBitrateAudio();
          q->AudioID      = M->getAudioID(M->getAudioID());
          q->PPValues     = M->getPPValues();
          q->Rename       = VdrripSetup.Rename;
          q->Container    = M->C->getContainer(M->getContainer());
          q->Preview      = p;

          if(Q->New(q)) {
            FREE(q);
            DELETE(Q);
            return osBack;
          } else {
#if VDRVERSNUM >= 10307
	    Skins.Message(mtError, tr("the queuefile is locked by the queuehandler !"));
#else
	    Interface->Error(tr("the queuefile is locked by the queuehandler !"));
#endif
	  }

          FREE(q);
          DELETE(Q);

	  Set();
        }
        break;
      }

      case kGreen: {
        if ((MovOSD.ScaleType == 1) | (MovOSD.ScaleType == 3)) {
	  if (CropReset) {
	    if (Interface->Confirm(tr("reset black movie boarders ?"))) {
	        CropReset = false;
		M->initCropValues();
		M->setScale();
		M->saveMovieData();
	    }
	  } else {
	    if (Interface->Confirm(tr("crop black movie boarders ?"))) {
	      CropReset = true;
#if VDRVERSNUM >= 10307
	      Skins.Message(mtStatus, tr("search for black movie boarders"));
	      Skins.Flush();
#else
              Interface->Status(tr("search for black movie boarders"));
	      Interface->Flush();
#endif
              if (! M->setCropValues()) {
		CropReset = false;
#if VDRVERSNUM >= 10307
		Skins.Message(mtError, tr("couldn't detect black movie boarders !"));
#else
		Interface->Error(tr("couldn't detect black movie boarders !"));
#endif
	      }
	      M->saveMovieData();
            }
	  }
	  Set();
        }
        break;
      }

      case kYellow: {
       Expert ? Expert = false : Expert = true;
	Set();
        break;
      }

      case kOk: {
	const char *l = Get(Current())->Text();
	if (strstr(l, tr("Audio-Str."))) {
	  AddSubMenu(new cMenuVdrripMovieAudio(M));
#ifdef VDRRIP_DVD
	} else if (strstr(l, tr("Title*"))) {
	  AddSubMenu(new cMenuVdrripMovieTitles(M));
#endif //VDRRIP_DVD
	}
	break;
      }

      default: 
        OSDupdate = true;
        break;
    }
  }

  if (OSDupdate) {OSDChange();}

  return state;
}

void cMenuVdrripMovie::AddColItem(cOsdItem *i) {
#if VDRVERSNUM < 10307
#ifdef clrScrolLine
   i->SetColor(clrScrolLine, clrBackground);
#else
   i->SetColor(clrCyan, clrBackground);
#endif
#endif

  Add(i);
}


// --- cMenuVdrripMovieTitles --------------------------------------------

#ifdef VDRRIP_DVD
cMenuVdrripMovieTitles::cMenuVdrripMovieTitles(cMovie *m):cOsdMenu(tr("select dvd title")) {
  M = m;
  char **s = M->getTitleData();
  for (int i = 0; i < M->getNumDVDTitles(); i++) {
    Add(new cOsdItem(s[i]));
  }
  SetCurrent(Get(M->getDVDTitle() - 1));
  SetHelp(NULL, NULL, NULL, NULL);
}

cMenuVdrripMovieTitles::~cMenuVdrripMovieTitles() {}

eOSState cMenuVdrripMovieTitles::ProcessKey(eKeys Key) {

  eOSState state = cOsdMenu::ProcessKey(Key);

  if (Key == kOk) {
#if VDRVERSNUM >= 10307
    Skins.Message(mtStatus, tr("reading audio-data from dvd..."));
    Skins.Flush();
#else
    Interface->Status(tr("reading audio-data from dvd..."));
    Interface->Flush();
#endif
    M->setDVDTitle(Current() + 1, true);
    M->saveMovieData();
    return osBack;
  }
    
  return state;
}
#endif //VDRRIP_DVD

// --- cMenuVdrripMovieAudio --------------------------------------------

cMenuVdrripMovieAudio::cMenuVdrripMovieAudio(cMovie *m):cOsdMenu(tr("select audio stream(s)")) {
  M = m;
  char **s = M->getAudioData2();
  for (int i = 0; i < M->getNumAudioID(); i++) {
    Add(new cOsdItem(s[i]));
  }
  SetCurrent(Get(M->getAudioID()));
  SetHelp(NULL, NULL, NULL, NULL);
}

cMenuVdrripMovieAudio::~cMenuVdrripMovieAudio() {}

eOSState cMenuVdrripMovieAudio::ProcessKey(eKeys Key) {

  eOSState state = cOsdMenu::ProcessKey(Key);

  if (Key == kOk) {
    M->setAudioID(Current());
    M->saveMovieData();
    return osBack;
  }
    
  return state;
}


// --- cVdrripSetup -----------------------------------------------------------

cVdrripSetup VdrripSetup;

cVdrripSetup::cVdrripSetup(void)
{
  MaxScaleWidth    = 704;
  MinScaleWidth    = 480;
  CropMode         = 0;
  CropLength       = 5;
  Rename           = 0;
  OggVorbis        = 0;
  AC3              = 0;
  Ogm              = 0;
  Matroska         = 0;
}

bool cVdrripSetup::SetupParse(const char *Name, const char *Value)
{
  if (!strcasecmp(Name, "MaxScaleWidth"))      MaxScaleWidth = atoi(Value);
  else if (!strcasecmp(Name, "MinScaleWidth")) MinScaleWidth = atoi(Value);
  else if (!strcasecmp(Name, "CropMode"))      CropMode      = atoi(Value);
  else if (!strcasecmp(Name, "CropLength"))    CropLength    = atoi(Value);
  else if (!strcasecmp(Name, "Rename"))        Rename        = atoi(Value);
  else if (!strcasecmp(Name, "OggVorbis"))     OggVorbis     = atoi(Value);
  else if (!strcasecmp(Name, "AC3"))           AC3           = atoi(Value);
  else if (!strcasecmp(Name, "Ogm"))           Ogm           = atoi(Value);
  else if (!strcasecmp(Name, "Matroska"))      Matroska      = atoi(Value);
  else
    return false;
  return true;
}


// --- cMenuVdrripSetup --------------------------------------------------------

cMenuVdrripSetup::cMenuVdrripSetup()
{
  data = VdrripSetup;

  Add(new cMenuEditIntItem(tr("MaxScaleWidth"), &data.MaxScaleWidth, 1, 9999));
  Add(new cMenuEditIntItem(tr("MinScaleWidth"), &data.MinScaleWidth, 1, 9999));
  Add(new cMenuEditStraItem(tr("Crop Mode"), &data.CropMode, 2, CropModes));
  Add(new cMenuEditIntItem(tr("Crop DetectLength (s)"), &data.CropLength, 1, 999));
  Add(new cMenuEditBoolItem(tr("Rename movie after encoding"), &data.Rename, tr("no"), tr("yes")));
  Add(new cMenuEditBoolItem(tr("Ogg-Vorbis support"), &data.OggVorbis, tr("no"), tr("yes")));
  Add(new cMenuEditBoolItem(tr("AC3 support (MPlayer-patch inst.)"), &data.AC3, tr("no"), tr("yes")));
  Add(new cMenuEditBoolItem(tr("Ogm support"), &data.Ogm, tr("no"), tr("yes")));
  Add(new cMenuEditBoolItem(tr("Matroska support"), &data.Matroska, tr("no"), tr("yes")));
}

void cMenuVdrripSetup::Store(void)
{
  // delete unused setup data
  SetupStore("FileSize");
  SetupStore("FileNumbers");
  SetupStore("LameAudioBitrate");
  SetupStore("Bpp");


  VdrripSetup = data;
  SetupStore("MaxScaleWidth", VdrripSetup.MaxScaleWidth);
  SetupStore("MinScaleWidth", VdrripSetup.MinScaleWidth);
  SetupStore("CropMode",      VdrripSetup.CropMode);
  SetupStore("CropLength",    VdrripSetup.CropLength);
  SetupStore("Rename",        VdrripSetup.Rename);
  SetupStore("OggVorbis",     VdrripSetup.OggVorbis);
  SetupStore("AC3",           VdrripSetup.AC3);
  SetupStore("Ogm",           VdrripSetup.Ogm);
  SetupStore("Matroska",      VdrripSetup.Matroska);
}
