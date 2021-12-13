#!/bin/bash
# cerius.sh

#C Help section 
if [ "$1" = "--help" ]; then
  echo "
  runs cerius
  usage:
  call it with arg1 = -unlock to unlock a crashed Cerius
  "
  exit
elif [ "$1" = "-unlock" ]; then 
  . /home/accelrys/License_Pack/msi_lic_profile
  export LD_LIBRARY_PATH=/usr/X11R6/lib:/lib
  /home/accelrys/cerius2_c410L/bin/cerius2 -unlock
else
  . /home/accelrys/License_Pack/msi_lic_profile
  export LD_LIBRARY_PATH=/usr/X11R6/lib:/lib
  /home/accelrys/cerius2_c410L/bin/cerius2 
fi

