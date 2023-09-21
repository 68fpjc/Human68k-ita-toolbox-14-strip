* strip - strip symbol information from .X type executable file of Human68k
*
* Itagaki Fumihiko 20-Jan-93  Create.
* 1.0
* Itagaki Fumihiko 06-Feb-93  �t�@�C�������ɉߏ�� / ������Ώ�������
* 1.1
* Itagaki Fumihiko 01-Mar-93  �o�C���h����Ă���t�@�C����strip���Ȃ��悤�C��
* 1.2
* Itagaki Fumihiko 04-Jan-94  ���ߍ���ID���C��
* Itagaki Fumihiko 28-Aug-94  �I�v�V���� -f ��ǉ�
* 1.3
*
* Usage: strip [ -sSgpf ] [ -- ] <�t�@�C��> ...

.include doscall.h
.include error.h
.include limits.h
.include stat.h
.include chrcode.h

.xref DecodeHUPAIR
.xref getlnenv
.xref strlen
.xref strcmp
.xref strfor1
.xref strip_excessive_slashes

STACKSIZE	equ	2048

FLAG_p		equ	0
FLAG_g		equ	1
FLAG_f		equ	2

LNDRV_O_CREATE		equ	4*2
LNDRV_O_OPEN		equ	4*3
LNDRV_O_DELETE		equ	4*4
LNDRV_O_MKDIR		equ	4*5
LNDRV_O_RMDIR		equ	4*6
LNDRV_O_CHDIR		equ	4*7
LNDRV_O_CHMOD		equ	4*8
LNDRV_O_FILES		equ	4*9
LNDRV_O_RENAME		equ	4*10
LNDRV_O_NEWFILE		equ	4*11
LNDRV_O_FATCHK		equ	4*12
LNDRV_realpathcpy	equ	4*16
LNDRV_LINK_FILES	equ	4*17
LNDRV_OLD_LINK_FILES	equ	4*18
LNDRV_link_nest_max	equ	4*19
LNDRV_getrealpath	equ	4*20

.text
start:
		bra.s	start1
		dc.b	'#HUPAIR',0
