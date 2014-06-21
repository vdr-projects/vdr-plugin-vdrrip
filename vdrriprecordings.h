//
// vdrriprecordings.h
//

#ifndef __VDRRIPRECORDINGS_H
#define __VDRRIPRECORDINGS_H

class cVdrripRecordings {
  private:
    char **Name;
    char **Date;
    char **Path;

    int NumRec;

  public:
    cVdrripRecordings();
    ~cVdrripRecordings();

    void ReadRec();
    int getNumRec();
    char *getName(int i);
    char *getDate(int i);
    char *getPath(int i);
};

#endif // __VDRRIPRECORDINGS_H
