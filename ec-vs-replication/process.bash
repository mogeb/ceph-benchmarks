#!/bin/bash

export LC_NUMERIC="en_US.UTF-8"

function average {
  declare -a table=("${!1}")
  local size=${#table[*]}
  local result=0
  for v in ${table[@]}; do
    result=`echo "$result + $v" | bc -l`
  done
  result=`echo "$result / $size" | bc -l`
  printf "%.0f" $result
}

function stdev {
  declare -a table=("${!1}")
  local size=${#table[*]}
  local sum=0
  local sumsq=0
  for v in ${table[@]}; do
    sum=`echo "$sum + $v" | bc -l`
    sumsq=`echo "$sumsq + $v*$v" | bc -l`
  done
  local result=`echo "sqrt($sumsq/$size - ($sum/$size)^2)" | bc -l`
  printf "%.0f" $result
}


#for w in randread; do
for w in randread randwrite randrw; do
printf "*********** $w workload *************\n"
printf "Jobs\tReplication\tEC\n"
for i in 1 2 8 16; do
printf "$i"
for FEATURE in ec replication; do
IOPS_SET=()
for r in 1 2 3; do
  DIR=results/run$r/$FEATURE/$w
  READ_IOPS=`awk -F ";" '{print $8}' $DIR/summary_j${i}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
  WRITE_IOPS=`awk -F ";" '{print $49}' $DIR/summary_j${i}.csv | awk 'BEGIN {sum=0;} {sum += $1} END { printf("%d", sum); }'`
  IOPS=$((READ_IOPS + WRITE_IOPS))
  IOPS_SET+=(${IOPS})
done
AVG=`average IOPS_SET[@]`
STDEV=`stdev IOPS_SET[@]`
printf "\t%s" $STDEV
# printf "%s -> %s -> %d -> %s -> %s\n" $w $FEATURE $i $AVG $STDEV
done
printf "\n"
done
printf "\n"
done
