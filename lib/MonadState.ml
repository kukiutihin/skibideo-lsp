module MonadState = struct
  let files : (string, string) Hashtbl.t = Hashtbl.create 0
  let open_document uri content = Hashtbl.replace files uri content
  let get_document (uri : string) = Hashtbl.find_opt files uri
end
