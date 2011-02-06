#!/bin/sh

#################################################################
#                                                               #
# this scrip handles the queue which is generated from          #
# the vdr-plugin vdrrip.                                        #    
#                                                               #
# usage: queuehandler.sh queuefile tempdir                      #
#                                                               #
#                                                               #
# written by herbert attenberger <herbsl@a-land.de>             #
#                                                               #
# 15.07.2003: 0.1.0: - initial version                          #
# 24.07.2003: 0.1.1: - added split function                     #
# 28.07.2003: 0.1.2: - added video codec "divx4/divx5"          #
# 22.08.2003: 0.1.3: - added vdrecho function                   #
# 07.09.2003: 0.1.4: - added (preview) to the output filename   #
#                      in preview mode                          #
# 15.09.2003: 0.1.5: - added -frames 0 to get -identify with    #
#                      mplayer1.0pre1 working (thx to ronny)    #
# 24.09.2003: 0.1.6: - added (optional) svdrpsend.pl in         #
#                      function vdrecho                         #
#                    - added dvd-handling                       #
# 28.09.2003: 0.1.7: - added handling of postprocess-filters    #
#                    - added rename function (thx to            #
#                      memed@www.vdrportal.de)                  #
#                    - copy 001.vdr if a symbolic link couldn't #
#                      be created (for fat-partitions)          #
#                      (thx to memed@www.vdrportal.de)          #
# 30.09.2003: 0.1.8: - added -sws 2 to xvid/divx5 encoding      #
# 25.11.2003: 0.1.9: - moved loop function to read_queue        #
#                    - added lock, unlock and wait_unlock       #
#                      functions                                #
#                    - moved encode.vdrrip to the plugins-dir   #
# 14.12.2003: 0.2.0: - added check_exe function                 #
# 16.12.2003: 0.2.1: - removed mod_quant from xvid encoding     #
# 20.12.2003: 0.2.2: - moved pp-filters to the last position    #
#                    - added log_error function to output the   #
#                      errors to the syslog & stderr            #
#                    - added log_info function to output the    #
#                      infos to the syslog & stdout             #
#                    - added log_debug function to output the   #
#                      debug-infos infos to the syslog & stdout #
# 10.01.2004: 0.2.4: - renamed check function to initialize     #
#                    - added ogg-vorbis, ac3-handling           #
#                    - added ogm, matroska-handling             #
#                    - moved configuration to the file          #
#                      queuehandler.sh.conf                     #
#                    - improved error-handling                  #
#                    - added execute function                   #
#                    - added trap-command & _trap-function      #
# 18.01.2004: 0.2.5: - fixed a bug if scaling is off (thx to    #
#                      cosmo@www.vdrportal.de)                  #
# 21.01.2004: 0.2.6: - added option $useropts                   #
#                    - completed dvd-handling                   #
# 13.02.2004: 0.2.7: - changed some if statements to elif       #
#                    - changed preview-handling                 #
# 10.03.2004: 0.2.8: - added calc_steps function                #
#                    - write status to encode.vdrrip            #
# 22.03.2004: 0.2.9: - moved 2-pass logiles to $tempdir         #
# 26.03.2004: 0.3.0: - added evecho function                    #
#                    - added $mencoder_ac3 & $mplayer_ac3       #
#                    - added $qh_ver & qh_conf_ver              #
#                                                               #
#################################################################
qh_ver="0.3.0"


function initialize () {
#
# make initial checks
#
  
  scriptname=`basename $0`
  scriptdir=`dirname $0`

  cfgfile="$scriptname.conf"

  if [ -e "$scriptdir/$cfgfile" ]
  then
    source "$scriptdir/$cfgfile"
  else
    log_error "file $cfgfile not found in $scriptdir, aborting !" 1
  fi

  if [ "$1" -a "$2" ]
  then
    queuefile="$1"
    tempdir="$2"
    pluginsdir=`dirname "$queuefile"`
  else
    log_error "usage: $scriptname queuefile tempdir" 1
  fi

  if [ ! -d "$tempdir" ]
  then
    log_error "directory $tempdir doesn't exist, aborting !" 1
  fi

  if [ "$3" ]; then log_info "the option -preview isn't supported anymore"; fi

  local pids=`pgrep -d" " "$scriptname"`
  local pid1=`echo "$pids" | cut -d" " -f1`
  local pid2=`echo "$pids" | cut -d" " -f3`

  if [ "$pid1" != "$pid2" ]
  then
    log_error "$scriptname is already running with pid $pid1, aborting !" 2
  fi

  # now the 2-pass logfiles are created in $tempdir ;-)
  # (because -passlogfile doesn't do its job for xvid)
  cd "$tempdir"
}


