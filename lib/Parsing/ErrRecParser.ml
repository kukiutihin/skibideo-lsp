open Lexemes.Lexemes
open Ast.Ast
open ParserErrors

module ErrRecParser = struct
  open Parser.Parser

  let max_errors = 100

  let is_decl_start = function
    | Let | Type | TypeAlias | Module -> true
    | _ -> false

  let is_sync = function End -> true | t -> is_decl_start t

  let range_of_input : input -> range = function
    | (_, ps, pe) :: _ -> Known (ps, pe)
    | [] -> Eof

  let mk_error message position : ParserErrors.t = { message; position }

  let rec sync (input : input) : input =
    match input with
    | [] -> []
    | _ :: rest -> (
        match rest with
        | (tok, _, _) :: _ when is_sync tok -> rest
        | [] -> []
        | _ -> sync rest)

  let module_header : string parser =
    let* _ = token Module in
    let* name, _ = must parse_big_id "Module must have a name (capitalized)" in
    let* _ = must_token (Operator "=") in
    let* _ = must_token Struct in
    return name

  let error_of_result input = function
    | Failed (m, p) | HardFailed (m, p) -> (m, p)
    | Parsed _ -> ("Could not parse declaration", range_of_input input)

  let rec recover_block ~in_module (input : input) :
      program * ParserErrors.t list * input =
    match input with
    | [] ->
        let errs =
          if in_module then
            [ mk_error "Unexpected end of file: expected 'end'" Eof ]
          else []
        in
        ([], errs, [])
    | (End, _, _) :: rest when in_module -> ([], [], rest)
    | (End, ps, pe) :: rest ->
        let err = mk_error "Unexpected 'end'" (Known (ps, pe)) in
        let decls, errs, rest' = recover_block ~in_module rest in
        (decls, err :: errs, rest')
    | (Module, _, _) :: _ -> (
        match module_header input with
        | Parsed (name, rest) ->
            let body, body_errs, rest2 = recover_block ~in_module:true rest in
            let mdecl = ModuleDecl { name; decls = body } in
            let decls, errs, rest3 = recover_block ~in_module rest2 in
            (mdecl :: decls, body_errs @ errs, rest3)
        | other ->
            let m, p = error_of_result input other in
            let rest = sync input in
            let decls, errs, rest2 = recover_block ~in_module rest in
            (decls, mk_error m p :: errs, rest2))
    | (tok, _, _) :: _ when is_decl_start tok -> (
        match parse_decl input with
        | Parsed (decl, rest) when rest != input ->
            let decls, errs, rest2 = recover_block ~in_module rest in
            (decl :: decls, errs, rest2)
        | other ->
            let m, p = error_of_result input other in
            let rest = sync input in
            let decls, errs, rest2 = recover_block ~in_module rest in
            (decls, mk_error m p :: errs, rest2))
    | _ ->
        let err = mk_error "Expected a declaration" (range_of_input input) in
        let rest = sync input in
        let decls, errs, rest2 = recover_block ~in_module rest in
        (decls, err :: errs, rest2)

  let dedup (errors : ParserErrors.t list) : ParserErrors.t list =
    let rec go prev = function
      | [] -> []
      | (e : ParserErrors.t) :: rest ->
          let same =
            match prev with
            | Some (p : ParserErrors.t) ->
                p.message = e.message && p.position = e.position
            | None -> false
          in
          if same then go prev rest else e :: go (Some e) rest
    in
    let rec take n = function
      | [] -> []
      | _ when n <= 0 -> []
      | x :: xs -> x :: take (n - 1) xs
    in
    take max_errors (go None errors)

  let parse_program_rec (input : input) : program * ParserErrors.t list =
    let decls, errors, _ = recover_block ~in_module:false input in
    (decls, dedup errors)

  let program_of_string (s : string) : program * ParserErrors.t list =
    match Lexer.Lexer.lex_string s with
    | Result.Error message -> ([], [ mk_error message Unknown ])
    | Result.Ok tokens -> parse_program_rec tokens

  let errors_of_string (s : string) : ParserErrors.t list =
    program_of_string s |> snd
end
