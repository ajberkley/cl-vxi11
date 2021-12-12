(defsystem :vxi11
    :description "VXI11 for Common Lisp"
    :version "1.0.0"
    :author "Andrew Berkley <ajberkley@gmail.com>"
    :licence "BSD 3 Clause"
    :depends-on ("frpc2" "drx" "fsocket" "pounds" "babel" "trivial-garbage")
    :components ((:file "vxi11")))
