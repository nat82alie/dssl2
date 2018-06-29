#lang racket/base

(provide struct-predicate-name
         struct-special-name
         struct-special-name/located
         generic-interface-contract-name
         generic-class-contract-name
         struct-constructor-name
         struct-getter-name
         struct-setter-name)

(require syntax/parse/define
         (only-in racket/syntax format-id))
(require (for-syntax racket/base
                     (only-in racket/syntax format-id)))

(define (struct-predicate-name name)
  (format-id name "~a?" name))

; Names like this are generated by the parser.
(define (struct-special-name name)
  (format-id name "~a{}" name))

; Here's the function the parser uses.
(define (struct-special-name/located name)
  (format-id #f "~a{}" name #:source name))

(define (generic-interface-contract-name name)
  (format-id name "~a_OF" name))

(define (generic-class-contract-name name)
  (format-id name "~aOf" name))

(define-syntax (struct-constructor-name stx)
  (syntax-parse stx
    [(_ name:id)
     (format-id #'name "make-~a" #'name)]))

(define-syntax (struct-getter-name stx)
  (syntax-parse stx
    [(_ name:id field:id)
     (format-id #'name "~a-~a" #'name #'field)]))

(define-syntax (struct-setter-name stx)
  (syntax-parse stx
    [(_ name:id field:id)
     (format-id #'name "set-~a-~a!" #'name #'field)]))
