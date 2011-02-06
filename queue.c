//
// queue.c
//

#include <stdio.h>
#include <stdlib.h>
#include <vdr/plugin.h>

#include "queue.h"
#include "a-tools.h"

cQueue::cQueue() {
  Q = NULL;

  WaitUnlock();
  if (! Locked) {Lock();}
  Load();  
}

cQueue::~cQueue() {
  if (! Locked) {Unlock();}
  DELETE(Q);
}

void cQueue::Load() {
  char *buf = NULL;
  size_t i = 0;
  int c = 0;

  FILE *q = fopen(AddDirectory(cPlugin::ConfigDirectory(), QUEUEFILE), "r");
  if (q) {
    // read QueueData
    while (getline(&buf, &i, q) != -1) {
      // reserve memory for QueueData
      Q = (struct QueueData*)realloc(Q, (c + 1) * sizeof(struct QueueData));
      Q[c].Dir          = strcol(buf, ";", 1);
      Q[c].Name         = strcol(buf, ";", 2);
      Q[c].FileSize     = atoi(strcol(buf, ";", 3));
      Q[c].FileNumbers  = atoi(strcol(buf, ";", 4));
      Q[c].VCodec       = strcol(buf, ";", 5);
      Q[c].BitrateVideo = atoi(strcol(buf, ";", 6));
      Q[c].MinQuant     = atoi(strcol(buf, ";", 7));
      Q[c].MaxQuant     = atoi(strcol(buf, ";", 8));
      Q[c].CropWidth    = atoi(strcol(buf, ";", 9));
      Q[c].CropHeight   = atoi(strcol(buf, ";", 10));
      Q[c].CropPosX     = atoi(strcol(buf, ";", 11));
      Q[c].CropPosY     = atoi(strcol(buf, ";", 12));
      Q[c].ScaleWidth   = atoi(strcol(buf, ";", 13));
      Q[c].ScaleHeight  = atoi(strcol(buf, ";", 14));
      Q[c].ACodec       = strcol(buf, ";", 15);
      Q[c].BitrateAudio = atoi(strcol(buf, ";", 16));
      Q[c].AudioID      = atoi(strcol(buf, ";", 17));
      Q[c].PPValues     = strcol(buf, ";", 18);
      Q[c].Rename       = atoi(strcol(buf, ";", 19));
      // migrate from version 0.1.1
      char *cont        = strcol(buf, ";", 20);
      cont ? Q[c].Container = cont : Q[c].Container = strdup("avi");
      // migrate from version 0.2.0a
      char *prev        = strcol(buf, ";", 21);
      prev ? Q[c].Preview = atoi(prev) : Q[c].Preview = 0;

      FREE(buf);
      c++;
    }

    fclose(q);
  } else {dsyslog("[vdrrip] could not open file %s, the queue is probably empty !", QUEUEFILE);}

  NumMovies = c;
}


bool cQueue::Save() {
  FILE *q;
  int c;
  int n = 0;

  if (Locked) {
    Load();
    return false;
  }

  q = fopen(AddDirectory(cPlugin::ConfigDirectory(), QUEUEFILE), "w");
  if (q) {
    for (c = 0; c < NumMovies; c++) {
      if (strcmp(Q[c].Name, "delete") != 0) {
        fprintf(q,"%s;%s;%i;%i;%s;%i;%i;%i;%i;%i;%i;%i;%i;%i;%s;%i;%i;%s;%i;%s;%i\n",
        Q[c].Dir, Q[c].Name, Q[c].FileSize, Q[c].FileNumbers, Q[c].VCodec,
        Q[c].BitrateVideo, Q[c].MinQuant, Q[c].MaxQuant, Q[c].CropWidth,
        Q[c].CropHeight, Q[c].CropPosX, Q[c].CropPosY, Q[c].ScaleWidth,
        Q[c].ScaleHeight, Q[c].ACodec, Q[c].BitrateAudio, Q[c].AudioID,
        Q[c].PPValues, Q[c].Rename, Q[c].Container, Q[c].Preview);
	n++;
      }
    }
    NumMovies = n;
    
    fclose(q);

    // delete queuefile if it's empty
    if (NumMovies < 1) {
      remove(AddDirectory(cPlugin::ConfigDirectory(), QUEUEFILE));
    }
  } else {dsyslog("[vdrrip] could not save %s", QUEUEFILE);}

  Load();

  return true;
}

