;; sram_bb_from_abstract.il - bien view abstract (do LEF In tao tu .fixed.lef 1x)
;; thanh view layout "hop den" de strmout ra GDS cho 2 SRAM khong co GDS.
;; Cach lam tay tuong duong sram_blackbox.il (cung nguon LEF), kiem ket qua
;; bang check_blackbox_gds.py.
;;
;; Trong CIW:
;;   load("<REPO>/Asap7/Script/virtuoso/sram_bb_from_abstract.il")
;;   bbListLpp("SRAM_BB" "srambank_128x4x20_6t122")      ; xem LEF In dat purpose gi
;;   bbFromAbstract("SRAM_BB" "srambank_128x4x20_6t122")  ; ky vong 16 x 30.24, 60 nhan
;;   bbFromAbstract("SRAM_BB" "srambank_256x4x32_6t122")  ; ky vong 30.348 x 43.2, 80 nhan
;;
;; Moi lan chay CHEP LAI abstract -> layout (ghi de), nen sua loi xong chay lai
;; bao nhieu lan cung duoc.  Dong cua so dang mo view layout truoc khi chay.
;; Neu abstract khong co prBoundary: bbFromAbstract("SRAM_BB" cell W H) voi W H
;; lay tu dong SIZE cua LEF.

;; In moi layer/purpose trong view (mac dinh abstract) + prBoundary, blockage.
procedure(bbListLpp(lib cell @optional (view "abstract"))
  let((cv)
    cv = dbOpenCellViewByType(lib cell view nil "r")
    unless(cv error("Khong mo duoc %s/%s/%s\n" lib cell view))
    printf("%s/%s/%s: prBoundary %L, %d blockage, %d terminal\n"
           lib cell view cv~>prBoundary && cv~>prBoundary~>bBox
           length(cv~>blockages) length(cv~>terminals))
    foreach(lpp cv~>lpps
      printf("  %-9s %-10s %5d hinh\n"
             lpp~>layerName lpp~>purpose length(lpp~>shapes)))
    dbClose(cv)
    t))

procedure(bbFromAbstract(lib cell @optional w h)
  let((src cv bb nPin nDel nClip nLbl x0 y0 x1 y1 key fig name tbl)
    src = dbOpenCellViewByType(lib cell "abstract" nil "r")
    unless(src error("Chua co %s/%s/abstract - chay LEF In truoc\n" lib cell))
    unless(dbCopyCellView(src lib cell "layout" nil nil t)
      error("Chep abstract -> layout that bai (view layout dang mo? dong lai)\n"))
    dbClose(src)
    cv = dbOpenCellViewByType(lib cell "layout" nil "a")
    unless(cv error("Khong mo duoc %s/%s/layout de sua\n" lib cell))

    ;; kich thuoc hop = prBoundary (= SIZE cua LEF, ORIGIN 0 0)
    unless(w && h
      unless(cv~>prBoundary
        error("Khong co prBoundary - goi lai: bbFromAbstract(%L %L W H)\n" lib cell))
      bb = cv~>prBoundary~>bBox
      w = xCoord(upperRight(bb))
      h = yCoord(upperRight(bb)))

    ;; phai con hinh cua chan, khong thi xoa het se ra hop rong
    nPin = length(setof(s cv~>shapes s~>objType == "rect" && s~>pin))
    when(nPin == 0
      error("Khong thay hinh nao gan voi pin - gui ket qua bbListLpp cho kiem tra\n"))

    ;; a) bo vung cam (OBS): hop den khong co ben trong
    foreach(b cv~>blockages dbDeleteObject(b))

    ;; b) chi giu rect cua chan, cat vao SIZE; xoa OBS dang hinh, label cu...
    ;;    (LEF tag co rail M4 toi x=16.442 va M3/V3 nam han ngoai x=16)
    nDel = 0  nClip = 0
    tbl = makeTable("bbPinFig" nil)
    foreach(s cv~>shapes
      if(s~>objType != "rect" || !s~>pin
      then dbDeleteObject(s)  nDel = nDel + 1
      else
        x0 = max(xCoord(lowerLeft(s~>bBox)) 0)
        y0 = max(yCoord(lowerLeft(s~>bBox)) 0)
        x1 = min(xCoord(upperRight(s~>bBox)) w)
        y1 = min(yCoord(upperRight(s~>bBox)) h)
        if(x1 <= x0 || y1 <= y0
        then dbDeleteObject(s)  nDel = nDel + 1
        else
          when(s~>bBox != list(x0:y0 x1:y1)
            s~>bBox = list(x0:y0 x1:y1)
            nClip = nClip + 1)
          ;; nho 1 hinh con lai cho moi chan de dat nhan len
          key = s~>pin~>term~>name
          unless(tbl[key] tbl[key] = s))))

    ;; c) khung dien tich BOUNDARY 100/0 = SIZE
    unless(dbCreateRect(cv list("BOUNDARY" "drawing") list(0:0 w:h))
      error("Khong tao duoc BOUNDARY/drawing - techlib khong co layer nay?\n"))

    ;; d) 1 nhan moi chan, purpose label (-> texttype 251).  LEF In doi
    ;;    ADDRESS[3] thanh ADDRESS<3>; nhan GDS phai giu ten LEF [].
    nLbl = 0
    foreach(k tbl
      fig = tbl[k]
      rexCompile("<")  name = rexReplace(k "[" 0)
      rexCompile(">")  name = rexReplace(name "]" 0)
      unless(dbCreateLabel(cv list(fig~>layerName "label") centerBox(fig~>bBox)
                           name "centerCenter" "R0" "stick" 0.1)
        error("Khong tao duoc nhan %s tren %s/label\n" name fig~>layerName))
      nLbl = nLbl + 1)

    unless(dbSave(cv) error("dbSave %s/%s/layout that bai\n" lib cell))
    dbClose(cv)
    printf("%s: hop %g x %g um | %d hinh chan ban dau, xoa %d, cat %d | %d nhan\n"
           cell w h nPin nDel nClip nLbl)
    t))
