# This script installs opam for the user. It should NOT be included in any makefiles/etc.

if [ -n "`which opam`"]
then
    if [ -n "`opam --version | grep -P "2\..\.."`" ]
    then
	echo "Opam 2.x seems to already exist, exiting..."
	exit 1
    fi
else
    read -p "This script will upgrade opam to the 2.x series, are you okay with that? (y/n)" choice1
    case "$choice1" in
	y|Y ) : ;;
	n|N ) exit ;;
    esac
fi

sudo apt-get install -y make \
     m4 \
     gcc \
     patch \
     bubblewrap \
     rsync \
     curl \
    
if [ -n "`uname -a | grep -i ubuntu`" ]
then
    sudo add-apt-repository -y ppa:avsm/ppa
    sudo apt-get update
    sudo apt-get install opam
else
    # I'm going to assume here that we're on x86_64, 32-bit users should be basically
    # extinct at this point right?
    curl -L https://github.com/ocaml/opam/releases/download/2.0.4/opam-2.0.4-x86_64-linux \
	 --output opam_temp_version_2_0_4.bin
    if [ "`openssl sha256 -r opam`" = "373e34f92f282273d482537f8103caad0d17b6f2699ff504bed77f474cb0c951 *opam" ]
    then
	# Stay paranoid, in case other checks fail don't want to overrwrite
	# user's opam on accident
	chmod +x opam_temp_version_2_0_4.bin # Set execute so we can get version
	if [ -e /usr/local/bin/opam ]
	then
	    opam_old_v=`/usr/local/bin/opam --version`
	    opam_new_v=`opam_temp_version_2_0_4.bin --version`
	    read -p "This will overrwrite the opam you have in /usr/local/bin (version $opam_old_v) with version $opam_new_v, do you actually want to do that? Type yes. (yes/n)" choice2
	else
	    choice2="yes"
	fi
	if [ $choice2 = "yes" ]
	then
	    sudo mv opam_temp_version_2_0_4.bin /usr/local/bin/opam
	else
	    rm opam_temp_version_2_0_4.bin
	    exit
    else
	echo "opam file hash doesn't match what was recorded at time of signature verification!"
	echo "(If you actually get this message, you should probably file an issue)"
	echo "https://gitlab.com/ligolang/ligo/issues"
	exit 1
    fi	   	   
fi

opam init -a --bare
