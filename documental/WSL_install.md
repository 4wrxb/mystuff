# WSL setup/install

This is my process for setting up a WSL user environment

## MISC/TODO

- LANG fix (where?): `sudo /usr/sbin/update-locale LANG=en_US.UTF8`
- Need to flush out workstuff/mystuff order, either hard-code proxy or do workstuff
- Can we access encrypted 7-zip from Linux? E.g. use gitcrypt_key directly
- Reconcile this process with work-env setup process

## Workstuff only

1) Download workstuff `git clone https://[WORKSTUFF]`
1) Run `~/workstuff/wsl/Install_wsl.sh` for key/proxy\*
1) Install git-crypt (`sudo apt install git-crypt`)
1) Manually source work_env (`source ~/workstuff/wsl/work_env`)

\*NOTE: this overrides its own remote URL, but it won't work until assh setup is complete

## Bootstrap mystuff

NOTE: WIP to replace this with Bootstrap_Install.sh, striking steps for now

1) ~~Download mystuff `git clone https://github.com/4wrxb/mystuff`~~
1) ~~Install git-crypt `sudo apt install git-crypt`~~
1) Extract git-crypt key from Dropbox (e.g. to `/mnt/c/Users/user/mystuff.gitcrypt_key`)
1) Unlock mystuff's encrypted files `git-crypt unlock /mnt/c/Users/user/mystuff.gitcrypt_key`
1) Remove the decrypted key `rm /mnt/c/Users/user/mystuff.gitcrypt_key`
1) Run the install script for mystuff `~/mystuff/home/Install_from_dir.sh`
1) CP/Link protected SSH key from Dropbox `cp /mnt/c/Users/user/Dropbox/keyparis/id_rsa ~/.ssh/`
1) Fix key file umask `chmod 600 ~/.ssh/id_rsa`
1) ~~Restart shell, confirm the following run: .will.bashrc, .will.profile, will.aliases, work_env if applicable~~
1) ~~Install/update WSL software `~/mystuff/home/Install_wsl_software.sh`~~
1) Resource aliases (assh for example) `aresrc`

## Finalize config

(after go and assh are working)

1) ~~Update remote url for mystuff (workstuff was already done) `git remote set-url origin git@github.com:4wrxb/mystuff.git`~~
1) ~~fetch both (cd to mystuff and workstuff) `git fetch`~~
1) set-up winhome copies of repos and add each others as remotes
