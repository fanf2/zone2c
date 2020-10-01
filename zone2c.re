/*!re2c	re2c:yyfill:enable = 0;
	re2c:eof = 0;
*/

extern const char *
scan_qname(void *qname) {
	typedef unsigned char YYCTYPE;
	YYCTYPE *YYCURSOR = qname;
	YYCTYPE *YYLIMIT = YYCURSOR + 255;
	YYCTYPE *YYMARKER = NULL;
/*

(progn
  ; empty the table
  (search-forward "wild")
  (set-mark (- (point) 6))
  (search-forward "\n\n")
  (kill-region (1+ (region-beginning))
	       (1- (region-end)))
  ; every non-root DNS label
  (dotimes (len 64)
    (if (not (= 0 len))
      (insert (format "wild%d = '\\x%02x' any{%d} ;\n" len len len))))
  (dotimes (len 64)
    (if (= 0 len)
      (insert "wildN = ")
      (insert (format "wild%d" len))
      (if (= 63 len)
        (insert " ;\n\n")
	(if (= 0 (% len 8))
	  (insert " |\n  ")
	  (insert " | "))))))

 */


%{
hack_to_stop_emacs_indenting = [}}];

any = [\x00-\xff] ;

wild1 = '\x01' any{1} ;
wild2 = '\x02' any{2} ;
wild3 = '\x03' any{3} ;
wild4 = '\x04' any{4} ;
wild5 = '\x05' any{5} ;
wild6 = '\x06' any{6} ;
wild7 = '\x07' any{7} ;
wild8 = '\x08' any{8} ;
wild9 = '\x09' any{9} ;
wild10 = '\x0a' any{10} ;
wild11 = '\x0b' any{11} ;
wild12 = '\x0c' any{12} ;
wild13 = '\x0d' any{13} ;
wild14 = '\x0e' any{14} ;
wild15 = '\x0f' any{15} ;
wild16 = '\x10' any{16} ;
wild17 = '\x11' any{17} ;
wild18 = '\x12' any{18} ;
wild19 = '\x13' any{19} ;
wild20 = '\x14' any{20} ;
wild21 = '\x15' any{21} ;
wild22 = '\x16' any{22} ;
wild23 = '\x17' any{23} ;
wild24 = '\x18' any{24} ;
wild25 = '\x19' any{25} ;
wild26 = '\x1a' any{26} ;
wild27 = '\x1b' any{27} ;
wild28 = '\x1c' any{28} ;
wild29 = '\x1d' any{29} ;
wild30 = '\x1e' any{30} ;
wild31 = '\x1f' any{31} ;
wild32 = '\x20' any{32} ;
wild33 = '\x21' any{33} ;
wild34 = '\x22' any{34} ;
wild35 = '\x23' any{35} ;
wild36 = '\x24' any{36} ;
wild37 = '\x25' any{37} ;
wild38 = '\x26' any{38} ;
wild39 = '\x27' any{39} ;
wild40 = '\x28' any{40} ;
wild41 = '\x29' any{41} ;
wild42 = '\x2a' any{42} ;
wild43 = '\x2b' any{43} ;
wild44 = '\x2c' any{44} ;
wild45 = '\x2d' any{45} ;
wild46 = '\x2e' any{46} ;
wild47 = '\x2f' any{47} ;
wild48 = '\x30' any{48} ;
wild49 = '\x31' any{49} ;
wild50 = '\x32' any{50} ;
wild51 = '\x33' any{51} ;
wild52 = '\x34' any{52} ;
wild53 = '\x35' any{53} ;
wild54 = '\x36' any{54} ;
wild55 = '\x37' any{55} ;
wild56 = '\x38' any{56} ;
wild57 = '\x39' any{57} ;
wild58 = '\x3a' any{58} ;
wild59 = '\x3b' any{59} ;
wild60 = '\x3c' any{60} ;
wild61 = '\x3d' any{61} ;
wild62 = '\x3e' any{62} ;
wild63 = '\x3f' any{63} ;
wildN = wild1 | wild2 | wild3 | wild4 | wild5 | wild6 | wild7 | wild8 |
  wild9 | wild10 | wild11 | wild12 | wild13 | wild14 | wild15 | wild16 |
  wild17 | wild18 | wild19 | wild20 | wild21 | wild22 | wild23 | wild24 |
  wild25 | wild26 | wild27 | wild28 | wild29 | wild30 | wild31 | wild32 |
  wild33 | wild34 | wild35 | wild36 | wild37 | wild38 | wild39 | wild40 |
  wild41 | wild42 | wild43 | wild44 | wild45 | wild46 | wild47 | wild48 |
  wild49 | wild50 | wild51 | wild52 | wild53 | wild54 | wild55 | wild56 |
  wild57 | wild58 | wild59 | wild60 | wild61 | wild62 | wild63 ;

wild = wildN+ ;

*	{ return "FORMERR"; }
$	{ return "FORMERR"; }

// this needs adjusting for the root zone...
wild	{ return "REFUSED"; }

// zones are appended by zone2re.pl
