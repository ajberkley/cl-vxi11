# cl-vxi11
Native VXI11 in Common Lisp for talking to instruments

# Dependencies
FRPC2, FSOCKET, DRAGONS, DRX, POUNDS

For now you want to
    git clone https://github.com/ajberkley/frpc2.git
    git clone https://github.com/ajberkley/fsocket.git
    git clone https://github.com/fjames86/dragons.git
    git clone https://github.com/fjames86/drx.git

and at the REPL run
    (quicklisp:quickload :pounds)

# TODO / features to add

* Reconnecting after a dropped / lost connection
* Implement DEVICE_INTR for SRQ (I have not run into a use case for this)

# Usage

    (defparameter *my-instr*
      (vxi11:vxi11-connect :host "tektronix-awg5208.your-domain.com"
                              :device "inst0"))

    (vxi11:vxi11-query/string *my-instr* "*IDN?")

    (vxi11:vxi11-disconnect *my-instr*) ;; or let it get garbage collected
