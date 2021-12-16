# cl-vxi11
Native VXI11 in Common Lisp for talking to instruments

# Dependencies

## Direct

FRPC2, DRX, TRIVIAL-GARBAGE, BABEL

## Indirect

FSOCKET, DRAGONS, DRX, POUNDS, NIBBLES

## Installing dependencies

For now you want to go to your quicklisp local projects directory

    cd ~/quicklisp/local-projects
    git clone https://github.com/fjames86/frpc2.git
    git clone https://github.com/fjames86/fsocket.git
    git clone https://github.com/fjames86/dragons.git
    git clone https://github.com/fjames86/drx.git

# TODO / features to add

* Detecting / reconnecting after a dropped / lost connection
* Implement DEVICE_INTR for SRQ (I have not run into a use case for this)
* Add broadcast for instrument discovery

# Usage

    (quicklisp:quickload "vxi11")

    (defparameter *my-instr*
      (vxi11:vxi11-connect :host "your-instrument-hostname" :device "inst0"))

    (vxi11:vxi11-query/string *my-instr* "*IDN?")

    (vxi11:vxi11-disconnect *my-instr*) ;; or let it get garbage collected