function read_queue () {
#
# wait for the queuefile and read the first line
#

  while [ ! -e "$queuefile" ]
  do
     echo
     echo "waiting for queuefile $queuefile"
     echo "sleeping $check seconds"
     echo
     sleep $check
  done

  wait_unlock # wait until the queuefile is unlocked
  lock # locks the queuefile

  local saveifs="$IFS"
  IFS=";"
  read dir name filesize filenumbers vcodec br_video min_q max_q \
  crop_w crop_h crop_x crop_y scale_w scale_h acodec br_audio audio_id \
  ppvalues rename container preview < "$queuefile"
  IFS=$saveifs

  # there is an active encoding
  echo "- reading queuefile..." > "$pluginsdir/encode.vdrrip"

  unlock # unlocks the queuefile

  # correct some data
  name=`echo "$name" | sed "s/ /_/g"`

  local name_length=`echo "$name" | wc -c`
  if [ $name_length -gt 20 ]
  then
    shortname=`echo "$name" | cut -c 1-17`
    shortname="$shortname..."
  else
    shortname="$name"
  fi

  if [ "$ppvalues" = "(null)" ]; then ppvalues=""; fi

  dvd=`echo "$dir" | grep "^dvd://"`

  if [ "$preview" = "1" ]
  then
    local mode="preview"
  else
    local mode="full"
  fi
  
  log_info "### start encoding movie $shortname in $mode mode ###"

  log_debug "version of queuehandler.sh: $qh_ver"
  log_debug "version of queuehandler.sh.conf: $qh_conf_ver"
  log_debug "dir: $dir" 
  log_debug "name: $name"
  log_debug "filesize: $filesize"
  log_debug "filenumbers: $filenumbers"
  log_debug "vcodec: $vcodec"
  log_debug "br_video: $br_video"
  log_debug "min_q: $min_q"
  log_debug "max_q: $max_q"
  log_debug "crop_w: $crop_w"
  log_debug "crop_h: $crop_h"
  log_debug "crop_x: $crop_x"
  log_debug "crop_y: $crop_y"
  log_debug "scale_w: $scale_w"
  log_debug "scale_h: $scale_h"
  log_debug "acodec: $acodec"
  log_debug "br_audio: $br_audio"
  log_debug "audio_id: $audio_id"
  log_debug "ppvalues: $ppvalues"
  log_debug "rename: $rename"
  log_debug "container: $container"
  log_debug "preview: $preview"
}


function pre_check () {
#
# make some checks before the encoding
#
  if [ "$error" ]; then return; fi

  # check mplayer/mencoder
  if [ ! "$dvd" -a $audio_id -ge 128 ]
  then
    # encoding a vdr-recording with selected ac3-stream
    check_exe "$mencoder_ac3" "mencoder_ac3="
    check_exe "$mplayer_ac3" "mplayer_ac3="
    mc=$mencoder_ac3
    mp=$mplayer_ac3
  else
    check_exe "$mencoder" "mencoder="
    check_exe "$mplayer" "mplayer="
    mc=$mencoder
    mp=$mplayer
  fi

  # check needed tools  
  case "$container" in
    "avi")
      if [ "$acodec" = "ogg-vorbis" ]
      then 
        log_error "ogg-vorbis isn't a valid audio-codec for a avi-container"
      fi
      ;;
    "ogm")
      check_exe "$vdrsync" "vdrsync="
      check_exe "$ogmmerge" "ogmmerge="

      if [ "$acodec" = "lame" -o "$acodec" = "ogg-vorbis" ]
      then
	check_exe "$ffmpeg" "ffmpeg="
      fi
      
      if [ $filenumbers -gt 1 ]
      then
	check_exe "$ogmsplit" "ogmsplit="
      fi
      ;;
    "matroska")
      check_exe "$vdrsync" "vdrsync="
      check_exe "$mkvmerge" "mkvmerge="

      if [ "$acodec" = "lame" -o "$acodec" = "ogg-vorbis" ]
      then
	check_exe "$ffmpeg" "ffmpeg="
      fi
      ;;
    *)
      log_error "unknown container $container"
      ;;
  esac
}


