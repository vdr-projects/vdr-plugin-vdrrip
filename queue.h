//
// queue.h
//

#ifndef __QUEUE_H
#define __QUEUE_H

#define QUEUEFILE "queue.vdrrip"
#define LOCKFILE "lock.vdrrip"
#define ENCODEFILE "encode.vdrrip"

struct QueueData {
  const char *Dir;
  char *Name;
  int FileSize;
  int FileNumbers;
  char *VCodec;
  int BitrateVideo;
  int MinQuant;
  int MaxQuant;
  int CropWidth;
  int CropHeight;
  int CropPosX;
  int CropPosY;
  int ScaleWidth;
  int ScaleHeight;
  char *ACodec;
  int BitrateAudio;
  int AudioID;
  const char *PPValues;
  int Rename;
  char *Container;
  int Preview;
};

class cQueue {
  private:
    struct QueueData *Q;
    int NumMovies;
    bool Locked;

    void Load();
    void Set(char *s, int c);

  public:
    cQueue();
    ~cQueue();

    bool Save();
    bool New(struct QueueData *q);
    bool Del(int i);
    bool Up(int i);
    bool Down(int i);
    bool Switch(int i);

    void Lock();
    void Unlock();
    void WaitUnlock();
    bool IsEncoding();
    char *getQueueStat();

    struct QueueData* getData(int i);
    char *getName(int i);
    char *getShortname(int i);
    int getNumMovies();
    bool getLockStat();
};

#endif // __QUEUE_H
