;; sram_blackbox.il - tao GDS "hop den" cho macro chi co LEF, bang Virtuoso
;;
;; ASAP7 khong ship GDS cho srambank_256x4x32_6t122 va srambank_128x4x20_6t122
;; (chi co srambank_32b/64b/128b).  Yeu cau cua thay: khong co GDS thi tao GDS
;; gia, chi can DUNG DIEN TICH, lay tu LEF da co - nhu mot hop den.
;;
;; Script doc LEF, tao cellview layout TRUNG TEN macro (de merge vao
;; top_soc.gds dung master), gom:
;;   - 1 hinh chu nhat BOUNDARY (100/0) = SIZE trong LEF      <- dien tich
;;   - hinh chan (PIN .. PORT .. RECT) dung layer, datatype 0  <- cho day top cham vao
;;   - 1 nhan ten chan cho moi chan, texttype 251             <- cho LVS box
;; KHONG ve OBS, ben trong khong co gi: do la hop den.
;; Hinh chan lo ra ngoai SIZE bi CAT sat bien, de bbox GDS = dung SIZE.  Chi
;; LEF tag 128x4x20 dinh: SIZE rong 64 nhung 40 rail VDD/VSS M4 keo toi
;; x=65.768 (bi cat) va 42 M3 + 40 V3 cua VDD/VSS nam han o x=65.41..65.65
;; (bi bo).  256x4x32 khong co hinh nao ngoai SIZE.
;;
;; DON VI.  LEF la 4x, asap7_TechLib la 1x.  Script KHONG dung co don vi nao
;; cua strmout; no ve sao cho SO NGUYEN dbu trong GDS = toa do LEF x 1000:
;;     toa do ve (um) = toa do LEF x 1000 / DBUPerUU cua techlib
;; DBUPerUU = 4000 -> ve o 1x (= LEF/4), GDS ghi 4000 dbu/um: dung quy uoc cua
;; GDS std cell va srambank_*.gds, va cung day so nguyen voi top_soc.gds
;; (streamOut -units 1000, 4x).  Muon doc o 4x: gds_rescale.py --dbu 1000.
;;
;; CHUAN BI: tao library bang Library Manager > File > New > Library, chon
;; "Attach to an existing technology library" -> asap7_TechLib (vd SRAM_BB).
;; Phai tao qua GUI de library vao cds.lib - strmout chay ngoai doc cds.lib.
;;
;; CHAY trong CIW (Virtuoso mo tu thu muc co cds.lib):
;;   load("<repo>/Asap7/Script/virtuoso/sram_blackbox.il")
;;   bbMakeBlackBox("SRAM_BB" "<lef>/srambank_256x4x32_6t122.lef.4x.lef" "./bb_gds")
;;   bbMakeBlackBox("SRAM_BB" "<lef>/srambank_128x4x20_6t122.lef.4x.fixed.lef" "./bb_gds")
;; Ra bb_gds/<macro>.gds, <macro>.layermap, <macro>.strmout.log.
;; KIEM (ngoai Virtuoso):
;;   python check_blackbox_gds.py bb_gds/<macro>.gds <file lef>

;; So layer GDS - giong SOC_GDS_LAYERS (soc_fp_config.tcl) va calibreDRC.rul
bbGdsLayers = '(("M1" 19) ("V1" 21) ("M2" 20) ("V2" 25) ("M3" 30) ("V3" 35)
                ("M4" 40) ("V4" 45) ("M5" 50) ("V5" 55) ("M6" 60) ("V6" 65)
                ("M7" 70) ("V7" 75) ("M8" 80) ("V8" 85) ("M9" 90) ("V9" 95)
                ("Pad" 96))
bbBoundaryGds = 100
bbPinTextType = 251

