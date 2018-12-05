Exprolog
=========

Exprolog is a logic programming language(DSL) like Prolog
built on top of Elixir.

Build
------

Exprlog is no dependency.

    % mix 

Using on iex
------------

You must 'use Exprlog' on iex.

Example:

    $ iex -S mix
    Eshell V8.0  (abort with ^G)
    Interactive Elixir (1.4.0-dev) - press Ctrl+C to exit (type h() ENTER for help)
    iex(1)> use Exprolog
    Cps
    iex(2)> defrule append([], c, c) ## define append/3 base rule
    true
    iex(3)> defrule append([a|as], b, [a|cs]) do  ## define append/3 recursive rule
    ...(3)> append(as, b, cs)
    ...(3)> end
    end
    true
    iex(4)> Exprolog.interprete(append([1,2,3], [4,5], a)) ## eval append/3
    [status: true, query: {:append, [], [[1, 2, 3], [4, 5], {:_var, "a"}]},
     answer: [{"a", [1, 2, 3, 4, 5]}],    ## answer a is [1,2,3,4,5]
     goal: {:append, [], [[1, 2, 3], [4, 5], [1, 2, 3, 4, 5]]}]
    iex(5)> fail()
    fail()
    nil
    iex(6)> Exprolog.interprete(append(a, b, [1,2,3])) ## combination a,b ?
    [status: true, query: {:append, [], [{:_var, "a"}, {:_var, "b"}, [1, 2, 3]]},
     answer: [{"a", []}, {"b", [1, 2, 3]}], # a: [], b: [1,2,3]
     goal: {:append, [], [[], [1, 2, 3], [1, 2, 3]]}]
    iex(7)> fail() ## more ?
    fail()
    [status: true, query: {:append, [], [{:_var, "a"}, {:_var, "b"}, [1, 2, 3]]},
     answer: [{"a", [1]}, {"b", [2, 3]}], # a: [1], b: [2,3]
     goal: {:append, [], [[1], [2, 3], [1, 2, 3]]}]
    iex(8)> fail()  ## more ?
    fail()
    [status: true, query: {:append, [], [{:_var, "a"}, {:_var, "b"}, [1, 2, 3]]},
     answer: [{"a", [1, 2]}, {"b", [3]}], # a: [1,2], b: [3]
     goal: {:append, [], [[1, 2], [3], [1, 2, 3]]}]
    iex(9)> fail() ## more ?
    fail()
    [status: true, query: {:append, [], [{:_var, "a"}, {:_var, "b"}, [1, 2, 3]]},
     answer: [{"a", [1, 2, 3]}, {"b", []}], # a: [1,2,3], b: []
     goal: {:append, [], [[1, 2, 3], [], [1, 2, 3]]}]
    iex(10)> fail() ## more ?
    nil
    iex(11)> Exprolog.interprete(append(a, b, c), [{"a", [1,2]}, {"b", [3]}])
    [status: true, query: {:append, [], [[1, 2], [3], {:_var, "c"}]},
     answer: [{"c", [1, 2, 3]}], goal: {:append, [], [[1, 2], [3], [1, 2, 3]]}]
    iex(12)> 
    
Introduction
-------------

## What is Exprolog?

Prolog is a logic programming language based on first-order predicate
logic.  Exprolog is a domain specific language for logic programming
built top of Elixir.

## Logic programming language?

first-order predicate logic is completeness, and noncontradiction.


References
-----------

## Syntax

    RULE:: FACT | RULE
    
    FACT::  'deffact' PREDICATE '(' ARGS ')'
    
    RULE::  'defrule' PREDICATE '(' ARGS ')' |
            'defrule' PREDICATE '(' ARGS ')' 'do'
              EXPS
            'end'
    
    EXP:: PREDICATE(ARGS) 
          | 'cut' '(' ')' 
          | 'fail' '(' ')' 
          | TERM '=' Arbitary-Elixir-Expression 
    
    EXPS:: ':elixir' | EXPRESSIONS 
    
    EXPRESSIONS:: EXP 
          | EXP NL EXPRESSIONS
    
    PREDICATE:: Atom
    
    ARGS:: 
       | TERM 
       | ARG, ARGS
    
    TERM:: Atom | Number |List | Tuple | Var | EXP
    NL:: '\n'

## Builtin

    atom/1 
    integer/1
    float/1
    atomic/1
    compound/1
    var/1
    true/0

## Pure Prolog

    0
    s(0)
    plus/3
    natural_number/1
    times/3

## Core Library

    append/3
    member/2
    sort/2
    select/3
    permutation/2
    partition/4
    append_dl/3

