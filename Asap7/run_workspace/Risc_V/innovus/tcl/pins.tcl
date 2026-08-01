setPinAssignMode -pinEditInBatch true

# Bottom - Metal7 Vertical
editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -spreadType side \
-spreadDirection counterclockwise -side BOTTOM -layer M7 -honorConstraint 1 \
-pin { iclk iA[31] iA[30] iA[29] iA[28] iA[27] iA[26] iA[25] iA[24] iA[23] iA[22] iA[21] iA[20] iA[19] iA[18] iA[17] iA[16] iA[15] iA[14] iA[13] iA[12] iA[11] iA[10] iA[9] iA[8] iA[7] iA[6] iA[5] iA[4] iA[3] iA[2] iA[1] iA[0] }

# Right - Metal6 Horizontal
editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -spreadType side \
-spreadDirection counterclockwise -side RIGHT -layer M6 -honorConstraint 1 \
-pin { iB[31] iB[30] iB[29] iB[28] iB[27] iB[26] iB[25] iB[24] iB[23] iB[22] iB[21] iB[20] iB[19] iB[18] iB[17] iB[16] iB[15] iB[14] iB[13] iB[12] iB[11] iB[10] iB[9] iB[8] iB[7] iB[6] iB[5] iB[4] iB[3] iB[2] iB[1] iB[0] }

# Top - Metal7 Vertical
editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -spreadType side \
-spreadDirection counterclockwise -side TOP -layer M7 -honorConstraint 1 \
-pin {rst_n oP[63] oP[62] oP[61] oP[60] oP[59] oP[58] oP[57] oP[56] oP[55] oP[54] oP[53] oP[52] oP[51] oP[50] oP[49] oP[48] oP[47] oP[46] oP[45] oP[44] oP[43] oP[42] oP[41] oP[40] oP[39] oP[38] oP[37] oP[36] oP[35] oP[34] oP[33] oP[32] }

# Left - Metal6 Horizontal
editPin -pinWidth 0.128 -pinDepth 0.288 -fixOverlap 1 -spreadType side \
-spreadDirection counterclockwise -side LEFT -layer M6 -honorConstraint 1 \
-pin { oP[31] oP[30] oP[29] oP[28] oP[27] oP[26] oP[25] oP[24] oP[23] oP[22] oP[21] oP[20] oP[19] oP[18] oP[17] oP[16] oP[15] oP[14] oP[13] oP[12] oP[11] oP[10] oP[9] oP[8] oP[7] oP[6] oP[5] oP[4] oP[3] oP[2] oP[1] oP[0] }

setPinAssignMode -pinEditInBatch false
