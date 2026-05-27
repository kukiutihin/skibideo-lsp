module Rpc = struct
  let ( let* ) = Result.bind

  type base_message = {
    method_ : string; [@key "method"]
    id : int option; [@default None]
  }
  [@@deriving yojson { strict = false }]

  let parse_json (content : string) : (Yojson.Safe.t, string) result =
    try Ok (Yojson.Safe.from_string content)
    with Yojson.Json_error msg -> Error ("Invalid JSON: " ^ msg)

  let encode (msg : Yojson.Safe.t) : (string, string) result =
    try
      let json = Yojson.Safe.to_string msg in
      let payload =
        Printf.sprintf "Content-Length: %d\r\n\r\n%s" (String.length json) json
      in
      Ok payload
    with e -> Error (Printexc.to_string e)

  let parse_content_length header =
    let prefix = "Content-Length: " in
    if not (String.starts_with ~prefix header) then
      Error "incorrect Content-Length header"
    else
      let len_str =
        String.sub header (String.length prefix)
          (String.length header - String.length prefix)
        |> String.trim
      in
      match int_of_string_opt len_str with
      | None -> Error "incorrect Content-Length header"
      | Some n -> Ok n

  let find_sep s =
    let len = String.length s in
    let rec go i =
      if i + 3 >= len then None
      else if
        s.[i] = '\r' && s.[i + 1] = '\n' && s.[i + 2] = '\r' && s.[i + 3] = '\n'
      then Some i
      else go (i + 1)
    in
    go 0

  let decode (msg : string) : (base_message * string, string) result =
    match find_sep msg with
    | None -> Error "not an RPC message: \\r\\n\\r\\n not found"
    | Some sep -> (
        let header = String.sub msg 0 sep in
        let* content_len = parse_content_length header in
        let body_start = sep + 4 in

        if String.length msg - body_start < content_len then
          Error "incorrect Content-Length header: body too short"
        else
          let json_str = String.sub msg body_start content_len in
          try
            let json = Yojson.Safe.from_string json_str in
            match base_message_of_yojson json with
            | Error _ ->
                Error
                  (Printf.sprintf
                     "Invalid RPC base message. Missing method? Raw: %s"
                     json_str)
            | Ok bm ->
                if String.trim bm.method_ = "" then
                  Error "field method is required"
                else Ok (bm, json_str)
          with Yojson.Json_error msg -> Error ("invalid json: " ^ msg))

  let split_jsonrpc (data : string) : ((int * string) option, string) result =
    match find_sep data with
    | None -> Ok None
    | Some sep ->
        let header = String.sub data 0 sep in
        let* content_len = parse_content_length header in
        let total_len = sep + 4 + content_len in

        if String.length data < total_len then Ok None
        else
          let frame = String.sub data 0 total_len in
          Ok (Some (total_len, frame))
end
