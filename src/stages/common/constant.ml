open Types

let bool_name = "bool"
let string_name = "string"
let bytes_name = "bytes"
let int_name = "int"
let operation_name = "operation"
let nat_name = "nat"
let tez_name = "tez"
let unit_name = "unit"
let address_name = "address"
let signature_name = "signature"
let key_name = "key"
let key_hash_name = "key_hash"
let timestamp_name = "timestamp"
let chain_id_name = "chain_id"
let option_name = "option"
let list_name = "list"
let map_name = "map"
let big_map_name = "big_map"
let set_name = "set"
let contract_name = "contract"
let michelson_or_name = "michelson_or"
let michelson_pair_name = "michelson_pair"
let michelson_pair_right_comb_name = "michelson_pair_right_comb"
let michelson_pair_left_comb_name = "michelson_pair_left_comb"
let michelson_or_right_comb_name = "michelson_or_right_comb"
let michelson_or_left_comb_name = "michelson_or_left_comb"
let map_or_big_map_name = "map_or_big_map"

let v_bool : type_variable = Var.of_name bool_name
let v_string : type_variable = Var.of_name string_name
let v_bytes : type_variable = Var.of_name bytes_name
let v_int : type_variable = Var.of_name int_name
let v_operation : type_variable = Var.of_name operation_name
let v_nat : type_variable = Var.of_name nat_name
let v_tez : type_variable = Var.of_name tez_name
let v_unit : type_variable = Var.of_name unit_name
let v_address : type_variable = Var.of_name address_name
let v_signature : type_variable = Var.of_name signature_name
let v_key : type_variable = Var.of_name key_name
let v_key_hash : type_variable = Var.of_name key_hash_name
let v_timestamp : type_variable = Var.of_name timestamp_name
let v_chain_id : type_variable = Var.of_name chain_id_name
let v_option : type_variable = Var.of_name option_name
let v_list : type_variable = Var.of_name list_name
let v_map  : type_variable = Var.of_name map_name
let v_big_map  : type_variable = Var.of_name big_map_name
let v_set  : type_variable = Var.of_name set_name
let v_contract  : type_variable = Var.of_name contract_name
let v_michelson_or  : type_variable = Var.of_name michelson_or_name
let v_michelson_pair  : type_variable = Var.of_name michelson_pair_name
let v_michelson_pair_right_comb  : type_variable = Var.of_name michelson_pair_right_comb_name
let v_michelson_pair_left_comb  : type_variable = Var.of_name michelson_pair_left_comb_name
let v_michelson_or_right_comb  : type_variable = Var.of_name michelson_or_right_comb_name
let v_michelson_or_left_comb  : type_variable = Var.of_name michelson_or_left_comb_name
let v_map_or_big_map : type_variable = Var.of_name map_or_big_map_name

(* temp solution for PP's*)
let type_name_lst = [
bool_name ;
string_name ;
bytes_name ;
int_name ;
operation_name ;
nat_name ;
tez_name ;
unit_name ;
address_name ;
signature_name ;
key_name ;
key_hash_name ;
timestamp_name ;
chain_id_name ;
option_name ;
list_name ;
map_name ;
big_map_name ;
set_name ;
contract_name ;
michelson_or_name ;
michelson_pair_name ;
michelson_pair_right_comb_name ;
michelson_pair_left_comb_name ;
michelson_or_right_comb_name ;
michelson_or_left_comb_name ;
]