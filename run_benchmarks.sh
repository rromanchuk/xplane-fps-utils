#!/bin/bash

set -e

tests=( "1" "2" "3" "4" "5" "54" )
working_dir="$PWD"
log_dir="benchmarks"
xplane_binary="X-Plane.app/Contents/MacOS/X-Plane"
xval="3840"
yval="2160"
NL='\n'
GRN='\e[32m'
grn='\e[92m'
DEF='\e[0m'
BLD='\e[1m'
UND='\e[4m'
YLW='\e[33m'
ylw='\e[93m'
divider=---------------------
divider=$divider$divider

usage() {
cat <<END
 
  SYNOPSIS
    /run_benchmarks.sh [-x resolution] [-y resolution]
  
  DESCRIPTION
    macOS script for automating framerate benchmarks using X-Plane's --fps_test flag.

    See https://forums.x-plane.org/index.php?/forums/topic/71725-x-plane-benchmark-charts-fps-tests
    for more information. 
    Run from the root of your X-Plane 11 directory. Default resolution is 3840x2160

    The options are as follows:
    - x resolution
                    Set a custom resolution to run the benchmark in (x-axis pixels)
    - y resolution
                    Set a custom resolution to run the benchmark in  (y-axis pixels)
END
}


function box_out()
{
  local s="$*"
  tput setaf 3
  echo " -${s//?/-}-
| ${s//?/ } |
| $(tput setaf 4)$s$(tput setaf 3) |
| ${s//?/ } |
 -${s//?/-}-"
  tput sgr 0
}

timestamp() {
 date +"%T"
}

t() {
  printf "$NL$GRN[$( timestamp )]$DEF"
}

check() {
  box_out "Current configuration"

  printf "${BLD}%-50s $DEF %s\n" "Log directory:" "$working_dir/$log_dir"
  printf "${BLD}%-50s $DEF %s\n" "Resolution flags:" "--pref:_x_res_full_ALL=$xval --pref:_y_res_full_ALL=$yval" 
  printf "${BLD}%-50s $DEF %s\n" "Binary:" "$working_dir/$xplane_binary"
  printf "${BLD}%-50s $DEF %s\n\n" "Tests to run:" "${tests[*]}"

  printf $BLD"Continue?$DEF (y/n)"
  read answer
  if [ "$answer" != "${answer#[Yy]}" ] ;then
    printf "$( t ) Running..."
    run
  else
    printf "$( t ) canceled "
    exit
  fi
}

run() {
  results_dir=$log_dir/${xval}_x_${yval}
  printf "$( t ) creating log directory $working_dir/$results_dir"
  mkdir -p $results_dir
  all_results=$results_dir/results.txt
  touch $all_results
  printf "$( t ) created results file $all_results "
  for i in "${tests[@]}"
  do
    printf "$( t ) Ready to run -fps_test=$i"
    start=$SECONDS
    ./X-Plane.app/Contents/MacOS/X-Plane --fps_test=$i --load_smo=Output/replays/test_flight_c4.fdr ---pref:_x_res_full_ALL=$xval --pref:_y_res_full_ALL=$yval 2>/dev/null
    printf "$( t ) FPS benchmarck complete, ran for $(( SECONDS - start )) seconds"

    FRAMERATE=$(sed -n '/^FRAMERATE/p' ./Log.txt) #>> $all_results
    GPU=$(sed -n '/^GPU LOAD/p' ./Log.txt) #>> $all_results
    printf "\n\n$BLD%s$DEF\n" "RESULTS FOR TEST $i"
    box_out $FRAMERATE $GPU

    echo -e $NL$NL"RESULTS FOR TEST "$i$NL"$(date -u)" >> $all_results
    echo -e $NL$FRAMERATE$NL$GPU >> $all_results
    
    printf "$( t ) Results saved to $all_results"
  done
printf "$( t ) Benchmarking complete"
}


while getopts ":x:y:" opt;
do
    case ${opt} in
    x ) 
      xval=${OPTARG}
      ;;
    y )
      yval=${OPTARG}
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage
      exit 2
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      usage
      exit 2
      ;;
    esac
done

if [ $OPTIND -eq 1 ] && [ $OPTIND -eq 5 ]; then
    printf "Invalid flags"
    usage
    exit 2
fi

check
