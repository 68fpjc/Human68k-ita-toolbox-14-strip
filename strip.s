* strip - strip symbol information from .X type executable file of Human68k
*
* Itagaki Fumihiko 14-Aug-92  Create.
*
* Usage: strip [ -p ] [ - ] <�t�@�C��> ...

.include doscall.h
.include error.h
.include limits.h
.include stat.h
.include chrcode.h

.xref DecodeHUPAIR
.xref strlen
.xref strfor1
.xref tfopen
.xref fclose

STACKSIZE	equ	256

FLAG_p		equ	0


.text
start:
		bra.s	start1
		dc.b	'#HUPAIR',0
start1:
		lea	stack_bottom(pc),a7		*  A7 := �X�^�b�N�̒�
		DOS	_GETPDB
		movea.l	d0,a0				*  A0 : PDB�A�h���X
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
		bsr	malloc
		bmi	insufficient_memory

		movea.l	d0,a1				*  A1 := �������ъi�[�G���A�̐擪�A�h���X
	*
	*  �������f�R�[�h���C���߂���
	*
		bsr	DecodeHUPAIR			*  �������f�R�[�h����
		movea.l	a1,a0				*  A0 : �����|�C���^
		move.l	d0,d7				*  D7.L : �����J�E���^
		moveq	#0,d5				*  D5.L : bit0:-p
decode_opt_loop1:
		tst.l	d7
		beq	decode_opt_done

		cmpi.b	#'-',(a0)
		bne	decode_opt_done

		subq.l	#1,d7
		addq.l	#1,a0
		move.b	(a0)+,d0
		beq	decode_opt_done
decode_opt_loop2:
		moveq	#FLAG_p,d1
		cmp.b	#'p',d0
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
		moveq	#0,d6				*  D6.W : �G���[�E�R�[�h
strip_arg_loop:
		bsr	strip
		bsr	strfor1
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
*****************************************************************
* strip - X�`���̎��s�\�t�@�C���̃V���{�������폜����
*
* CALL
*      A0     �t�@�C����
*
* RETURN
*      D1-D4/A1-A2   �j��
*****************************************************************
strip:
		moveq	#2,d0				*  �ǂݏ������[�h��
		bsr	tfopen				*  �t�@�C�����I�[�v������
		move.l	d0,d1				*  D1.L : �t�@�C���E�n���h��
		bmi	strip_perror

		bsr	is_chrdev			*  �L�����N�^�E�f�o�C�X�łȂ����ǂ������ׂ�
		bne	strip_chrdev

		clr.l	-(a7)
		move.w	d1,-(a7)
		DOS	_FILEDATE
		addq.l	#6,a7
		move.l	d0,d2				*  D2.L : �t�@�C���̃^�C���E�X�^���v
		cmp.l	#$ffff0000,d0
		bhs	strip_perror

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
		bne	strip_not_x			*  X�`���ł͂Ȃ�

		cmpi.b	#'H',0(a1)
		bne	strip_not_x			*  X�`���łȂ�

		cmpi.b	#'U',1(a1)
		bne	strip_not_x			*  X�`���łȂ�

		move.l	$001c(a1),d4			*  D4.L : �V���{���̃o�C�g��
		beq	strip_return			*  �V���{���͖���

		*  �V���{�������̃w�b�_����������
		clr.l	$001c(a1)
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

		btst	#0,d5
		beq	strip_return

		move.l	d2,-(a7)
		move.w	d1,-(a7)
		DOS	_FILEDATE
		addq.l	#6,a7
		cmp.l	#$ffff0000,d0
		bhs	strip_perror
strip_return:
		move.l	d1,d0
		bpl	fclose				*  return
		rts

strip_chrdev:
		lea	msg_is_device(pc),a2
		bsr	werror_myname_word_colon_msg
		bra	strip_return

strip_not_x:
		lea	msg_not_x(pc),a2
		bsr	werror_myname_word_colon_msg
		bra	strip_return

strip_perror:
		bsr	perror
		bra	strip_return
*****************************************************************
malloc:
		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		rts
*****************************************************************
is_chrdev:
		movem.l	d0,-(a7)
		move.w	d0,-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		tst.l	d0
		bpl	is_chrdev_1

		moveq	#0,d0
is_chrdev_1:
		btst	#7,d0
		movem.l	(a7)+,d0
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

		cmp.l	#256,d0
		blo	perror_1

		sub.l	#256,d0
		cmp.l	#4,d0
		bhi	perror_1

		lea	perror_table_2(pc),a2
		bra	perror_3

perror_1:
		moveq	#25,d0
perror_2:
		lea	perror_table(pc),a2
perror_3:
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
	dc.b	'## strip 1.0 ##  Copyright(C)1992 by Itagaki Fumihiko',0

.even
perror_table:
	dc.w	msg_error-sys_errmsgs			*   0 ( -1)
	dc.w	msg_nofile-sys_errmsgs			*   1 ( -2)
	dc.w	msg_nodir-sys_errmsgs			*   2 ( -3)
	dc.w	msg_too_many_openfiles-sys_errmsgs	*   3 ( -4)
	dc.w	msg_dir_vol-sys_errmsgs			*   4 ( -5)
	dc.w	msg_error-sys_errmsgs			*   5 ( -6)
	dc.w	msg_error-sys_errmsgs			*   6 ( -7)
	dc.w	msg_error-sys_errmsgs			*   7 ( -8)
	dc.w	msg_error-sys_errmsgs			*   8 ( -9)
	dc.w	msg_error-sys_errmsgs			*   9 (-10)
	dc.w	msg_error-sys_errmsgs			*  10 (-11)
	dc.w	msg_error-sys_errmsgs			*  11 (-12)
	dc.w	msg_bad_name-sys_errmsgs		*  12 (-13)
	dc.w	msg_error-sys_errmsgs			*  13 (-14)
	dc.w	msg_bad_drive-sys_errmsgs		*  14 (-15)
	dc.w	msg_error-sys_errmsgs			*  15 (-16)
	dc.w	msg_error-sys_errmsgs			*  16 (-17)
	dc.w	msg_error-sys_errmsgs			*  17 (-18)
	dc.w	msg_write_disabled-sys_errmsgs		*  18 (-19)
	dc.w	msg_error-sys_errmsgs			*  19 (-20)
	dc.w	msg_error-sys_errmsgs			*  20 (-21)
	dc.w	msg_error-sys_errmsgs			*  21 (-22)
	dc.w	msg_disk_full-sys_errmsgs		*  22 (-23)
	dc.w	msg_directory_full-sys_errmsgs		*  23 (-24)
	dc.w	msg_cannot_seek-sys_errmsgs		*  24 (-25)
	dc.w	msg_error-sys_errmsgs			*  25 (-26)

.even
perror_table_2:
	dc.w	msg_bad_drivename-sys_errmsgs		* 256 (-257)
	dc.w	msg_no_drive-sys_errmsgs		* 257 (-258)
	dc.w	msg_no_media_in_drive-sys_errmsgs	* 258 (-259)
	dc.w	msg_media_set_miss-sys_errmsgs		* 259 (-260)
	dc.w	msg_drive_not_ready-sys_errmsgs		* 260 (-261)

sys_errmsgs:
msg_error:		dc.b	'�G���[',0
msg_nofile:		dc.b	'���̂悤�ȃt�@�C���͂���܂���',0
msg_nodir:		dc.b	'���̂悤�ȃf�B���N�g���͂���܂���',0
msg_too_many_openfiles:	dc.b	'�I�[�v�����Ă���t�@�C�����������܂�',0
msg_dir_vol:		dc.b	'�f�B���N�g�����{�����[�����x���ł�',0
msg_bad_name:		dc.b	'���O�������ł�',0
msg_bad_drive:		dc.b	'�h���C�u�̎w�肪�����ł�',0
msg_write_disabled:	dc.b	'�������݂�������Ă��܂���',0
msg_disk_full:		dc.b	'�f�B�X�N�����t�ł�',0
msg_directory_full:	dc.b	'�f�B���N�g�������t�ł�',0
msg_cannot_seek:	dc.b	'�V�[�N�ł��܂���',0
msg_bad_drivename:	dc.b	'�h���C�u���������ł�',0
msg_no_drive:		dc.b	'�h���C�u������܂���',0
msg_no_media_in_drive:	dc.b	'�h���C�u�Ƀ��f�B�A���Z�b�g����Ă��܂���',0
msg_media_set_miss:	dc.b	'�h���C�u�Ƀ��f�B�A���������Z�b�g����Ă��܂���',0
msg_drive_not_ready:	dc.b	'�h���C�u�̏������ł��Ă��܂���',0

msg_myname:			dc.b	'strip'
msg_colon:			dc.b	': ',0
msg_no_memory:			dc.b	'������������܂���',CR,LF,0
msg_illegal_option:		dc.b	'�s���ȃI�v�V���� -- ',0
msg_too_few_args:		dc.b	'����������܂���',0
msg_is_device:			dc.b	'�L�����N�^�E�f�o�C�X�ł�',0
msg_not_x:			dc.b	'.X�^�C�v���s�\�`���t�@�C���ł͂���܂���',0
msg_usage:			dc.b	CR,LF,'�g�p�@:  strip [-p] [-] <�t�@�C��> ...'
msg_newline:			dc.b	CR,LF,0
*****************************************************************
.bss

buffer:			ds.b	64

.even
			ds.b	STACKSIZE
.even
stack_bottom:
*****************************************************************

.end start
