#!/bin/bash

echo "- - -" | sudo tee -a /sys/class/scsi_host/host3/scan
sudo mount /media/VIDEO1
sudo mount /media/VIDEO2
