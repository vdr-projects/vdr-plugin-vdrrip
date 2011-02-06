//
// movie.c 
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifdef VDRRIP_DVD
#ifdef NEW_IFO_READ
  #include <stdint.h>
  #include <dvdread/ifo_read.h>
  #include <dvdread/ifo_types.h>
#else
  #include <dvdnav/ifo_read.h>
#endif
#endif //VDRRIP_DVD

#include <vdr/plugin.h>

#include "movie.h"
#include "menu-vdrrip.h"
#include "a-tools.h"
#include "queue.h"
#include "templates.h"

#define SAVEFILE "save.vdrrip"

#define IDENTCMD "%s \'%s\'%s -identify -frames 1 -vo md5sum:outfile=/dev/null -ao null 2>/dev/null | sed -e \'s/[`\\!$\"]/\\&/g\'"
#define CROPCMD "%s \'%s\'%s -vo null -ao null -quiet -ss %i -frames %i -vf cropdetect 2>/dev/null | grep \"crop=\" | sed \"s/.*crop\\(.*\\)).*/\\1/\" | sort | uniq -c | sort -r"
#define AUDIOPID "%s \'%s/00001.ts\' -vo null -ao null -frames 0 2>/dev/null | grep pid | cut -d \')\' -f2 | cut -d \'=\' -f 2"
#define AUDIOCMD "%s \'%s/00001.ts\' -vo null -ao null -frames 0 -aid %i 2>/dev/null | grep ^AUDIO"
#define AUDIOCMDDVD "%s %s -vo null -ao null -frames 0 -aid %i 2>/dev/null | grep ^AUDIO"
#define MENCCMD "%s %s help 2>/dev/null"

// --- cMovie ------------------------------------------------------------


cMovie::cMovie(char *d, char *n) {
  C = NULL;
  T = NULL;
#ifdef VDRRIP_DVD
  D = NULL;
  StrTitles = NULL;
#endif //VDRRIP_DVD

  Dir = OrigName = Name = PPValues = NULL;
  A = NULL;
  StrAudioData = StrAudioData2 = NULL;

  Dir  = strdup(d);
  Name = strdup(n);

  // detect codecs
  C = new cCodecs();

  // detect templates
  T = new cTemplate();

  // init some values
  AudioID = 0;
  initCropValues();

  if (strstr(Dir, "dvd://")) {
    Dvd = true;

#ifdef VDRRIP_DVD
    // detect dvd-data
    queryDVDName();
    queryDVDData();

    if (! restoreMovieData()) {
      NumTemplate = T->getNumTemplate(TDEFAULT);

      setDVDTitle(Title, true);
      // save Movie Data
      saveMovieData();
    }
#endif //VDRRIP_DVD
  } else {
    Dvd = false;

    // detect vdr-data
    setLengthVDR();
    queryMpValuesVDR();
    queryAudioDataVDR();
    
    if (! restoreMovieData()) {
      // set to default template
      NumTemplate = T->getNumTemplate(TDEFAULT);
      setNumTemplate(NumTemplate);

      // save Movie Data
      saveMovieData();
    }
  }
}

cMovie::~cMovie() {
  int i;

  DELETE(C);
  DELETE(T);

  FREE(Dir);
  FREE(OrigName);
  FREE(Name);
  FREE(PPValues);

  for (i = 0; i < NumAudioID; i++) {
    FREE(A[i].Lang);
    FREE(A[i].Format);
    FREE(StrAudioData[i]);
    FREE(StrAudioData2[i]);
  }
  FREE(A);
  FREE(StrAudioData);
  FREE(StrAudioData2);

#ifdef VDRRIP_DVD
  if (Dvd) {
    for (i = 0; i < NumTitles; i++) {
      //TODO: fix this
      //for (i1 = 0; i1 < D[i].NumAudio; i1++) {
        //FREE(D[i].A[i1].Lang);
        //FREE(D[i].A[i1].Format);
      //}
      FREE(D[i].A);
      if (StrTitles) FREE(StrTitles[i]);
    }
    FREE(D);
    FREE(StrTitles);
  }
#endif // VDRRIP_DVD
}

bool cMovie::isDVD() {return Dvd;}

void cMovie::setFileSize(int s, int n) {
  FileNumbers = n;

  if (s == -1 ) {
    // calculate FileSize
    if (Length < 1) {
      FileSize = -1;
    } else {
      FileSize = Bitrate * Length / FileNumbers / 8 / 1024;
    }
  } else {
    // calculate Bitrate
    FileSize = s;
    setBitrate(-1, BitrateAudio);
  }
}

