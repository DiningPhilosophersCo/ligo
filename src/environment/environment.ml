open Ast_typed
open Stage_common.Constant

let star = t_variable @@ Var.of_name "will_be_ignored" (* This will later be replaced by the kind of the constant *)

let default =
  Environment.of_list_type
    [
      (v_bool , t_sum_ez [ ("true" ,t_unit ()); ("false",t_unit ()) ] ) ;
      (v_string , t_constant string_name []) ;
      (v_bytes , t_constant bytes_name []) ;
      (v_int , t_constant int_name []) ;
      (v_operation , t_constant operation_name []) ;
      (v_nat , t_constant nat_name []) ;
      (v_tez , t_constant tez_name []) ;
      (v_unit , t_constant unit_name []) ;
      (v_address , t_constant address_name []) ;
      (v_signature , t_constant signature_name []) ;
      (v_key , t_constant key_name []) ;
      (v_key_hash , t_constant key_hash_name []) ;
      (v_timestamp , t_constant timestamp_name []) ;
      (v_chain_id , t_constant chain_id_name []) ;
      (v_option , t_constant option_name [star]) ;
      (v_list , t_constant list_name [star]) ;
      (v_map , t_constant map_name [star;star]) ;
      (v_big_map , t_constant big_map_name [star;star]);
      (v_set , t_constant set_name [star]);
      (v_contract , t_constant contract_name [star]);
      (v_map_or_big_map , t_constant map_or_big_map_name [star;star]);
      (v_michelson_or , t_constant michelson_or_name [star;star]);
      (v_michelson_pair , t_constant michelson_pair_name [star;star]);
      (v_michelson_pair_right_comb , t_constant michelson_pair_right_comb_name [star]);
      (v_michelson_pair_left_comb , t_constant michelson_pair_left_comb_name [star]);
      (v_michelson_or_right_comb , t_constant michelson_or_right_comb_name [star]);
      (v_michelson_or_left_comb , t_constant michelson_or_left_comb_name [star]);
    ]
