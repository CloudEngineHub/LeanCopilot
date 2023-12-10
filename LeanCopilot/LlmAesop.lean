import LeanCopilot.Tactics
import LeanCopilot.Options
import Std.Data.String.Basic
import Aesop

set_option autoImplicit false

open Lean Meta Elab Term Tactic

namespace LeanCopilot


def tacGen : Aesop.TacGen := fun (mvarId : MVarId) => do
  let state ← ppTacticState [mvarId]
  let nm ← SuggestTactics.getGeneratorName
  let model ← getGenerator nm
  let suggestions ← generate model state ""
  -- A temporary workaround to prevent the tactic from using the current theorem.
  -- TODO: Use a more pincipled way, e.g., see Lean4Repl.lean in LeanDojo.
  -- println! s!"theorem name: {decl_name%}"
  let theoremName := match (← getDeclName?).get! |>.toString with
    | "_example" => ""
    | n => (n.splitOn ".").getLast!
  -- println! s!"theorem name: {theoremName}"
  let theoremNameMatcher := String.Matcher.ofString theoremName
  let filteredSuggestions := suggestions.filterMap fun ((t, s) : String × Float) =>
    let isAesop := t == "aesop"
    let isSelfReference := ¬ (theoremName == "") ∧ (theoremNameMatcher.find? t |>.isSome)
    if isSelfReference ∨ isAesop then none else some (t, s)
  return filteredSuggestions


macro "#configure_llm_aesop" : command => `(@[aesop 100%] def tacGen := LeanCopilot.tacGen)


macro "search_proof" : tactic => `(tactic| aesop? (add 100% tacGen))


end LeanCopilot