function calc_steps () {
#
# calculate the nuber of encoding-steps
#
  if [ "$error" ]; then return
  elif [ "$preview" = "1" ]
  then
    if [ "$container" = "avi" ]; then steps="2"
    else steps="3"; fi
    return
  fi

  steps="8"

  if [ "$filenumbers" = "1" ]; then let steps=steps-1; fi
  
  case "$container" in
    "avi")
      let steps=steps-4
      if [ "$dvd" ]; then let steps=steps-1
      elif [ ! -e "$dir/002.vdr" ]; then let steps=steps-1; fi
      ;;
    "ogm")
      let steps=steps-2
      if [ "$acodec" = "copy" -a $audio_id -ge 128 ]
      then
	let steps=steps-1
      fi
      ;;
    "matroska")
      let steps=steps-2
      if [ "$acodec" = "copy" ]; then let steps=steps-1; fi
      ;;
    *)
      ;;
  esac
}


function preview () {
#
# get the preview values
#
  if [ "$error" ]; then return
  elif [ "$preview" != "1" ]; then return; fi

  name="$name(preview)"
  shortname="$shortname(preview)"
  
  # start the preview in the middle of the movie
  local length=`"$mp" -identify -frames 0 "$dir/001.vdr" 2>/dev/null | grep ID_LENGTH | cut -d"=" -f2`
  let local ss=length/2
  previewval="-ss $ss -endpos $previewlength"
}


function prepare() {
#
# prepares the encoding-process
#
  if [ "$error" ]; then return
  elif [ "$dvd" ]; then return; fi

  case "$container" in
    "avi")
      # join all vdr-files to $tempdir/temp.vdr
      if [ -e "$dir/002.vdr" -a "$preview" != "1" ]
      then
        log_info "joining all vdr-files from directory $dir"
	evecho "joining vdr-files"
        nice -+19 cat $dir/[0-9][0-9][0-9].vdr > "$tempdir/temp.vdr"
     else
	create_symbolic_link
      fi
      ;;
    "ogm"|"matroska")
      # demux vdr-recording with vdrsync
      if [ "$preview" = "1" ]
      then
        create_symbolic_link
      else
        log_info "demuxing all vdr-files from directory $dir"
	evecho "demuxing vdr-files"
        execute "$vdrsync $dir -o $tempdir"
      fi
      ;;
    *)
      ;;
  esac
}


function create_symbolic_link() {
#
# creates a symbolic link of 001.vdr to $temdir/temp.vdr
#
  if [ "$error" ]; then return
  elif [ "$dvd" ]; then return; fi

  log_info "create a symbolic link from $dir/001.vdr to $tempdir/temp.vdr"
  ln -s "$dir/001.vdr" "$tempdir/temp.vdr"

  if [ ! -e "$tempdir/temp.vdr" ]
  then
    log_info "could not create a symolic link"
    log_info "try to copy $dir/001.vdr to $tempdir/temp.vdr"
    execute "cp $dir/001.vdr $tempdir/temp.vdr"
  fi
}


function check_exe () {
#
# checks if $1 is a executable and exit the queuehandler with
# rc $3, if this one is set
#
  if [ ! -x "$1" ]
  then
    if [ "$1" ]; then log_error "$1 isn't a executable"; fi
    log_error "set a valid path for $2 in the file $scriptdir/$cfgfile." $3
  fi
}


