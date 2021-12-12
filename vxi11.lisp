(defpackage :vxi11
  (:documentation
   "An implementation of the VXI-11 protocol.

    VXI-11 provides three channels of communication between a client and a
    server:
     CORE CHANNEL: send commands from the CLIENT to the SERVER
     ABORT CHANNEL: abort from previously sent CORE CHANNEL commands
     INTR CHANNL: send an interrupt from the SERVER to the CLIENT

    The RPC IDs are those assigned to Hewlett Packard in RFC5531:
     #x0607AF (DEVICE_CORE)
     #x0607B0 (DEVICE_ASYNC)
     #x0607B1 (DEVICE_INTR)

    The latter two channels only provide a single call:
     DEVICE_ABORT for client to server, and DEVICE_INTR_SRQ  for
     server to client.  I do not setup a server to listen to
     DEVICE_INTR_SRQ because I haven't needed it, but FRPC2 has support
     for this so feel free to add it!

    The CORE CHANNEL implements the following:
     CREATE_LINK  opens a link to a device
     DEVICE_WRITE device receives a message
     DEVICE_READ  device returns a result
     DEVICE_READSTB device returns its status byte
     DEVICE_TRIGGER device executes a trigger
     DEVICE_CLEAR   device clears itself
     DEVICE_REMOTE  device disables its front panel
     DEVICE_LOCAL   device enables its front panel
     DEVICE_LOCK    device is locked
     DEVICE_UNLOCK  device is unlocked
     CREATE_INTR_CHAN device creates an interrupt channel
     DESTROY_INTR_CHAN device destroys an interrupt channel
     DEVICE_ENABLE_SRQ device enables/disables sending of service requests
     DEVICE_DOCMD   device executes a command
     DESTROY_LINK   closes a link to a device

   Until quicklisp is updated, you will need to go into your local quicklisp
   directory, typically ~/quicklisp/local-projects and run:

   git clone https://github.com/ajberkley/frpc2.git
   git clone https://github.com/ajberkley/fsocket.git
   git clone https://github.com/fjames86/dragons.git
   git clone https://github.com/fjames86/drx.git

   and at the REPL (quicklisp:quickload :vxi11).")
  (:use :drx :frpc2 :common-lisp)
  (:export
   #:vxi11-flush-incoming-data
   #:vxi11-test
   #:vxi11-query/string
   #:vxi11-write
   #:vxi11-write-raw
   #:vxi11-read/string
   #:vxi11-read/raw
   #:vxi11-connect
   #:vxi11-conn-max-recv-size
   #:vxi11-disconnect))

(in-package :vxi11)

(defxenum device-addr-family ()
  (:DEVICE_TCP 0)
  (:DEVICE_UDP 1))

(defxtype device-link () :uint32)
(defxtype device-flags () :uint32)
(defxtype device-error-code () :uint32)
         
(defxstruct device-error ()
  (error-code device-error-code))

(defxstruct create-link-parms ()
  (client-id :int32)
  (lock-device :boolean) ;; attempt to lock the device
  (lock-timeout :uint32) ;; time to wait on a lock (milliseconds)
  (device :string))      ;; name of device

(defxstruct create-link-resp ()
  (err device-error-code)
  (lid device-link)        ;; link id
  (abort-port :uint32)
  (max-recv-size :uint32)) ;; max data size in bytes device will accept on a write

(defxstruct device-write-parms ()
  (lid device-link)
  (io-timeout :uint32) ;; time to wait for I/O milliseconds
  (lock-timeout :uint32) ;; time to wait for lock milliseconds
  (flags device-flags)
  (data :opaque)) ;; the length and the data itself

(defxstruct device-write-resp ()
  (err device-error-code) ;; if 5 "parameter error" then it is too much data
  (size :uint32)) ;; number of bytes written

(defxstruct device-read-parms ()
  (lid device-link) ;; link id from create-link-parms
  (request-size :uint32) ;; bytes requested
  (io-timeout :uint32)
  (lock-timeout :uint32)
  (flags :uint32)
  (termchar :uint32 0)) ;; valid if flags & termchrset  flag bit 7 is termchrset (80), bit 3 is end (8), bit 0 is waitlock (1).  If bit 3 is set, the last byte is sent with an end indicator.

(defxstruct device-read-resp ()
  (err device-error-code)
  (reason :uint32)
  (data :opaque))

(defxstruct device-read-stb-resp ()
  (err device-error-code) ;; error code
  (stb :uint32)) ;; the returned status byte (still 32 bits because of RPC limitations)

(defxstruct device-generic-parms ()
  (lid device-link)
  (flags device-flags)
  (lock-timeout :uint32)
  (io-timeout :uint32))

(defxstruct device-remote-func ()
  (host-addr :uint32) ;; host servicing interrupt
  (host-port :uint32) ;; valid port # on client ;; uint16?
  (prog-num :uint32) ;; DEVICE_INTR
  (prog-vers :uint32) ;; DEVICE_INTR_VERSION
  (prog-family device-addr-family)) ;; DEVICE_UDP | DEVICE_TCP

(defxarray srq-parms-handle () :opaque 40)

(defxstruct device-enable-srq-parms ()
  (lid device-link)
  (enable :boolean)
  (handle srq-parms-handle))

(defxstruct device-lock-parms ()
  (lid device-link)
  (flags device-flags)
  (lock-timeout :uint32))

(defxstruct device-do-cmd-parms ()
  (lid device-link)
  (flags device-flags)
  (io-timeout :uint32)
  (lock-timeout :uint32)
  (cmd :uint32)
  (network_order :boolean)
  (datasize :uint32)
  (data-in :opaque))

(defxstruct device-do-cmd-resp ()
  (err device-error-code)
  (data-out :opaque))

(defconstant +device-core-pgm+ #x0607AF)
(defconstant +device-core-ver+ 1)

(define-rpc-client
    device-core (+device-core-pgm+ +device-core-ver+)
    (null0 :void :void)                                   ;; calls 0 - 9 are non-existant
    (null1 :void :void)                                   ;; calls 0 - 9 are non-existant
    (null2 :void :void)                                   ;; calls 0 - 9 are non-existant
    (null3 :void :void)                                   ;; calls 0 - 9 are non-existant
    (null4 :void :void)                                   ;; calls 0 - 9 are non-existant
    (null5 :void :void)                                   ;; calls 0 - 9 are non-existant
    (null6 :void :void)                                   ;; calls 0 - 9 are non-existant
    (null7 :void :void)                                   ;; calls 0 - 9 are non-existant
    (null8 :void :void)                                   ;; calls 0 - 9 are non-existant
    (null9 :void :void)                                   ;; calls 0 - 9 are non-existant
    (create-link create-link-parms create-link-resp) ;; 10
    (device-write device-write-parms device-write-resp)
    (device-read device-read-parms device-read-resp)
    (device-read-stb device-generic-parms device-read-stb-resp)
    (device-trigger device-generic-parms device-error)
    (device-clear device-generic-parms device-error)
    (device-remote device-generic-parms device-error)
    (device-local device-generic-parms device-error)
    (device-lock device-lock-parms device-error)
    (device-unlock device-link device-error)
    (enable-srq device-enable-srq-parms device-error) ;; 20
    (null10 :void :void)
    (device-do-cmd device-do-cmd-parms device-do-cmd-resp) ;; 22
    (destroy-link device-link device-error)                ;; 23
    (null11 :void :void)
    (create-intr-chan device-remote-func device-error) ;;25
    (destroy-intr-chan :void device-error)) ;; 26

;; Async channel
(defconstant +device-async-pgm+ #x0607B0)
(defconstant +device-async-ver+ 1)

(defrpc device-abort (+device-async-pgm+ +device-async-ver+ 1) device-link device-error)

;; Interrupt channel
(defconstant +device-intr-pgm+ #x0607B1)
(defconstant +device-intr-ver+ 1)

(defxstruct device-intr-srq ()
  (handle :opaque))

(defrpc device-intr (+device-intr-pgm+ +device-intr-ver+ 30) device-intr-srq :void)

;; begin higher level interface

(defvar *vxi11-errors*
    #.(let ((result (make-array 30 :element-type t :initial-element "INVALID ERROR CODE")))
        (map nil (lambda (e)
                   (setf (aref result (car e)) (cadr e)))
             '((0 "NO ERROR")
               (1 "SYNTAX ERROR")
               (3 "DEVICE NOT ACCESSIBLE")
               (4 "INVALID LINK IDENTIFIER (LID)")
               (5 "PARAMETER ERROR (DATA EXCEEDS MAXRECVSIZE)")
               (6 "CHANNEL NOT ESTABLISHED")
               (8 "OPERATION NOT SUPPORTED")
               (9 "OUT OF RESOURCES")
               (11 "DEVICE LOCKED BY ANOTHER LINK")
               (12 "NO LOCK HELD BY THIS LINK")
               (15 "I/O TIMEOUT")
               (17 "I/O ERROR")
               (21 "INVALID DEVICE ADDRESS")
               (23 "ABORT")
               (29 "CHANNEL ALREADY ESTABLISHED")))
        result))

(defun vxi11-check-error (resp)
  (multiple-value-bind (err-code operation)
      (etypecase resp
        (create-link-resp (values (create-link-resp-err resp) "CREATE-LINK"))
        (device-write-resp (values (device-write-resp-err resp) "DEVICE-WRITE"))
        (device-read-resp (values (device-read-resp-err resp) "DEVICE-READ"))
        (device-read-stb-resp (values (device-read-stb-resp-err resp) "DEVICE-READ-STB"))
        (device-do-cmd-resp (values (device-do-cmd-resp-err resp) "DEVICE-DO-CMD")))
    (if (zerop err-code)
        resp
        (error "During ~A got error ~A" operation (aref *vxi11-errors* err-code)))))

(defstruct vxi11-conn
  (lid -1 :type fixnum)
  (client nil)
  (device "" :type string)
  (host "" :type string)
  (max-recv-size 65536 :type fixnum))

(defmacro with-vxi11 ((lid conn vxi11-conn) &body body)
  (alexandria:once-only (vxi11-conn)
    `(let ((,lid (vxi11-conn-lid ,vxi11-conn))
           (,conn (vxi11-conn-client ,vxi11-conn)))
       ,@body)))

(defun setup-vxi11-finalizer (vxi11-conn lid client)
  (trivial-garbage:finalize
   vxi11-conn (lambda ()
                (handler-case
                    (progn
                      (call-device-core-destroy-link client lid)
                      (rpc-client-close client))
                  (error ())))))

(defun vxi11-connect (&key (host "tektronix-awg5208.dwavesys.local") (device "inst0") extant-vxi11-conn
                        (timeout 10000))
  "If extant-vxi11-conn is provided, will reconnect it. Used for the case where the TCP connection get dropped.
   we do not setup an abort or interrupt connection... not needed by any users yet.  Provide a port otherwise will
   use the port mapper to find out."
  (let* ((host (if extant-vxi11-conn (vxi11-conn-host extant-vxi11-conn) host))
         (device (if extant-vxi11-conn (vxi11-conn-device extant-vxi11-conn) device))
         (addr (get-rpc-address +device-core-pgm+ +device-core-ver+ host :tcp))
         (client (make-instance 'frpc2:tcp-client :addr addr :provider nil ;; no authentication
                                :timeout timeout :block (xdr-block (* 1024 32))))) ;; maybe bigger block size?
    (setf (fsocket:socket-option (frpc2::tcp-client-fd client) :tcp :nodelay) t) ;; also quickack
    (handler-case
        (let* ((create-link-resp (vxi11-check-error
                                  (call-device-core-create-link
                                   client
                                   (make-create-link-parms :client-id 0 :lock-timeout 1000 :device device))))
               (lid (create-link-resp-lid create-link-resp))
               (max-recv-size (create-link-resp-max-recv-size create-link-resp))
               (vxi11-conn (if extant-vxi11-conn
                               (progn
                                 (setf (vxi11-conn-lid extant-vxi11-conn) lid)
                                 (setf (vxi11-conn-client extant-vxi11-conn) client)
                                 (setf (vxi11-conn-max-recv-size extant-vxi11-conn) max-recv-size)
                                 extant-vxi11-conn)
                               (make-vxi11-conn :lid lid :client client :device device
                                                :max-recv-size max-recv-size :host host))))
          ;; Update our buffer size so we can send the max they can receive
          (setf (frpc2::rpc-client-block (vxi11-conn-client vxi11-conn)) (xdr-block max-recv-size))
          (when extant-vxi11-conn
            (trivial-garbage:cancel-finalization vxi11-conn))
          (setup-vxi11-finalizer vxi11-conn lid client)
          vxi11-conn)
      (error (e) (format t "Error on connect ~A!~%" e) (rpc-client-close client)))))

(defun vxi11-disconnect (vxi11-conn)
  "You do not have to explicitly close the connection as it will go away when garbage collected,
   but if you are opening / closing connections a lot you want to do this or you may run out of
   file descriptors."
  (assert (typep vxi11-conn 'vxi11-conn))
  (call-device-core-destroy-link (vxi11-conn-client vxi11-conn) (vxi11-conn-lid vxi11-conn))
  (rpc-client-close (vxi11-conn-client vxi11-conn))
  (trivial-garbage:cancel-finalization vxi11-conn))

;; TODO, add error handling which will reconnect the vxi11-conn (see vxi11-connect :extant-vxi11-conn).  Need to find
;; out what errors are thrown (some fsocket error presumably?)

;; read-resp-reason flags
(defconstant +reqcnt+ 1)
(defconstant +chr+ 2)
(defconstant +end+ 4)

;; read-parms FLAGS
(defconstant +waitlock+ 1)
(defconstant +end-flag+ 8)
(defconstant +term-char-set+ 80)

(defun vxi11-read/raw (vxi11-conn &optional (max-response-length 20480) (io-timeout 10000) (lock-timeout 10000))
  (with-vxi11 (lid conn vxi11-conn)
    (labels ((read-chunk ()
               (vxi11-check-error (call-device-core-device-read conn (make-device-read-parms :lid lid :request-size max-response-length :io-timeout io-timeout :lock-timeout lock-timeout :flags +end-flag+)))))
      (let* (data)
        (loop
          for resp = (read-chunk)
          do (unless (zerop (length (device-read-resp-data resp)))
               (setf data (concatenate '(simple-array (unsigned-byte 8) (*)) data (device-read-resp-data resp))))
          while (not (logtest (device-read-resp-reason resp) +end+)))
        data))))

(defconstant +newline+ (char-code #\Newline))
(defconstant +return+ (char-code #\Return))

(defun vxi11-read/string (vxi11-conn &key (max-response-length 20480) (io-timeout 10000))
  "Read result and return it as a SIMPLE-BASE-STRING.  As such we only support ASCII character
   encoding.  I don't think VXI11 supports unicode (certainly our instruments do not)."
  (let* ((raw-result (vxi11-read/raw vxi11-conn max-response-length io-timeout))
        (length (length raw-result)))
    (loop for char = (aref raw-result (1- length))
          while (and (or (= char +newline+) (= char +return+)) (not (zerop length)))
          do (decf length))
    (map-into (make-string length :element-type 'base-char) #'code-char raw-result)))

(defun vxi11-write/raw (vxi11-conn data &optional (io-timeout 10000))
  (with-vxi11 (lid conn vxi11-conn)
    (vxi11-check-error
     (call-device-core-device-write
      conn
      (make-device-write-parms
       :lid lid :flags +end-flag+ :data data
       :io-timeout io-timeout :lock-timeout 10000)))))

(defun vxi11-write (vxi11-conn data &optional (io-timeout 10000))
  (assert (or (stringp data) (typep data '(simple-array (unsigned-byte 8) (*)))))
  (vxi11-write/raw vxi11-conn (if (stringp data) (babel:string-to-octets data) data) io-timeout))

(defun vxi11-query/string (vxi11-conn query-string &key (max-response-length 20480) (io-timeout 10000))
  (vxi11-write vxi11-conn (concatenate 'string query-string (list #\Newline)))
  (vxi11-read/string vxi11-conn :max-response-length max-response-length :io-timeout io-timeout))

(defun vxi11-flush-incoming-data (vxi11-conn)
  (let* ((client (vxi11-conn-client vxi11-conn))
         (original-timeout (frpc2::tcp-client-timeout client)))
    (unwind-protect
         (progn
           (setf (frpc2::tcp-client-timeout client) 250)
           (frpc2::rpc-client-recv client))
      (setf (frpc2::tcp-client-timeout client) original-timeout))))