void cMovie::setName(char *n) {Name = n;}

void cMovie::setNumTemplate(int i) {
  // init some values
  NumTemplate = i;
  Bpp         = T->getBpp(NumTemplate);
  FileNumbers = T->getFileNumbers(NumTemplate);
  FileSize    = T->getFileSize(NumTemplate);
  ScaleType   = T->getScaleType(NumTemplate);
    
  // the rest is done here ...
  setContainer(T->getContainer(NumTemplate));
  setCodecs(T->getVCodec(NumTemplate), T->getACodec(NumTemplate));
}

int cMovie::getFileSize() {return FileSize;}

int cMovie::getFileNumbers() {return FileNumbers;}

void cMovie::setBitrate(int v, int a) {
  // avoid BitrateAudio < 32
  if (a < 32 && strcmp(C->getACodec(ACodec), "copy") != 0) {a = 32;}
  BitrateAudio = a;

  if (v == -1) {
    // calculate BitrateVideo
    if (FileSize == -1) {
      // fixed Bitrate
      Bitrate = BitrateVideo + BitrateAudio;
    } else {
      // fixed FileSize
      Bitrate = FileSize * 1024 * FileNumbers * 8 / Length;
     
      // avoid BitrateVideo < 150
      if (Bitrate <= BitrateAudio + 150) {
	Bitrate = BitrateAudio + 150;
        setFileSize(-1, FileNumbers);
      }
      
      // avoid BitrateVideo > 99999
      if (Bitrate > BitrateAudio + 99999) {
	Bitrate = BitrateAudio + 99999;
        setFileSize(-1, FileNumbers);
      }

      BitrateVideo = Bitrate - BitrateAudio;
    }
  } else {
    // calculate FileSize
    BitrateVideo = v;
    Bitrate = BitrateVideo + BitrateAudio;
    setFileSize(-1, FileNumbers);
  }

  setScale();
}

void cMovie::setContainer(int c) {
  if (c >= 0 && c < C->getNumContainers()) {Container = c;
  } else {
    dsyslog("[vdrrip] unknown container, falling back to avi !");
    Container = C->getNumContainer("avi");
  }
}

void cMovie::setScaleType(int s) {
  ScaleType = s;
  setScale();
}

void cMovie::setScale() {
  switch (ScaleType) {
  case 0: {
    // off
    ScaleWidth  = -1;
    ScaleHeight = -1;
    initCropValues();
    break;
  }

  case 1: {
    // auto: this is based on encoding-tips.txt from the mplayer-documentation
    ScaleWidth = roundValue((int)sqrt(BitrateVideo * 1024 * CalcAspect * 100 / Bpp /Fps), 16);
    if (ScaleWidth > VdrripSetup.MaxScaleWidth) {ScaleWidth = VdrripSetup.MaxScaleWidth;}
    if (ScaleWidth < VdrripSetup.MinScaleWidth) {ScaleWidth = VdrripSetup.MinScaleWidth;}
    ScaleHeight = roundValue((int)(ScaleWidth / CalcAspect), 16);
    break;
  }

  case 2: {
    // dvb: set default dvb-values
    ScaleWidth  = 352;
    ScaleHeight = 288;
    initCropValues();
    break;
  }

  case 3: {
    // manual
    ScaleWidth  = Width;
    ScaleHeight = Height;
    break;
  }

  }
}

void cMovie::setScale(int width, int height) {
  ScaleWidth  = width;
  ScaleHeight = height;
}

void cMovie::setCropValues(int width, int height) {
  CropWidth  = width;
  if (CropWidth > Width) CropWidth = Width;
  
  CropHeight = height;
  if (CropHeight > Height) CropHeight = Height;

  if (CropWidth == -1) CropPosX = -1;
  else CropPosX = (Width - CropWidth) / 2;

  if (CropHeight == -1) {
    CropPosY = -1;
    CalcAspect = Aspect;
  } else {
    CropPosY = (Height - CropHeight) / 2;
    CalcAspect = Height * Aspect / CropHeight;
  }

  setScale();
}


