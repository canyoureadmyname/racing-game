TITLE 	group_48 of ASM       (group_48.ASM)

INCLUDE Irvine32.inc

main          EQU start@0
;------------------------------
GetStdHandle PROTO,
	nStdHandle:DWORD
SetConsoleCursorInfo PROTO,
	hConsoleOutput:DWORD, lpConsoleCursorInfo:PTR CONSOLE_CURSOR_INFO
SetCars PROTO,
	xpos:DWORD, ypos:DWORD
SetOpponents PROTO,
	ypos:DWORD, NumOfCars:DWORD, OpoMode:DWORD
PrintOpponents PROTO
MovOpponents PROTO
PlayerCarMov PROTO
IsCrash PROTO		;return in ebx
CarsDataGenerator PROTO,
	indexI:DWORD
CheckTime PROTO

PrintBoundary MACRO
  mov al, '|'
  mov dl, 13
  mov dh, 0
  mov ecx, 24
  Print_B:
    call Gotoxy
    call WriteChar
    inc dh
  LOOP Print_B
ENDM

MYTimer STRUCT
  StartT DWORD ? ;from midnight to the time when the game starting 
  NowT DWORD 0	;from the game starting to now timer
  LastAcT DWORD 0	;last accelerate recording time
  LastMovT DWORD 0	;last cars moving recoeding time
  WaitTime DWORD 500	;need delay time to control moving speed 
MYTimer ENDS

.data
hOut DWORD ?
TrackX = 0	;Race Track up-left
TrackY = 0	;Race Track up-left
Car_1 BYTE "  #  ",0
Car_2 BYTE " @#@ ",0
Cleaner BYTE 13 DUP(" "),0	;use to clean track
PlayerCleaner BYTE 4 DUP(" "),0
NowCarsData DWORD 9 DUP(?)	;int NowCarsData[3][3];//The first index = Cars which in console screen are at most 3
                      			;And the second index = 3 parameters of the function SetOpponents()
CarsDataSwitch DWORD 3 DUP(0)	;if that index value is true ,it means that index of NowCarsDara should be read
PlayerXpos DWORD 4	;record now the player car xpos 
GameEnd BYTE "GAME OVER!!",0
TimerString BYTE "time:  ",0
ScoreString BYTE "score: ",0
HighString BYTE "high score:",0
NewHighString BYTE "<NEW HIGH SCORE>",0
NowScore DWORD 0
HighScore DWORD 0
TheTime MYTimer <>
Cursorinfo CONSOLE_CURSOR_INFO <1,0>

