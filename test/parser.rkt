#lang racket

(require dssl2/private/parser)

(module+ test
  (require rackunit)
  (define (test-parse str result)
    (check-equal? (syntax->datum
                   (parse-dssl2 #false (open-input-string str) #false))
                  result))

  ; simple expressions
  
  (test-parse "a"
              '(begin a))
  (test-parse "5"
              '(begin 5))
  (test-parse "-5E-2"
              '(begin (- 5E-2)))
  (test-parse "v[i]"
              '(begin (vector-ref v i)))
  (test-parse "s.f"
              '(begin (struct-ref s f)))
  (test-parse "[0, 1, 2]"
              '(begin (vector 0 1 2)))
  (test-parse "[0, 1, 2,]"
              '(begin (vector 0 1 2)))
  (test-parse "[0; 10]"
              '(begin (make-vector 10 0)))
  (test-parse "posn { x = 3, y = 4 }"
              '(begin (make-posn [x 3] [y 4])))
  (test-parse "a == 4"
              '(begin (== a 4)))
  (test-parse "lambda x: y == 1"
              '(begin (lambda (x) (== y 1))))
  (test-parse "lambda x, y: x == y"
              '(begin (lambda (x y) (== x y))))
  (test-parse "λ x, y: x == y"
              '(begin (lambda (x y) (== x y))))
  (test-parse "f(3, x)"
              '(begin (f 3 x)))
  (test-parse "\na"
              '(begin a))

  ; compound expressions

  (test-parse "a + b * c + d"
              '(begin (+ (+ a (* b c)) d)))
  (test-parse "a ** b ** c"
              '(begin (** a (** b c))))
  (test-parse "a ** b ** c == 5"
              '(begin (== (** a (** b c)) 5)))
  (test-parse "a + -6"
              '(begin (+ a (- 6))))
  (test-parse "[5, lambda x: x + 1]"
              '(begin (vector 5 (lambda (x) (+ x 1)))))
  (test-parse "a.b.c"
              '(begin (struct-ref (struct-ref a b) c)))
  
  ; simple statements

  (test-parse "a = b"
              '(begin (setf! a b)))
  (test-parse "a = b; c = d.e"
              '(begin (setf! a b) (setf! c (struct-ref d e))))
;  (test-parse "a = b\nc = d\n"
;              '(begin (setf! a b) (setf! c d)))
  (test-parse "let x"
              '(begin (let x)))
  (test-parse "defstruct posn(x, y)"
              '(begin (defstruct posn (x y))))
  (test-parse "a.b.c = e[f]"
              '(begin (setf! (struct-ref (struct-ref a b) c)
                             (vector-ref e f))))
  (test-parse "assert False"
              '(begin (assert #f)))
  (test-parse "assert_eq a + 1, 6"
              '(begin (assert_eq (+ a 1) 6)))

  ; compound statements
  
  (test-parse "if a: c = d"
              '(begin (cond [a (setf! c d)] [else (pass)])))
  (test-parse "if a: c\nelse: e"
              '(begin (cond [a c] [else e])))
  (test-parse "if a: c = d\nelif b: e = 3\nelse: f = 4"
              '(begin (cond [a (setf! c d)]
                            [b (setf! e 3)]
                            [else (setf! f 4)])))
  (test-parse "if a:\n  c = d"
              '(begin (cond [a (setf! c d)]
                            [else (pass)])))
  (test-parse "if a:\n  b\n  c"
              '(begin (cond [a b c]
                            [else (pass)])))
  (test-parse "if a:\n  e[0]"
              '(begin (cond [a (vector-ref e 0)]
                            [else (pass)])))
  (test-parse "if a:\n  c = d\n  e[0] = 9"
              '(begin (cond [a (setf! c d)
                               (setf! (vector-ref e 0) 9)]
                            [else (pass)])))
  (test-parse "if a:\n  if b:\n    5"
              '(begin (cond [a (cond [b 5]
                                     [else (pass)])]
                            [else (pass)])))
  (test-parse "while True:\n  a = 6\n  b = 7"
              '(begin (while #t (setf! a 6) (setf! b 7))))
  (test-parse (string-append "def fact(n):\n"
                             "  if n <= 1: return 1\n"
                             "  else: return n * fact(n - 1)")
              '(begin (def (fact n)
                        (cond [(<= n 1) (return 1)]
                              [else     (return (* n (fact (- n 1))))]))))
  (test-parse (string-append "for j in v:\n"
                             "  println(j)")
              '(begin (for [j v] (println j))))
  (test-parse (string-append "for i, j in v:\n"
                             "  println(i, j)")
              '(begin (for [(i j) v] (println i j))))
  (test-parse "[ i for i in size_ ]"
              '(begin (for/vector [i size_] i)))
  (test-parse "let x = lambda y: z\nw"
              '(begin
                 (let x (lambda (y) z))
                 w))
  (test-parse "def as_vector():\n    [ i for i in size_ ]"
              '(begin (def (as_vector)
                           (for/vector [i size_] i))))
  )