bool cMovie::setCropValues() {
  char *cmd = NULL, *buf = NULL;
  bool ret = true;

  size_t i = 0;
  int l = 0;
  int l1;

  if (Dvd) {asprintf(&cmd, IDENTCMD, MPlayer, Dir, "");
  } else {asprintf(&cmd, IDENTCMD, MPlayer, Dir, "/00001.ts");}

  FILE *p = popen(cmd, "r");
  if (p) {
    char *s = NULL;
    s = strcol(strgrep("ID_LENGTH", p), "=", 2);
    if (s) {l = atoi(s);}
    FREE(s);
  } else {
    dsyslog("[vdrrip] could not open pipe to %s !", cmd);
  }
  pclose(p);
  FREE(cmd);


  l1 = VdrripSetup.CropLength * (int)Fps;
  if (Dvd) {
    asprintf(&cmd, CROPCMD, MPlayer, Dir, "", l/2, l1);
    isyslog("[vdrrip] detecting crop values in %s", Dir);
  } else {
    asprintf(&cmd, CROPCMD, MPlayer, Dir, "/00001.ts", l/2, l1);
    isyslog("[vdrrip] detecting crop values in %s/00001.ts", Dir);
  }
  p = popen(cmd, "r");
  FREE(cmd);

  if (p) {
    //  get first line
    if (getline(&buf, &i, p) != -1) {
      char *s = NULL;

      s = strcol(buf, "=", 2);
      CropWidth = roundValue(atoi(strcol(s, ":", 1)), 16);
      if (CropWidth > Width || CropWidth < 0) {
	ret = false;
	CropWidth = Width;
      }
      
      CropHeight = roundValue(atoi(strcol(s, ":", 2)), 16);
      if (CropHeight > Height || CropHeight < 0) {
	ret = false;
	CropHeight = Height;
      }

      if (VdrripSetup.CropMode == 1) {CropWidth = Width;} 
      CropPosX = (Width - CropWidth) / 2;
      CropPosY = (Height - CropHeight) / 2;
      // CalcAspect is changed now:
      CalcAspect = Height * Aspect / CropHeight;
      setScale();

      FREE(s);
      FREE(buf);
    } else {
      ret = false;
    }

  pclose(p);
  } else ret = false;

  if (! ret) initCropValues();

  return ret;
}

void cMovie::initCropValues() {
  CropWidth  = -1;
  CropHeight = -1;
  CropPosX   = -1;
  CropPosY   = -1;
  CalcAspect = Aspect;
}

void cMovie::setCodecs(int v, int a) {
  // validate video codec
  if (v >= 0 && v < C->getNumVCodecs()) {VCodec = v;
  } else {
    dsyslog("[vdrrip] unknown video codec, falling back to %s !", C->getVCodec(0));
    VCodec = 0;
  }
  
  // validate audio codec
  if (a >= 0 && a < C->getNumACodecs()) {
    if (strcmp(C->getContainer(Container), "avi") == 0 &&
	strcmp(C->getACodec(a), "ogg-vorbis") == 0) {
      dsyslog("[vdrrip] avi couldn't contain ogg-vorbis audio, falling back to copy !");
      ACodec = C->getNumACodec("copy");
    } else {ACodec = a;}
  } else {
    dsyslog("[vdrrip] unknown audio codec, falling back to copy !"),
    ACodec = C->getNumACodec("copy");
  }

  // set audio bitrates
  if (ACodec == C->getNumACodec("copy")) {
    setBitrate(T->getBitrateVideo(NumTemplate), A[AudioID].Bitrate);
  } else {
    setBitrate(T->getBitrateVideo(NumTemplate), T->getBitrateAudio(NumTemplate));
  }
}

void cMovie::setBpp(int i) {
  Bpp = i;
  setScale();
}

int cMovie::getBitrateAudio() {return BitrateAudio;}

int cMovie::getBitrateVideo() {return BitrateVideo;}

int cMovie::getLength() {return Length;}

int cMovie::getWidth() {return Width;}

int cMovie::getHeight() {return Height;}

double cMovie::getAspect() {return Aspect;}

double cMovie::getCalcAspect() {return CalcAspect;}

double cMovie::getFps() {return Fps;}

int cMovie::getContainer() {return Container;}

int cMovie::getScaleType() {return ScaleType;}

int cMovie::getScaleWidth() {return ScaleWidth;}

int cMovie::getScaleHeight() {return ScaleHeight;}

int cMovie::getCropWidth() {return CropWidth;}

int cMovie::getCropHeight() {return CropHeight;}

int cMovie::getCropPosX() {return CropPosX;}

int cMovie::getCropPosY() {return CropPosY;}

