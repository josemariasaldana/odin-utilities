#!/bin/bash

PATHKERNELSRC="/home/fran/kernels/linux-3.18.13"

cd $PATHKERNELSRC

rmmod ath9k_htc
rmmod ath9k_common
rmmod ath9k_hw
rmmod ath

insmod ./drivers/net/wireless/ath/ath.ko 
insmod ./drivers/net/wireless/ath/ath9k/ath9k_hw.ko
insmod ./drivers/net/wireless/ath/ath9k/ath9k_common.ko
insmod ./drivers/net/wireless/ath/ath9k/ath9k_htc.ko
