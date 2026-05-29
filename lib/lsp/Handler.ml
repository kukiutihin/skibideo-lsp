open LspStructs
open Logger
open Rpc
open MonadState
open Analysis

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
            | Ok encoded ->
                Logger.log Logger.Debug
                  (Printf.sprintf "Built initialize response: %s" encoded);
                print_string encoded;
                flush stdout))

  let initialized_handler _ _ = Logger.log Logger.Info "connected to client"

  let publish_diagnostics uri =
    match MonadState.get_document uri with
    | None ->
        Logger.log Logger.Error
          (Printf.sprintf "couldnt find buffer in memory: %s" uri)
    | Some doc -> (
        match Analysis.get_syntax_diagnostic doc with
        | Error e ->
            Logger.log Logger.Error
              (Printf.sprintf "Error during analysis: %s" e)
        | Ok diagnostic -> (
            let t =
              LspStructs.publish_diagnostics_notification_to_yojson
                {
                  rpc = "2.0";
                  method_ = "textDocument/publishDiagnostics";
                  params = { uri; diagnostics = [ diagnostic ] };
                }
            in
            match Rpc.encode t with
            | Error e -> failed_send_log e
            | Ok encoded ->
                print_string encoded;
                flush stdout))

  let did_change_handler id content =
    match Rpc.parse_json content with
    | Error e -> failed_parse_log e content
    | Ok j -> (
        match LspStructs.did_change_notification_of_yojson j with
        | Error e -> failed_parse_log e content
        | Ok decoded ->
            Logger.log Logger.Debug
              (Printf.sprintf "Received file changes; file uri: %s"
                 decoded.params.text_document.uri);
            List.iter
              (fun (ev : LspStructs.content_change_event) ->
                MonadState.open_document decoded.params.text_document.uri
                  ev.text)
              decoded.params.content_changes;
            publish_diagnostics decoded.params.text_document.uri;
            Logger.log Logger.Debug
              (Printf.sprintf "Changes saved; file uri: %s"
                 decoded.params.text_document.uri))

  let did_open_handler id content =
    match Rpc.parse_json content with
    | Error e -> failed_parse_log e content
    | Ok j -> (
        match LspStructs.did_open_notification_of_yojson j with
        | Error e -> failed_parse_log e content
        | Ok decoded ->
            MonadState.open_document decoded.params.text_document.uri
              decoded.params.text_document.text;
            Logger.log Logger.Debug
              (Printf.sprintf "Opened document; file uri: %s"
                 decoded.params.text_document.uri))

  let did_save_handler id content =
    match Rpc.parse_json content with
    | Error e -> failed_parse_log e content
    | Ok j -> (
        match LspStructs.did_open_notification_of_yojson j with
        | Error e -> failed_parse_log e content
        | Ok decoded ->
            Logger.log Logger.Debug
              (Printf.sprintf "File saved; file uri: %s"
                 decoded.params.text_document.uri))

  let handle met id content =
    match met with
    | "initialize" -> initialize_handler id content
    | "initialized" -> initialized_handler id content
    | "textDocument/didChange" -> did_change_handler id content
    | "textDocument/didOpen" -> did_open_handler id content
    | "textDocument/didSave" -> did_save_handler id content
    | _ ->
        Logger.log Logger.Error (Printf.sprintf "no handler for method: %s" met)
end
