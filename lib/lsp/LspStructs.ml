open Analysis

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

  type position = { line : int; character : int } [@@deriving yojson]

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
    Initialize
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

  type completion_provider = {
    resolve_provider : bool; [@key "resolveProvider"]
  }
  [@@deriving yojson]

  type server_capabilities = {
    text_document_sync_kind : int; [@key "textDocumentSync"]
    completion_provider : completion_provider; [@key "completionProvider"]
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

  (*
    didChange
  *)

  type content_change_event = { text : string } [@@deriving yojson]

  type did_change_params = {
    text_document : version_document_identifier; [@key "textDocument"]
    content_changes : content_change_event list; [@key "contentChanges"]
  }
  [@@deriving yojson]

  type did_change_notification = {
    params : did_change_params;
    rpc : string; [@key "jsonrpc"]
    method_ : string; [@key "method"]
  }
  [@@deriving yojson]

  (*
    didOpen
  *)

  type did_open_params = {
    text_document : text_document_item; [@key "textDocument"]
  }
  [@@deriving yojson]

  type did_open_notification = {
    params : did_open_params;
    rpc : string; [@key "jsonrpc"]
    method_ : string; [@key "method"]
  }
  [@@deriving yojson]

  (*
    didSave
  *)

  type did_save_params = {
    text_document : version_document_identifier; [@key "textDocument"]
  }
  [@@deriving yojson]

  type did_save_notification = {
    params : did_change_params;
    rpc : string; [@key "jsonrpc"]
    method_ : string; [@key "method"]
  }
  [@@deriving yojson]

  (*
   publish diagnostics 
  *)

  type publish_diagnostics_params = {
    uri : string;
    diagnostics : Analysis.analysis_error list;
  }
  [@@deriving yojson]

  type publish_diagnostics_notification = {
    rpc : string; [@key "jsonrpc"]
    method_ : string; [@key "method"]
    params : publish_diagnostics_params;
  }
  [@@deriving yojson]

  (*
    completion
  *)

  type completion_context = {
    trigger_kind : int; [@key "triggerKind"]
    trigger_char : string option; [@default None] [@key "triggerCharacter"]
  }
  [@@deriving yojson]

  type completion_params = {
    text_document : text_document_identifier; [@key "textDocument"]
    position : position;
    context : completion_context;
  }
  [@@deriving yojson]

  type completion_request = {
    rpc : string; [@key "jsonrpc"]
    id : int;
    method_ : string; [@key "method"]
    params : completion_params;
  }
  [@@deriving yojson]

  type completion_item = { label : string; kind : int; detail : string }
  [@@deriving yojson]

  type completion_result = {
    is_incomplete : bool; [@key "isIncomplete"]
    items : completion_item list;
  }
  [@@deriving yojson]

  type completion_response = {
    rpc : string; [@key "jsonrpc"]
    id : int;
    result : completion_result;
  }
  [@@deriving yojson]
end