double cMovie::getResBpp() {
  return (double)BitrateVideo * 1024. / (double)ScaleWidth / (double)ScaleHeight / Fps;}

double cMovie::getBpp() {return (double)Bpp;}

char *cMovie::getName() {return Name;}

int cMovie::getNumTemplate() {return NumTemplate;}

char *cMovie::getDir() {return Dir;}

int cMovie::getNumAudioID() {return NumAudioID;}

int cMovie::getAudioID() {return AudioID;}

void cMovie::setAudioID(int i) {
  if (i >= 0 && i < NumAudioID) {
    AudioID = i;
  } else {
    dsyslog("[vdrrip] %d is not a valid audio-id, falling back to 0 !", AudioID);
    AudioID = 0;
  }
  setCodecs(VCodec, ACodec);
}

int cMovie::getVCodec() {return VCodec;}

int cMovie::getACodec() {return ACodec;}

void cMovie::setPPValues(const char *pp) {
  FREE(PPValues);
  if (pp) {
    PPValues = strdup(pp);
  } else {
    PPValues = NULL;
  }
}

const char* cMovie::getPPValues() {return PPValues;}


// --- VDR-Movie ---------------------------------------------------------


void cMovie::setLengthVDR() {
  char *file = NULL;

  asprintf(&file, "%s/index", Dir);
  FILE *f = fopen(file, "r");
  if (f) {
    fseek(f, 0, SEEK_END);
    Length = ftell(f) / 200;
    fclose(f);
  } else {
      dsyslog("[vdrrip] could not open file %s !", file);
      dsyslog("[vdrrip] perhaps you have to create it with genindex.c !");
      Length = -1;
  }

  FREE(file);
}


void cMovie::queryMpValuesVDR() {
  char *cmd = NULL, *s = NULL;

  asprintf(&cmd, IDENTCMD, MPlayer, Dir, "/00001.ts");
  FILE *p = popen(cmd, "r");
  if (p) {
    s = strcol(strgrep("ID_VIDEO_WIDTH", p), "=", 2);
    if (s) {
      Width = atoi(s);
    } else {Width = -1;}
    FREE(s);

    s = strcol(strgrep("ID_VIDEO_HEIGHT", p), "=", 2);
    if (s) {
      Height = atoi(s);
    } else {Height = -1;}
    FREE(s);

    s = strcol(strgrep("ID_VIDEO_FPS", p), "=", 2);
    if (s) {
      Fps = atof(s);
    } else {Fps = -1;}
    FREE(s);

    s = strcol(strgrep("ID_VIDEO_ASPECT", p), "=", 2);
    if (s && atof(s) == 0.0) { // Workaround for mplayer-1.0rc1: search for second aspect line
      s = strcol(strgrep("ID_VIDEO_ASPECT", p), "=", 2);
      dsyslog("VDRRIP-FIX: searched for second aspect line: %s", s);
    }
    if (s) {
      Aspect = atof(s);
      if (Aspect == (double)(int)Aspect) { // Workaround for locale problems
        if (strchr(s, '.'))
          *strchr(s, '.') = ',';
        else if (strchr(s, ','))
          *strchr(s, ',') = '.';
        dsyslog("VDRRIP-FIX: tried to solve locale problem: %s", s);
        Aspect = atof(s);
      }
    } else {Aspect = -1;}

    if (Aspect <= 0.0) { // Workaround for mplayer-1.0pre7
      pclose(p);
      p = popen(cmd, "r");
      if (p && strgrep("(aspect 3)", p)) {
        Aspect = 1.7778; // 16:9
        dsyslog("VDRRIP-FIX: found (aspect 3) - set aspect to 16:9");
      } else {
        Aspect = 1.3333; // 4:3
        dsyslog("VDRRIP-FIX: (aspect 3) NOT found - set aspect to 4:3");
      }
    }

    CalcAspect = Aspect;

    pclose(p);
  } else {dsyslog("[vdrrip] could not open pipe to %s !", cmd);}

  FREE(s);
  FREE(cmd);
}