.code
main PROC
  INVOKE GetStdHandle, STD_OUTPUT_HANDLE
  mov hOut, eax
  INVOKE SetConsoleCursorInfo, hOut, ADDR Cursorinfo	;make cursor invisible
  NewGame:
  PrintBoundary
  call Randomize			;= srand
  INVOKE SetCars, PlayerXpos, 20	;print player car
  INVOKE CarsDataGenerator, 0		;initial random value
  INVOKE CarsDataGenerator, 1
  INVOKE CarsDataGenerator, 2
  mov NowCarsData[(0*3+0)*4], -3	;from the top go down
  mov NowCarsData[(1*3+0)*4], 7
  mov NowCarsData[(2*3+0)*4], 17
  mov CarsDataSwitch[0*4], 1		;at first, only one row appears
  mov CarsDataSwitch[1*4], 0
  mov CarsDataSwitch[2*4], 0

  mov dl, 30
  mov dh, 12
  call Gotoxy
  call WaitMsg
  mov dl, 30
  mov dh, 12
  call Gotoxy
  mov ecx, 3
  WashOut:
    mov edx, OFFSET Cleaner
    call WriteString
  LOOP WashOut
  call GetMseconds
  mov TheTime.StartT, eax	;get the game starting time
  call PrintOpponents
  mov dl, 15			;----------------
  mov dh, 6
  call Gotoxy
  mov edx, OFFSET HighString	
  call WriteString		;print high score
  mov eax, HighScore
  call WriteDec			;----------------
  LoopMain:
    call CheckTime
    mov dl, 15
    mov dh, 3
    call Gotoxy
    mov edx, OFFSET TimerString
    call WriteString
    mov eax, TheTime.NowT
    mov edx, 0
    mov ebx, 1000
    div ebx		;millisecond->second
    call WriteDec	;print the timer
    mov dl, 15			;--------
    mov dh, 4	
    call Gotoxy			;print score
    mov edx, OFFSET ScoreString
    call WriteString
    mov eax, TheTime.NowT	;score=NowT+(500-WaitTime)*16
    mov ebx, 500
    sub ebx, TheTime.WaitTime
    shl ebx, 4
    add eax, ebx
    mov NowScore, eax 
    call WriteDec		;--------	
    mov eax, TheTime.NowT	;--------------------
    sub eax, TheTime.LastAcT
    .IF eax >= 5000		;when through 5s
      mov eax, TheTime.WaitTime	;smaller WaitTime
      shr eax, 1
      .IF eax == 0
        mov eax, 1
      .ENDIF
      mov TheTime.WaitTime, eax
      mov eax, TheTime.NowT	;update record
      mov TheTime.LastAcT, eax
    .ENDIF			;--------------------
    mov eax, TheTime.NowT	;------------------------
    sub eax, TheTime.LastMovT	;now-lastmov > WaitTime (through WaitTime ms),then can go
    cmp eax, TheTime.WaitTime
    jb LoopMain
    mov eax, TheTime.NowT	;update the record
    mov TheTime.LastMovT, eax	;------------------------
    call PlayerCarMov
    call IsCrash
    cmp ebx, 1
    jz NextL
    call MovOpponents
    INVOKE SetCars, PlayerXpos, 20
    call PrintOpponents
    call IsCrash
    cmp ebx, 1
    jz NextL
  jmp LoopMain
  NextL:
    mov dl, 42
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET GameEnd
    call WriteString
    mov eax, NowScore
    .IF HighScore < eax		;--------
      mov HighScore, eax	;update high score
      mov dl, 15		
      mov dh, 6
      call Gotoxy
      mov edx, OFFSET HighString	
      call WriteString		;print high score
      mov eax, HighScore
      call WriteDec
      mov dl, 15
      mov dh, 7
      call Gotoxy
      mov edx, OFFSET NewHighString	;print new high string
      call WriteString
    .ENDIF			;--------
    mov dl, 45
    mov dh, 24
    call Gotoxy
    mov eax, 500
    call Delay
    call WaitMsg
    mov eax, 0			;before new game initialize some value
    mov TheTime.LastAcT, eax
    mov TheTime.LastMovT, eax
    mov NowScore, eax
    mov eax, 500
    mov TheTime.WaitTime, eax
    mov eax, 4
    mov PlayerXpos, eax
    call Clrscr			;clean console screen
    jmp NewGame	
	exit
main ENDP

;print a car
SetCars PROC USES edx,
	xpos:DWORD, ypos:DWORD	
	LOCAL CeilingVal:SBYTE, FloorVal:SBYTE	;in order to use .IF by sign-value comparing
  mov CeilingVal, 23
  mov FloorVal, 0	
  mov dl, BYTE PTR xpos
  mov dh, BYTE PTR ypos
  .IF dh > CeilingVal		;dh range in 0~23, otherwise it don't print
    ret
  .ENDIF
  cmp dh, FloorVal
  jl NEXT_1
  call Gotoxy
  mov edx, OFFSET Car_1
  call WriteString
  NEXT_1:
    mov dl, BYTE PTR xpos
    mov dh, BYTE PTR ypos
    inc dh
    .IF dh > CeilingVal
      ret
    .ENDIF
    cmp dh, FloorVal
    jl NEXT_2
    call Gotoxy
    mov edx, OFFSET Car_2
    call WriteString
  NEXT_2:
    mov dl, BYTE PTR xpos
    mov dh, BYTE PTR ypos
    add dh, 2
    .IF dh > CeilingVal
      ret
    .ENDIF
    cmp dh, FloorVal
    jl NEXT_3
    call Gotoxy
    mov edx, OFFSET Car_1
    call WriteString
  NEXT_3:
    mov dl, BYTE PTR xpos
    mov dh, BYTE PTR ypos
    add dh, 3
    .IF dh > CeilingVal || dh < FloorVal
      ret
    .ENDIF
    call Gotoxy
    mov edx, OFFSET Car_2
    call WriteString
  ret
SetCars ENDP

;create a row of opponents
SetOpponents PROC USES eax ecx esi,
	ypos:DWORD, NumOfCars:DWORD, OpoMode:DWORD
	LOCAL arrange[18]:DWORD, xpos:DWORD	
  mov arrange[0*TYPE arrange], 1		;int arrange[6][3]={{1,2,3},{1,3,2},{2,1,3},{2,3,1},{3,1,2},{3,2,1}}
  mov arrange[1*4], 2		;Opponent cars arrange mode
  mov arrange[2*4], 3
  mov arrange[3*4], 1
  mov arrange[4*4], 3
  mov arrange[5*4], 2
  mov arrange[6*4], 2
  mov arrange[7*4], 1
  mov arrange[8*4], 3
  mov arrange[9*4], 2
  mov arrange[10*4], 3
  mov arrange[11*4], 1
  mov arrange[12*4], 3
  mov arrange[13*4], 1
  mov arrange[14*4], 2
  mov arrange[15*4], 3
  mov arrange[16*4], 2
  mov arrange[17*4], 1
  mov ecx, NumOfCars
  L:
    mov esi, OpoMode 	;esi=(OpoMode-1)*3+(ecx-1)
    dec esi
    mov eax, esi
    shl esi, 1
    add esi, eax
    add esi, ecx
    dec esi
    mov eax, arrange[esi*TYPE arrange]	;xpos=(arrange[esi]-1)*4
    mov xpos, eax
    dec xpos
    shl xpos, 2
    INVOKE SetCars, xpos, ypos
  LOOP L
  ret
