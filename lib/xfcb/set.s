; CP/M-65 Copyright © 2022 David Given
; This file is licensed under the terms of the 2-clause BSD license. Please
; see the COPYING file in the root project directory for the full text.

	.include "xfcb.inc"
	.include "cpm65.inc"

	.importzp __fcb

.export xfcb_set
xfcb_set:
	sta __fcb+0
	stx __fcb+1
	rts

