import { EditorState, EditorView, basicSetup } from "@codemirror/basic-setup";
import { javascript } from "@codemirror/lang-javascript";

let ligoEditor = new EditorView({
  state: EditorState.create({
    extensions: [basicSetup, javascript()],
    doc: `
type storage = int
type parameter =
  Increment of int
| Decrement of int
| Reset
type return = operation list * storage
// Two entrypoints
let add (store, delta : storage * int) : storage = store + delta
let sub (store, delta : storage * int) : storage = store - delta
(* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. *)
let main (action, store : parameter * storage) : return =
 ([] : operation list),    // No operations
 (match action with
   Increment (n) -> add (store, n)
 | Decrement (n) -> sub (store, n)
 | Reset         -> 0)
`,
  }),
  parent: document.getElementById("ligo"),
});

let michelsonEditor = new EditorView({
  state: EditorState.create({
    extensions: [basicSetup, javascript()],
    doc: `
`,
  }),
  parent: document.getElementById("michelson"),
});

document.getElementById("compile").addEventListener("click", function () {
  let michelson = compile.main(ligoEditor.state.doc.toJSON().join("\n"));
  console.log(michelson);
  michelsonEditor.setState(
    EditorState.create({
      extensions: [basicSetup],
      doc: michelson,
    })
  );
  // console.log(compile.main());
});