SetOpponents ENDP

PrintOpponents PROC USES eax ecx esi
	LOCAL ypos:DWORD, NumOfCars:DWORD, OpoMode:DWORD, VisibleY:SDWORD, indexI:DWORD
  mov VisibleY, 23
  mov ecx, 3
  L:
    mov esi, ecx
    dec esi
    mov indexI, esi
    .IF CarsDataSwitch[esi* TYPE CarsDataSwitch] == 1	;if switch off => next
      mov eax, esi	;esi=esi*3
      shl esi, 1
      add esi, eax	
      mov eax, NowCarsData[esi* TYPE NowCarsData]	;ypos=NowCarsData[i][0]
      mov ypos, eax
      .IF eax > VisibleY
        push esi
        mov esi, indexI
        mov CarsDataSwitch[esi* TYPE CarsDataSwitch], 0	;set cannot be visible (using for IsCrash PROC)
        pop esi
      .ENDIF
      inc esi
      mov eax, NowCarsData[esi* TYPE NowCarsData]	;NumOfCars=NowCarsData[i][1]
      mov NumOfCars, eax
      inc esi
      mov eax, NowCarsData[esi* TYPE NowCarsData]	;OpoMode=NowCarsData[i][2]
      mov OpoMode, eax
      INVOKE SetOpponents, ypos, NumOfCars, OpoMode
    .ENDIF
  LOOP L
  ret
PrintOpponents ENDP

;make opponents cars down 1 row
MovOpponents PROC USES eax ecx edx esi
	LOCAL indexI:DWORD, CeilingVal:SDWORD
  mov CeilingVal, 25
  mov ecx, 24
  L1:
    mov dl, TrackX		;----clean the track----
    mov dh, TrackY
    add dh, cl
    dec dh
    call Gotoxy
    mov edx , OFFSET Cleaner
    call WriteString
  LOOP L1			;----clean the track----
  mov ecx, 3
  L2:				;every opponent ypos +1	
    mov esi,ecx		
    dec esi	
    mov indexI, esi
    mov eax, esi	;esi=esi*3
    shl esi, 1
    add esi, eax
    mov eax, NowCarsData[esi* TYPE NowCarsData]		;eax=NowCarsData[i][0]
    .IF eax > CeilingVal
      INVOKE CarsDataGenerator, indexI			;become new row and generate new car data
      mov NowCarsData[esi* TYPE NowCarsData], -3	;after the lowest point go to the top
    .ELSE
      inc NowCarsData[esi* TYPE NowCarsData]	;NowCarsData[i][0]+=1
    .ENDIF
  LOOP L2
  ret
MovOpponents ENDP

;arrow keylistener
PlayerCarMov PROC USES eax ecx edx
  mov eax, 50		;sleep, to allow OS to time slice. otherwise, some key presses are lost
  call Delay
  call ReadKey
  mov eax, PlayerXpos
  jz  NoPress
  .IF dx == VK_LEFT
    .IF eax != 0
      sub eax, 4	;if not at most left playerXpos move left 1 unit
      jmp ThereIsMov
    .ENDIF
  .ELSEIF dx == VK_RIGHT
    .IF eax != 8
      add eax, 4	;if not at most right playerXpos move right 1 unit
      jmp ThereIsMov
    .ENDIF
  .ENDIF
  jmp NoPress		;if cannot mov
  ThereIsMov:
    mov ecx, 4
    L1:
      mov dl, BYTE PTR PlayerXpos			;---clean player car---
      mov dh, 20
      add dh, cl
      dec dh
      call Gotoxy
      mov edx, OFFSET PlayerCleaner
      call WriteString
    LOOP L1						;---clean player car---
    mov PlayerXpos, eax 
    INVOKE SetCars, PlayerXpos, 20
  NoPress:   
  ret
PlayerCarMov ENDP