void cMovie::queryAudioDataVDR() {
  char *cmd = NULL, *buf = NULL;
  size_t i = 0;
  int n = 0;
  
  // Get Audio PID
  asprintf(&cmd, AUDIOPID, MPlayer, Dir);
  FILE *apid = popen(cmd,"r");
  isyslog ("Getting Audio PID of ts: %s",cmd);
  int c = 0;
  if (apid && getline(&buf,&i,apid) != -1) {
      c = atoi (buf);
  }
  pclose(apid);
  isyslog("Pid selected : %i",c);
  
  bool next = true;

  while (next) {
    asprintf(&cmd, AUDIOCMD, MPlayer, Dir, c);
    FILE *p = popen(cmd, "r");
    if (p) {
      if (getline(&buf, &i, p) != -1) {
	if (c == 255) {next = false;}
	A = (struct AudioData*)realloc(A, (n + 1) * sizeof(struct AudioData));

	A[n].AudioID = c;
	A[n].Lang   = strdup(tr("unknown"));

	if (c == 128) {A[n].Format = strdup("ac3");
	} else {A[n].Format = strdup("mp2");}

	char *s = NULL;
        s = strcol(buf, " ", 2);
	if (s) {A[n].Freq = atoi(s);
	} else {A[n].Freq = 0;}
	FREE(s);

        s = strcol(buf, " ", 4);
	if (s) {A[n].Chan = atoi(s);
	} else {A[n].Chan = 0;}
	FREE(s);

        s = strcol(buf, " ", 11);
	if (s) {
	  A[n].Bitrate = atoi(s + sizeof(char));
	} else {A[n].Bitrate = 192;}
        FREE(s);
	
	// isyslog("[vdrrip] Audio-ID %i found: lang %s, format %s, %i kbit, %i Hz, %i ch", A[n].AudioID, A[n].Lang, A[n].Format, A[n].Bitrate, A[n].Freq, A[n].Chan);
        n++;
	c++;
      } else {
	// nothing found:
	if (c < 128 && VdrripSetup.AC3 == 1) {c = 128;
	} else {next = false;}
      }
    pclose(p);
    } else {dsyslog("[vdrrip] could not open pipe to %s !", cmd);}
  }

  NumAudioID = n;
    
  // write AudioData to an array
  if (NumAudioID > 0) {
    StrAudioData  = (char **)malloc(NumAudioID * sizeof(char*));
    StrAudioData2 = (char **)malloc(NumAudioID * sizeof(char*));
    for (c = 0; c < NumAudioID; c++) {
      asprintf(&StrAudioData[c], "%s, %i kbit, lang: %s", A[c].Format, A[c].Bitrate, A[c].Lang);

      asprintf(&StrAudioData2[c], "%d: %s, %d kbit, %i chan, %d hz, lang: %s", A[c].AudioID, A[c].Format, A[c].Bitrate, A[c].Chan, A[c].Freq, A[c].Lang);
    }
  } else {
    dsyslog("[vdrrip] no Audio ID found !");
    A = (struct AudioData*)malloc(sizeof(struct AudioData));
    A[0].Lang    = strdup(tr("unknown"));
    A[0].Format  = strdup(tr("unknown"));
    A[0].Bitrate = 0;
    A[0].Freq    = 0;
    A[0].Chan    = 0;
    A[0].AudioID = 0;
    
    StrAudioData = (char **)malloc(sizeof(char*));
    asprintf(&StrAudioData[0], tr("not found"));
    NumAudioID = 1;
  }

  FREE(buf);
  FREE(cmd);
}

int cMovie::getAudioID(int i) {
  if (i >= 0 && i < NumAudioID) {
    return A[i].AudioID;
  } else {return 0;}
}

char **cMovie::getAudioData() {return StrAudioData;}
  
char **cMovie::getAudioData2() {return StrAudioData2;}

void cMovie::saveMovieData() {
  char *file = NULL;

  if (Dvd) {
    if (OrigName) asprintf(&file, "/tmp/%s.vdrrip", OrigName);
    else return;
  } else asprintf(&file, "%s/%s", Dir, SAVEFILE);
  
  FILE *f = fopen(file,"w");
  if (f) {
    fprintf(f,"%s;%i;%i;%i;%s;%i;%i;%i;%i;%i;%i;%i;%i;%i;%s;%i;%i;%s;%s;%s;%d\n",
    Name, FileSize, FileNumbers, Bitrate, C->getVCodec(VCodec), BitrateVideo,
    CropWidth, CropHeight, CropPosX, CropPosY, ScaleType, ScaleWidth,
    ScaleHeight, Bpp, C->getACodec(ACodec), BitrateAudio, AudioID, PPValues,
    T->getName(NumTemplate), C->getContainer(Container),
#ifdef VDRRIP_DVD
      Dvd ? Title : 0
#else
      0
#endif //VDRRIP_DVD
    );

    fclose(f);
  } else {dsyslog("[vdrrip] could not open file %s !", file);}

  FREE(file);
}