bool cQueue::New(struct QueueData *q) {
  if (Locked) {return false;}

  Q = (struct QueueData*)realloc(Q, ((NumMovies + 1) * sizeof(struct QueueData)));
  Q[NumMovies] = *q;

  NumMovies++;
  Save();

  return true;
}


bool cQueue::Del(int i) {
  if (i >= 0 && i < NumMovies) {

    // don't delete the first entry of the queuefile,
    // if there is an aktiv encoding
    if (i == 0 && IsEncoding()) {return false;}

    isyslog("added delete flag on movie %s", Q[i].Name);
    Q[i].Name = strdup("delete");
    Save();

    return true;
  }
  return false;
}

bool cQueue::Up(int i) {
  if (i >= 1 && i < NumMovies) {

    // don't move to the first entry of the queuefile,
    // if there is an aktiv encoding
    if (i == 1 && IsEncoding()) return false;

    struct QueueData q;
    q = Q[i];
    Q[i] = Q[i-1];
    Q[i-1] = q;
    Save();

    return true;
  }
  return false;
}

bool cQueue::Down(int i) {
  if (i >= 0 && i < NumMovies - 1) {

    // don't move the first entry of the queuefile,
    // if there is an aktiv encoding
    if (i == 0 && IsEncoding()) return false;

    struct QueueData q;
    q = Q[i];
    Q[i] = Q[i+1];
    Q[i+1] = q;
    Save();

    return true;
  }
  return false;
}

bool cQueue::Switch(int i) {
  if (i >= 0 && i < NumMovies) {

    // don't switch the first entry of the queuefile,
    // if there is an aktiv encoding
    if (i == 0 && IsEncoding()) return false;

    (Q[i].Preview == 0) ? Q[i].Preview = 1 : Q[i].Preview = 0;
    Save();

    return true;
  }
  return false;
}

    
int cQueue::getNumMovies() {return NumMovies;}

struct QueueData* cQueue::getData(int i) {
  if (i >= 0 && i < NumMovies) {return &Q[i];
  } else {return NULL;}
}

char *cQueue::getName(int i) {
  if (i >= 0 && i < NumMovies) {return Q[i].Name;
  } else {return NULL;}
}

char *cQueue::getShortname(int i) {
  if (i >= 0 && i < NumMovies) {
    if (strlen(Q[i].Name) > 20) {
      char *s, *s1;
      s = strsub(Q[i].Name,1 , 17);
      asprintf(&s1, "%s...", s);
      return s1;
    } else {return Q[i].Name;}
  } else {return NULL;}
}

bool cQueue::getLockStat() {return Locked;}

void cQueue::Lock() {
  FILE *l;
  l = fopen(AddDirectory(cPlugin::ConfigDirectory(), LOCKFILE), "w");
  if (l) {
    fprintf(l,"0");
    isyslog("[vdrrip] queuefile locked");
    fclose(l);
  } else {
    dsyslog("[vdrrip] could not lock queuefile");
  }   
}

void cQueue::Unlock() {
  int r = remove(AddDirectory(cPlugin::ConfigDirectory(), LOCKFILE));
  if (r == -1) {dsyslog("[vdrrip] could not unlock queuefile");
  } else {isyslog("[vdrrip] queuefile unlocked");}
}

void cQueue::WaitUnlock() {
  FILE *l;
  int i = 0;
  bool loop = true;

  while (loop) {
    l = fopen(AddDirectory(cPlugin::ConfigDirectory(), LOCKFILE), "r");
    if (l) {

      // check if the content of the lockfile 0
      int c = fgetc(l);
      if (c == 48) {
	loop   = false;
	Locked = false;
	break;
      }
      
      i++;
      if (i > 2) {
	loop   = false;
	Locked = true;
      }
      isyslog("[vdrrip] %d. try: queuefile is locked by another process", i);
      sleep(1);
      fclose(l);
    } else {
      isyslog("[vdrrip] queuefile is not locked by another process");
      loop   = false;
      Locked = false;
    }
  }
}

bool cQueue::IsEncoding() {
  FILE *e;
  e = fopen(AddDirectory(cPlugin::ConfigDirectory(), ENCODEFILE), "r");
  if (! e) return false;
  
  fclose(e);
  return true;
}

char *cQueue::getQueueStat() {
  char *buf = NULL;
  size_t i = 0;

  FILE *e = fopen(AddDirectory(cPlugin::ConfigDirectory(), ENCODEFILE), "r");
  if (e) {
    if (getline(&buf, &i, e) != -1) {
      fclose(e);
      return buf;
    }
  }
  return NULL;
}
