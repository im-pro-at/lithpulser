#!/bin/bash

set -x

monitor 0X40000000

#Configur
monitor 0x40000004 0      # #STOP
monitor 0x40000008 1      # #RESET Settings
monitor 0x40000010 0xFFFF      # #RESET PATTERN
monitor 0x40000020 3      # #LOGLEVEL FULL

#Configur sequence 1
monitor 0x40010000 1    ##Enable
monitor 0x40010020 1000000000   ##Rerun after 1s
monitor 0x40010024 100  ##Length 100ns

for i in {1..100}
do
    monitor 0x40010030  $i          #Outputpattern
    monitor 0x40010034  $(($i * 1)) #Output time
    monitor 0x40010038 0x00000001   ##transfer 
done

monitor 0x40010100 0x00000004    ##ld mode

monitor 0x40010110 0x00000000    ##ld I0 st
monitor 0x40010114 0x00000400    ##ld I0 et
monitor 0x40010118 0x00000020    ##ld I0 minc
monitor 0x4001011C 0x00000100    ##ld I0 maxc

monitor 0x40010120 0x00000040    ##ld I1 st
monitor 0x40010124 0x00000400    ##ld I1 et
monitor 0x40010128 0x00000000    ##ld I1 minc
monitor 0x4001012C 0x00000100    ##ld I1 maxc

#Configur sequence 2
monitor 0x40011000 1    ##Enable
monitor 0x40011020 100000000    ##Rerun after 0.1s
monitor 0x40011024 100  ##Length 100ns

for i in {1..100}
do
    monitor 0x40011030  $i          #Outputpattern
    monitor 0x40011034  $(($i * 1)) #Output time
    monitor 0x40011038 0x00000001   ##transfer 
done

monitor 0x40011100 0x00000000    ##ld mode

monitor 0x40000004 1    ##START

sleep 10s

monitor 0x40000004 0    ##STOP

exit

