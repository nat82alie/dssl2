#lang racket

(provide ; values
         ; * type predicates
         num?
         int?
         nat?
         float?
         str?
         char?
         bool?
         proc?
         vec?
         contract?
         ; * contracts
         any/c ; generated by parser
         AnyC
         VoidC
         (contract-out
           [OrC (-> contract? contract? ... contract?)]
           [AndC (-> contract? contract? ... contract?)]
           [FunC (-> contract? contract? ... contract?)]
           [NewForallC (-> str? contract?)]
           [NewExistsC (-> str? contract?)]
           [IntInC (-> (OrC int? #f) (OrC int? #f) contract?)]
           [apply_contract (case-> (-> contract? AnyC AnyC)
                                   (-> contract? AnyC str? AnyC)
                                   (-> contract? AnyC str? str? AnyC))]
           [make_contract (-> str?
                              (OrC #f (-> AnyC AnyC))
                              (OrC #f (-> (-> str? VoidC) AnyC AnyC))
                              contract?)])
         ; * numeric operations
         (contract-out
           [floor (-> num? int?)]
           [ceiling (-> num? int?)]
           [int (-> (OrC num? str? bool?) int?)]
           [float (-> (OrC num? str? bool?) float?)]
           [max (-> num? num? ... num?)]
           [min (-> num? num? ... num?)]
           [quotient (-> int? int? int?)]
           [random (case->
                     (-> float?)
                     (-> (IntInC 1 RAND_MAX) nat?)
                     (-> int? int? int?))]
           [random_bits (-> nat? nat?)]
           [RAND_MAX nat?]
           [remainder (-> int? int? int?)]
           [sqrt (-> num? num?)])
         ; ** predicates
         (contract-out
           [zero? (-> num? bool?)]
           [positive? (-> num? bool?)]
           [negative? (-> num? bool?)]
           [even? (-> int? bool?)]
           [odd? (-> int? bool?)])
         ; * string operations
         (contract-out
           [chr (-> nat? char?)]
           [explode (-> str? vec?)]
           [format (-> str? AnyC ... str?)]
           [implode (-> vec? str?)]
           [ord (-> char? nat?)]
           [strlen (-> str? nat?)])
         ; * vector operations
         (contract-out
           [build_vector (-> nat? (-> nat? AnyC) vec?)]
           [len (-> vec? nat?)]
           [map (-> (-> AnyC AnyC) vec? vec?)]
           [filter (-> (-> AnyC AnyC) vec? vec?)])
         ; * I/O operations
         (contract-out
           [print (-> str? AnyC ... VoidC)]
           [println (-> str? AnyC ... VoidC)])
         ; * other functions
         identity)
(require dssl2/private/errors
         (prefix-in racket: racket))

(define (num? x) (number? x))

(define (int? x) (exact-integer? x))

(define (nat? x) (and (int? x) (not (negative? x))))

(define (float? x) (flonum? x))

(define (str? x) (string? x))

(define (char? x)
  (and (string? x) (= 1 (string-length x))))

(define (bool? x) (boolean? x))

(define (proc? x) (procedure? x))

(define (vec? x) (vector? x))

(define AnyC (flat-named-contract 'AnyC any/c))

(define VoidC (flat-named-contract 'VoidC void?))

(define (format-fun f x xs)
  (define port (open-output-string))
  (fprintf port "~a(~a" f (contract-name x))
  (for ([xi (in-list xs)])
    (fprintf port ", ~a" (contract-name xi)))
  (fprintf port ")")
  (get-output-string port))

(define (OrC c . cs)
  (rename-contract
    (apply or/c c cs)
    (format-fun 'OrC c cs)))

(define (AndC c . cs)
  (rename-contract
    (apply and/c c cs)
    (format-fun 'AndC c cs)))

(define (FunC c . cs)
  (define all (cons c cs))
  (define rev-all (reverse all))
  (define args (reverse (rest rev-all)))
  (define res (first rev-all))
  (rename-contract
    (dynamic->* #:mandatory-domain-contracts args
                #:range-contracts (list res))
    (format-fun 'FunC c cs)))

(define (NewForallC name)
  (new-∀/c (string->symbol name)))

(define (NewExistsC name)
  (new-∃/c (string->symbol name)))

(define (IntInC low high)
  (rename-contract
    (integer-in low high)
    (format-fun 'IntInC low (list high))))

(define apply_contract
  (case-lambda
    [(contract value pos neg)
     (racket:contract contract value pos neg)]
    [(contract value pos)
     (apply_contract contract value pos "the context")]
    [(contract value)
     (apply_contract contract value "the contracted value")]))

(define (make_contract name first-order? projection)
  (make-contract #:name name
                 #:first-order first-order?
                 #:late-neg-projection
                 (λ (blame)
                    (λ (value party)
                       (projection
                         (λ (message)
                            (raise-blame-error blame
                                               #:missing-party party
                                               value
                                               message))
                         value)))))

(define (build_vector n f)
  (racket:build-vector n f))

(define (len v)
  (vector-length v))

(define (map f vec)
  (build-vector (vector-length vec)
                (λ (i) (f (vector-ref vec i)))))

(define (filter f vec)
  (list->vector (racket:filter f (vector->list vec))))

(define (print fmt . values)
  (cond
    [(string? fmt) (display (apply format fmt values))]
    [else          (for-each display (cons fmt values))]))

(define (println fmt . values)
  (apply print fmt values)
  (newline))

(define (chr i)
  (~a (integer->char i)))

(define (explode s)
  (list->vector
    (racket:map (λ (c) (list->string (list c)))
                (string->list s))))

(define (implode vec)
  (apply string-append (vector->list vec)))

(define (ord c)
  (char->integer (string-ref c 0)))

(define (strlen str)
  (string-length str))

(define (floor n)
  (inexact->exact (racket:floor n)))

(define (ceiling n)
  (inexact->exact (racket:ceiling n)))

(define (int x)
  (cond
    [(number? x) (inexact->exact (truncate x))]
    [(string? x)
     (cond
       [(string->number x) => int]
       [else (runtime-error "int: could not convert to integer: ~s" x)])]
    [(eq? #t x)  1]
    [(eq? #f x)  0]
    [else (type-error 'int x "number, string, or Boolean")]))

(define (float x)
  (cond
    [(number? x) (exact->inexact x)]
    [(string? x)
     (cond
       [(string->number x) => float]
       [else (runtime-error "float: could not convert to float: ~s" x)])]
    [(eq? #t x)  1.0]
    [(eq? #f x)  0.0]
    [else (type-error 'int x "number, string, or Boolean")]))

; This is the largest argument that `random` can take.
(define RAND_MAX 4294967087)

(define random
  (case-lambda
    [() (racket:random)]
    [(limit) (racket:random limit)]
    [(low high) (racket:random low high)]))

(define (random_bits n)
  (define *RADIX* 16)
  (cond
    [(zero? n)      0]
    [else           (+ (* 2 (random_bits (sub1 n)))
                       (random 2))]))