bool cMovie::restoreMovieData() {
  char *file = NULL, *vcodec = NULL, *acodec = NULL, *tname = NULL,
       *container = NULL, *buf = NULL;
  size_t i = 0;

  if (Dvd) {
    if (OrigName) asprintf(&file, "/tmp/%s.vdrrip", OrigName);
    else return false;
  } else asprintf(&file, "%s/%s", Dir, SAVEFILE);

  FILE *f = fopen(file,"r");
  if (f) {
    if (getline(&buf, &i, f) != -1) {
      Name          = strcol(buf, ";",  1);
      FileSize      = atoi(strcol(buf, ";",  2));
      FileNumbers   = atoi(strcol(buf, ";",  3));
      Bitrate       = atoi( strcol(buf, ";", 4));
      vcodec        = strcol(buf, ";",  5);
      BitrateVideo  = atoi(strcol(buf, ";",  6));
      CropWidth     = atoi(strcol(buf, ";",  7));
      CropHeight    = atoi(strcol(buf, ";",  8));
      CropPosX      = atoi(strcol(buf, ";",  9));
      CropPosY      = atoi(strcol(buf, ";", 10));
      ScaleType     = atoi(strcol(buf, ";", 11));
      ScaleWidth    = atoi(strcol(buf, ";", 12));
      ScaleHeight   = atoi(strcol(buf, ";", 13));
      Bpp           = atoi(strcol(buf, ";", 14));
      acodec        = strcol(buf, ";", 15);
      BitrateAudio  = atoi(strcol(buf, ";", 16));
      AudioID       = atoi(strcol(buf, ";", 17));
      PPValues      = strcol(buf, ";", 18);
      if (strcmp(PPValues, "(null)") == 0) PPValues = NULL;
      tname         = strcol(buf, ";", 19);
      // migrate from version 0.1.1
      container     = strcol(buf, ";", 20);
      if (! container) container = strdup("avi");
#ifdef VDRRIP_DVD
      // migrate from version 0.2.0a
      if (Dvd) Title = atoi(strcol(buf, ";", 21));
#endif //VDRRIP_DVD

      FREE(buf);

      fclose(f);
      isyslog("[vdrrip] restored data from file %s !", file);

      // validate some values:
      if (! Dvd) setCropValues(CropWidth, CropHeight);

      NumTemplate = T->getNumTemplate(tname);
      if (NumTemplate == -1) {
        dsyslog("[vdrrip] %s is not a valid template, falling back to default !", tname);
	NumTemplate = T->getNumTemplate(TDEFAULT);
      }
      FREE(tname);

#ifdef VDRRIP_DVD
      if (Dvd) setDVDTitle(Title, false);
#endif //VDRRIP_DVD

      setContainer(C->getNumContainer(container));
      FREE(container);

      setCodecs(C->getNumVCodec(vcodec), C->getNumACodec(acodec));
      FREE(vcodec);
      FREE(acodec);

      setAudioID(AudioID);

    } else {
      dsyslog("[vdrrip] could not read data from file %s !", file);
      FREE(file);
      return false;
    }
  } else {
    dsyslog("[vdrrip] could not open file %s, perhaps it is not available !", file);
    FREE(file);
    return false;
  }
  FREE(file);

  saveMovieData();
  return true;
}


// --- DVD-Movie ---------------------------------------------------------

#ifdef VDRRIP_DVD
void cMovie::queryDVDName() {
  int  i;
  char name[33];

  FILE *f = fopen(DVD, "r");
  
  if (f) {
    if (! fseek(f, 32808, SEEK_SET )) {
      i = fread(name, 1, 32, f);
      if (i == 32) {
	name[32] = '\0';
        while(i-- > 2) {if (name[i] == ' ') name[i] = '\0';}
        Name = strdup(name);
	OrigName = strdup(name);
      } else {
	dsyslog("[vdrrip] Couldn't read enough bytes for title !");
	Name = strdup(tr("unknown"));
      }
    } else {
      dsyslog("[vdrrip] Couldn't seek in %s for title", DVD);
      Name = strdup(tr("unknown"));
    }

    fclose(f);
  } else {
    dsyslog("[vdrrip] Couldn't open %s for title", DVD);
    Name = strdup(tr("unknown"));
  }
}

