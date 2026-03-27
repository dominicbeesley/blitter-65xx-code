
	.struct point
		PX	.byte
		PY	.byte
	.endstruct

	.struct size
		W	.byte
		H	.byte
	.endstruct

	.struct rectangle
		topleft	.tag	point
		size	.tag	size
	.endstruct