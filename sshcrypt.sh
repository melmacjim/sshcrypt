#!/bin/bash

# Description:
# `sshcrypt.sh` will use a RSA SSH (no id_ed25519 support) Public Key to encrypt a file
# and use the Private RSA SSH Key to decrypt said file.
#
#
# Usage:
# To encrypt a file:
# `sshcrypt.sh -e file-to-encrypt path-to-public-ssh-key`
#
# To decrypt that file (the ecrypted file MUST have the .sshcrypt file extension):
# `sshcrypt.sh -d encrypted-file.sshcrypt path-to-private-ssh-key`
#
# (during decryption, `~/.ssh/id_rsa` will be used if no private-key is given)
#
#
# Source:
# https://bjornjohansen.no/encrypt-file-using-ssh-key


SECRET_SYMMETRIC_KEY="sskfile"  # 256 random character password file
SHRED="shred -n2 -uzf"

remove_sskfile () {
  [ -f $SECRET_SYMMETRIC_KEY ] && $SHRED $SECRET_SYMMETRIC_KEY*
}

something_failed () {
  if [ "$STEP" = "decryption" ] ; then
    echo -e "\n$STEP failed!\nyou may have typed the ssh private key password incorrectly\n"
  fi 
  remove_sskfile
  $SHRED *.enc
  exit 1
}

ssh_encrypt_file () {
  if [ $(openssl version | awk '{print $5}') -lt 2016 ] ; then
    echo -e "\nYou're current OpenSSL version is susceptible to te Heartbleed Bug : $(openssl version)\nPlease update openssl\n"
    exit 1
  fi
  STEP="encryption"
  local SECRET_FILE="$2"
  local PUBLIC_SSH_KEYPATH="$3"
  [ -z $SECRET_FILE ] || [ -z $PUBLIC_SSH_KEYPATH ] && print_help
  if ! grep -q "ssh-rsa" $PUBLIC_SSH_KEYPATH ; then
    echo -e "\nPlease use an RSA SSH public key."
    print_help
  else
    local ARCIVED_FILE="$SECRET_FILE.sshcrypt"
    { openssl rand -out $SECRET_SYMMETRIC_KEY 256 # 256 random character password file
      openssl aes-256-cbc -in $SECRET_FILE -out $SECRET_FILE.enc -pass file:$SECRET_SYMMETRIC_KEY # use the sskfile to encrypt the file
      openssl rsautl -encrypt -oaep -pubin -inkey <(ssh-keygen -e -m PKCS8 -f $PUBLIC_SSH_KEYPATH) -in $SECRET_SYMMETRIC_KEY -out $SECRET_SYMMETRIC_KEY.enc
    } || something_failed
    tar -czf $ARCIVED_FILE $SECRET_SYMMETRIC_KEY.enc $SECRET_FILE.enc
    $SHRED $SECRET_SYMMETRIC_KEY.enc $SECRET_FILE.enc
    echo -n "would you like to remove the original unencrypted file? [n]/y :  " && read CHOICE
    [ "$CHOICE" = "y" ] && $SHRED $SECRET_FILE
    echo -e "\nThe encrypted file is : $ARCIVED_FILE\n"
  fi
}

ssh_decrypt_file () {
  STEP="decryption"
  local ARCIVED_FILE="$2"
  local PRIVATE_SSH_KEYPATH="$3"
  [ -z $ARCIVED_FILE ] && print_help
  if [ -z "$PRIVATE_SSH_KEYPATH" ] ; then
    if [ -f "$HOME/.ssh/id_rsa" ] ; then
      PRIVATE_SSH_KEYPATH="$HOME/.ssh/id_rsa"
    else
      echo -e "\nCould not find your Private RSA SSH key."
      print_help
    fi
  fi
  if ! grep -q "PRIVATE KEY" $PRIVATE_SSH_KEYPATH ; then
    echo -e "\nPlease use an RSA SSH private key."
    print_help
  fi
  tar -xzf $ARCIVED_FILE
  local LOCAL_SSK_FILE="$SECRET_SYMMETRIC_KEY.enc"
  local ENCRYPTED_FILE="$(tar -ztf $ARCIVED_FILE | grep $SECRET_SYMMETRIC_KEY -v)"
  { openssl rsautl -decrypt -oaep -inkey $PRIVATE_SSH_KEYPATH -in $LOCAL_SSK_FILE -out $SECRET_SYMMETRIC_KEY
    openssl aes-256-cbc -d -in $ENCRYPTED_FILE -out $(echo $ENCRYPTED_FILE | sed 's/.enc//') -pass file:$SECRET_SYMMETRIC_KEY
  } || something_failed
  $SHRED $ENCRYPTED_FILE $LOCAL_SSK_FILE
  echo -n "would you like to remove the encrypted file? [y]/n :  " && read CHOICE
  [ "$CHOICE" != "n" ] && $SHRED $ARCIVED_FILE
  echo -e "\nThe decrypted file is : $(echo $ENCRYPTED_FILE | sed 's/.enc//')\n"
}

print_help() {
  echo "
Usage:
To encrypt a file: sshcrypt.sh -e file-to-encrypt path-to-public-ssh-key
To decrypt a file: sshcrypt.sh -d encrypted-file.sshcrypt path-to-private-ssh-key

(during decryption, ~/.ssh/id_rsa will be used if no private-key is given)
  "
  exit 1
}

if [ -z "$1" ] ; then
  print_help
else
  for input_options ; do
    case "$input_options" in
      -e|--encrypt) ssh_encrypt_file $@ ; break ;;
      -d|--decrypt) ssh_decrypt_file $@ ; break ;;
      -h|--help) print_help ;;
      *) echo -e "\nUnknown option $@\nSee \`sshcrypt -h\` for help." ; break ;;
    esac
  done
fi

remove_sskfile