function encode () {
#
# encodes the movie
#
  if [ "$error" ]; then return; fi

  # set mencoder audio values
  case "$container" in
    "avi")
      case "$acodec" in
        "lame")
          if [ "$dvd" ]
	  then
            local aopts="-oac mp3lame -lameopts br=$br_audio:abr:q=2:vol=8 -aid $audio_id"
	  else
            local aopts="-oac mp3lame -lameopts br=$br_audio:abr:q=2 -aid $audio_id"
	  fi
          ;;
        "copy")
          local aopts="-oac copy -aid $audio_id"
          ;;
	"ogg-vorbis")
          # this shouldn't happen
	  ;;
        *)
          log_error "unknown audio codec $acodec"
          ;;
      esac
      ;;
    "ogm")
      local aopts="-nosound"
      case "$acodec" in
        "lame"|"ogg-vorbis")
	  if [ "$dvd" ]; then dump_audio_mplayer; fi
          encode_ffmpeg
	  ;;
        "copy")
          # convert mp2-files to ac3, because
          # mp2 isn't supported by ogm
	  if [ "$dvd" ]; then dump_audio_mplayer; fi
	  if [ $audio_id -lt 128 ]; then encode_ffmpeg; fi
	  ;;
        *)
          log_error "unknown audio codec $acodec"
          ;;
      esac
      ;;
    "matroska")
      local aopts="-nosound"
      case "$acodec" in
        "lame"|"ogg-vorbis")
	  if [ "$dvd" ]; then dump_audio_mplayer; fi
          encode_ffmpeg
	  ;;
        "copy")
	  if [ "$dvd" ]; then dump_audio_mplayer; fi
	  ;;
        *)
          log_error "unknown audio codec $acodec"
          ;;
      esac
      ;;
    *)
      ;;
  esac

  # set mencoder -vop values
  if [ "$crop_w" = "-1" -a "$crop_h" = "-1" -a "$crop_x" = "-1" -a \
       "$crop_y" = "-1" -a "$scale_w" = "-1" -a "$scale_h" = "-1" ]
  then
    local vopopts=""
  elif [ "$crop_w" = "-1" -a "$crop_h" = "-1" -a "$crop_x" = "-1" -a \
         "$crop_y" = "-1" ]
  then
    local vopopts="scale=$scale_w:$scale_h"
  else
    local vopopts="scale=$scale_w:$scale_h,crop=$crop_w:$crop_h:$crop_x:$crop_y"
  fi

  if [ "$ppvalues" ]
  then
    local vopopts="-vop pp=$ppvalues,$vopopts"
  elif [ "$vopopts" ]
  then
    local vopopts="-vop $vopopts"
  fi

  # encode in two passes 
  for pass in 1 2
  do
    if [ "$pass" = "1" ]
    then
      local ofile="-o /dev/null"
    else
      local ofile="-o $tempdir/$name.avi"
    fi

    # set mencoder video values
    case "$vcodec" in
      "lavc")
        local vopts="-ovc lavc -lavcopts vcodec=mpeg4:vhq:vbitrate=$br_video:vqmin=$min_q:vqmax=$max_q:vpass=$pass -sws 2"
        ;;
      "xvid")
        local vopts="-ovc xvid -xvidencopts bitrate=$br_video:me_quality=6:pass=$pass -sws 2"
        ;;
      "divx4")
        local vopts="-ovc divx4 -divx4opts br=$br_video:q=5:min_quant=$min_q:max_quant=$max_q:pass=$pass -sws 2"
        ;;
      *)
        log_error "unknown video codec $vcodec"
        ;;
    esac

    # set mencoder input file
    if [ "$dvd" ]
    then
      # dvd
      local ifile="$dvd"
    elif [ "$container" = "avi" -o "$preview" = "1" ]
    then
      # no dvd, avi container
      local ifile="$tempdir/temp.vdr"
    else
      # no dvd, ogm/matroska container

      # search for the first video-file
      local num=0
      while [ ! "$ifile" ]
      do
        if [ ! -e "$tempdir/e$num.mpv" ]
	then
	  log_info "video-file $tempdir/e$num.mpv not found !"
	  if [ $num -ge 9 ]
	  then
	      log_error "no video-stream found !"
              # exit loop
              local ifile="dummy"
	    fi
	    let num=num+1
        else	  
	  log_info "video-file $tempdir/e$num.mpv found !"
          local ifile="$tempdir/e$num.mpv"
	fi
      done
    fi

    if [ "$error" ]; then return; fi

    log_info  "encoding movie $shortname (pass: $pass)"

    if [ "$aopts" = "-nosound" ]
    then
      local encstr="video"
    else
      local encstr="video & audio"
    fi

    evecho "enc. $encstr ($pass. pass)"
    if [ "$useropts" ]; then log_info "\$useropts are set to \"$useropts\""; fi
    execute "$mc $ifile $ofile $useropts $vopts $vopopts $aopts $previewval"
  done
}


