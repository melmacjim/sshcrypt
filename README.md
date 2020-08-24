# File Encryption with SSH Keys


## Description:
`sshcrypt.sh` will use a RSA SSH Public Key (sorry, no id_ed25519 support) to encrypt a file
and use the Private RSA SSH Key to decrypt said file.

When you use the encrypt flag (`-e`) followed by your `ORIGINAL_FILE`, and the full path to the receivers Public SSH Key<br>
(which is usually `~/.ssh/id_rsa.pub`), it will create a secure file named `ORIGINAL_FILE.sshcrypt`, which may be trasmitted via email, slack, or whatever.

When you use the decrypt flag (`-d`) followed by the `ORIGINAL_FILE.sshcrypt` file, and the full path to the Private RSA SSH Key (which is usually `~/.ssh/id_rsa`), it will prompt the user to enter their SSH Key password and if correct, produce the `ORIGINAL_FILE`.


## Usage:
To encrypt a file:
`sshcrypt.sh -e <file-to-encrypt> <path-to-public-ssh-key>`

To decrypt that file:
`sshcrypt.sh -d <encrypted-file.sshcrypt> <path-to-private-ssh-key>`


## Source:
https://bjornjohansen.no/encrypt-file-using-ssh-key