void cMovie::queryDVDData() {
  //
  // parts of this code are pasted from the tool lsdvd by chris phillips
  // which is hosted at http://sourceforge.net/projects/acidrip/
  //
  // thx a lot...
  //
  dvd_reader_t *dvd = NULL;
  ifo_handle_t *ifo_zero = NULL, **ifo = NULL;
  pgcit_t *vts_pgcit;
  vtsi_mat_t *vtsi_mat;
  vmgi_mat_t *vmgi_mat;
  audio_attr_t *audio_attr;
  video_attr_t *video_attr;
  pgc_t *pgc;
  dvd_time_t *dt;

  int i, i1, vts_ttn, numifos, numifo;
  int l = 0;

  Title = 1;
  NumTitles = 0;

  const char *audio_format[] = {"ac3", "?", "mpeg1", "mp2", "lpcm ", "sdds ", "dts"};
  const char *sample_freq[]  = {"48000", "48000"};
  const int height[]    = {480, 576};
  const int width[]     = {720, 704, 352, 352};
  const double aspect[] = {4.0/3.0, 16.0/9.0, 1/1, 16.0/9.0};
  const double fps[]    = {-1.0, 25.00, -1.0, 29.97};


  dvd = DVDOpen(DVD);

  if (dvd) {
    ifo_zero = ifoOpen(dvd, 0);

    if (ifo_zero) {
      // read needed data from ifo_zero
      numifos   = ifo_zero->vts_atrt->nr_of_vtss;
      vmgi_mat  = ifo_zero->vmgi_mat;
      NumTitles = ifo_zero->tt_srpt->nr_of_srpts;

      // reserve memory for numifos ifos
      ifo = (ifo_handle_t **)malloc((numifos + 1) * sizeof(ifo_handle_t *));

      // save ifo data
      for (i = 1; i <= numifos; i++) {
        ifo[i] = ifoOpen(dvd, i);
        if (! ifo[i]) dsyslog("[vdrrip] Can't open ifo %d !", i);
      }

      // reserve memory for DVDData
      D = (struct DVDData *)malloc((NumTitles + 1) * sizeof(struct DVDData));

      // read movie data    
      for (i = 0; i < NumTitles; i++) {
        // get ifo number for title i
        numifo = ifo_zero->tt_srpt->title[i].title_set_nr;

        if (ifo[numifo]->vtsi_mat) {
          vtsi_mat     = ifo[numifo]->vtsi_mat;
	  vts_pgcit    = ifo[numifo]->vts_pgcit;
	  video_attr   = &vtsi_mat->vts_video_attr;
	  vts_ttn      = ifo_zero->tt_srpt->title[i].vts_ttn;
	  vmgi_mat     = ifo_zero->vmgi_mat;
	  pgc          = vts_pgcit->pgci_srp[ifo[numifo]->vts_ptt_srpt->title[vts_ttn - 1].ptt[0].pgcn - 1].pgc;
	  dt           = &pgc->playback_time;
	  
          // read the movie-data of the title into the struc DVDData:
	  D[i].Length  = (((dt->hour &   0xf0) >> 3) * 5 + (dt->hour   & 0x0f)) * 3600;
	  D[i].Length += (((dt->minute & 0xf0) >> 3) * 5 + (dt->minute & 0x0f)) * 60;
	  D[i].Length += (((dt->second & 0xf0) >> 3) * 5 + (dt->second & 0x0f));
	  if (D[i].Length == 0) {D[i].Length = -1;}

	  D[i].Width    = width[video_attr->picture_size];
	  D[i].Height   = height[video_attr->video_format];
	  D[i].Aspect   = aspect[video_attr->display_aspect_ratio];
	  D[i].Fps      = fps[(pgc->playback_time.frame_u & 0xc0) >> 6];

          D[i].NumAudio = vtsi_mat->nr_of_vts_audio_streams;
          // reserve memory for DVDAudioData
          D[i].A = (struct AudioData*)malloc(D[i].NumAudio * sizeof(struct AudioData));

          for (i1 = 0; i1 < D[i].NumAudio; i1++) {
            audio_attr = &vtsi_mat->vts_audio_attr[i1];

            asprintf(&D[i].A[i1].Lang, "%c%c", audio_attr->lang_code >> 8, audio_attr -> lang_code & 0xff);
            D[i].A[i1].Format = strdup(audio_format[audio_attr->audio_format]);
            D[i].A[i1].Freq   = atoi(sample_freq[audio_attr->sample_frequency]);
	    D[i].A[i1].Chan   = audio_attr->channels+1;
	    D[i].A[i1].AudioID = 128 + i1;
	    D[i].A[i1].Bitrate = -1;
          }
	    
          // save number of the longest Title
          if (D[i].Length > l) {
            l = D[i].Length;
            Title  = i + 1;
	    LongestTitle = Title;
          }
	}
      }

      // close ifos
      ifoClose(ifo_zero);
      for (i = 1; i <= numifos; i++) {
	if(ifo[i]) ifoClose(ifo[i]);
      }
      FREE(ifo);
    
      
      DVDClose(dvd);
    } else {dsyslog("[vdrrip] Can't open main ifo !");}
  } else {dsyslog("[vdrrip] Can't open disc %s !", DVD);}


}


