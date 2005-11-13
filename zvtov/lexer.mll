(*  Copyright 2004 INRIA  *)
(*  $Id: lexer.mll,v 1.8 2005-11-13 22:49:11 doligez Exp $  *)
{
open Token;;
}

let blank = [ ' ' '\t' '\r' '\n' ]
let idchar = [ '0'-'9' 'A'-'Z' 'a'-'z' '_' ]
let pathchar = [ '0'-'9' '_' ]
let digit = [ '0'-'9' ]

rule token = parse
  | "Require"
      { REQUIRE (Lexing.lexeme lexbuf) }
  | "Section" blank+ idchar* "__" idchar*
      { SECTION (Lexing.lexeme lexbuf) }
(*
  | "Local" blank+ "__l_" [^ '.']* "(* to be proved *)" [^ '.']* "(* Qed *)."
      { TOBE (Lexing.lexeme lexbuf) }
  | "Local" blank+ "__lemma_" [^ '.']* "(* to be proved *)" [^ '.']*
    "(* Qed *)."
      { TOBE (Lexing.lexeme lexbuf) }
  | "Local" blank+ "__goal_" [^ '.']* "(* to be proved *)" [^ '.']* "(* Qed *)."
      { TOBE (Lexing.lexeme lexbuf) }
*)
  | "%%begin-auto-proof" blank+
    "%%location:" blank* '[' ([^ ']']* as loc) ']' blank+
    "%%name:" blank* (idchar+ as name) blank+
    "%%syntax:" blank* (idchar+ as syntax) blank+
    "%%statement" ([^'.']+ as statement) '.' blank+
    ([^ '%']+ | "%@" [^ '\n']+ '\n')+
    "%%end-auto-proof" blank+
      { if syntax = "TPTP" then Invoke.set_tptp_option ();
        AUTOPROOF (Lexing.lexeme lexbuf, loc, statement, name) }
  | eof
      { EOF }
  | _
      { CHAR (Lexing.lexeme lexbuf) }

and section = parse
  | "Section" blank+ (idchar* as species) "__" (idchar* as proof)
      { (species, proof) }

and lemma = parse
  | "Local" blank+ "__lemma_" { LEMMA (lemma_path lexbuf) }
  | "Local" blank+ "__goal_" { GOAL }
  | "Local" blank+ "__l_" { TOP }

and lemma_path = parse
  | "_" { lemma_path lexbuf }
  | digit+
      { let h = int_of_string (Lexing.lexeme lexbuf) in
        let t = lemma_path lexbuf in
        h :: t
      }
  | _ { [] }
