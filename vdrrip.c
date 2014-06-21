/*
 * vdrrip.c: A plugin for the Video Disk Recorder
 *
 * See the README file for copyright information and how to reach the author.
 *
 * $Id$
 */

#include <unistd.h>

#include <getopt.h>
#include <vdr/plugin.h>
#include <vdr/menu.h>
#include "menu-vdrrip.h"
#include "movie.h"
#include <vdr/i18n.h>
#include "a-tools.h"

static const char *VERSION       = "0.3.0";
static const char *DESCRIPTION   = "A MPlayer using movie encoder";
static const char *MAINMENUENTRY = "Vdrrip";

const char *MPlayer  = "/usr/local/bin/mplayer";
const char *MEncoder = "/usr/local/bin/mencoder";
const char *DVD      = "/dev/dvd";

class cPluginVdrrip : public cPlugin {
private:
  // Add any member variables or functions you may need here.
public:
  cPluginVdrrip(void);
  virtual ~cPluginVdrrip();
  virtual const char *Version(void) { return VERSION; }
  virtual const char *Description(void) { return DESCRIPTION; }
  virtual const char *CommandLineHelp(void);
  virtual bool ProcessArgs(int argc, char *argv[]);
  virtual bool Initialize(void);
  virtual bool Start(void);
  virtual void Housekeeping(void);
  virtual const char *MainMenuEntry(void) { return MAINMENUENTRY; }
  virtual cOsdObject *MainMenuAction(void);
  virtual cMenuSetupPage *SetupMenu(void);
  virtual bool SetupParse(const char *Name, const char *Value);
  };

cPluginVdrrip::cPluginVdrrip(void)
{
  // Initialize any member variables here.
  // DON'T DO ANYTHING ELSE THAT MAY HAVE SIDE EFFECTS, REQUIRE GLOBAL
  // VDR OBJECTS TO EXIST OR PRODUCE ANY OUTPUT!
}

cPluginVdrrip::~cPluginVdrrip()
{
  // Clean up after yourself!
}

const char *cPluginVdrrip::CommandLineHelp(void)
{
  // Return a string that describes all known command line options.
  char *s = NULL;
  asprintf(&s, "   -p LOC,  --MPlayer=LOC      use LOC as location of MPlayer\n"
               "                               (default is %s)\n"
               "   -e LOC,  --MEncoder=LOC     use LOC as location of MEncoder\n"
               "                               (default is %s)\n"
#ifdef VDRRIP_DVD
               "   -d DEV,  --DVD=DEV          use DEV as your DVD-device\n" 
               "                               (default is %s)\n"
#endif // VDRRIP_DVD
           , MPlayer, MEncoder
#ifdef VDRRIP_DVD
	   , DVD
#endif // VDRRIP_DVD
	   );
  return s;
}

bool cPluginVdrrip::ProcessArgs(int argc, char *argv[])
{
  // Implement command line argument processing here if applicable.
  static struct option long_options[] = {
    { "MPlayer",      required_argument, NULL, 'p' },
    { "MEncoder",     required_argument, NULL, 'e' },
    { "DVD",          required_argument, NULL, 'd' },
    { NULL }
  };

  int c, option_index = 0;
  while ((c = getopt_long(argc, argv, "p:e:d:", long_options, &option_index)) != -1) {
    switch (c) {
      case 'p':
        MPlayer = optarg;
        break;
    
      case 'e':
        MEncoder = optarg;
        break;

      case 'd':
        DVD = optarg;
        break;

      default:
        return false;
    }
  }

  return true;
}

bool cPluginVdrrip::Initialize(void)
{
  // Initialize any background activities the plugin shall perform.
  return true;
}

bool cPluginVdrrip::Start(void)
{
  // Start any background activities the plugin shall perform.
  return true;
}

void cPluginVdrrip::Housekeeping(void)
{
  // Perform any cleanup or other regular tasks.
}

cOsdObject *cPluginVdrrip::MainMenuAction(void)
{
  // Perform the action when selected from the main VDR menu.
  if (access(MPlayer, X_OK) == -1) {
    char *s = NULL;
    asprintf(&s, "%s doesn't exist or isn't a executable !", MPlayer);
#if VDRVERSNUM >= 10307
    Skins.Message(mtError, s);
#else
    Interface->Error(s);
#endif
    FREE(s);
    return NULL;
  } else if (access(MEncoder, X_OK) == -1) {
    char *s = NULL;
    asprintf(&s, "%s doesn't exist or isn't a executable !", MEncoder);
#if VDRVERSNUM >= 10307
    Skins.Message(mtError, s);
#else
    Interface->Error(s);
#endif
    FREE(s);
    return NULL;
  } else return new cMenuVdrrip();
}

cMenuSetupPage *cPluginVdrrip::SetupMenu(void)
{
  // Return a setup menu in case the plugin supports one.
  return new cMenuVdrripSetup();
}

bool cPluginVdrrip::SetupParse(const char *Name, const char *Value)
{
  // Parse your own setup parameters and store their values.
  return VdrripSetup.SetupParse(Name, Value);
}

VDRPLUGINCREATOR(cPluginVdrrip); // Don't touch this!
