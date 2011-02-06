// codecs.h

#ifndef __CODECS_H
#define __CODECS_H

class cCodecs {
 protected:
  int NumVCodecs;
  int NumACodecs;
  int NumContainers;

  char **VCodecs;
  char **ACodecs;
  char **Containers;

  void queryCodecs(char *v, char *a);
  void queryContainers();
 public:
  cCodecs();
  ~cCodecs();

  int getNumVCodecs();
  int getNumACodecs();
  int getNumContainers();
  char *getVCodec(int i);
  char *getACodec(int i);
  char *getContainer(int i);
  int getNumVCodec(char *v);
  int getNumACodec(char *a);
  int getNumContainer(char *c);
  char **getACodecs();
  char **getVCodecs();
  char **getContainers();
};

#endif // __CODECS_H
