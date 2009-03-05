(*
    Title:      Standard Basis Library: Time Signature and structure.
    Author:     David Matthews
    Copyright   David Matthews 2000, 2005

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
	
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Lesser General Public License for more details.
	
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*)

(* G&R 2004 status: updated. *)

signature TIME =
sig
	 eqtype time
     exception Time
     val zeroTime : time
     val fromReal : LargeReal.real -> time
     val toReal : time -> LargeReal.real
     val toSeconds      : time -> LargeInt.int
     val toMilliseconds : time -> LargeInt.int
     val toMicroseconds : time -> LargeInt.int
	 val toNanoseconds  : time -> LargeInt.int
     val fromSeconds      : LargeInt.int -> time
     val fromMilliseconds : LargeInt.int -> time
     val fromMicroseconds : LargeInt.int -> time
     val fromNanoseconds  : LargeInt.int -> time
     val + : time * time -> time
     val - : time * time -> time
     val compare : time * time -> General.order
     val <  : time * time -> bool
     val <= : time * time -> bool
     val >  : time * time -> bool
     val >= : time * time -> bool
     val now : unit -> time
     val fmt : int -> time -> string
     val toString : time -> string
     val fromString : string -> time option
     val scan       : (char, 'a) StringCvt.reader -> (time, 'a) StringCvt.reader
end;

structure Time :> TIME =
struct
	(* Unix and Windows both use 64 bit quantities for times.  Windows
	   uses a 64-bit number of 100ns ticks, Unix uses one word of seconds
	   and another of microseconds.  To handle both easily we use a single
	   arbitrary precision number for times with the actual resolution
	   returned as an RTS call.  The intention is retain as much precision
	   as possible. *)
	type time = int (* Becomes abstract *)
    exception Time

	open RuntimeCalls

	val doTiming: int*int->int = RunCall.run_call2 POLY_SYS_timing_dispatch
	fun callTiming (code: int) args = doTiming (code,args);

	(* Get the number of ticks per microsecond and compute the corresponding
	   values for milliseconds and seconds. *)
	val ticksPerMicrosecond = callTiming 0 0
	val ticksPerMillisecond = ticksPerMicrosecond * 1000
	val ticksPerSecond = ticksPerMillisecond * 1000

	(* Check for very large time values.  These cause problems if
	   converted to dates. *)
	local
		val Years100000 = ticksPerSecond*60*60*24*365*100000
	in
		fun checkTimeValue t =
			if t <  ~ Years100000 orelse t > Years100000
			then raise Time else t
	end;

	(* The real representation is as a number of seconds. *)
	local
		val realTicks = Real.fromInt ticksPerSecond
	in
		fun fromReal (x: real): time = 
			checkTimeValue(Real.round (x * realTicks))
		and toReal (t: time): real = Real.fromInt t / realTicks
	end

	val zeroTime = fromReal 0.0

	(* Convert to seconds, etc.*)
	fun toSeconds x = x div ticksPerSecond
	and toMilliseconds x = x div ticksPerMillisecond
	and toMicroseconds x = x div ticksPerMicrosecond
	and toNanoseconds x = x * 1000 div ticksPerMicrosecond

	(* Convert from the integer representations. *)
	fun fromSeconds i = checkTimeValue(i * ticksPerSecond)
	and fromMilliseconds i = checkTimeValue(i * ticksPerMillisecond)
	and fromMicroseconds i = checkTimeValue(i * ticksPerMicrosecond)
	and fromNanoseconds i = checkTimeValue(i * ticksPerMicrosecond div 1000)

	(* Format as a fixed precision number.  if n < 0 treat as n = 0. *)
	fun fmt n r = Real.fmt (StringCvt.FIX(SOME(Int.max(n, 0)))) (toReal r)
	val toString = fmt 3

	(* The scanned string is a subset of the format of a real number.
	   It does not have an exponent.  At present we convert it as a real
	   number but it would probably be better to treat it as an integer. *)
	fun scan getc src =
	let
		(* Return a list of digits. *)
		fun getdigits inp src =
			case getc src of
				NONE => (List.rev inp, src)
			  | SOME(ch, src') =>
			  		if ch >= #"0" andalso ch <= #"9"
					then getdigits ((Char.ord ch - Char.ord #"0") :: inp) src'
					else (List.rev inp, src)

		fun read_number sign src =
			case getc src of
				NONE => NONE
			  | SOME(ch, src') =>
					if not (ch >= #"0" andalso ch <= #"9" orelse ch = #".")
					then NONE (* Bad "*)
					else (* Digits or decimal. *)
					let
						(* Get the digits before the decimal point (if any) *)
						val (intPart, src'') = getdigits [] src
						(* Get the digits after the decimal point (if any).
						   If there is a decimal point we swallow the decimal only
						   if there is at least one digit after it. *)
						val (decPart, srcAfterMant) =
							case getc src'' of
								SOME (#".", src''') =>
							 		( (* Check that the next character is a digit. *)
									case getc src''' of
										NONE => ([], src'')
									  | SOME(ch, _) =>
									  		if ch >= #"0" andalso ch <= #"9"
											then getdigits [] src'''
											else ([], src'')
									)
							 |  _ => ([], src'')
					in
						case (intPart, decPart) of
							([], []) => NONE (* Must have a digit either before or after the dp. *)
						|	_ =>
						let
							(* Get exactly 9 digits after the decimal point. *)
							val decs = intPart @ (List.take(decPart @ [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ], 9));
							(* It's now in nanoseconds. *)
							val toInt = List.foldl (fn (i, j) => i + j*10) 0 decs
						in
							SOME(fromNanoseconds(if sign then ~toInt else toInt), srcAfterMant)
						end
					end
	in
		case getc src of
			NONE => NONE
		 |  SOME(ch, src') =>
		 	if Char.isSpace ch (* Skip white space. *)
			then scan getc src' (* Recurse *)
			else if ch = #"+" (* Remove the + sign *)
			then read_number false src'
			else if ch = #"-" orelse ch = #"~"
			then read_number true src'
			else  (* See if it's a valid digit or decimal point. *)
				read_number false src
	end
	
	val fromString = StringCvt.scanString scan

	(* Use the integer operations for these. *)
    val op < : (time * time) -> bool = Int.<
    val op <= : (time * time) -> bool = Int.<=
    val op > : (time * time) -> bool = Int.>
    val op >= : (time * time) -> bool = Int.>=;

	val compare = Int.compare

    val op + : (time * time) -> time = Int.+
    val op - : (time * time) -> time = Int.-

	fun now () = callTiming 1 0 handle _ => raise Time

end;


local
	(* Install the pretty printer for Time.time.  This has to be
	   done outside the structure because of the opaque matching. *)
	fun pretty _ _ x = PolyML.PrettyString(Time.toString x)
in
	val it = PolyML.addPrettyPrinter pretty
	(* Add overloads for +, -, <= etc *)
	val it = RunCall.addOverload Time.+ "+";
	val it = RunCall.addOverload Time.- "-";
	val it = RunCall.addOverload Time.< "<";
	val it = RunCall.addOverload Time.> ">";
	val it = RunCall.addOverload Time.<= "<=";
	val it = RunCall.addOverload Time.>= ">=";
end
