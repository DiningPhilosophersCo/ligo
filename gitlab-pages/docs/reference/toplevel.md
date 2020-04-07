---
id: toplevel
title: Toplevel
description: Available functions at the top level
hide_table_of_contents: true
---

import Syntax from '@theme/Syntax';
import SyntaxTitle from '@theme/SyntaxTitle';

These functions are available without any needed prefix.

<SyntaxTitle syntax="pascaligo">
function is_nat: int -> option(nat)
</SyntaxTitle>
<SyntaxTitle syntax="cameligo">
val is_nat: int -> nat option
</SyntaxTitle>
<SyntaxTitle syntax="reasonligo">
let is_nat: int => option(nat)
</SyntaxTitle>

Convert an `int` to a `nat` if possible.

<SyntaxTitle syntax="pascaligo">
function abs: int -> nat
</SyntaxTitle>
<SyntaxTitle syntax="cameligo">
val abs: int -> nat
</SyntaxTitle>
<SyntaxTitle syntax="reasonligo">
let abs: int => nat
</SyntaxTitle>

Cast an `int` to `nat`.

<SyntaxTitle syntax="pascaligo">
function int: nat -> int
</SyntaxTitle>
<SyntaxTitle syntax="cameligo">
val int: nat -> int
</SyntaxTitle>
<SyntaxTitle syntax="reasonligo">
let int: nat => int
</SyntaxTitle>

Cast an `nat` to `int`.

<SyntaxTitle syntax="pascaligo">
const unit: unit
</SyntaxTitle>
<SyntaxTitle syntax="cameligo">
val unit: unit
</SyntaxTitle>
<SyntaxTitle syntax="reasonligo">
let (): unit
</SyntaxTitle>

A helper to create a unit.

<SyntaxTitle syntax="pascaligo">
function failwith : string -> unit
</SyntaxTitle>
<SyntaxTitle syntax="cameligo">
val failwith : string -> unit
</SyntaxTitle>
<SyntaxTitle syntax="reasonligo">
let failwith: string => unit
</SyntaxTitle>

Cause the contract to fail with an error message.

> ⚠ Using this currently requires in general a type annotation on the
> `failwith` call.

<SyntaxTitle syntax="pascaligo">
function assert : bool -> unit
</SyntaxTitle>
<SyntaxTitle syntax="cameligo">
val assert : bool -> unit
</SyntaxTitle>
<SyntaxTitle syntax="reasonligo">
let assert: bool => unit
</SyntaxTitle>

Check if a certain condition has been met. If not the contract will fail.

<SyntaxTitle syntax="pascaligo">
function ediv : int -> int -> option (int * nat)
</SyntaxTitle>
<SyntaxTitle syntax="pascaligo">
function ediv : mutez -> nat -> option (mutez * mutez)
</SyntaxTitle>
<SyntaxTitle syntax="pascaligo">
function ediv : mutez -> mutez -> option (mutez * nat)
</SyntaxTitle>
<SyntaxTitle syntax="pascaligo">
function ediv : nat -> nat -> option (nat * nat)
</SyntaxTitle>

<SyntaxTitle syntax="cameligo">
val ediv : int -> int -> (int * nat) option
</SyntaxTitle>
<SyntaxTitle syntax="cameligo">
val ediv : mutez -> nat -> (mutez * mutez) option 
</SyntaxTitle>
<SyntaxTitle syntax="cameligo">
val ediv : mutez -> mutez -> (mutez * nat) option
</SyntaxTitle>
<SyntaxTitle syntax="cameligo">
val ediv : nat -> nat -> (nat * nat) option
</SyntaxTitle>

<SyntaxTitle syntax="reasonligo">
let ediv: (int, int) => option((int, nat))
</SyntaxTitle>
<SyntaxTitle syntax="reasonligo">
let ediv: (mutez, nat) => option((mutez, mutez))
</SyntaxTitle>
<SyntaxTitle syntax="reasonligo">
let ediv: (mutez, mutez) => option((mutez, nat))
</SyntaxTitle>
<SyntaxTitle syntax="reasonligo">
let ediv: (nat, nat) => option((nat, nat))
</SyntaxTitle>

Perform one operation to get both the quotient and remainder of a division.
