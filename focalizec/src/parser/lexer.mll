(* $Id: lexer.mll,v 1.7 2007-02-02 00:15:50 weis Exp $ *)

{
open Lexing
open Parser

type error =
  | Illegal_character of char
  | Illegal_escape of string
  | Unterminated_comment
  | Uninitiated_comment
  | Unterminated_string
  | Comment_in_string
;;

exception Error of error * Lexing.position;;

let keyword_table = Hashtbl.create 42;;
List.iter (fun (kwd, tok) -> Hashtbl.add keyword_table kwd tok) [
    "all", ALL;
    "and", AND;
    "as", AS;
    "assumed", ASSUMED;
    "but", BUT;
    "by", BY;
    "collection", COLLECTION;
    "decl", DECL;
    "def", DEF;
    "else", ELSE;
    "end", END;
    "ex", EX;
    "external", EXTERNAL;
    "fun", FUN;
    "if", IF;
    "in", IN;
    "inherits", INHERITS;
    "is", IS;
    "let", LET;
    "letprop", LETPROP;
    "local", LOCAL;
    "match", MATCH;
    "not", NOT;
    "of", OF;
    "open", OPEN;
    "or", OR;
    "proof", PROOF;
    "prove", PROVE;
    "prop", PROP;
    "property", PROPERTY;
    "qed", QED;
    "rec", REC;
    "rep", REP;
    "self", SELF;
    "sig", SIG;
    "species", SPECIES;
    "then", THEN;
    "theorem", THEOREM;
    "type", TYPE;
    "uses", USES;
    "value", VALUE;
    "Coq", COQ;
    "Caml", CAML;
    "with", WITH;
  ];;

let initial_string_buffer = String.create 256;;
let string_buff = ref initial_string_buffer
and string_index = ref 0
;;

let reset_string_buffer () =
  string_buff := initial_string_buffer;
  string_index := 0
;;

let store_string_char c =
  if !string_index >= String.length (!string_buff) then begin
    let new_buff = String.create (String.length (!string_buff) * 2) in
      String.blit (!string_buff) 0
                  new_buff 0 (String.length (!string_buff));
      string_buff := new_buff
  end;
  String.unsafe_set (!string_buff) (!string_index) c;
  incr string_index
;;

let get_stored_string () =
  let s = String.sub (!string_buff) 0 (!string_index) in
  string_buff := initial_string_buffer;
  s
;;

let string_start_pos = ref None;;
let comment_start_pos = ref [];;
let in_comment () = !comment_start_pos <> [];;

let char_for_backslash = function
  | 'n' -> '\010'
  | 'r' -> '\013'
  | 'b' -> '\008'
  | 't' -> '\009'
  | c   -> c
;;

let char_for_decimal_code lexbuf i =
  let c = 100 * (Char.code(Lexing.lexeme_char lexbuf i) - 48) +
           10 * (Char.code(Lexing.lexeme_char lexbuf (i+1)) - 48) +
                (Char.code(Lexing.lexeme_char lexbuf (i+2)) - 48) in
  if c < 0 || c > 255
  then raise (Error (Illegal_escape (Lexing.lexeme lexbuf), lexbuf.lex_start_p))
  else Char.chr c
;;

let char_for_hexadecimal_code lexbuf i =
  let d1 = Char.code (Lexing.lexeme_char lexbuf i) in
  let val1 =
    if d1 >= 97 then d1 - 87 else
    if d1 >= 65 then d1 - 55 else
    d1 - 48 in
  let d2 = Char.code (Lexing.lexeme_char lexbuf (i+1)) in
  let val2 =
    if d2 >= 97 then d2 - 87 else
    if d2 >= 65 then d2 - 55 else
    d2 - 48 in
  Char.chr (val1 * 16 + val2)
;;

let update_loc lexbuf file line absolute chars =
  let pos = lexbuf.lex_curr_p in
  let new_file =
    match file with
    | None -> pos.pos_fname
    | Some s -> s in
  lexbuf.lex_curr_p <- {
    pos with
    pos_fname = new_file;
    pos_lnum = if absolute then line else pos.pos_lnum + line;
    pos_bol = pos.pos_cnum - chars;
  }
;;

let mk_coqproof s = COQPROOF (String.sub s 2 (String.length s - 4));;

let mk_prefix_prefixop s = PIDENT s;;
let mk_prefix_infixop s = IIDENT s;;

let mk_infixop s =
  assert (String.length s > 0);
  match s.[0] with
  | '+' -> PLUS_OP s
  | '-' ->
    begin match String.length s with
    | 1 -> DASH_OP s
    | 2 -> if s.[1] = '>' then DASH_GT else DASH_OP s
    | _ -> if s.[1] = '>' then DASH_GT_OP s else DASH_OP s end
  | '*' ->
    begin match String.length s with
    | 1 -> STAR_OP s
    | _ -> if s.[1] = '*' then STAR_STAR_OP s else STAR_OP s end
  | '/' -> SLASH_OP s
  | '%' -> PERCENT_OP s
  | '&' -> AMPER_OP s
  | '|' ->
    begin match String.length s with
    | 1 -> BAR
    | _ -> BAR_OP s end
  | ',' ->
    begin match String.length s with
    | 1 -> COMMA
    | _ -> COMMA_OP s end
  | ':' ->
    begin match String.length s with
    | 1 -> COLON
    | 2 -> if s.[1] = ':' then COLON_COLON else COLON_OP s
    | _ -> if s.[1] = ':' then COLON_COLON_OP s else COLON_OP s end
  | ';' ->
    begin match String.length s with
    | 1 -> SEMI
    | 2 -> if s.[1] = ';' then SEMI_SEMI else SEMI_OP s
    | _ -> if s.[1] = ';' then SEMI_SEMI_OP s else SEMI_OP s end
  | '<' ->
    begin match String.length s with
    | 1 -> LT_OP s
    | n ->
      if s.[1] = '-' && n >= 2 && s.[2] = '>'
      then if n >= 3 then LT_DASH_GT_OP s else LT_DASH_GT
      else LT_OP s end
  | '=' ->
    begin match String.length s with
    | 1 -> EQUAL
    | _ -> EQ_OP s end
  | '>' -> GT_OP s
  | '@' -> AT_OP s
  | '^' -> HAT_OP s
  | '\\' -> BACKSLASH_OP s
  | c ->
    failwith
      (Printf.sprintf "Unknown first character of infix ``%c''" c)
;;

open Format;;

let report_error ppf = function
  | Illegal_character c ->
      fprintf ppf "Illegal character (%s)" (Char.escaped c)
  | Illegal_escape s ->
      fprintf ppf "Illegal backslash escape in string or character (%s)" s
  | Unterminated_comment ->
      fprintf ppf "Comment not terminated"
  | Comment_in_string ->
      fprintf ppf "Non escaped comment separator in string constant"
  | Uninitiated_comment ->
      fprintf ppf "Comment has not started"
  | Unterminated_string ->
      fprintf ppf "String literal not terminated"
;;

}

