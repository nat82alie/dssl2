#lang scribble/manual

@(require
        "util.rkt"
        (for-label dssl2))

@title{DSSL2: Data Structures Student Language}
@author{Jesse A. Tov <jesse@"@"eecs.northwestern.edu>}

@defmodulelang[dssl2]

@section[#:tag "dssl-syntax"]{Syntax of DSSL2}

@subsection{Compound statements and blocks}

DSSL2 uses alignment and indentation to delimit blocks. In particular,
compound statements such as @racket[if]-@racket[elif]-@racket[else] take
@syn[block]s for each condition, where a @syn[block] can be either one
simple statement followed by a newline, or a sequence of statements on
subsequent lines that are all indented by four additional spaces. Here
is an example of a tree insertion function written using indentation:

@dssl2block|{
def insert!(t, k):
    if empty?(t): new_node(k)
    elif random(size(t) + 1) == 0:
        root_insert!(t, k)
    elif k < t.key:
        t.left = insert!(t.left, k)
        fix_size!(t)
        t
    elif k > t.key:
        t.right = insert!(t.right, k)
        fix_size!(t)
        t
    else: t
}|

Each block follows a colon and newline, and is indented 4 spaces more
than the previous line. In particular, the block started by @racket[def]
is indented by 4 spaces, and the @racket[elif] blocks by
8. When a block is a simple statement, it can be placed on the same
line, as in the @racket[if] and @racket[else] cases.

Extranous indentation is an error.

@subsection{DSSL2 Formal Grammar}

The DSSL2 language has a number of statement and expression forms, which
are described in more depth below. Here they are summarized in
@hyperlink["https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form"]{
    Extended Backus-Naur Form}.

Non-terminal symbols are written in @syn{italic typewriter}, whereas
terminal symbols are in @q{colored typewriter}. Conventions include:

@itemlist[
 @item{@m["{"] @syn[x] @m["}*"] for repetition 0 or more times}
 @item{@m["{"] @syn[x] @m["}⁺"] for repetition 1 or more times}
 @item{@m["{"] @syn[x] @m["},*"] for repetition 0 or more times with commas in
 between}
 @item{@m["["] @syn[x] @m["]"] for optional}
]

The grammar begins by saying that a program is a sequence of zero or
more statements, where a statement is either a simple statement followed
by a newline, or a compound statement.

@racketgrammar*[
#:literals (def defstruct let lambda λ else if elif while for in test
            time object break continue : True False =
            assert assert_eq pass return NEWLINE INDENT DEDENT)
[program (code:line @#,m["{"] statement @#,m["}*"])]
[statement   (code:line simple @#,q{NEWLINE})
             compound]
[simple
            (code:line assert expr)
            (code:line assert_eq expr @#,q{,} expr)
            break
            continue
            (code:line defstruct name @#,q{(} @#,m["{"] field @#,m["},*"] @#,q{)})
            (code:line lvalue = expr)
            expr
            (code:line let var @#,m["["] @#,q{=} expr @#,m["]"])
            (code:line pass)
            (code:line return @#,m["["] expr @#,m["]"])
            (code:line simple @#,q{;} simple)]
[lvalue var
        (code:line expr @#,q{.} field)
        (code:line expr @#,q["["] expr @#,q["]"])]
[compound
            (code:line def name @#,q{(} var @#,q{,} @#,m{...} @#,q{)} @#,q{:} block)
            (code:line if expr @#,q{:} block @#,m["{"] elif expr @#,q{:} block @#,m["}*"] @#,m["["] else expr @#,q{:} block @#,m["]"])
            (code:line for var @#,m{[} @#,q{,} var @#,m{]} @#,q{in} expr @#,q{:} block)
            (code:line test expr @#,q{:} block)
            (code:line time expr @#,q{:} block)
            (code:line while expr @#,q{:} block)
            ]
[block
        (code:line simple @#,q{NEWLINE})
        (code:line @#,q{NEWLINE} @#,q{INDENT} @#,m["{"] statement @#,m["}⁺"] @#,q{DEDENT})]
[expr lvalue
      number
      string
      True
      False
      (code:line expr @#,q{(} @#,m["{"] expr @#,m["},*"] @#,q{)})
      (code:line lambda @#,m["{"] var @#,m["},*"] @#,q{:} expr)
      (code:line @#,q{λ} @#,m["{"] var @#,m["},*"] @#,q{:} expr)
      (code:line expr @#,q{if} expr @#,q{else} expr)
      (code:line structname @#,q["{"] @#,m["{"] fieldname = expr @#,m["},*"] @#,q[" }"])
      (code:line object structname @#,q["{"] @#,m["{"] fieldname = expr @#,m["},*"] @#,q[" }"])
      (code:line @#,q{[} @#,m["{"] expr @#,m["},*"] @#,q{]})
      (code:line @#,q{[} expr @#,q{;} expr @#,q{]})
      (code:line @#,q{[} expr @#,q{for} var @#,m{[} @#,q{,} var @#,m{]} @#,q{in} expr @#,m{[} @#,q{if} expr @#,m{]} @#,q{]})
      (code:line expr BINOP expr)
      (code:line UNOP expr)
      ]
]

@italic{BINOP}s are, from tightest to loosest precedence:

@itemlist[
 @item{@racket[**]}
 @item{@racket[*], @racket[/], and @racket[%]}
 @item{@racket[+] and @racket[-]}
 @item{@racket[>>] and @racket[<<]}
 @item{@racket[&]}
 @item{@racket[^]}
 @item{@racket[\|] (not written with the backslash)}
 @item{@racket[==], @racket[<], @racket[>], @racket[<=], @racket[>=],
 @racket[!=], @racket[===], and @racket[!==]}
 @item{@racket[and]}
 @item{@racket[or] (not written with the backslashes)}
]

@italic{UNOP}s are @racket[!], @racket[~], @racket[+], @racket[-].

@subsection[#:tag "stm-forms"]{Statement Forms}

@defsmplform{@defidform/inline[assert] @syn[expr]}

Asserts that the given @syn[expr] evaluates to non-false. If the
expression evaluates false, signals an error.

@dssl2block|{
test "sch_member? finds 'hello'":
    let h = sch_new_sbox(10)
    assert !sch_member?(h, 'hello')
    sch_insert!(h, 'hello', 5)
    assert sch_member?(h, 'hello')
}|

@defsmplform{@defidform/inline[assert_eq] @syn[expr]₁, @syn[expr]₂}

Asserts that the given @syn[expr]s evaluates to structurally equal values.
If they are not equal, signals an error.

@dssl2block|{
test 'first_char_hasher':
    assert_eq first_char_hasher(''), 0
    assert_eq first_char_hasher('A'), 65
    assert_eq first_char_hasher('Apple'), 65
    assert_eq first_char_hasher('apple'), 97
}|

@defsmplform{@defidform/inline[break]}

When in a @racket[for] or @racket[while] loop, ends the (inner-most)
loop immediately.

@defsmplform{@defidform/inline[continue]}

When in a @racket[for] or @racket[while] loop, ends the current
iteration of the (inner-most) loop and begins the next iteration.

@defcmpdform{@defidform/inline[def] @syn[name](@syn[var]₁, ... @syn[var]@subscript{k}): @syn[block]}

Defines @syn[name] to be a function with formal parameters @syn[var]₁,
@code{...}, @syn[var]@subscript{k} and with body @syn[block].

For example,

@dssl2block|{
def fact(n):
    if n < 2:
        return 1
    else:
        return n * fact(n - 1)
}|

A function may have zero arguments, as in @racket[greet]:

@dssl2block|{
def greet(): println("Hello, world!")
}|

The body of a function is defined to be a block, which means it can be
an indented sequence of statements, or a single simple statement on the
same line as the @racket[def].

Note that @racket[def]s can be nested:

@dssl2block|{
# rbt_insert! : X RbTree<X> -> Void
def rbt_insert!(key, tree):
    # parent : RbLink<X> -> RbLink<X>
    def parent(link):
        link.parent if rbn?(link) else False
    # grandparent : RbLink<X> -> RbLink<X>
    def grandparent(link):
        parent(parent(link))
    # sibling : RbLink<X> -> RbLink<X>
    def sibling(link):
        let p = parent(link)
        if rbn?(p):
            if link === p.left: p.right
            else: p.left
        else: False
    # aunt : RbLink<X> -> RbLink<X>
    def aunt(link):
        sibling(parent(link))
    #
    # . . .
    #
    def set_root!(new_node): tree.root = new_node
    search!(tree.root, set_root!)
}|

@defsmplform{@defidform/inline[defstruct] @syn[structname](@syn[fieldname]₁, ..., @syn[fieldname]@subscript{k})}

Defines a new structure type @syn[structname] with fields given by
@syn[fieldname]₁, @code{...}, @syn[fieldname]@subscript{k}. For example,
to define a struct @racket[posn] with fields @racket[x] and @racket[y],
we write:

@dssl2block|{
defstruct posn(x, y)
}|

Then we can create a @racket[posn] using struct construction syntax and
select out the fields using dotted selection syntax:

@dssl2block|{
let p = posn { x = 3, y = 4 }
}|

@dssl2block|{
def magnitude(q):
    sqrt(q.x * q.x + q.y * q.y)
}|

It also possible to construct the struct by giving the fields in order
using function syntax:

@dssl2block|{
assert_eq magnitude(posn(3, 4)), 5
}|

Another example:

@dssl2block|{
# A RndBst<X> is one of:
# - False
# - Node(X, Natural, RndBst<X>, RndBst<X>)
defstruct Node(key, size, left, right)
#
# singleton : X -> RndBst<X>
def singleton(key):
    Node(key, 1, False, False)
#
# size : RndBst<X> -> Natural
def size(tree):
    tree.size if Node?(tree) else 0
#
# fix_size! : Node? -> Void
def fix_size!(node):
    node.size = 1 + size(node.left) + size(node.right)
}|

@defsmplform{@syn[lvalue] @defidform/inline[=] @syn[expr]}

Assignment. The assigned @syn[lvalue] can be in one of three forms:

@itemlist[
 @item{@syn[var] assigns to a variable, which can be a @syn[let]-bound
 local or a function parameter.}
 @item{@code{@syn[expr].@syn[fieldname]} assigns to a structure field, where
 the expression must evaluate to a structure that has the given field
 nane.}
 @item{@code{@syn[expr]₁[@syn[expr]₂]} assigns to a vector element, where
 @code{@syn[expr]₁} evaluates to the vector and @code{@syn[expr]₂}
 evaluates to the index of the element.}
]

This function assigns all three kinds of l-value:

@dssl2block|{
def sch_insert!(hash, key, value):
    let index = sch_bucket_index_(hash, key)
    let current = hash.buckets[index]
    while cons?(current):
        if key == current.first.key:
            current.first.value = value
            return
        current = current.rest
    hash.buckets[index] = cons(sc_entry(key, value), hash.buckets[index])
}|

@defsmplform{@syn[expr]}

An expression, evaluated for both side effect and, if at the tail end
of a function, its value.

For example, this function returns the @racket[size] field of parameter
@racket[tree] if @racket[tree] is a @racket[Node], and @racket[0] otherwise:

@dssl2block|{
# size : RndBst<X> -> Natural
def size(tree):
    if Node?(tree): tree.size
    else: 0
}|

@defcmpdform{@defidform/inline[if] @syn[expr]@subscript{if}: @syn[block]@subscript{if}
             @defidform/inline[elif] @syn[expr]@subscript{i}: @syn[block]@subscript{i}
             @defidform/inline[else]: @syn[block]@subscript{else}}

The DSSL2 conditional statement contains an @racket[if], 0 or more
@racket[elif]s, and optionally an @racket[else] for if none of the
conditions holds.

First it evaluates the @racket[if] condition @syn[expr]@subscript{if}.
If non-false, it then evaluates @syn[block]@subscript{if} and finishes.
Otherwise, it evaluates each @racket[elif] condition
@syn[expr]@subscript{i} in turn; if each is false, it goes on to the
next, but when one is non-false then it finishes with the corresponding
@syn[block]@subscript{i}. Otherwise, if all of the conditions were false
and the optional @syn[block]@subscript{else} is included, evaluates
that.

For example, we can have an @racket[if] with no @racket[elif] or
@racket[else] parts:

@dssl2block|{
if should_greet:
    greet()
}|

The function @code{greet()} will be called if variable
@code{should_greet} is true, and otherwise it will not.

Or we can have several @racket[elif] parts:

@dssl2block|{
def rebalance_left_(key, balance, left0, right):
    let left = left0.node
    if !left0.grew?:
        insert_result(node(key, balance, left, right), False)
    elif balance == 1:
        insert_result(node(key, 0, left, right), False)
    elif balance == 0:
        insert_result(node(key, -1, left, right), True)
    elif left.balance == -1:
        insert_result(node(left.key, 0, left.left,
                           node(key, 0, left,right, right)),
                      False)
    elif left.balance == 1:
        insert_result(node(left.right.key, 0,
                           node(left.key,
                                -1 if left.right.balance == 1 else 0,
                                left.left,
                                left.right.left),
                           node(key,
                                1 if left.right.balance == -1 else 0,
                                left.right.right,
                                right)),
                      False)
    else: error('Cannot happen')
}|

@defsmplform{@defidform/inline[let] @syn[var] = @syn[expr]}

Declares and defines a local variable. Local variables may be declared in any
scope and last for that scope. A local variable may be re-assigned with the
assignment form (@racket[=]), as in the third line here:

@dssl2block|{
def sum(vec):
    let result = 0
    for v in vec: result = result + v
    return result
}|

@defsmplform{@defidform/inline[let] @syn[var]}

Declares a local variable, which will be undefined until it is assigned:

@dssl2block|{
let x
if y:
    x = f()
else:
    x = g()
println(x)
}|

@defcmpdform{@defidform/inline[for] @syn[var] @q{in} @syn[expr]: @syn[block]}

Loops over the values of the given @syn[expr], evaluating the
@syn[block] for each. The @syn[expr] can evaluate to a vector, a string,
or a natural number. If a vector, then this form iterates over the
values (not the indices) of the vector; if a string, this iterates over
the characters as 1-character strings; if a natural number @racket[n]
then it counts from @racket[0] to @racket[n - 1].

@dssl2block|{
for person in people_to_greet:
    println("Hello, ~a!", person)
}|

In this example hash function producer, the @racket[for] loops over the
characters in a string:

@dssl2block|{
# make_sbox_hash : -> [String -> Natural]
# Returns a new n-bit string hash function.
def make_sbox_hash(n):
    let sbox = [ random_bits(n) for i in 256 ]
    def hash(input_string):
        let result = 0
        for c in input_string:
            let svalue = sbox[ord(c)]
            result = result ^ svalue
            result = (3 * result) % (2 ** n)
        return result
    hash
}|

@defcmpdform{@defidform/inline[for] @syn[var]₁, @syn[var]₂ @q{in} @syn[expr]: @syn[block]}

Loops over the indices and values of the given @syn[expr], evaluating
the @syn[block] for each. The @syn[expr] can evaluate to a vector, a
string, or a natural number. If a vector, then @syn[var]₁
takes on the indices of the vector while @syn[var]₂ takes on
the values; if a string, then @syn[var]₁ takes on the
indices of the characters while @syn[var]₂ takes on the
characters; if a natural number then both variables count together.

@dssl2block|{
for ix, person in people_to_greet:
    println("~a: Hello, ~a!", ix, person)
}|

@defsmplform{@defidform/inline[pass]}

Does nothing.

@dssl2block|{
# account_credit! : Number Account -> Void
# Adds the given amount to the given account’s balance.
def account_credit!(amount, account):
    pass
#   ^ FILL IN YOUR CODE HERE
}|

@defsmplform{@defidform/inline[return] @syn[expr]}

Returns the value of the given @syn[expr] from the inner-most function.
Note that this is often optional, since the last expression in a
function will be used as its return value.

That is, these are equivalent:

@dssl2block|{
def inc(x): x + 1
}|

@dssl2block|{
def inc(x): return x + 1
}|

In this function, the first @racket[return] is necessary because it breaks out
of the loop and exits the function; the second @racket[return] is optional and
could be omitted.

@dssl2block|{
# : BloomFilter String -> Boolean
def bloom_check?(b, s):
    for hash in b.hashes:
        let index = hash(s) % b.bv.size
        if !bv_ref(b.bv, index): return False
    return True
}|

@defsmplform{@defidform/inline[return]}

Returns void from the current function.

@defcmpdform{@defidform/inline[test] @syn[expr]: @syn[block]}

Runs the code in @syn[block] as a test case named @syn[expr]. If an
assertion fails or an error occurs in @syn[block], the test case
terminates, failure is reported, and the program continues after the
block.

For example:

@dssl2block|{
test "arithmetic":
    assert_eq 1 + 1, 2
    assert_eq 2 + 2, 4
}|

A @racket[test] block can be used to perform just one check or a long sequence
of preparation and checks:

@dssl2block|{
test 'single-chaining hash table':
    let h = sch_new_1(10)
    assert !sch_member?(h, 'hello')
    sch_insert!(h, 'hello', 5)
    assert sch_member?(h, 'hello')
    assert_eq sch_lookup(h, 'hello'), 5
    assert !sch_member?(h, 'goodbye')
    assert !sch_member?(h, 'helo')
    sch_insert!(h, 'helo', 4)
    assert_eq sch_lookup(h, 'hello'), 5
    assert_eq sch_lookup(h, 'helo'), 4
    assert !sch_member?(h, 'hel')
    sch_insert!(h, 'hello', 10)
    assert_eq sch_lookup(h, 'hello'), 10
    assert_eq sch_lookup(h, 'helo'), 4
    assert !sch_member?(h, 'hel')
    assert_eq sch_keys(h), cons('hello', cons('helo', nil()))
}|

@defcmpdform{@defidform/inline[time] @syn[expr]: @syn[block]}

Times the execution of the block, and then prints the results labeled
with the result of @syn[expr] (which isn’t timed).

For example, we can time how long it takes to create an array of
10,000,000 @racket[0]s:

@dssl2block|{
time '10,000,000 zeroes':
    [ 0; 10000000 ]
}|

The result is printed as follows:

@verbatim|{
1,000,000 zeroes: cpu: 45 real: 46 gc: 20
}|

This means it tooks 45 milliseconds of CPU time over 46 milliseconds of
wall clock time, with 20 ms of CPU time spent on garbage collection.

@defcmpdform{@defidform/inline[while] @syn[expr]: @syn[block]}

Iterates the @syn[block] while the @syn[expr] evaluates to non-false. For example:

@dssl2block|{
while !is_empty(queue):
    explore(dequeue(queue))
}|

Here's a hash table lookup function that uses @racket[while], which it breaks
out of using @racket[break]:

@dssl2block|{
def sch_lookup(hash, key):
    let bucket = sch_bucket_(hash, key)
    let result = False
    while cons?(bucket):
        if key == bucket.first.key:
            result = bucket.first.value
            break
        bucket = bucket.rest
    return result
}|

@subsection[#:tag "exp-forms"]{Expression Forms}

@defexpform{@syn[var]}

The value of a variable, which must be a function parameter, bound with
@racket[let], or defined with @racket[def]. For example,

@dssl2block|{
let x = 5
println(x)
}|

prints “@code{5}”.

Lexically, a variable is a letter or underscore, followed by zero or
more letters, underscores, or digits, optionally ending in a question
mark or exclamation point.

@defexpform{@syn[expr].@syn[fieldname]}

Expression @syn[expr] must evaluate to struct value that has field
@syn[fieldname]; then this expression evaluates to the value of that
field of the struct.

@defexpform{@syn[expr]₁[@syn[expr]₂]}

Expression @syn[expr]₁ must evaluate to a vector @code{v}; @syn[expr]₂
must evaluate to an integer @code{n} between 0 and @code{len(v) - 1}.
Then this returns the @code{n}th element of vector @code{v}.

@defexpform{@syn{number}}

Numeric literals include:

@itemlist[
  @item{Decimal integers: @racket[0], @racket[3], @racket[18446744073709551617]}
  @item{Hexadedecimal, octal, and binary integers: @q{0xFFFF00},
      @q{0o0177}, @q{0b011010010}}
  @item{Floating point: @racket[3.5], @q{6.02E23}, @racket[1e-12]}
]

@defexpform{@syn{string}}

String literals are delimited by either single or double quotes:

@dssl2block|{
def does_not_matter(double):
    if double:
        return "This is the same string."
    else:
        return 'This is the same string.'
}|

The contents of each kind of string is treated the same, except that
each kind of quotation mark can contain the other kind unescaped:

@dssl2block|{
def does_matter(double):
    if double:
        return "This isn't the same string."
    else:
        return '"This is not the same string" isn\'t the same string.'
}|

Strings cannot contain newlines directly, but can contain newline
characters via the escape code @code{\n}. Other escape codes include:

@itemlist[
  @item{@code{\a} for ASCII alert (also @code{\x07})}
  @item{@code{\b} for ASCII backspace (also @code{\x08})}
  @item{@code{\f} for ASCII formfeed (also @code{\x0C})}
  @item{@code{\n} for ASCII newline (also @code{\x0A})}
  @item{@code{\r} for ASCII carriage return (also @code{\x0D})}
  @item{@code{\t} for ASCII tab (also @\code{\x09})}
  @item{@code{\v} for ASCII vertical tab (also @\code{\x0B})}
  @item{@code{\x@syn{hh}} in hex, for example @code{\x0A} is newline}
  @item{@code{\@syn{ooo}} in octal, for example @code{\011} is tab}
  @item{A backslash immediately followed by a newline causes both characters to
      be ignored, which provides a way to wrap long strings across lines.}
]

Any other character following a backslash stands for itself.

@defexpform{@defidform/inline[True]}

The true Boolean value.

@defexpform{@defidform/inline[False]}

The false Boolean value, the only value that is not considered true.

@defexpform{@syn[expr]@subscript{0}(@syn[expr]₁, ..., @syn[expr]@subscript{k})}

Evaluates all the expressions; then applies the result of
@syn[expr]@subscript{0} with the results of the other expressions as
arguments.

For example,

@dssl2block|{
fact(5)
}|

calls the function @racket[fact] with argument @racket[5], and

@dssl2block|{
ack(5 + 1, 5 + 2)
}|

calls the function @racket[ack] with arguments @racket[6] and
@racket[7].

@defexpforms[
  @list{@defidform/inline[lambda] @syn[var]₁, ..., @syn[var]@subscript{k}: @syn[expr]}
  @list{@q{λ} @syn[var]₁, ..., @syn[var]@subscript{k}: @syn[expr]}
]

Creates an anonymous function with parameters @syn[var]₁, @code{...},
@syn[var]@subscript{k} and body @syn[expr]. For example, the function to
add twice its first argument to its second argument can be written

@dssl2block|{
lambda x, y: 2 * x + y
}|

@defexpform{@syn[expr]₁ @q{if} @syn[expr]₂ @q{else} @syn[expr]₃}

The ternary expression first evaluates the condition
@syn[expr]₂. If non-false,
evaluates @syn[expr]₁ for its value; otherwise,
evaluates @syn[expr]₃ for its value.

For example:

@dssl2block|{
def parent(link):
    link.parent if rbn?(link) else False
}|

@defexpform{@syn[structname] { @syn[field]₁ = @syn[expr]₁, ..., @syn[field]@subscript{k} = @syn[expr]@subscript{k} }}

Constructs a struct with the given name and the values of the given
expressions for its fields. The struct must have been declared with
those fields using @racket[defstruct].

If a variable with the same name as a field is in scope, omitting the
field value will use that variable:

@dssl2block|{
defstruct Foo(bar, baz)
let bar = 4
let baz = 5
assert_eq Foo { bar, baz = 9 }, Foo(4, 9)
}|

@defexpform{@defidform/inline[object] @syn[structname] { @syn[field]₁ = @syn[expr]₁, ..., @syn[field]@subscript{k} = @syn[expr]@subscript{k} }}

Creates a struct value without declaring the struct type with
@racket[defstruct]. In particular, creates a struct with the given name
@syn[structname] and the given fields and values, regardless of what
structs might be declared. The field names cannot have any repeats.

This is useful for one-off objects. For example, a simple 2-D point
object might be defined as:

@dssl2block|{
def Posn(x_, y_):
    def get_x(): x_
    def get_y(): y_
    def fmt(): format("(~a, ~a)", x_, y_)
    object Posn { get_x = get_x, get_y = get_y, fmt = fmt, }
}|

@defexpform{[ @syn[expr]@subscript{0}, ..., @syn[expr]@subscript{k - 1} ]}

Creates a new vector of length @code{k} whose values are the values
of the expressions.

For example:

@dssl2block|{
let vec = [ 1, 2, 3, 4, 5 ]
}|

@defexpform{[ @syn[expr]₁; @syn[expr]₂ ]}

Constructs a new vector whose length is the value of
@syn[expr]₂, filled with the value of @syn[expr]₁. That is,

@dssl2block|{
[ 0; 5 ]
}|

means the same thing as

@dssl2block|{
[ 0, 0, 0, 0, 0 ]
}|

@defexpforms[
  @list{[ @syn[expr]₁ @q{for} @syn[var] @q{in} @syn[expr]₂ ]}
  @list{[ @syn[expr]₁ @q{for} @syn[var]₁, @syn[var]₂ @q{in} @syn[expr]₂ ]}
]

Vector comprehensions: produces a vector of the values of @syn[expr]₁
while iterating the variable(s) over @syn[expr]₂. In particular,
@syn[expr]₂ must be a vector @code{v}, a string @code{s}, or a
natural number @code{n}; in which case the iterated-over values are
the elements of @code{v}, the 1-character strings comprising
@code{s}, or counting from 0 to @code{n - 1}, respectively. If one
variable @syn[var] is provided, it takes on those values. If two are
provided, then @syn[var]₂ takes on those values, while @syn[var]₁
takes on the indices counting from 0 upward.

For example,

@dssl2block|{
[ 10 * n for n in [ 5, 4, 3, 2, 1 ] ]
}|

evaluates to

@dssl2block|{
[ 50, 40, 30, 20, 10 ]
}|

And

@dssl2block|{
[ 10 * n + i for i, n in [ 5, 4, 3, 2, 1 ] ]
}|

evaluates to

@dssl2block|{
[ 50, 41, 32, 23, 14 ]
}|

@defexpforms[
  @list{[ @syn[expr]₁ @q{for} @syn[var] @q{in} @syn[expr]₂ @q{if} @syn[expr]₃ ]}
  @list{[ @syn[expr]₁ @q{for} @syn[var]₁, @syn[var]₂ @q{in} @syn[expr]₂ @q{if} @syn[expr]₃ ]}
]

If the optional @syn[expr]₃ is provided, only elements for which
@syn[expr]₃ is non-false are included. That is, the variable(s) take on
each of their values, then @syn[expr]₃ is evaluated in the scope of the
variable(s). If it's non-false then @syn[expr]₁ is evaluated and
included in the resulting vector.

For example,

@dssl2block|{
[ 10 * n for n in [ 5, 4, 3, 2, 1 ] if odd?(n) ]
}|

evaluates to

@dssl2block|{
[ 50, 30, 10 ]
}|

@subsubsection{Operators}

Operators are described in order from tighest to loosest precedence.

@defexpform{@syn[expr]₁ @defidform/inline[**] @syn[expr]₂}

Raises the value of @syn[expr]₁ to the power of the value of
@syn[expr]₂, both of which must be numbers.

The @racket[**] operator is right-associative.

@defexpforms[
  @list{@defidform/inline[!]@syn[expr]}
  @list{@defidform/inline[~]@syn[expr]}
  @list{-@syn[expr]}
  @list{+@syn[expr]}
]

Logical negation, bitwise negation, numerical negation, and numerical identity.

@code{!}@syn[expr] evaluates @syn[expr], then returns @racket[True] if
the result was @racket[False], and @racket[False] for any other result.

@code{~}@syn[expr], @code{-}@syn[expr], and @code{+}@syn[expr] require
that @syn[expr] evaluate to a number. Then @code{~} flips every bit,
@code{-} negates it, and @code{+} returns it unchanged.

@defexpforms[
  @list{@syn[expr]₁ @defidform/inline[*] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[/] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[%] @syn[expr]₂}
]

Multiplies, divides, or modulos the values of the expressions, respectively.

@defexpforms[
  @list{@syn[expr]₁ @defidform/inline[+] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[-] @syn[expr]₂}
]

Addition and subtraction.

@defexpforms[
  @list{@syn[expr]₁ @defidform/inline[<<] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[>>] @syn[expr]₂}
]

Left and right bitwise shift.

@defexpform{@syn[expr]₁ @defidform/inline[&] @syn[expr]₂}

Bitwise and.

@defexpform{@syn[expr]₁ @defidform/inline[^] @syn[expr]₂}

Bitwise xor.

@defexpform{@syn[expr]₁ @defidform/inline[\|] @syn[expr]₂}

Bitwise or. (Not written with the backslash.)

@defexpforms[
  @list{@syn[expr]₁ @defidform/inline[==] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[!=] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[===] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[!==] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[<] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[<=] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[>] @syn[expr]₂}
  @list{@syn[expr]₁ @defidform/inline[>=] @syn[expr]₂}
]

Operator @racket[==] is structural equality, and @racket[!=] is its
negation. Operator @racket[===] is physical equality, and @racket[!==]
is its negation. To understand the difference, suppose that we create
two different vectors with the same contents. Those vectors are
structurally equal but not physically equal.

Operators @racket[<], @racket[<=], @racket[>], and @racket[>=] are the
standard inequalities for numbers, and compare pairs of strings in
lexicographic order.

@defexpform{@syn[expr]₁ @defidform/inline[and] @syn[expr]₂}

Short-circuiting logical and. First evaluates @syn[expr]₁; if the result
is @racket[False] then the whole conjunction is @racket[False];
otherwise, the result of the conjunction is the result of @syn[expr]₂.

@defexpform{@syn[expr]₁ @defidform/inline[or] @syn[expr]₂}

Short-circuiting logical or. First evaluates @syn[expr]₁; if the result
is non-false then the whole disjunction has that result; otherwise the
result of the conjunction is the result of @syn[expr]₂.

@section{Built-in functions and values}

@subsection{Type predicates}

@defprocform[proc?]{(Any) -> Boolean}

Determines whether its argument is a procedure (function).

@defprocform[str?]{(Any) -> Boolean}

Determines whether its argument is a string.

@defprocform[num?]{(Any) -> Boolean}

Determines whether its argument is a number.

@defprocform[int?]{(Any) -> Boolean}

Determines whether its argument is an integer.

@defprocform[float?]{(Any) -> Boolean}

Determines whether its argument is a floating-point number.

@defprocform[vec?]{(Any) -> Boolean}

Determines whether its argument is a vector.

@defprocform[bool?]{(Any) -> Boolean}

Determines whether its argument is a Boolean.

@subsection{Numeric operations}

@defprocform[floor]{(Number) -> Integer}

Rounds a number down to the largest integer that is no greater.

@defprocform[ceiling]{(Number) -> Integer}

Rounds a number up to the smallest integer that is no less.

@defprocforms[
    [int @list{(Number) -> Integer}]
    [int @list{(String) -> Integer}]
    [int @list{(Boolean) -> Integer}]
]

Returns the integer part of a number, by truncation. That is, the
decimal point and everything after it is removed. If given a string,
attempt to convert to a number before truncating, throwing an error if
the conversion fails. Booleans @racket[True] and @racket[False] convert
to @racket[1] and @racket[0], respectively.

@defprocforms[
  [float @list{(Number) -> Floating}]
  [float @list{(String) -> Floating}]
  [float @list{(Boolean) -> Floating}]
]

Converts an exact (integral or rational) number to the nearest
double-precision floating point value. If given a string, attempt to
convert to a number, throwing an error if the conversion fails. Booleans
@racket[True] and @racket[False] convert to @racket[1.0] and @racket[0.0],
respectively.

@defprocforms[
  [random @list{() -> Floating}]
  [random @list{(IntegerIn<1, 4294967087>) -> Natural}]
  [random @list{(Integer, IntegerIn<1, 4294967087>) -> Natural}]
]

When called with zero arguments, returns a random floating point number
in the open interval (@racket[0.0], @racket[1.0]).

When called with one argument @racket[limit], returns a random exact
integer from the closed interval [@racket[0], @racket[limit - 1]].

When called with two arguments @racket[min] and @racket[max], returns a
random exact integer from the closed interval [@racket[min], @racket[max - 1]].
The difference between the arguments can be no greater than
@racket[4294967087].

@defprocform[max]{(Number, Number, ...) -> Number}

Returns the largest of the given numbers.

@defprocform[min]{(Number, Number, ...) -> Number}

Returns the smallest of the given numbers.

@defprocform[quotient]{(Natural, Natural) -> Natural}

Returns the truncated quotient.

@defconstform[RAND_MAX]{Natural}

Defined to be @racket[4294967087], the largest parameter (or span) that
can be passed to @racket[random].

@defprocform[random_bits]{(Natural) -> Natural}

Returns a number consisting of the requested number of random bits.

@defprocform[remainder]{(Natural, Natural) -> Natural}

Returns the remainder of the truncated @racket[quotient].

@defprocform[sqrt]{(Number) -> Floating}

Computes the square root of a number.

@subsubsection{Predicates}

@defprocform[zero?]{(Number) -> Boolean}

Determines whether its argument is zero.

@defprocform[positive?]{(Number) -> Boolean}

Determines whether its argument is greater than zero.

@defprocform[negative?]{(Number) -> Boolean}

Determines whether its argument is less than zero.

@defprocform[even?]{(Integer) -> Boolean}

Determines whether its argument is an even integer.

@defprocform[odd?]{(Integer) -> Boolean}

Determines whether its argument is an odd integer.

@subsection{String operations}

@defprocform[chr]{(Natural) -> String}

Converts the code point of a character to the character that it
represents, as a one-character string. Inverse to @racket[ord].

@dssl2block|{
assert_eq chr(97), 'a'
}|

@defprocform[explode]{(String) -> Vector<String>}

Breaks a string into a vector of 1-character strings.

@defprocform[format]{(String, Any, ...) -> String}

Using its first argument as a template, interpolates the remaining
arguments, producing a string. The main recognized escape codes are
@code{~a} and @code{~s}. Both can be used to include any kind of data,
the difference being that @code{~s} quotes and escapes strings, whereas
@code{~a} includes them literally.

Additionally, @code{~n} can be used to insert a newline, and @code{~~}
inserts a literal @code{~}.

@defprocform[implode]{(Vector<String>) -> String}

Concatenates a vector of strings into a single string.

@defprocform[ord]{(String) -> Natural}

Converts a character, represented as a one-character string, to its
code point. Inverse to @racket[chr].

@dssl2block|{
assert_eq ord('a'), 97
}|

@defprocform[strlen]{(String) -> Natural}

Returns the length of a string in characters.

@subsection{Vector operations}

@defprocform[build_vector]{(n: Natural, f: (Natural) -> X) -> Vector<X>}

Creates a vector of size @code{n} whose elements are @code{f(0)},
@code{f(1)}, ..., @code{f(n - 1)}. Equivalent to

@dssl2block|{
[ f(x) for x in n ]
}|

@defprocform[filter]{(pred: (X) -> Boolean, vec: Vector<X>) -> Vector<X>}

Returns a vector containing the elements of @code{vec} for which
@code{pred} returns non-false. Equivalent to

@dssl2block|{
[ x for x in vec if pred(x) ]
}|

@defprocform[len]{(Vector<X>) -> Natural}

Returns the length of a vector.

@defprocform[map]{(f: (X) -> Y, vec: Vector<X>) -> Vector<Y>}

Returns a vector consisting of @code{f} applied to each element of
@code{vec}. Equivalent to

@dssl2block|{
[ f(x) for x in vec ]
}|

@subsection{I/O Functions}

@defprocform[print]{(String, Any, ...) -> Void}

The first argument is treated as a format string into which the
remaining arguments are interpolated, à la @racket[format]. Then the
result is printed.

@defprocform[println]{(String, Any, ...) -> Void}

Like @code{print}, but adds a newline at the end.

@subsection{Other functions}

@defprocform[identity]{(X) -> X}

The identity function, which just returns its argument.
