open Cli_expect

let bad_test s = (bad_test "")^"/deep_pattern_matching/"^s
let good_test s = (test "")^"/deep_pattern_matching/"^s

(* Negatives *)

(* Trying to match on values *)
let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail10.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail10.ligo", line 5, characters 9-10:
      4 |   case x of [
      5 |   | One (1) -> 2
      6 |   | Two -> 1

    Invalid case pattern.
    Can't match on values. |}]

(* unbound variable *)

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail9.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail9.ligo", line 6, characters 11-12:
      5 |   | One (a) -> 2
      6 |   | Two -> a
      7 |   ]

    Variable "a" not found. |}]

(* wrong patterns type *)
let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail1.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail1.ligo", line 6, characters 11-30:
      5 |   case x of [
      6 |   | (Nil , record [a ; b ; c ]) -> 1
      7 |   | (xs  , Nil) -> 2

    Pattern not of the expected type myt |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail2.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail2.ligo", line 5, characters 11-18:
      4 |   case x of [
      5 |   | (Nil , (a,b,c)) -> 1
      6 |   | (xs  , Nil) -> 2

    Pattern not of the expected type myt |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail5.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail5.ligo", line 5, characters 4-17:
      4 |   case x of [
      5 |   | Some_fake (x) -> x
      6 |   | None_fake -> 1

    Pattern not of the expected type option (int) |}]

(* wrong body type *)

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail7.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail7.ligo", line 6, characters 9-10:
      5 |   | A -> "hey"
      6 |   | B -> 2
      7 |   ]

    Invalid type(s).
    Expected: "string", but got: "int". |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail8.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail8.ligo", line 23, characters 24-33:
     22 |           } with f (b+1)
     23 |         | Cons (a,b) -> "invalid"
     24 |         ] ;

    Invalid type(s).
    Expected: "int", but got: "string". |}]


(* rendundancy detected while compiling the pattern matching *)
let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail3.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail3.ligo", line 4, character 2 to line 7, character 3:
      3 | function t (const x: myt * ( int * int * int)) is
      4 |   case x of [
      5 |   | (xs , (a,b,c)) -> 1
      6 |   | (xs , (c,b,a)) -> 2
      7 |   ]

    Redundant pattern matching |}]

(* anomaly detected in the pattern matching self_ast_typed pass *)

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail11.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail11.ligo", line 2, character 2 to line 5, character 3:
      1 | function t (const x : list(int)) is
      2 |   case x of [
      3 |   | hd#(hd2#tl) -> hd + hd2
      4 |   | nil -> 0
      5 |   ]

    Pattern matching anomaly (redundant, or non exhaustive). |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail12.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail12.ligo", line 4, character 2 to line 7, character 3:
      3 | function t (const x:recordi) is
      4 |   case x of [
      5 |   | record [ a = Some (nil) ; b = (hd#tl) ] -> hd
      6 |   | record [ a = Some ((hd#tl)) ; b = nil ] -> hd
      7 |   ]

    Pattern matching anomaly (redundant, or non exhaustive). |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail4.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail4.ligo", line 4, character 2 to line 7, character 3:
      3 | function t (const x: myt * myt) is
      4 |   case x of [
      5 |   | (Nil , ys)  -> 1
      6 |   | (xs  , Nil) -> 2
      7 |   ]

    Pattern matching anomaly (redundant, or non exhaustive). |}]

let%expect_test _ =
  run_ligo_bad [ "print" ; "ast-typed" ; (bad_test "pm_fail13.ligo") ] ;
  [%expect{|
    File "../../test/contracts/negative//deep_pattern_matching/pm_fail13.ligo", line 10, characters 8-17:
      9 |         Increment (n) -> s + 1
     10 |       | Decrement -> s - 1
     11 |     ]

    Variant pattern argument is expected of type nat but is of type unit. |}]

(* Positives *)

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t1 (Nil,Nil)" ; "--init-file";(good_test "pm_test.ligo") ] ;
  [%expect{|
    1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t1 (Nil,Cons(1,2))" ; "--init-file";(good_test "pm_test.ligo") ] ;
  [%expect{|
    1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t1 (Cons(1,2),Nil)" ; "--init-file";(good_test "pm_test.ligo") ] ;
  [%expect{|
    2 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t1 (Cons(1,2),Cons(3,4))" ; "--init-file";(good_test "pm_test.ligo") ] ;
  [%expect{|
    10 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2 (Nil, Nil)" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2 (Nil, (Cons (1,2)))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2 (Cons(1,2) , Cons(1,2))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 6 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2 (Cons(1,2) , Nil)" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 7 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t3 (One (Nil))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{|
    1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t3 (One (Cons(1,2)))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{|
    3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t3 (Two (record [a = 1 ; b = 2n ; c = \"tri\"]))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 6 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t2_3 (Cons(1,2) , Nil, (One(Nil)))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 8 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t4 (One(Nil) , One (Nil))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t4 (One(Nil) , Two (record [a=1;b=2n;c=\"tri\"]))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 2 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t4 (One(Cons(1,2)) , Two (record [ a=1;b=2n;c=\"tri\"]))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t4 (Two (record [a=0;b=0n;c=\"\"]) , Two (record [ a=1;b=2n;c=\"tri\"]))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 4 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t5 (1)" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t6 (42)" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 2 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t7 (Some (10))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 10 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t7 ((None: option(int)))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t8 (Some (1,2), 2)" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t8 ( (None: option(int * int)), 2)" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 2 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t9 ((None:option(int)) , (None: option(int)))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t9 ((None: option(int)) , Some (1))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t9 (Some (1) , (None: option(int)))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 2 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t9 (Some (1) , Some (2))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t10 (Consi ((None:  option(int))) ,  Consi(Some (100)) )" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t11 (Consi ((None: option(int))) , Consi (Some (100)))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 4 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t12 ((nil: list(int)))" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 0 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t12 (list [1])" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t12 (list [1;2])" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t12 (list [1;2;3])" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 6 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret"  ; "t12 (list [1;2;3;4])" ; "--init-file" ; (good_test "pm_test.ligo")] ;
  [%expect{| -1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t13 (none_a , some_a)" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| -1 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t13 (some_a , a_empty_b_not)" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 111 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t13 (some_a,  b_empty_a_not)" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{| 222 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "t13 (some_a, some_a)" ; "--init-file";(good_test "pm_test.ligo") ] ;
  [%expect{| 4 |}]

let%expect_test _ =
  run_ligo_good [ "print" ; "ast-core" ; (good_test "list_pattern.ligo") ] ;
  [%expect{|
    const a =
       match CONS(1 , LIST_EMPTY()) with
        | [  ] -> 1
        | a :: b :: c :: [  ] -> 2
        | _#2 -> 3 |}]

let%expect_test _ =
  run_ligo_good [ "run" ; "interpret" ; "nested_record_pm (record [ a = 1 ; b = E ])" ; "--init-file" ; (good_test "pm_test.ligo") ] ;
  [%expect{|
    5 |}]

let%expect_test _ =
  run_ligo_good [ "info" ; "measure-contract" ; (good_test "nested_record_sum.ligo") ] ;
  [%expect{|
    142 bytes |}]