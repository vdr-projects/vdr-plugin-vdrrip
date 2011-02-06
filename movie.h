/* movie.h */

#ifndef __MOVIE_H
#define __MOVIE_H

#include <stdio.h>

#include "templates.h"
#include "codecs.h"


extern const char *MPlayer;
#ifdef VDRRIP_DVD
  extern const char *DVD;
#endif  //VDRRIP_DVD

struct AudioData {
  char* Lang;
  char* Format;
  int Bitrate;
  int Freq;
  int Chan;
  int AudioID;
};

#ifdef VDRRIP_DVD
  struct DVDData {
    int Length;
    int Width;
    int Height;
    double Aspect;
    double Fps;
    int NumAudio;
    struct AudioData *A;
  };
#endif //VDRRIP_DVD


class cMovie {
  protected:
    bool Dvd;
    
    char *OrigName;
    char *Name;
    char *Dir;
    int Length;
    int FileSize;
    int FileNumbers;
    int NumTemplate;
    int Bitrate;
    int BitrateVideo;
    int BitrateAudio;
    int Width;
    int Height;
    double Aspect;
    double CalcAspect;
    double Fps;
    int ScaleType;
    int ScaleWidth;
    int ScaleHeight;
    int CropWidth;
    int CropHeight;
    int CropPosX;
    int CropPosY;
    int Bpp;
    int Container;
    int VCodec;
    int ACodec;
    int AudioID;
    int NumAudioID;
    struct AudioData *A;
    char *PPValues;
    
    char *MarksFile;
    char **StrAudioData;
    char **StrAudioData2;

#ifdef VDRRIP_DVD    
    int Title;
    int LongestTitle;
    int NumTitles;
    char **StrTitles;
    struct DVDData* D;
#endif
    
  public:
    cMovie(char *d, char *n);
    ~cMovie();

    cTemplate *T;
    cCodecs *C;

    bool isDVD();

    void setName(char *n);
    char *getName();
    char *getDir();
    void setNumTemplate(int i);
    int getNumTemplate();
    void setBitrate(int v, int a);
    int getBitrateVideo();
    int getBitrateAudio();
    int getLength();

    void setFileSize(int s, int n);
    int getFileSize();
    int getFileNumbers();
    int getHeight();
    int getWidth();
    double getAspect();
    double getCalcAspect();
    double getFps();
    void setScaleType(int s);
    void setScale();
    void setScale(int width, int height);
    int getScaleType();
    int getScaleWidth();
    int getScaleHeight();
    void setCropValues(int width, int height);
    bool setCropValues();
    int getCropHeight();
    int getCropWidth();
    int getCropPosX();
    int getCropPosY();
    void setBpp(int i);
    double getBpp();
    double getResBpp();
    void initCropValues();
    void setContainer(int c);
    int getContainer();
    void setCodecs(int v, int a);
    int getVCodec();
    int getACodec();
    void setAudioID(int i);
    int getAudioID();
    int getNumAudioID();
    void setPPValues(const char *pp);
    const char* getPPValues();
    char** getAudioData();
    char** getAudioData2();
    int getAudioID(int i);

    // VDR-Movie
    void setLengthVDR();
    void queryMpValuesVDR();
    void queryAudioDataVDR();

    void saveMovieData();
    bool restoreMovieData();

#ifdef VDRRIP_DVD
    // DVD
    void queryDVDName();
    void queryDVDData();
    void setDVDTitle(int t, bool st);
    int getDVDTitle();
    int queryAudioBrDVD(int c);
    int getNumDVDTitles();
    char** getTitleData();
#endif //VDRRIP_DVD
};

#endif //__MOVIE_H