function dump_audio_mplayer() {
#
# dump audio-stream from dvd with mplayer
#
  if [ "$error" ]; then return
  elif [ "$preview" = "1" ]; then return
  elif [ ! "$dvd" ]; then return; fi

  log_info "dumping audio-stream $audio_id from $dvd with $mp"
  evecho "dumping audio-stream from dvd"
  execute "$mp $dir -vo null -vc dummy -aid $audio_id -aop list=volnorm -dumpaudio -dumpfile $tempdir/bd.ac3"
}


function encode_ffmpeg() {
#
# encode the audio-stream with ffmpeg
#
  if [ "$error" ]; then return
  elif [ "$preview" = "1" ]; then return; fi
 
  if [ $audio_id -ge 128 ]
  then
    local ifile="$tempdir/bd.ac3"
  else
    local ifile="$tempdir/c$audio_id.mpa"
    local forceinput="-f mp3"
  fi

  case "$acodec" in 
    "lame")
      local filetype="mp3"
      ;;
    "ogg-vorbis")
      local filetype="ogg"
      ;;
    "copy")
      log_info "ogm doesn't support mp2 audio-streams, i will convert it into ac3"
      local filetype="ac3"
      ;;
    *)
      ;;
  esac

  log_info "converting $ifile into $filetype-format"
  evecho "conv. audio into $filetype-format"
  execute "$ffmpeg -hq -y $forceinput -i $ifile -ab $br_audio $tempdir/c$audio_id.$filetype"
}


function merge_ogm_mkv() {
  if [ "$error" ]; then return; fi
  if [ "$container" != "ogm" -a "$container" != "matroska" ]; then return; fi
    

  case "$container" in
    "ogm")
      local merge="$ogmmerge"
      local filetype="ogm"
      ;;
    "matroska")
      local merge="$mkvmerge"
      local filetype="mkv"
      ;;
    *)
      ;;
  esac


  if [ "$preview" != "1" ]
  then
    case "$acodec" in
      "lame")
        local afile="$tempdir/c$audio_id.mp3"
        ;;
      "ogg-vorbis")
	local afile="$tempdir/c$audio_id.ogg"
	;;
      "copy")
        if [ $audio_id -ge 128 ]
        then
          # ac3
	  local afile="$tempdir/bd.ac3"
	elif [ "$container" = "ogm" ]
	then
	  # mpg2, container ogm
	  local afile="$tempdir/c$audio_id.ac3"
	else
          # mpg2
	  local afile="$tempdir/c$audio_id.mpa"
	fi
        ;;
      *)
        ;;
    esac
  fi

  log_info "merging movie $shortname into $filetype-container"
  evecho "merging into $filetype-container"
  execute "$merge -o $tempdir/$name.$filetype $tempdir/$name.avi $afile"
}


function cleanup () {
#
# delete temp-files and reset variables
#
  # temp. codec-files
  rm -f "$tempdir/divx2pass.log"
  rm -f "$tempdir/lavc_stats.txt"
  rm -f "$tempdir/analyse.log"
  rm -f "$tempdir/c:\\trace_b.txt"
  rm -f "$tempdir/xvid-twopass.stats"

  # temp. movie-files
  rm -f "$tempdir/temp.vdr"
  if [ "$container" = "ogm" -o "$container" = "matroska" ]
  then
    rm -f "$tempdir/$name.avi"
  fi
  rm -f "$tempdir"/e[0-9].mpv
  rm -f "$tempdir"/c[0-9].mpa
  rm -f "$tempdir"/c[0-9].mp3
  rm -f "$tempdir"/c[0-9].ogg
  rm -f "$tempdir"/c[0-9].ac3
  rm -f "$tempdir"/c[0-9][0-9][0-9].mp3
  rm -f "$tempdir"/c[0-9][0-9][0-9].ogg
  rm -f "$tempdir"/bd.ac3

  # temp. queuehandler-files
  rm -f "$pluginsdir/encode.vdrrip"
  rm -f /tmp/queuehandler.err


  # reset variables
  dir=""
  name=""
  filesize=""
  filenumbers=""
  vcodec=""
  br_video=""
  min_q=""
  max_q=""
  crop_w=""
  crop_h=""
  crop_x=""
  crop_y=""
  scale_w=""
  scale_h=""
  acodec=""
  br_audio=""
  audio_id=""
  ppvalues=""
  rename=""
  container=""
  preview=""

  mc=""
  mp=""
  
  dvd=""
  previewval=""
  error=""

  step="0"
}


