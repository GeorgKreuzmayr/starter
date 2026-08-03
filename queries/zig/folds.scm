; Fold function bodies, control-flow blocks, and container (struct/enum/union) bodies.
; Deliberately narrower than nvim-treesitter's own zig folds.scm, which also folds
; parameters, call expressions and every if/while/for -- replaces it (no `;; extends`).
[
  (block)
  (block_expression)
  (switch_expression)
  (initializer_list)
  (struct_declaration)
  (enum_declaration)
  (union_declaration)
  (opaque_declaration)
  (error_set_declaration)
] @fold
