(**************************************************************************)
(*                                                                        *)
(*    Copyright (c) 2014 - 2018.                                          *)
(*    Dynamic Ledger Solutions, Inc. <contact@tezos.com>                  *)
(*                                                                        *)
(*    All rights reserved. No warranty, explicit or implicit, provided.   *)
(*                                                                        *)
(**************************************************************************)

type t = {
  data_dir : string ;
  p2p : p2p ;
  rpc : rpc ;
  log : log ;
  shell : shell ;
}

and p2p = {
  expected_pow : float ;
  bootstrap_peers : string list ;
  listen_addr : string option ;
  closed : bool ;
  limits : P2p.limits ;
  disable_mempool : bool ;
}

and rpc = {
  listen_addr : string option ;
  cors_origins : string list ;
  cors_headers : string list ;
  tls : tls option ;
}

and tls = {
  cert : string ;
  key : string ;
}

and log = {
  output : Logging_unix.Output.t ;
  default_level : Logging.level ;
  rules : string option ;
  template : Logging.template ;
}

and shell = {
  block_validator_limits : Node.block_validator_limits ;
  prevalidator_limits : Node.prevalidator_limits ;
  peer_validator_limits : Node.peer_validator_limits ;
  chain_validator_limits : Node.chain_validator_limits ;
}

val default_data_dir: string
val default_p2p_port: int
val default_rpc_port: int
val default_p2p: p2p
val default_config: t

val update:
  ?data_dir:string ->
  ?min_connections:int ->
  ?expected_connections:int ->
  ?max_connections:int ->
  ?max_download_speed:int ->
  ?max_upload_speed:int ->
  ?binary_chunks_size:int->
  ?peer_table_size:int ->
  ?expected_pow:float ->
  ?bootstrap_peers:string list ->
  ?listen_addr:string ->
  ?rpc_listen_addr:string ->
  ?closed:bool ->
  ?disable_mempool:bool ->
  ?cors_origins:string list ->
  ?cors_headers:string list ->
  ?rpc_tls:tls ->
  ?log_output:Logging_unix.Output.t ->
  ?bootstrap_threshold:int ->
  t -> t tzresult Lwt.t

val to_string: t -> string
val read: string -> t tzresult Lwt.t
val write: string -> t -> unit tzresult Lwt.t

val resolve_listening_addrs: string -> (P2p_addr.t * int) list Lwt.t
val resolve_rpc_listening_addrs: string -> (P2p_addr.t * int) list Lwt.t
val resolve_bootstrap_addrs: string list -> (P2p_addr.t * int) list Lwt.t

val encoding: t Data_encoding.t

val check: t -> unit Lwt.t