function del_queue () {
#
# delete first line from the queuefile
#
  # waits until the queuefile is unlocked, and locks it
  wait_unlock
  lock

  if [ "$error" ]
  then
    head -n 1 "$queuefile" >> "$queuefile.rejected"
  fi

  # delete first entry of the queuefile
  local lines=`cat "$queuefile" | wc -l`
  if [ "$lines" -le 1 ]
  then
    rm -f "$queuefile"
  else
    let lines=lines-1
    tail -n $lines "$queuefile" > /tmp/queuefile.tmp
    mv /tmp/queuefile.tmp $queuefile
  fi

  if [ "$error" ]
  then  
    log_info "### moved movie $shortname to $queuefile.rejected ###"
  else
    log_info "### movie $shortname deleted from queuefile ###"
  fi 

  # unlock queuefile
  unlock
}


function split () {
#
# splits the encoded movie into $filenumbers pieces
#
  if [ "$error" ]; then return
  elif [ "$filenumbers" = "1" -o "$preview" = "1" ]; then return; fi

  log_info "splitting $shortname in $filenumbers pieces"
  evecho "splitting movie"

  case "$container" in
    "avi")
      local overlap=3

      local count=1
      local splitpos=0

      # workaround to get the correct filesize from mencoder with -endpos
      let local splitsize=filesize*99/100
      
      log_info "splitting $shortname in $filenumbers pieces"
      while [ $count -le $filenumbers ]
      do
        local ofile="$name-$count.avi"

        if [ $count -eq $filenumbers ]
        then
          local endpos=""
        else
          local endpos="-endpos ${splitsize}mb"
        fi

        # split file
        execute "$mc -ovc copy -oac copy $tempdir/$name.avi \
                 -ss $splitpos $endpos -o $tempdir/$ofile"
	
        # detect length of splitted file and add it to $splitpos
        local length=`$mplayer -identify -frames 0 $tempdir/$ofile 2>/dev/null | \
                      grep ID_LENGTH | cut -d= -f2`
        let splitpos=splitpos+length-overlap
        let count=count+1
      done
      ;;
    "ogm")
      execute "$ogmsplit -s $filesize -n $filenumbers $tempdir/$name.ogm"
      ;;
    "matroska")
      execute "$mkvmerge --split d${filesize}m --split-max-files \
               $filenumbers -o $tempdir/$ofile"
      ;;
    *)
      ;;
  esac
}


function vdrecho () {
#
# echo $1 in the vdr-infobar (or console)
#

  if [ -x "$svdrpsend" ]
  then
    $svdrpsend -d "$vdrhostname" "MESG $1" 2>/dev/null 1>/dev/null
  elif [ -x "$netcat" ]
  then
    echo "MESG $1" | $netcat -q 1 "$vdrhostname" 2001 2>/dev/null 1>/dev/null
  else
    log_info "$1"
  fi
}


function evecho () {
#
# echo $ in the file encode.vdrrip
#
  let step=step+1
  local time=`date +"%k:%M h"`
  echo "- step $step/$steps (since $time): $1" > "$pluginsdir/encode.vdrrip"
}


function log_error () {
#
# echo $1 on stderr and write it to the syslog with priority user.error
#
  logger -s -p user.error -t [vdrrip-qh] "$1"

  if [ "$2" ]
  then
    vdrecho "$1"
    exit "$2"
  else
    error="1"
  fi
}


