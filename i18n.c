// i18n.c

#include "i18n.h"

const tI18nPhrase Phrases[] = {
  { "encode vdr-recording",
    "VDR-Aufzeichnung encodieren",
    "",// TODO
    "Comprimi registrazioni di vdr",
    "",// TODO
    "",// TODO
    "Encoder un enregistrement",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "edit encoding queue",
    "Warteschlange bearbeiten",
    "",// TODO
    "Visualizza coda di compressione",
    "",// TODO
    "",// TODO
    "Voir les encodages en attente",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "edit templates",
    "Schablonen bearbeiten",
    "",// TODO
    "Editare le maschere",
    "",// TODO
    "",// TODO
    "Editer les gabarits",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "encoding queue",
    "Warteschlange",
    "",// TODO
    "Coda di compressione",
    "",// TODO
    "",// TODO
    "Queue d'encodage",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "edit template",
    "Schablone bearbeiten",
    "",// TODO
    "Editare la maschera",
    "",// TODO
    "",// TODO
    "Editer les gabarits",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "reading movie-data...",
    "lese Film-Daten...",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif //VDRVERSNUM
  },
  
  { "edit",
    "bearbeiten",
    "",// TODO
    "Editare",
    "",// TODO
    "",// TODO
    "Editer",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "new",
    "neu",
    "",// TODO
    "Nuovo",
    "",// TODO
    "",// TODO
    "Nouveau",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "delete",
    "löschen",
    "",// TODO
    "Cancellare",
    "",// TODO
    "",// TODO
    "Effacer",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "delete template %s ?",
    "Schablone %s löschen ?",
    "",// TODO
    "Cancellare maschera %s ?",
    "",// TODO
    "",// TODO
    "Effacer le gabarit %s ?",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "Name",
    "Name",
    "",// TODO
    "Nome",
    "",// TODO
    "",// TODO
    "Nom",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "FileSize",
    "Datei-Grösse",
    "",// TODO
    "Dimensione file",
    "",// TODO
    "",// TODO
    "TailleFich",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "FileNumbers",
    "Anzahl Dateien",
    "",// TODO
    "Numero di file",
    "",// TODO
    "",// TODO
    "Nb fichiers",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "BitrateVideo",
    "Bitrate Video",
    "",// TODO
    "Video bitrate",
    "",// TODO
    "",// TODO
    "Bitrate Video",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "BitrateAudio",
    "Bitrate Audio",
    "",// TODO
    "Audio bitrate",
    "",// TODO
    "",// TODO
    "Bitrate Audio",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "Container",
    "Container",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "Video-Codec",
    "Video Codec",
    "",// TODO
    "Codec video",
    "",// TODO
    "",// TODO
    "Codec Video",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "Audio-Codec",
    "Audio Codec",
    "",// TODO
    "Codec audio",
    "",// TODO
    "",// TODO
    "Codec Audio",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "Bpp-Value (*100)",
    "Bpp-Wert (*100)",
    "",// TODO
    "Valore Bpp (*100)",
    "",// TODO
    "",// TODO
    "ValeurBpp (*100)",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "ScaleType",
    "Skalierungsart",
    "",// TODO
    "Tipo scalatura",
    "",// TODO
    "",// TODO
    "Dimensionnement",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "encode movie",
    "Film encodieren",
    "",// TODO
    "Compressione video",
    "",// TODO
    "",// TODO
    "Encoder le film",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "add movie to encoding queue ?",
    "Film zur Warteschlange hinzufügen ?",
    "",// TODO
    "Aggiungere un film alla coda di compressione ?",
    "",// TODO
    "",// TODO
    "Ajouter le film à la queue d'encodage ?",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "crop black movie boarders ?",
    "schwarze Filmränder schneiden ?",
    "",// TODO
    "Tagliare i bordi neri del video ?",
    "",// TODO
    "",// TODO
    "Découper le film entre les limites noires ?",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "reset black movie boarders ?",
    "schwarze Filmränder löschen ?",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "search for black movie boarders",
    "suche nach schwarzen Filmrändern",
    "",// TODO
    "Ricerca bordi neri nel video",
    "",// TODO
    "",// TODO
    "Rechercher les limites noires dans le film",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "couldn't detect black movie boarders !",
    "konnte keine schwarzen Filmränder erkennen !",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "add to queue",
    "in Warteschl.",
    "",// TODO
    "Aggiunto in coda",
    "",// TODO
    "",// TODO
    "Ajout. Queue",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "crop boarders",
    "Ränder schn.",
    "",// TODO
    "Taglio bordi",
    "",// TODO
    "",// TODO
    "Supp. les limites",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "reset boarders",
    "Ränder lösch.",
    "",// TODO
    "Taglio bordi",
    "",// TODO
    "",// TODO
    "Supp. les limites",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "expert modus(off)",
    "Exp.-Modus(aus)",
    "",// TODO
    "Modo esperto(off)",
    "",// TODO
    "",// TODO
    "Mode Expert(off)",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "expert modus(on)",
    "Exp.-Modus(ein)",
    "",// TODO
    "Modo esperto(on)",
    "",// TODO
    "",// TODO
    "Mode Expert(on)",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "Template",
    "Schablone",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "Gabarit",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "Audio-Str.",
    "Audiospur",
    "",// TODO
    "Stream audio",
    "",// TODO
    "",// TODO
    "Flux Audio",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "MovieData",
    "Film-Daten",
    "",// TODO
    "Dati del Film",
    "",// TODO
    "",// TODO
    "Film-Infos",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "CropData",
    "Schnitt-Daten",
    "",// TODO
    "Valori di taglio",
    "",// TODO
    "",// TODO
    "ValeursDécoupage",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "ScaleData",
    "Skalierung",
    "",// TODO
    "Valore di scalatura",
    "",// TODO
    "",// TODO
    "ValeursRedimensionnement",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "ScaleWidth",
    "Skal.-breite",
    "",// TODO
    "Scalatura larghezza",
    "",// TODO
    "",// TODO
    "Largeur Redimensionnement",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "ScaleHeight",
    "Skal.-höhe",
    "",// TODO
    "Scalatura altezza",
    "",// TODO
    "",// TODO
    "Hauteur Redimensionnement",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "------ expert settings: ------",
    "--- Experten-Einstellungen: ---",
    "",// TODO
    "------ settaggi esperto: ------",
    "",// TODO
    "",// TODO
    "--- Paramètres Mode Expert: ---",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "- adjust crop values:",
    "- Schnittwerte anpassen:",
    "",// TODO
    "- aggiustatura valori di taglio:",
    "",// TODO
    "",// TODO
    "- Ajuster les valeurs de découpage:",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "CropWidth",
    "Schnittbreite",
    "",// TODO
    "Taglio larghezza",
    "",// TODO
    "",// TODO
    "Largeur Découpage",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "CropHeight",
    "Schnitthöhe",
    "",// TODO
    "Taglio altezza",
    "",// TODO
    "",// TODO
    "Hauteur Découpage",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "- postprocessing Filters(%s):",
    "- Nachbearbeitungsfilter(%s):",
    "",// TODO
    "- Filtri dopo il processo(%s):",
    "",// TODO
    "",// TODO
    "- Filtres de PostTraitement(%s):",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "- remaining:",
    "- sonstiges:",
    "",// TODO
    "- rimanenti:",
    "",// TODO
    "",// TODO
    "- restant:",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "MaxScaleWidth",
    "max. Skal.-breite",
    "",// TODO
    "Massima scalatura larghezza",
    "",// TODO
    "",// TODO
    "LargeurMaxiRedimensionnement",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "MinScaleWidth",
    "min. Skal.-breite",
    "",// TODO
    "Minima scalatura larghezza",
    "",// TODO
    "",// TODO
    "LargeurMiniRedimensionnement",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  }, 
  
  { "Crop Mode",
    "Schnittmodus",
    "",// TODO
    "Modo di taglio",
    "",// TODO
    "",// TODO
    "Mode de découpage",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "Crop DetectLength (s)",
    "Schnitt-Suchdauer (s)",
    "",// TODO
    "Ricerca larghezza di taglio (s)",
    "",// TODO
    "",// TODO
    "Découpage-Longeur de détection (s)",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "Rename movie after encoding",
    "Film nach Enc. umbenennen",
    "",// TODO
    "Rinnominare il film dopo la compressione",
    "",// TODO
    "",// TODO
    "Renommer le film après l'encodage",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "up",
    "nach oben",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "down",
    "nach unten",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  { "switch mode",
    "Modus wechseln",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "<ok> for preview-mode",
    "<ok> fuer Vorschau-Modus",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "the queuefile is locked by the queuehandler !",
    "die Warteschlange wird momentan vom queuehandler gesperrt !",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },


  { "delete movie %s from queue ?",
    "Film %s von Warteschl. löschen ?",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },
  
  
  { "not used",
    "keine Nutzung",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "unknown",
    "unbekannt",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

  { "not found",
    "nicht gefunden",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif
  },

#ifdef VDRRIP_DVD
  { "encode dvd",
    "DVD encodieren",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif //VDRVERSNUM
  },

  { "back",
    "zurueck",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif //VDRVERSNUM
  },

  { "checking dvd...",
    "ueberpruefe dvd...",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif //VDRVERSNUM
  },

  { "Title*",
    "Titel*",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif //VDRVERSNUM
  },
  
  { "accept",
    "akzeptieren",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif //VDRVERSNUM
  },
  
  { "reading audio-data from dvd...",
    "lese Audio-Daten von DVD...",
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
    "",// TODO
#if VDRVERSNUM>10301
    "",// TODO
#endif //VDRVERSNUM
  },
  
#endif //VDRRIP_DVD

 { NULL }
  };
