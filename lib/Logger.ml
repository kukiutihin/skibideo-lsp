module Logger = struct
  type level = Debug | Info | Error

  let log_file = ref None
  let current_level = ref Info
  let set_level l = current_level := l

  let init path =
    let oc = open_out_gen [ Open_creat; Open_text; Open_append ] 0o666 path in
    log_file := Some oc

  let log l msg =
    let level_to_int = function Debug -> 0 | Info -> 1 | Error -> 2 in
    if level_to_int l >= level_to_int !current_level then
      match !log_file with
      | Some file ->
          let prefix =
            match l with Debug -> "DEBUG" | Info -> "INFO" | Error -> "ERROR"
          in
          let tm = Unix.localtime (Unix.time ()) in
          let time =
            Printf.sprintf "%04d-%02d-%02d %02d:%02d:%02d" (tm.tm_year + 1900)
              (tm.tm_mon + 1) tm.tm_mday tm.tm_hour tm.tm_min tm.tm_sec
          in
          Printf.fprintf file "[%s][%s] %s%!\n" prefix time msg
      | None -> ()
end
