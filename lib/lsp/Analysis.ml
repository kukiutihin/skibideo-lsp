module Analysis = struct
  type skibob = { line : int; character : int } [@@deriving yojson]

  type range = { start : skibob; end_ : skibob [@key "end"] }
  [@@deriving yojson]

  type analysis_error = { message : string; range : range; severity : int }
  [@@deriving yojson]

  let get_syntax_diagnostic text =
    Ok
      {
        message = "skibidi keks";
        range =
          {
            start = { line = 0; character = 1 };
            end_ = { line = 0; character = 11 };
          };
        severity = 1;
      }
end