let newline = '\010'
let blank = [' ' '\009' '\012']

(** (0) Les identificateurs alphanumériques, noms propres et noms communs (!) *)

let lowercase = ['a'-'z']
let uppercase = ['A'-'Z']
let decimal = ['0'-'9']

let start_lowercase_ident = '_' | lowercase
let start_uppercase_ident = uppercase

let continue_ident = start_lowercase_ident
                   | start_uppercase_ident
                   | decimal

(** (1) Les identificateurs infixes, noms des opérations binaires

   Ne comprennent ni Quote DoubleQuote qui sont des délimiteurs de chaînes et de caractères

   Rq: End_Infix ::= SPACE  (::= blanc tab newline) ( ) [] {} *)

let start_prefix = ['`' '~' '?' '$']
(* Rq: ! and # and . are treated specially and cannot be inside idents. *)

let start_infix =
  [ '+' '-' '*' '/' '%' '&' '|' ':' ';' '<' '=' '>' '@' '^' '\\' ]

let continue_infix = start_infix
                   | start_prefix
                   | continue_ident

(* Identifiers *)

let lowercase_ident = start_lowercase_ident continue_ident*

let uppercase_ident = start_uppercase_ident continue_ident*

let infix = start_infix continue_infix*

(** (2) Les identificateurs préfixes, noms des opérations unaires. *)
let prefix = start_prefix continue_infix*

(** Integers. *)
let decimal_literal =
  ['0'-'9'] ['0'-'9' '_']*
let hex_literal =
  '0' ['x' 'X'] ['0'-'9' 'A'-'F' 'a'-'f' '_']+
let bin_literal =
  '0' ['b' 'B'] ['0'-'1' '_']+
let int_literal =
  decimal_literal | hex_literal | bin_literal

rule token = parse
  | newline
      { update_loc lexbuf None 1 false 0;
        token lexbuf }
  | blank +
      { token lexbuf }
  | lowercase_ident
      { let s = Lexing.lexeme lexbuf in
        try Hashtbl.find keyword_table s
        with Not_found -> LIDENT s }
  | uppercase_ident
      { UIDENT (Lexing.lexeme lexbuf) }
  | "\'" lowercase_ident
      { QIDENT (Lexing.lexeme lexbuf) }
  | int_literal
      { INT (Lexing.lexeme lexbuf) }
  | "\""
      { reset_string_buffer();
        string_start_pos := Some lexbuf.lex_start_p;
        string lexbuf;
        begin match !string_start_pos with
        | Some pos -> lexbuf.lex_start_p <- pos
        | _ -> assert false end;
        STRING (get_stored_string()) }
  | "'" [^ '\\' '\'' '\010'] "'"
      { CHAR (Lexing.lexeme_char lexbuf 1) }
  | "'\\" ['\\' '\'' '"' 'n' 't' 'b' 'r' ' '] "'"
      { CHAR (char_for_backslash (Lexing.lexeme_char lexbuf 2)) }
  | "'\\" ['0'-'9'] ['0'-'9'] ['0'-'9'] "'"
      { CHAR (char_for_decimal_code lexbuf 2) }
  | "'\\" 'x' ['0'-'9' 'a'-'f' 'A'-'F'] ['0'-'9' 'a'-'f' 'A'-'F'] "'"
      { CHAR (char_for_hexadecimal_code lexbuf 3) }
  | "'\\" _
      { let l = Lexing.lexeme lexbuf in
        let esc = String.sub l 1 (String.length l - 1) in
        raise (Error (Illegal_escape esc, lexbuf.lex_start_p)) }
  | "(*"
      { comment_start_pos := [lexbuf.lex_start_p];
        comment lexbuf;
        token lexbuf }
  | "*)"
      { raise (Error (Uninitiated_comment, lexbuf.lex_start_p)) }
  | "#" [' ' '\t']* (['0'-'9']+ as num) [' ' '\t']*
        ("\"" ([^ '\010' '\013' '"' ] * as name) "\"")?
        [^ '\010' '\013'] * newline
      { update_loc lexbuf name (int_of_string num) true 0;
        token lexbuf }
  | '('  { LPAREN }
  | ')'  { RPAREN }
  | '['  { LBRACKET }
  | ']'  { RBRACKET }
  | '{'  { LBRACE }
  | '}'  { RBRACE }

  | '#'  { SHARP } (* To be suppressed. *)
  | '!'  { BANG } (* To be suppressed. *)
  | '.'  { DOT }

  | "~|" { TILDA_BAR }
  | prefix { PREFIX_OP (Lexing.lexeme lexbuf) }
  | "( " prefix " )" { mk_prefix_prefixop (Lexing.lexeme lexbuf) }

  | "( " infix " )" { mk_prefix_infixop (Lexing.lexeme lexbuf) }
  | infix { mk_infixop (Lexing.lexeme lexbuf) }


  | "{*" ([^ '*'] | '*' [^ '}'])* "*}"
     { mk_coqproof (Lexing.lexeme lexbuf) }

  | eof { EOF }
  | _
      { raise
          (Error
             (Illegal_character
                (Lexing.lexeme_char lexbuf 0), lexbuf.lex_start_p)) }

and comment = parse
    "(*"
      { comment_start_pos := lexbuf.lex_start_p :: !comment_start_pos;
        comment lexbuf; }
  | "*)"
      { match !comment_start_pos with
        | [] -> assert false
        | [x] -> comment_start_pos := [];
        | _ :: l -> comment_start_pos := l;
                    comment lexbuf; }
  | eof
      { match !comment_start_pos with
        | [] -> assert false
        | pos :: _ ->
          comment_start_pos := [];
          raise (Error (Unterminated_comment, pos)) }
  | newline
      { update_loc lexbuf None 1 false 0;
        comment lexbuf }
  | _
      { comment lexbuf }

and string = parse
    '"'
      { () }
  | '\\' newline ([' ' '\t'] * as space)
      { update_loc lexbuf None 1 false (String.length space);
        string lexbuf }
  | '\\' ['(' '\\' '\'' '"' 'n' 't' 'b' 'r' ' ' '*' ')']
      { store_string_char(char_for_backslash(Lexing.lexeme_char lexbuf 1));
        string lexbuf }
  | '\\' ['0'-'9'] ['0'-'9'] ['0'-'9']
      { store_string_char(char_for_decimal_code lexbuf 1);
        string lexbuf }
  | '\\' 'x' ['0'-'9' 'a'-'f' 'A'-'F'] ['0'-'9' 'a'-'f' 'A'-'F']
      { store_string_char(char_for_hexadecimal_code lexbuf 2);
        string lexbuf }
  | '\\' _
      { raise
          (Error
             (Illegal_escape
                (Lexing.lexeme lexbuf), lexbuf.lex_start_p)) }
  | ( "(*" | "*)" )
      { raise (Error (Comment_in_string, lexbuf.lex_start_p)) }
  | ( newline | eof )
      { match !string_start_pos with
        | Some pos -> raise (Error (Unterminated_string, pos))
        | _ -> assert false }
  | _
      { store_string_char(Lexing.lexeme_char lexbuf 0);
        string lexbuf }
