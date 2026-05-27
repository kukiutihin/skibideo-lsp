open LspStructs
open Logger
open Rpc

module Handler = struct
  let compiler_path = ref ""
  let init path = compiler_path := path

  let failed_parse_log err content =
    Logger.log Logger.Error (Printf.sprintf "Failed to parse request: %s" err);
    Logger.log Logger.Debug (Printf.sprintf "Raw: %s" content)

  let failed_send_log err =
    Logger.log Logger.Error (Printf.sprintf "Failed to send response: %s" err)

  let initialize_handler id content =
    match Rpc.parse_json content with
    | Error e -> failed_parse_log e content
    | Ok j -> (
        match LspStructs.initialize_request_of_yojson j with
        | Error e -> failed_parse_log e content
        | Ok req -> (
            let resp : LspStructs.initialize_response =
              {
                id;
                rpc = "2.0";
                result =
                  {
                    capabilities = { text_document_sync_kind = 1 };
                    server_info =
                      Some { name = "skibideo"; version = Some "0.0.7" };
                  };
              }
            in
            (match req.params.client_info with
            | Some info ->
                Logger.log Logger.Info
                  (Printf.sprintf
                     "Received initialize request from client: %s %s" info.name
                     info.version)
            | None ->
                Logger.log Logger.Info
                  "Received initialize request from unknown client");
            let resp_json = LspStructs.initialize_response_to_yojson resp in
            match Rpc.encode resp_json with
            | Error e -> failed_send_log e
            | Ok encoded -> print_string encoded))

  let initialized_handler _ _ = Logger.log Logger.Info "connected to client"

  let handle met id content =
    match met with
    | "initialize" -> initialize_handler id content
    | "initialized" -> initialized_handler id content
    | _ ->
        Logger.log Logger.Error (Printf.sprintf "no handler for method: %s" met)
end
