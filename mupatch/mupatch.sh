#!/bin/bash
RED='\033[0;31m'
NCO='\033[0m'
clear
pwd=$(pwd)
echo -e "${RED}${NCO}"

echo -e "${RED}You are logged in as `whoami` ${NCO}"
if [ `whoami` != "oracle" ]; then
  echo "Must be logged on as oracle to run this script."
  exit
fi

stty -echo
        echo -n -e "${RED}Enter the database system password:${NCO}"
        read pw
stty echo
echo ""

echo -e "${RED}Unzipping opatcher...${NCO}"
unzip -o -d $pwd/opatcher $pwd/opatcher/*.zip 2>&1 >/dev/null | grep 'unzip'

echo -e "${RED}Unzipping patch...${NCO}"
unzip -o -d $pwd/patch $pwd/patch/*.zip 2>&1 >/dev/null | grep 'unzip'

echo -e "${RED}Shutting down Oracle instance...${NCO}"
out=`sqlplus -S "sys/$pw as sysdba" << EOF
  shutdown immediate;
EOF
`

echo -e "${RED}Shutting down Oracle listener...${NCO}"
lsnrctl stop 2>&1 >/dev/null

echo ''
echo -e "${RED}Applying patches ...${NCO}"
for f in patch/*; do
  if [[ -d $f ]]; then
    for i in $f/*; do
      if [[ -d $i ]]; then
        $pwd/opatcher/OPatch/opatch apply $i
      fi
    done
  fi
done

echo -e "${RED}Post installation tasks...${NCO}"
echo -e "${RED}Starting up Oracle instance in upgrade mode...${NCO}"
out=`sqlplus -S "sys/$pw as sysdba" << EOF
  startup upgrade;
EOF
`

echo -e "${RED}Applying datapatch...${NCO}"
$pwd/opatcher/OPatch/datapatch

echo -e "${RED}Shutting down Oracle instance...${NCO}"
out=`sqlplus -S "sys/$pw as sysdba" << EOF
  shutdown immediate;
EOF
`

echo -e "${RED}Starting up Oracle instance...${NCO}"
out=`sqlplus -S "sys/$pw as sysdba" << EOF
  startup;
EOF
`

echo -e "${RED}Script ended!${NCO}"
