module LspStructs = struct
  (*
    Default
  *)
  type request = {
    id : int;
    rpc : string; [@key "jsonrpc"]
    method_ : string; [@key "method"]
  }
  [@@deriving yojson]

  type response = { id : int option; rpc : string [@key "jsonrpc"] }
  [@@deriving yojson]

  type notification = {
    rpc : string; [@key "jsonrpc"]
    method_ : string; [@key "method"]
  }
  [@@deriving yojson]

  (*
    Text Document
  *)

  type text_document_item = {
    uri : string;
    lang_id : string; [@key "languageId"]
    version : int;
    text : string;
  }
  [@@deriving yojson]

  type text_document_identifier = { uri : string } [@@deriving yojson]

  type version_document_identifier = { uri : string; version : int }
  [@@deriving yojson]

  (*
    Initialize Request
  *)
  type client_info = { name : string; version : string }
  [@@deriving yojson { strict = false }]

  type initialize_request_params = {
    client_info : client_info option;
        [@key "clientInfo"] [@default None] [@yojson_drop_default ( = )]
  }
  [@@deriving yojson { strict = false }]

  type initialize_request = { id : int; params : initialize_request_params }
  [@@deriving yojson { strict = false }]

  type server_capabilities = {
    text_document_sync_kind : int; [@key "textDocumentSync"]
  }
  [@@deriving yojson]

  type server_info = {
    name : string;
    version : string option; [@default None] [@yojson_drop_default ( = )]
  }
  [@@deriving yojson]

  type initialize_result = {
    capabilities : server_capabilities;
    server_info : server_info option;
        [@key "serverInfo"] [@default None] [@yojson_drop_default ( = )]
  }
  [@@deriving yojson]

  type initialize_response = {
    id : int option; [@default None] [@yojson_drop_default ( = )]
    rpc : string; [@key "jsonrpc"]
    result : initialize_result;
  }
  [@@deriving yojson]
end
