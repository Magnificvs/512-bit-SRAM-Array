; Minimal: generate Spectre meas for 50%→50% delays (no OCEAN needed)
; Vector file must be whitespace-separated:  time  A  B  Cin
; Lines starting with # are ignored.

procedure(faGenDelayMeasures(vecPath vdd outMeasPath preWindow postWindow netA netB netCin netSum netCout)
  let((inPort outPort line lines data prev n vth)

    vth = 0.5 * vdd
    lines = nil

    ;--- read lines (skip blank / comment)
    inPort = infile(vecPath)
    unless(inPort
      error(sprintf(nil "Cannot open vector file: %s\n" vecPath))
    )
while(gets(line inPort)
  when(line && strlen(line) > 0
    let((firstChar)
      firstChar = car(parseString(line))
      unless(firstChar && firstChar == "#"
        lines = cons(line lines)
      )
    )
  )
)
    close(inPort)
    lines = reverse(lines)

    ;--- parse to (t a b cin)
    data = nil
    foreach(l lines
      let((f k a b cin)
        f = parseString(l)           ; whitespace-separated only
        when(length(f) >= 4
          k   = atof(car(f))
          a   = atoi(nth(1 f))
          b   = atoi(nth(2 f))
          cin = atoi(nth(3 f))
          data = cons(list(k a b cin) data)
        )
      )
    )
    data = reverse(data)
    unless(data
      error("Vector file empty or malformed (need: time A B Cin per line).\n")
    )

    ;--- open output
    outPort = outfile(outMeasPath)
    unless(outPort
      error(sprintf(nil "Cannot open output file: %s\n" outMeasPath))
    )
    fprintf(outPort "simulator lang=spice\n")
    fprintf(outPort ".param vdd=%g vth=%g\n\n" vdd vth)

    ;--- detect toggles & emit meas
    prev = car(data)
    n = 0
    foreach(d cdr(data)
      let((tNow aNow bNow cinNow aPrev bPrev cinPrev const0 oneHot inName dirStr
            fromTnum fromT fromTout toT inNet sPrev sNow coutPrev coutNow )

        tNow   = car(d)     ; time
        aNow   = cadr(d)
        bNow   = caddr(d)
        cinNow = cadddr(d)

        aPrev   = cadr(prev)
        bPrev   = caddr(prev)
        cinPrev = cadddr(prev)

	; SUM = A ^ B ^ Cin  (xor via chained !=)
	sumPrev = if(aPrev!=bPrev then 1 else 0)
	sumPrev = if(sumPrev!=cinPrev then 1 else 0)
	sumNow  = if(aNow !=bNow  then 1 else 0)
	sumNow  = if(sumNow !=cinNow then 1 else 0)
	
	; COUT = AB + ACin + BCin


	; --- directions for outputs (rise/fall/neither)
	if(sumNow > sumPrev then
	  dirStrSum = "rise"
	else if(sumNow < sumPrev then
	  dirStrSum = "fall"
	else
	  dirStrSum = "neither"
	))
	


const0 = cinNow!=nil && bNow!=nil && aNow!=nil && cinPrev!=nil && bPrev!=nil && aPrev!=nil && tNow!=nil
oneHot = if(aNow!=aPrev && const0 then 1 else 0) + if(bNow!=bPrev && const0 then 1 else 0) + if(cinNow!=cinPrev && const0 then 1 else 0) 




    when(oneHot==1 || oneHot==2 || oneHot==3
          n = n + 1
          	coutPrev = floor((aPrev+bPrev+cinPrev)/2)
	          coutNow  = floor((aNow+bNow+cinNow)/2)
                     	if(coutNow > coutPrev then
	  dirStrCout = "rise"
	else if(coutNow < coutPrev then
	  dirStrCout = "fall"
	else
	  dirStrCout = "neither"
	))
          if(aNow!=aPrev then inName=netA
            else if(bNow!=bPrev then inName=netB else inName=netCin))
          dirStr = if( (inName==netA && aNow>aPrev) ||
                       (inName==netB && bNow>bPrev) ||
                       (inName==netCin && cinNow>cinPrev) then "rise" else "fall")
	  ; numeric version (seconds)
	  fromTnum = max(0.0 tNow - preWindow)
          fromT = sprintf(nil "%g" fromTnum)
	  fromTout = floor(fromTnum/2) + 1
          toT   = sprintf(nil "%g" (tNow + postWindow))
          inNet = inName


;edgeIn = if(dirStr=="rise" then "rising" else "falling")

; SUM \"%s\"
;fprintf(outPort
;  "measure ev%02d_%s_%s_SUM_rise param=delay(VT(%s), 0.5, %s, \"%s\", VT(%s), 0.5, %d, \"rising\")\n"
;  n inName dirStr inNet fromT edgeIn netSum fromTout)
;fprintf(outPort
;  "measure ev%02d_%s_%s_SUM_rise param=delay(VT(%s), 0.5, %s, \"%s\", VT(%s), 0.5, %d, \"falling\")\n"
;  n inName dirStr inNet fromT edgeIn netSum fromTout)

; COUT \"%s\"
;fprintf(outPort
;  "measure ev%02d_%s_%s_COUT_rise param=delay(VT(%s), 0.5, %s, \"%s\", VT(%s), 0.5, %d, \"rising\")\n"
;  n inName dirStr inNet fromT edgeIn netCout fromTout)

;fprintf(outPort
;  "measure ev%02d_%s_%s_COUT_rise param=delay(VT(%s), 0.5, %s, \"%s\", VT(%s), 0.5, %d, \"falling\")\n"
;  n inName dirStr inNet fromT edgeIn netCout fromTout)

; SUM delay @ 50%→50%
if( dirStrSum != "neither" then
fprintf(outPort
  ".measure tran ev%02d_%s_%s_SUM  trig v(\"%s\") val=vth %s=1 from=%se-9 to=%se-9  targ v(\"%s\") val=vth %s=1 from=%se-9 to=%se-9\n"
  n inName dirStr  inNet dirStr fromT  toT   netSum   dirStrSum fromT  toT))

; COUT delay @ 50%→50%
if( dirStrCout != "neither" then
fprintf(outPort
  ".measure tran ev%02d_%s_%s_COUT trig v(\"%s\") val=vth %s=1 from=%se-9 to=%se-9  targ v(\"%s\") val=vth %s=1 from=%se-9 to=%se-9\n\n"
  n inName dirStr  inNet dirStr fromT  toT   netCout  dirStrCout fromT  toT)
)

        )
        prev = d
      )
    )
    close(outPort)
    printf("Wrote %s with %d toggle events (SUM & COUT each).\n" outMeasPath n)
    outMeasPath
  )
)

