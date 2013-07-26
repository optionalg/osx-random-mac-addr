OS X Random MAC Address Changer
-------------------------------

A Bash shell script which does the heavy lifting and an Administrative privlege seeking OS X .app wrapper for ease of use.

It works with my Macbook and 10.6.8, YMMV.


Use
---------

    # by default will change en1 (Wireless Interface)
    mac-spoof.sh -yes

    # You can also spoof your ethernet.
    mac-spoof.sh -yes en0



Install
---------
Two Parts:
Copy or symlink mac-spoof.sh to `~/bin/`

    mkdir -vp ~/Code && cd ~/Code
    git clone https://git-direct.ns1.net/px/osx-random-mac-addr.git osx-random-mac-addr.git
    cd osx-random-mac-addr.git
    # create the directory
    mkdir -vp ~/bin
    # symlink
    ln -sf mac-spoof.sh ~/bin/
    # copy
    cp mac-spoof.sh ~/bin/

Copy the .app file.
 `cp "Random MAC Address.app" ~/Applications/`

Enjoy!