;; ---------------------------------------------------------------- doc LEF
;; Tra ve DPL: ->macro ->size (w h) ->pins (theo thu tu trong LEF)
;;             ->rects[pin] = list((layer x0 y0 x1 y1) ...) ->skipped
procedure(bbParseLef(lefFile @optional macroName)
  let((ip line toks key state inProp done macro size pinNames pinTab
       curPin curLayer skipped r)
    unless(ip = infile(lefFile)
      error("bbParseLef: khong mo duoc %s\n" lefFile))
    state   = 'top
    pinTab  = makeTable("bbPins" nil)
    skipped = 0
    while(!done && gets(line ip)
      toks = parseString(line " \t\n\r;")
      when(toks
        key = car(toks)
        cond(
          ;; trong PROPERTYDEFINITIONS co dong "MACRO CatenaDesignType
          ;; STRING" - khong phai macro that
          (inProp
            when(key == "END" inProp = nil))
          (key == "PROPERTYDEFINITIONS"
            inProp = t)
          (state == 'top
            when(key == "MACRO" && (!macroName || cadr(toks) == macroName)
              macro = cadr(toks)
              state = 'macro))
          (state == 'macro
            cond(
              (key == "SIZE"
                size = list(atof(nth(1 toks)) atof(nth(3 toks))))
              (key == "PIN"
                curPin   = cadr(toks)
                pinNames = cons(curPin pinNames)
                state    = 'pin)
              (key == "OBS"
                state = 'obs)
              (key == "END" && cadr(toks) == macro
                done = t)))
          (state == 'pin
            cond(
              (key == "PORT" state = 'port)
              (key == "END"  state = 'macro)))
          (state == 'port
            cond(
              (key == "LAYER"
                curLayer = cadr(toks))
              (key == "RECT"
                r = cdr(toks)
                when(car(r) == "MASK" r = cddr(r))
                r = mapcar('atof r)
                pinTab[curPin] = cons(cons(curLayer r) pinTab[curPin]))
              (key == "END"
                state = 'pin)
              ;; POLYGON / VIA / ... : khong ve, dem de canh bao
              (t skipped = skipped + 1)))
          (state == 'obs
            when(key == "END" state = 'macro)))))
    close(ip)
    unless(macro
      error("bbParseLef: %s khong co MACRO %L\n" lefFile macroName))
    unless(size
      error("bbParseLef: MACRO %s khong co SIZE\n" macro))
    foreach(p pinNames pinTab[p] = reverse(pinTab[p]))
    list(nil 'macro macro 'size size 'pins reverse(pinNames)
         'rects pinTab 'skipped skipped)))

;; (x0 y0 x1 y1) -> goc duoi-trai truoc
procedure(bbNorm(r)
  list(min(nth(0 r) nth(2 r)) min(nth(1 r) nth(3 r))
       max(nth(0 r) nth(2 r)) max(nth(1 r) nth(3 r))))

;; cat vao [0,w]x[0,h]; nil neu nam han ngoai
procedure(bbClip(r w h)
  let((x0 y0 x1 y1)
    x0 = max(nth(0 r) 0.0)  y0 = max(nth(1 r) 0.0)
    x1 = min(nth(2 r) w)    y1 = min(nth(3 r) h)
    when(x1 > x0 && y1 > y0 list(x0 y0 x1 y1))))

;; ------------------------------------------------------- ve + stream out
procedure(bbMakeBlackBox(libName lefFile outDir @optional macroName)
  let((lef rects cell w h cv tf dbu f layers c n best bestA a nRect nClip nDrop
       nLabel lp mapFile op gds cmd ok)
    lef   = bbParseLef(lefFile macroName)
    cell  = lef->macro
    rects = lef->rects
    w     = car(lef->size)
    h     = cadr(lef->size)
    unless(ddGetObj(libName)
      error("Chua co library %s - tao bang Library Manager, attach asap7_TechLib, roi chay lai\n"
            libName))

    ;; layer can dung, va layer nao cung phai co trong techlib + bang GDS
    layers = nil
    foreach(p lef->pins
      foreach(r rects[p]
        unless(member(car(r) layers) layers = cons(car(r) layers))))
    layers = sort(layers 'alphalessp)
    foreach(l layers
      unless(assoc(l bbGdsLayers)
        error("Layer %s cua LEF khong co trong bbGdsLayers\n" l)))

    cv = dbOpenCellViewByType(libName cell "layout" "maskLayout" "w")
    unless(cv error("Khong mo duoc %s/%s/layout de ghi\n" libName cell))
    tf  = techGetTechFile(cv)
    dbu = cv~>DBUPerUU
    f   = 1000.0 / dbu
    foreach(l cons("BOUNDARY" layers)
      unless(techGetLayerNum(tf l)
        dbClose(cv)
        error("Techlib cua %s khong co layer %s - library co attach asap7_TechLib chua?\n"
              libName l)))

    ;; 1. bien = dien tich
    unless(dbCreateRect(cv list("BOUNDARY" "drawing")
                        list(list(0.0 0.0) list(w*f h*f)))
      dbClose(cv)
      error("Khong ve duoc BOUNDARY/drawing\n"))

    ;; 2. hinh chan + 3. nhan ten chan (dat o tam hinh metal lon nhat)
    nRect = 0  nClip = 0  nDrop = 0  nLabel = 0
    foreach(p lef->pins
      best  = nil
      bestA = -1.0
      foreach(r rects[p]
        n = bbNorm(cdr(r))
        c = bbClip(n w h)
        if(c then
          unless(c == n nClip = nClip + 1)
          unless(dbCreateRect(cv list(car(r) "drawing")
                   list(list(nth(0 c)*f nth(1 c)*f) list(nth(2 c)*f nth(3 c)*f)))
            dbClose(cv)
            error("Khong ve duoc %s/drawing (chan %s)\n" car(r) p))
          nRect = nRect + 1
          a = (nth(2 c) - nth(0 c)) * (nth(3 c) - nth(1 c))
          when(rexMatchp("^M[0-9]" car(r)) && a > bestA
            best  = cons(car(r) c)
            bestA = a)
        else
          nDrop = nDrop + 1))
      if(best then
        c = cdr(best)
        unless(dbCreateLabel(cv list(car(best) "label")
                 list((nth(0 c) + nth(2 c)) / 2.0 * f (nth(1 c) + nth(3 c)) / 2.0 * f)
                 p "centerCenter" "R0" "stick" 0.1 * f)
          dbClose(cv)
          error("Khong tao duoc nhan %s tren %s/label\n" p car(best)))
        nLabel = nLabel + 1
      else
        warn("Chan %s khong con hinh metal nao ben trong SIZE - khong co nhan\n" p)))
    dbSave(cv)
    dbClose(cv)

    ;; layermap rieng, chi gom layer da ve: *drawing -> dt 0, *label -> 251
    ;; (asap7.layermap co layer khong ton tai trong asap7_TechLib)
    unless(isDir(outDir) createDir(outDir))
    mapFile = sprintf(nil "%s/%s.layermap" outDir cell)
    op = outfile(mapFile)
    fprintf(op "# sinh boi sram_blackbox.il cho %s\n" cell)
    fprintf(op "BOUNDARY drawing %d 0\n" bbBoundaryGds)
    foreach(l layers
      lp = cadr(assoc(l bbGdsLayers))
      fprintf(op "%s drawing %d 0\n" l lp)
      when(rexMatchp("^M[0-9]" l)
        fprintf(op "%s label %d %d\n" l lp bbPinTextType)))
    close(op)

    gds = sprintf(nil "%s/%s.gds" outDir cell)
    cmd = sprintf(nil "strmout -library %s -topCell %s -view layout -strmFile %s -layerMap %s -logFile %s/%s.strmout.log"
                  libName cell gds mapFile outDir cell)
    printf("%s\n" cmd)
    ok = sh(cmd)

    printf("\n==== hop den %s\n" cell)
    printf("  LEF            : %s\n" lefFile)
    printf("  SIZE LEF (4x)  : %g x %g um\n" w h)
    printf("  DBUPerUU       : %g  -> ve %g x %g um trong Virtuoso\n" dbu w*f h*f)
    printf("  GDS mong doi   : %d x %d dbu (header %g dbu/um)\n"
           round(w * 1000) round(h * 1000) dbu)
    printf("  chan           : %d, nhan %d\n" length(lef->pins) nLabel)
    printf("  hinh chan      : %d ve, %d bi cat sat bien, %d bo (han ngoai SIZE)\n"
           nRect nClip nDrop)
    when(lef->skipped > 0
      warn("%d cau lenh trong PORT khong phai LAYER/RECT (POLYGON/VIA?) - KHONG ve\n"
           lef->skipped))
    printf("  strmout        : %s - doc %s/%s.strmout.log\n"
           if(ok "xong" "LOI") outDir cell)
    printf("  kiem           : python check_blackbox_gds.py %s %s\n" gds lefFile)
    ok))
