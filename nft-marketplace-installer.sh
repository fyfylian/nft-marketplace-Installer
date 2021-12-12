#!/bin/sh

#**********************************************
#          NFT Marketplace Installer           *
# Created By: Fyfy.io                  *
# Copyright: Fyfy.io - Dec 2021         *
#**********************************************

clear #Start the screen fresh.

#Reused variables
current_dir=$(pwd)
GITHUB=""
SITENAME=""
asset_pfix_new="ASSET_PREFIX="
asset_pfix_old="ASSET_PREFIX=/nft-marketplace/"

#Functions Here
user_status () {
   ID=$(/usr/bin/id -u)
   if [ ${ID} -ne 0 ] && [ whoami != "root" ]; then
      echo "You don't possess the power of Root!"
      echo "You must be Root user to run the Installer."
      exit 1
   fi
}

filechanges () {
  #Edit packages.json file at line 47
  clear
  #Change the owner name of the repository for NFT Marketplace."
  sed -i 's/fyfyio/'${GITHUB}'/g' ${current_dir}/nft-marketplace/js/packages/web/package.json
  #Modify Asset Prefix in package.json line 56.
  sed -i "s|${asset_pfix_old}|${asset_pfix_new}|" ${current_dir}/nft-marketplace/js/packages/web/package.json
  #Add wallet address in .env file.
  read -p "Paste the wallet address for the store owner: " WALLET
  cat > ${current_dir}/nft-marketplace/js/packages/web/.env <<EOF
  REACT_APP_STORE_OWNER_ADDRESS_ADDRESS=${WALLET}
  REACT_APP_STORE_ADDRESS=
EOF
  #Add CNAME
  touch ${current_dir}/nft-marketplace/js/packages/web/public/CNAME
  read -p "Enter your CNAME or website name that will point to github pages: " SITENAME
  echo ${SITENAME} > ${current_dir}/nft-marketplace/js/packages/web/public/CNAME
}

user_status

#Clone the NFT Marketplace Repo from the Users Github repository.
read -p "Enter your github name: " GITHUB
if [ ! -d ${current_dir}/nft-marketplace ]; then
  git clone https://github.com/"${GITHUB}"/nft-marketplace.git
fi

# Prerequisites for NFT Marketplace to be installed.
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y curl
if [ $? = 0 ]; then
  curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
  if [ $? = 0 ]; then
    sudo apt install -y nodejs
  else
    clear
    echo "Nodejs did not download properly! Please Investigate."
    exit 1
  fi
else
  clear
  echo "Curl did not install! Please Investigate."
  exit 2
fi

#Run function to make the necessary file changes.
filechanges

#Setup npm, yarn and then deploy.
cd ${current_dir}/nft-marketplace/js
npm install -g yarn
if [ $? = 0 ]; then
  echo "Yarn installed successfully!"
  yarn
  if [ $? = 0 ]; then
    yarn bootstrap
    if [ $? = 0 ]; then
      clear
      echo "NFT Marketplace will now be built and deployed. Have your github account and access code ready."
      yarn build
      if [ $? = 0 ]; then
        cd packages/web
        #Ask user if they have set their Github identity before, get info and set if not.
        read -p "Have you set your GitHub default identity? (y/N) " IDENTITY
        if [ ${IDENTITY} = "n" ] || [ ${IDENTITY} = "N" ]; then
          read -p "Enter your email address that is used for Github: " EMAIL
          read -p "Enter your Github User Name: " USER
          git config --global user.email "${EMAIL}"
          git config --global user.name "${USER}"
        fi
        #Deploy the NFT Marketplace and Go Live.
        yarn deploy
        if [ $? = 0 ]; then
          clear
          echo "************************************************************************"
          echo "* Your NFT Marketplace is now ready to be used at: ${SITENAME}   *"
          echo "* If you found this installer helpful please support with SOL.         *"
          echo "*                                                                      *"
          echo "*    Donate SOL: 77S3j6r36qF3nLYFGpJrWA1nfPQighfkmiPhNkwGrusE          *"
          echo "************************************************************************"
        fi
      else
          clear
          echo "The command (yarn build) had an issue, please investigate."
          exit 4
      fi
    fi
  fi
else
  clear
  echo "Yarn did not install, please investigate."
  exit 3
fi