; fa_meas_to_csv.il — read Spectre psf/measure.meas and write CSV (name,value_ps)

procedure(faMeasToCsv(measPath csvPath)
  let((in out line toks name raw val)

    in = infile(measPath)
    unless(in
      error(sprintf(nil "Cannot open measure file: %s\n" measPath))
    )

    out = outfile(csvPath)
    unless(out
      close(in)
      error(sprintf(nil "Cannot open CSV for write: %s\n" csvPath))
    )

    ; header
    fprintf(out "name,value_ps\n")

    ; each line typically looks like:  ev03_A2_rise_SUM = 3.75e-11
    while(gets(line in)
      when(line && strlen(line) > 0
        toks = parseString(line)  ; whitespace-split
        when(length(toks) >= 2
          name = car(toks)
          ; handle "name = value" or "name value"
          if( length(toks) >= 3 && equal(cadr(toks) "=") then
            raw = caddr(toks)
          else
            raw = cadr(toks)
          )
          ; some measures may be missing; guard atof
          when(raw && raw != "" 
            val = atof(raw)    ; seconds -> picoseconds
            fprintf(out "%s,%g\n" name val)
          )
        )
      )
    )

    close(in)
    close(out)
    printf("Wrote CSV: %s\n" csvPath)
    csvPath
  )
)
