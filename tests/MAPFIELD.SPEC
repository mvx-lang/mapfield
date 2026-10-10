   PROGRAM MAPFIELD.SPEC
* mapfield — the %MAP% spec builder's own test.  GPL-2.0-only.
*
* Run it in an account with mapfield deployed:
*
*   UniData    BASIC BP MAPFIELD.SPEC ; RUN BP MAPFIELD.SPEC
*   UniVerse   BASIC BP MAPFIELD.SPEC ; RUN BP MAPFIELD.SPEC
*   jBASE      BASIC BP MAPFIELD.SPEC ; RUN BP MAPFIELD.SPEC
*
* It prints FAILURES=0 when the builder is right.  CI runs it on all three
* through mv-package-registry's mv-package-test action (#15).
*
* WHAT IS WORTH ASSERTING HERE.  MAPFIELD returns
*
*     name <VM> attr <VM> conv <VM> type <VM> assoc
*
* and its only logic is deriving the type when TYPE is empty, from
* OCONV(CONV, "MCU").  Two of these cases are load-bearing in a way the
* README does not show:
*
*   10  THE OCONV IS NOT DECORATION.  Remove it and the function still
*       compiles, and still passes every case that happens to pass an
*       uppercase conversion -- which is all of 3 to 9.  A lowercase conv is
*       the only thing that notices.
*
*    2  AN EXPLICIT TYPE MUST WIN.  A caller that has said NUMERIC must not
*       have it recomputed from a conv that would say something else.
*
* COUNT, NOT DCOUNT, for the field count: the spec's last field is empty for a
* scalar, and platforms disagree about whether DCOUNT counts a trailing empty
* field.  COUNT asks how many delimiters there are, which nothing disagrees
* about.
*
* NO ORDERING CASE.  The arms test different positions -- CU[1,2] for the M
* prefixes and CU[1,1] for D -- so a conv matching MD has CU[1,1] = "M" and can
* never reach the D arm.  Reordering them changes nothing, so a test asserting
* that it does would be asserting a property this code does not have.
   DEFFUN MAPFIELD(A, B, C, D, E)
   FAILS = 0
*
   R = MAPFIELD("CUST", 3, "MD2", "", "ORDERS")
   OK = (COUNT(R, @VM) = 4)
   OK = OK AND (R<1,1> = "CUST") AND (R<1,2> = 3) AND (R<1,3> = "MD2")
   OK = OK AND (R<1,4> = "NUMERIC") AND (R<1,5> = "ORDERS")
   IF NOT(OK) THEN FAILS += 1
   SHAPE = R<1,1> : "/" : R<1,2> : "/" : R<1,3> : "/" : R<1,4> : "/" : R<1,5>
   PRINT "1  shape: five fields     ok=" : OK : "  " : SHAPE
*
   R = MAPFIELD("AMT", 1, "MD2", "TEXT", "")
   OK = (R<1,4> = "TEXT")
   IF NOT(OK) THEN FAILS += 1
   PRINT "2  explicit TYPE wins     ok=" : OK : "  got " : R<1,4> : " (want TEXT)"
*
   R = MAPFIELD("AMT", 1, "MD2", "", "")
   OK = (R<1,4> = "NUMERIC")
   IF NOT(OK) THEN FAILS += 1
   PRINT "3  MD -> NUMERIC          ok=" : OK : "  got " : R<1,4>
*
   R = MAPFIELD("AMT", 1, "MR2", "", "")
   OK = (R<1,4> = "NUMERIC")
   IF NOT(OK) THEN FAILS += 1
   PRINT "4  MR -> NUMERIC          ok=" : OK : "  got " : R<1,4>
*
   R = MAPFIELD("AMT", 1, "ML2", "", "")
   OK = (R<1,4> = "NUMERIC")
   IF NOT(OK) THEN FAILS += 1
   PRINT "5  ML -> NUMERIC          ok=" : OK : "  got " : R<1,4>
*
   R = MAPFIELD("WHEN", 2, "MTH", "", "")
   OK = (R<1,4> = "TIME")
   IF NOT(OK) THEN FAILS += 1
   PRINT "6  MT -> TIME             ok=" : OK : "  got " : R<1,4>
*
   R = MAPFIELD("DUE", 4, "D4/", "", "")
   OK = (R<1,4> = "DATE")
   IF NOT(OK) THEN FAILS += 1
   PRINT "7  D... -> DATE           ok=" : OK : "  got " : R<1,4>
*
   R = MAPFIELD("NAME", 5, "MCU", "", "")
   OK = (R<1,4> = "TEXT")
   IF NOT(OK) THEN FAILS += 1
   PRINT "8  other conv -> TEXT     ok=" : OK : "  got " : R<1,4>
*
   R = MAPFIELD("NAME", 5, "", "", "")
   OK = (R<1,4> = "TEXT")
   IF NOT(OK) THEN FAILS += 1
   PRINT "9  no conv -> TEXT        ok=" : OK : "  got " : R<1,4>
*
* The OCONV(CONV, "MCU") is what makes these three work; without it each
* derives TEXT and only this case says so.
   R1 = MAPFIELD("AMT", 1, "md2", "", "")
   R2 = MAPFIELD("WHEN", 2, "mth", "", "")
   R3 = MAPFIELD("DUE", 4, "d4/", "", "")
   OK = (R1<1,4> = "NUMERIC") AND (R2<1,4> = "TIME") AND (R3<1,4> = "DATE")
   IF NOT(OK) THEN FAILS += 1
   PRINT "10 lowercase conv folds   ok=" : OK : "  got " : R1<1,4> : "/" : R2<1,4> : "/" : R3<1,4>
*
* An empty assoc is a scalar field; a named one passes through verbatim, and
* the name is not interpreted -- it is an association name, not a conversion.
   R1 = MAPFIELD("NAME", 5, "", "", "")
   R2 = MAPFIELD("QTY", 6, "", "", "LINES")
   OK = (R1<1,5> = "") AND (R2<1,5> = "LINES")
   IF NOT(OK) THEN FAILS += 1
   PRINT "11 assoc: scalar vs named ok=" : OK : "  [" : R1<1,5> : "] [" : R2<1,5> : "]"
*
   PRINT "FAILURES=" : FAILS
