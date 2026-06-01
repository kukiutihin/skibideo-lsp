module Analysis = struct
  type skibob = { line : int; character : int } [@@deriving yojson]

  type range = { start : skibob; end_ : skibob [@key "end"] }
  [@@deriving yojson]

  type analysis_error = { message : string; range : range; severity : int }
  [@@deriving yojson]

  let skibob_of_pos (p : Lexing.position) =
    {
      line = max 0 (p.pos_lnum - 1);
      character = max 0 (p.pos_cnum - p.pos_bol);
    }

  let eof_range text =
    let lines = String.split_on_char '\n' text in
    let last_line = max 0 (List.length lines - 1) in
    let last_len =
      match List.nth_opt lines last_line with
      | Some l -> String.length l
      | None -> 0
    in
    let pos = { line = last_line; character = last_len } in
    { start = pos; end_ = pos }

  let range_of_ast text (r : Ast.Ast.range) =
    match r with
    | Ast.Ast.Known (ps, pe) ->
        { start = skibob_of_pos ps; end_ = skibob_of_pos pe }
    | Ast.Ast.Eof -> eof_range text
    | Ast.Ast.Unknown ->
        let pos = { line = 0; character = 0 } in
        { start = pos; end_ = pos }

  let error_of_parser text (e : ParserErrors.ParserErrors.t) =
    { message = e.message; range = range_of_ast text e.position; severity = 1 }

  let get_syntax_diagnostic text : (analysis_error list, string) result =
    let _program, errors = ErrRecParser.ErrRecParser.program_of_string text in
    Ok (List.map (error_of_parser text) errors)
end
