open Skibideoml
open Skibideoml.Rpc
open Skibideoml.Logger
open Skibideoml.Handler

(* args *)
let log_path = ref "/tmp/skibideo_log.txt"
let compiler_path = ref "skib"
let debug = ref false
let handle_anon_arg arg = Printf.printf "Unknown argument received: %s\n" arg

let speclist =
  [
    ("--debug", Arg.Set debug, " to enable debug mode");
    ( "--compiler",
      Arg.Set_string compiler_path,
      "path to 1f compiler exetutable" );
    ("--log", Arg.Set_string log_path, "path to file for writing logs");
  ]

let usage_msg = "Usage: skibideo --compiler_path <path>"

let process_rpc_frame frame =
  match Rpc.decode frame with
  | Error e -> Logger.log Logger.Error e
  | Ok (base, body) ->
      Logger.log Logger.Debug
        (Printf.sprintf "Received request with method: %s" base.method_);
      Handler.handle base.method_ base.id body

let rec read_loop buf =
  let tmp = Bytes.create 4096 in
  let n = input stdin tmp 0 4096 in
  if n = 0 then ()
  else
    let buf = Bytes.cat buf (Bytes.sub tmp 0 n) in
    (* Logger.log Logger.Debug *)
    (*   (Printf.sprintf "Received raw: %s" (String.of_bytes buf)); *)
    match Rpc.split_jsonrpc (String.of_bytes buf) with
    | Error e -> Logger.log Logger.Error e
    | Ok None -> read_loop buf
    | Ok (Some (consumed, frame)) ->
        process_rpc_frame frame;
        let rest = Bytes.sub buf consumed (Bytes.length buf - consumed) in
        read_loop rest

let () =
  Arg.parse speclist handle_anon_arg usage_msg;
  if !compiler_path = "skib" then begin
    Arg.usage speclist usage_msg;
    exit 1
  end;

  Logger.init !log_path;
  if !debug then Logger.log Logger.Info "debug mode enabled";
  Logger.set_level Logger.Debug;

  read_loop (String.to_bytes "")