function log_info () {
#
# echo $1 on stdout and write it to the syslog with priority user.info
#
  logger -s -p user.info -t [vdrrip-qh] "$1" 2>&1
}


function log_debug () {
#
# echo $1 on stdout and write it to the syslog with priority user.debug
#
  if [ "$debug" = "1" ]
  then
    logger -s -p user.debug -t [vdrrip-qh] "$1"
  fi
}


function execute () {
#
# executes $1 and checks the rc
#
  local cmd="$1"
 
  log_debug "execute command: $cmd"

  # execute $cmd and save the return-code:
  if [ "$stdout" = "1" ]
  then
    nice -+19 $cmd 2>/tmp/queuehandler.err
    local rc="$?"
  else
    nice -+19 $cmd 1>/dev/null 2>/tmp/queuehandler.err
    local rc="$?"
  fi

  if [ "$rc" != "0" ]
  then
    # display stderr if the return-code isn't 0
    log_error "an error occured (rc $rc) while processing the command: $cmd"
    local err_message=`cat /tmp/queuehandler.err 2>/dev/null`
    if [ "$err_message" ]
    then
      log_error "error message: $err_message"
    fi
  elif [ "$debug" = "1" ]
  then
    # display stderr if the debug-mode is set
    local dbg_message=`cat /tmp/queuehandler.err 2>/dev/null`
    if [ "$dbg_message" ]
    then
      log_debug "debug message: $dbg_message"
    fi
  fi
}


function rename () {
#
# renames the vdr recording to indicate it was encoded properly
# this function is written by memed@www.vdrportal.de
#
  if [ "$error" ]; then return
  elif [ "$dvd" ]; then return
  elif [ "$preview" = "1" ]; then return
  elif [ "$rename" = "0" ]; then return; fi

  new_dir="$(dirname $dir)${append_string}"                                                            
  mkdir -p "$new_dir"                                                                                  
  #move finished subdir to new folder
  mv "$dir" "$new_dir"                                                                                 
  #if all subdirs are empty, also delete dir one up
  [ $(find $(dirname $dir) -type f|wc -l)  -eq 0 ] && rm -rf $(dirname $dir)
}


function wait_unlock () {
#
# wait until the queuefile is unlocked
#
  local lockstat
  read lockstat 2>/dev/null < "$pluginsdir/lock.vdrrip"

  while [ -e "$pluginsdir/lock.vdrrip" -a "$lockstat" != "1" ]
  do
    echo
    echo "queuefile is locked !"
    echo "sleeping $lock seconds" 
    echo
    sleep $lock
  done
}


function lock () {
#
# locks the queuefile
#
  local lockfile="$pluginsdir/lock.vdrrip"
  echo 1 > $lockfile 2>/dev/null

  if [ ! -e "$lockfile" ]
  then
    log_error "couldn't write to $lockfile" 1
  fi
}


function unlock () {
#
# unlocks the queuefile
#
  rm -f $pluginsdir/lock.vdrrip

  if [ -e "$lockfile" ]
  then
    log_error "couldn't delete $lockfile" 1
  fi
}

function _trap () {
#
# this function is called if the queuehandler is killed
#
  if [ "$debug" = "0" ]; then cleanup; fi
  log_error "queuehandler was killed !"
  vdrecho "queuehandler was killed !"
}


#
# this is the main part
#

trap "_trap; exit" 2 9 15

initialize "$1" "$2" "$3"  # make initial checks
cleanup                    # delete old temp-files

while [ true ]
do
  read_queue               # read the first line from the queuefile
  pre_check                # make some checks before the encoding
  calc_steps               # calc the number of encoding-steps
  preview                  # get the preview values
  prepare                  # prepares the encoding
  encode                   # encodes the movie
  merge_ogm_mkv            # merge ogm/mkv-files 
  split                    # splits the encoded movie

  if [ ! "$error" ]
  then
    mess="movie $shortname encoded"
    log_info "$mess"
    vdrecho "$mess"
  else
    mess="couldn't encode movie $shortname"
    log_info "$mess"
    vdrecho "$mess"
  fi

  rename                   # rename dir-name of the vdr-recording
  del_queue                # delete first line from the queuefile
  cleanup                  # delete temp-files
done