;when Opponents ypos+3 >= the player ypos then it may crash
;if crash return ebx =1,else ebx =0
IsCrash PROC USES eax ecx esi
	LOCAL OpoArrange[18]:DWORD, OpoNumOfCars:DWORD, OpoMode:DWORD, OpoXpos:SDWORD,
		CrashY:SDWORD
  mov CrashY, 20
  mov OpoArrange[0*TYPE OpoArrange], 1		;int OpoArrange[6][3]={{1,2,3},{1,3,2},{2,1,3},{2,3,1},{3,1,2},{3,2,1}}
  mov OpoArrange[1*4], 2			
  mov OpoArrange[2*4], 3
  mov OpoArrange[3*4], 1
  mov OpoArrange[4*4], 3
  mov OpoArrange[5*4], 2
  mov OpoArrange[6*4], 2
  mov OpoArrange[7*4], 1
  mov OpoArrange[8*4], 3
  mov OpoArrange[9*4], 2
  mov OpoArrange[10*4], 3
  mov OpoArrange[11*4], 1
  mov OpoArrange[12*4], 3
  mov OpoArrange[13*4], 1
  mov OpoArrange[14*4], 2
  mov OpoArrange[15*4], 3
  mov OpoArrange[16*4], 2
  mov OpoArrange[17*4], 1
  mov ecx, 3
  L1:
    mov esi, ecx
    dec esi
    .IF CarsDataSwitch[esi* TYPE CarsDataSwitch] == 1
      mov eax, esi
      shl esi, 1
      add esi, eax
      mov eax, NowCarsData[esi*TYPE NowCarsData]	;eax=NowCarsData[i][0]
      add eax, 3
      .IF eax >= CrashY					;Opponents Cars lowest ypos >= the player car highest ypos
        inc esi
        mov eax, NowCarsData[esi*TYPE NowCarsData]	;OpoNumOfCars=NowCarsData[i][1]
        mov OpoNumOfCars, eax
	inc esi
        mov eax, NowCarsData[esi*TYPE NowCarsData]		;OpoMode=NowCarsData[i][2]
	mov OpoMode, eax
	push ecx
        mov ecx, OpoNumOfCars
	jmp L2
	MidLOOP:	;because jmp to far, need a middle point
	  jmp L1
	L2:
	  mov esi, OpoMode
	  dec esi
	  mov eax, esi
	  shl esi, 1
	  add esi, eax
	  add esi, ecx
	  dec esi
	  mov eax, OpoArrange[esi* TYPE OpoArrange]
	  dec eax
	  shl eax, 2
	  mov OpoXpos, eax		;OpoXpos=(OpoArrange[OpoMode-1][i]-1)*4
	  mov eax, PlayerXpos		;--eax = abs(PlayerXpos-OpoXpos)--
	  .IF OpoXpos > eax
	    mov eax, OpoXpos
	    sub eax, PlayerXpos
	  .ELSE
	    sub eax, OpoXpos
	  .ENDIF 			;--eax = abs(PlayerXpos-OpoXpos)--
	  .IF eax < 4			;if Opponents cars and the player car overlap
	    mov ebx, 1			;return ebx = 1
	    ret
	  .ENDIF
	LOOP L2
	pop ecx
	mov ebx, 0			;No Crash (because only one opponent row ypos in one time can >= the player car)
	ret				;return ebx = 0
      .ENDIF
    .ENDIF
  LOOP MidLOOP
  mov ebx, 0				;No any opponents cars ypos+3 >= the player car ypos
  ret					;;return ebx = 0
IsCrash ENDP

;generate the new random car data
CarsDataGenerator PROC USES eax ebx esi,
	indexI:DWORD
  mov eax, 5
  call RandomRange
  mov esi, indexI
  .IF eax == 0		;20% probability to hide the cars. CarsDataSwitch[i] = 0 or 1
    mov CarsDataSwitch[esi* TYPE CarsDataSwitch], 0
  .ELSE
    mov CarsDataSwitch[esi* TYPE CarsDataSwitch], 1
  .ENDIF
  mov eax, 2
  call RandomRange
  inc eax
  mov ebx, esi
  shl esi, 1
  add esi, ebx
  inc esi
  mov NowCarsData[esi* TYPE NowCarsData], eax	;NowCarsData[i][1] = 0~1
  mov eax, 6
  call RandomRange
  inc eax
  inc esi
  mov NowCarsData[esi* TYPE NowCarsData], eax	;NowCarsData[i][2] = 1~6
  ret
CarsDataGenerator ENDP

;making the timer
CheckTime PROC USES eax
  call GetMseconds
  sub eax, TheTime.StartT
  mov TheTime.NowT, eax
  ret
CheckTime ENDP
;------------------------------
END main