start1:
		lea	stack_bottom(pc),a7		*  A7 := �X�^�b�N�̒�
		lea	$10(a0),a0			*  A0 : PDB�A�h���X
		move.l	a7,d0
		sub.l	a0,d0
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
	*
	*  �������ъi�[�G���A���m�ۂ���
	*
		lea	1(a2),a0			*  A0 := �R�}���h���C���̕�����̐擪�A�h���X
		bsr	strlen				*  D0.L := �R�}���h���C���̕�����̒���
		addq.l	#1,d0
		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	insufficient_memory

		movea.l	d0,a1				*  A1 := �������ъi�[�G���A�̐擪�A�h���X
	*
	*  lndrv ���g�ݍ��܂�Ă��邩�ǂ�������������
	*
		bsr	getlnenv
		move.l	d0,lndrv
	*
	*  �������f�R�[�h���C���߂���
	*
		moveq	#0,d6				*  D6.W : �G���[�E�R�[�h
		bsr	DecodeHUPAIR			*  �������f�R�[�h����
		movea.l	a1,a0				*  A0 : �����|�C���^
		move.l	d0,d7				*  D7.L : �����J�E���^
		subq.l	#1,d0
		bne	decode_opt_start

		lea	word_tease(pc),a1
		bsr	strcmp
		beq	strip_show

		lea	word_show(pc),a1
		bsr	strcmp
		beq	strip_show
decode_opt_start:
		moveq	#0,d5				*  D5.L : flags
decode_opt_loop1:
		tst.l	d7
		beq	decode_opt_done

		cmpi.b	#'-',(a0)
		bne	decode_opt_done

		tst.b	1(a0)
		beq	decode_opt_done

		subq.l	#1,d7
		addq.l	#1,a0
		move.b	(a0)+,d0
		cmp.b	#'-',d0
		bne	decode_opt_loop2

		tst.b	(a0)+
		beq	decode_opt_done

		subq.l	#1,a0
decode_opt_loop2:
		moveq	#FLAG_p,d1
		cmp.b	#'p',d0
		beq	set_option

		moveq	#FLAG_g,d1
		cmp.b	#'g',d0
		beq	set_option

		cmp.b	#'S',d0
		beq	set_option

		cmp.b	#'s',d0
		beq	clear_option

		moveq	#FLAG_f,d1
		cmp.b	#'f',d0
		beq	set_option

		lea	msg_illegal_option(pc),a0
		bsr	werror_myname_and_msg
		move.w	d0,-(a7)
		move.l	#1,-(a7)
		pea	5(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	12(a7),a7
		bra	usage

clear_option:
		bclr	d1,d5
		bra	set_option_done

set_option:
		bset	d1,d5
set_option_done:
		move.b	(a0)+,d0
		bne	decode_opt_loop2
		bra	decode_opt_loop1

decode_opt_done:
		tst.l	d7
		beq	too_few_args
	*
	*  �����J�n
	*
		move.w	#-1,-(a7)
		DOS	_BREAKCK
		addq.l	#2,a7
		move.w	d0,breakflag
strip_arg_loop:
		movea.l	a0,a1
		bsr	strfor1
		exg	a0,a1
		bsr	strip_excessive_slashes
		move.l	a1,-(a7)
		bsr	strip
		movea.l	(a7)+,a0
		subq.l	#1,d7
		bne	strip_arg_loop
****************
exit_program:
		move.w	d6,-(a7)
		DOS	_EXIT2

strip_error_exit:
		bsr	werror_myname_word_colon_msg
		bra	exit_program

too_few_args:
		lea	msg_too_few_args(pc),a0
		bsr	werror_myname_and_msg
usage:
		lea	msg_usage(pc),a0
		bsr	werror
		moveq	#1,d6
		bra	exit_program

insufficient_memory:
		lea	msg_no_memory(pc),a0
		bsr	werror_myname_and_msg
		moveq	#3,d6
		bra	exit_program

strip_show:
		pea	msg_show(pc)
		DOS	_PRINT
		addq.l	#4,a7
		bra	exit_program
*****************************************************************
* strip - �w�t�@�C���̃V���{�������폜����
*
* CALL
*      A0     �t�@�C����
*
* RETURN
*      D1-D4/A1-A3   �j��
*****************************************************************
strip:
		sf	breakflag_changed
		sf	mode_changed
		bsr	lgetmode
		bmi	strip_perror

		btst	#FLAG_f,d5
		beq	strip_open

		movea.l	a0,a3
		btst	#MODEBIT_LNK,d0
		beq	strip_chmod_relax

		move.l	lndrv,d0
		beq	strip_open

		movea.l	d0,a2
		movea.l	LNDRV_getrealpath(a2),a2
		lea	refname(pc),a1
		clr.l	-(a7)
		DOS	_SUPER				*  �X�[�p�[�o�C�U�E���[�h�ɐ؂芷����
		addq.l	#4,a7
		move.l	d0,-(a7)			*  �O�� SSP �̒l
		movem.l	d2-d7/a0-a1/a3-a6,-(a7)
		move.l	a0,-(a7)
		move.l	a1,-(a7)
		jsr	(a2)
		addq.l	#8,a7
		movem.l	(a7)+,d2-d7/a0-a1/a3-a6
		move.l	d0,d1
		DOS	_SUPER				*  ���[�U�E���[�h�ɖ߂�
		addq.l	#4,a7
		tst.l	d1
		bmi	strip_open

		exg	a0,a1
		bsr	lgetmode
		exg	a0,a1
		bmi	strip_open

		movea.l	a1,a3
strip_chmod_relax:
		move.b	d0,mode
		and.b	#(MODEVAL_DIR|MODEVAL_VOL|MODEVAL_LNK|MODEVAL_ARC|MODEVAL_EXE|MODEVAL_HID),d0
		cmp.b	mode,d0
		beq	strip_open

		exg	a0,a3
		bsr	chmod
		exg	a0,a3
		st	mode_changed
strip_open:
		move.w	#2,-(a7)			*  �ǂݏ������[�h��
		move.l	a0,-(a7)			*  �t�@�C����
		DOS	_OPEN				*  �I�[�v������
		addq.l	#6,a7
		move.l	d0,d1				*  D1.L : �t�@�C���E�n���h��
		bmi	strip_perror

		*  �^�C���X�^���v�𓾂�
		btst	#FLAG_p,d5
		beq	strip_timestamp_ok

			clr.l	-(a7)
			move.w	d1,-(a7)
			DOS	_FILEDATE
			addq.l	#6,a7
			move.l	d0,d2			*  D2.L : �t�@�C���̃^�C���E�X�^���v
			cmp.l	#$ffff0000,d0
			bhs	strip_perror
strip_timestamp_ok:
		lea	buffer(pc),a1
		moveq	#64,d3				*  �w�b�_64�o�C�g��ǂ�ł݂�
		move.l	d3,-(a7)
		move.l	a1,-(a7)
		move.w	d1,-(a7)
		DOS	_READ
		lea	10(a7),a7
		tst.l	d0
		bmi	strip_perror

		cmp.l	d3,d0				*  64�o�C�g�ǂ߂Ȃ������Ȃ�
		bne	strip_not_x			*  �w�t�@�C���ł͂Ȃ�

		cmpi.w	#'HU',0(a1)
		bne	strip_not_x			*  �w�t�@�C���łȂ�

		tst.l	$003c(a1)			*  �o�C���h����Ă���Ȃ�
		bne	cannot_strip_boundfile		*  strip�ł��Ȃ�

		move.l	$0020(a1),d4			*  SCD line number table
		add.l	$0024(a1),d4			*  SCD information
		bcs	strip_not_x

		add.l	$0028(a1),d4			*  SCD name table
		bcs	strip_not_x

		move.l	$001c(a1),d0			*  symbol
		add.l	d4,d0
		bcs	strip_not_x

		btst	#FLAG_g,d5
		bne	test_strip

		move.l	d0,d4
test_strip:
		tst.l	d4
		beq	strip_return

		tst.w	breakflag
		beq	not_change_breakflag

		cmpi.w	#2,breakflag
		beq	not_change_breakflag

		clr.w	-(a7)
		DOS	_BREAKCK			*  BREAK OFF
		addq.l	#2,a7
		st	breakflag_changed
not_change_breakflag:
		*  �w�b�_����������
		btst	#FLAG_g,d5
		bne	not_clear_symbol

		clr.l	$001c(a1)
not_clear_symbol:
		clr.l	$0020(a1)
		clr.l	$0024(a1)
		clr.l	$0028(a1)
		clr.w	-(a7)
		clr.l	-(a7)
		move.w	d1,-(a7)
		DOS	_SEEK
		addq.l	#8,a7
		tst.l	d0
		bmi	strip_perror

		move.l	d3,-(a7)
		move.l	a1,-(a7)
		move.w	d1,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		tst.l	d0
		bmi	strip_perror

		*  �V���{�����폜����
		neg.l	d4
		move.w	#2,-(a7)
		move.l	d4,-(a7)
		move.w	d1,-(a7)
		DOS	_SEEK
		addq.l	#8,a7
		tst.l	d0
		bmi	strip_perror

		clr.l	-(a7)
		move.l	a1,-(a7)
		move.w	d1,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		tst.l	d0
		bmi	strip_perror

		*  �^�C���X�^���v���Đݒ肷��
		btst	#FLAG_p,d5
		beq	strip_return

		move.l	d2,-(a7)
		move.w	d1,-(a7)
		DOS	_FILEDATE
		addq.l	#6,a7
		cmp.l	#$ffff0000,d0
		bhs	strip_perror
strip_return:
		tst.l	d1
		bmi	strip_close_ok

		move.w	d1,-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
strip_close_ok:
		tst.b	mode_changed
		beq	strip_resume_mode_ok

		move.b	mode,d0
		exg	a0,a3
		bsr	chmod
		exg	a0,a3
strip_resume_mode_ok:
		tst.b	breakflag_changed
		beq	strip_resume_breakflag_ok

		move.w	breakflag,-(a7)
		DOS	_BREAKCK
		addq.l	#2,a7
strip_resume_breakflag_ok:
		rts


cannot_strip_boundfile:
		lea	msg_cannot_strip_boundfile(pc),a2
		bra	strip_error

strip_not_x:
		lea	msg_not_x(pc),a2
strip_error:
		bsr	werror_myname_word_colon_msg
		bra	strip_return

strip_perror:
		bsr	perror
		bra	strip_return
****************************************************************
* lgetmode - �t�@�C���̑����𓾂�
*
* CALL
*      A0     �p�X��
*
* RETURN
*      D0.L   OS���^�[���R�[�h
*             (�����Ȃ�Ή��� 1�o�C�g���t�@�C���̑���)
*      CCR    TST.L D0
****************************************************************
****************************************************************
* chmod - �t�@�C���̑�����ύX����
*
* CALL
*      A0     �p�X��
*      D0.B   �ύX���郂�[�h
*
* RETURN
*      D0.L   OS���^�[���R�[�h
*      CCR    TST.L D0
****************************************************************
lgetmode:
		moveq	#-1,d0
chmod:
		move.w	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_CHMOD
		addq.l	#6,a7
		tst.l	d0
chmod_done:
		rts
*****************************************************************
werror_myname_and_msg:
		move.l	a0,-(a7)
		lea	msg_myname(pc),a0
		bsr	werror
		movea.l	(a7)+,a0
werror:
		movem.l	d0/a1,-(a7)
		movea.l	a0,a1
werror_1:
		tst.b	(a1)+
		bne	werror_1

		subq.l	#1,a1
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		movem.l	(a7)+,d0/a1
		rts
*****************************************************************
werror_myname_word_colon_msg:
		bsr	werror_myname_and_msg
		move.l	a0,-(a7)
		lea	msg_colon(pc),a0
werror_word_msg_and_set_error:
		bsr	werror
		movea.l	a2,a0
		bsr	werror
		lea	msg_newline(pc),a0
		bsr	werror
		movea.l	(a7)+,a0
		moveq	#2,d6
		rts
*****************************************************************
perror:
		movem.l	d0/a2,-(a7)
		not.l	d0		* -1 -> 0, -2 -> 1, ...
		cmp.l	#25,d0
		bls	perror_2

		moveq	#0,d0
perror_2:
		lea	perror_table(pc),a2
		lsl.l	#1,d0
		move.w	(a2,d0.l),d0
		lea	sys_errmsgs(pc),a2
		lea	(a2,d0.w),a2
		bsr	werror_myname_word_colon_msg
		movem.l	(a7)+,d0/a2
		tst.l	d0
		rts
*****************************************************************
.data

	dc.b	0
	dc.b	'## strip 1.3 ##  Copyright(C)1993-94 by Itagaki Fumihiko',0

.even
perror_table:
	dc.w	msg_error-sys_errmsgs			*   0 ( -1)
	dc.w	msg_nofile-sys_errmsgs			*   1 ( -2)
	dc.w	msg_nofile-sys_errmsgs			*   2 ( -3)
	dc.w	msg_too_many_openfiles-sys_errmsgs	*   3 ( -4)
	dc.w	msg_not_x-sys_errmsgs			*   4 ( -5)
	dc.w	msg_error-sys_errmsgs			*   5 ( -6)
	dc.w	msg_error-sys_errmsgs			*   6 ( -7)
	dc.w	msg_error-sys_errmsgs			*   7 ( -8)
	dc.w	msg_error-sys_errmsgs			*   8 ( -9)
	dc.w	msg_error-sys_errmsgs			*   9 (-10)
	dc.w	msg_error-sys_errmsgs			*  10 (-11)
	dc.w	msg_error-sys_errmsgs			*  11 (-12)
	dc.w	msg_bad_name-sys_errmsgs		*  12 (-13)
	dc.w	msg_error-sys_errmsgs			*  13 (-14)
	dc.w	msg_bad_name-sys_errmsgs		*  14 (-15)
	dc.w	msg_error-sys_errmsgs			*  15 (-16)
	dc.w	msg_error-sys_errmsgs			*  16 (-17)
	dc.w	msg_error-sys_errmsgs			*  17 (-18)
	dc.w	msg_write_disabled-sys_errmsgs		*  18 (-19)
	dc.w	msg_error-sys_errmsgs			*  19 (-20)
	dc.w	msg_error-sys_errmsgs			*  20 (-21)
	dc.w	msg_error-sys_errmsgs			*  21 (-22)
	dc.w	msg_error-sys_errmsgs			*  22 (-23)
	dc.w	msg_error-sys_errmsgs			*  23 (-24)
	dc.w	msg_cannot_seek-sys_errmsgs		*  24 (-25)
	dc.w	msg_error-sys_errmsgs			*  25 (-26)

sys_errmsgs:
msg_error:		dc.b	'�G���[',0
msg_nofile:		dc.b	'���̂悤�ȃt�@�C���͂���܂���',0
msg_too_many_openfiles:	dc.b	'�I�[�v�����Ă���t�@�C�����������܂�',0
msg_bad_name:		dc.b	'���O�������ł�',0
msg_write_disabled:	dc.b	'�������݂�������Ă��܂���',0
msg_cannot_seek:	dc.b	'�V�[�N�ł��܂���',0

msg_myname:			dc.b	'strip'
msg_colon:			dc.b	': ',0
word_show:			dc.b	'-show',0
word_tease:			dc.b	'-tease',0
msg_no_memory:			dc.b	'������������܂���',CR,LF,0
msg_illegal_option:		dc.b	'�s���ȃI�v�V���� -- ',0
msg_too_few_args:		dc.b	'����������܂���',0
msg_not_x:			dc.b	'�w�t�@�C���ł͂���܂���',0
msg_cannot_strip_boundfile:	dc.b	'�o�C���h����Ă��܂�',0
msg_usage:			dc.b	CR,LF,'�g�p�@:  strip [-sSgpf] [--] <�t�@�C��> ...'
msg_newline:			dc.b	CR,LF,0
msg_show:	dc.b	'strip tease�kshow�ln. �X�g���b�v�V���[. ���ǂ�q�����y�ɍ��킹�Ȃ���ߏւ��ʂ����Ă鉉�|.',CR,LF,0
*****************************************************************
.bss

.even
lndrv:			ds.l	1
breakflag:		ds.w	1
breakflag_changed:	ds.b	1
mode:			ds.b	1
mode_changed:		ds.b	1
refname:		ds.b	128
.even
buffer:			ds.b	64

.even
			ds.b	STACKSIZE
.even
stack_bottom:
*****************************************************************

.end start