void cMovie::setDVDTitle(int t, bool st) {

  if (t > 0 && t <= NumTitles) Title = t;
  else {
    dsyslog("[vdrrip] Unknown title %d, setting back to longest Title %d !", t, LongestTitle);
    Title = LongestTitle;
    st = true;
  }

  // set directory-name (for the queuehandler)
  FREE(Dir);
  asprintf(&Dir, "dvd://%i", Title);

  // set video data:
  Length     = D[Title - 1].Length;
  Width      = D[Title - 1].Width;
  Height     = D[Title - 1].Height;
  Fps        = D[Title - 1].Fps;
  Aspect     = D[Title - 1].Aspect;

  if (st) initCropValues(); // no restore
  else setCropValues(CropWidth, CropHeight);

  // set audio data:
  if (st) AudioID = 0; // no restore
  NumAudioID = D[Title - 1].NumAudio;
  
  if (NumAudioID > 0) {
    A = (struct AudioData*)realloc(A, NumAudioID * sizeof(struct AudioData));
    StrAudioData  = (char **)realloc(StrAudioData,  NumAudioID * sizeof(char*));
    StrAudioData2 = (char **)realloc(StrAudioData2, NumAudioID * sizeof(char*));

    for (int i = 0; i < NumAudioID; i++) {

      // get audio bitrate
      if (D[Title -1].A[i].Bitrate == -1) {D[Title -1].A[i].Bitrate = queryAudioBrDVD(D[Title -1].A[i].AudioID);}
      A[i] = D[Title - 1].A[i];

      asprintf(&StrAudioData[i], "%s, %d kbit, lang: %s", A[i].Format, A[i].Bitrate, A[i].Lang);

      asprintf(&StrAudioData2[i], "%d: %s, %d kbit, %d chan, %d hz, lang: %s", A[i].AudioID, A[i].Format, A[i].Bitrate, A[i].Chan, A[i].Freq, A[i].Lang);
    }
  } else {
    dsyslog("[vdrrip] no Audio ID found !");
    A = (struct AudioData*)realloc(A, sizeof(struct AudioData));
    A[0].Lang    = strdup(tr("unknown"));
    A[0].Format  = strdup(tr("unknown"));
    A[0].Bitrate = 0;
    A[0].Freq    = 0;
    A[0].Chan    = 0;
    A[0].AudioID = 0;
    
    StrAudioData = (char **)realloc(StrAudioData, sizeof(char*));
    asprintf(&StrAudioData[0], tr("not found"));
    NumAudioID = 1;
  }

  if (st) setNumTemplate(NumTemplate); // no restore
}

int cMovie::queryAudioBrDVD(int c) {
  char *cmd = NULL, *buf = NULL;
  size_t i = 0;
  int b = 0;

  asprintf(&cmd, AUDIOCMDDVD, MPlayer, Dir, c);
  FILE *p = popen(cmd, "r");
  if (p) {
    if (getline(&buf, &i, p) != -1) {
      char *s = strcol(buf, " ", 11);
      if (s) {
	b = atoi(s + sizeof(char));
        FREE(s);
      }
    }
    pclose(p);
  } else {dsyslog("[vdrrip] could not open pipe to %s !", cmd);}


  FREE(buf);
  FREE(cmd);

  return b;
}

int cMovie::getDVDTitle() {return Title;}

int cMovie::getNumDVDTitles() {return NumTitles;}

char **cMovie::getTitleData() {
  StrTitles = (char **)malloc(NumTitles * sizeof(char*));
  for (int i = 0; i < NumTitles; i++)
    asprintf(&StrTitles[i], "Title %d: %i audio channels, length: %d sec.", i + 1, D[i].NumAudio, D[i].Length);

  return StrTitles;
}
#endif //VDRRIP_DVD
