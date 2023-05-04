; program przyk³adowy (wersja 32-bitowa)
.686
.model flat
extern _ExitProcess@4 : PROC
extern __write : PROC
extern __read : PROC
public _main
.data
znaki		db 12 dup (?)			; deklaracja tab 12-bajtowej do przechowywania tworzonych cyfr
dekoder		db '0123456789ABCD'
czy_ujemna	dd 0
.code

wyswietl_EAX_U2_b14 PROC
	pusha

	mov esi, 10					; index w tab 'znaki'
	mov ebx, 14					; dzielnik równy 14

	mov edi, 0					; licz na którym indeksie wstawiæ znak

	mov ebp, 1					; dodatnia
	
	cmp eax, 0
	jg konwersja
	mov ebp, 0					; ujemna
	neg eax

	konwersja:
		mov edx, 0				; zerowanie starszej czêœci dzielnej
		div ebx					; /14, reszta w edx, iloraz w eax

		; add dl, dekoder[edx]
		mov ecx, edx
		mov cl, dekoder[edx]
		mov edx, ecx

		mov znaki [esi], dl
		dec esi
		cmp eax, 0
		jne konwersja			; skok, gdy iloraz niezerowy

	; wype³nienie pozosta³ych bajtów spacjami i wpisanie znaków nowego wiersza
	wypeln:
		or esi, esi
		jz wyswietl				; skok, gdy esi = 0
		mov byte PTR znaki[esi], 20h
		dec esi
		inc edi					; zapisuj, gdzie ostatnia liczba
		jmp wypeln

	wyswietl:
		mov byte PTR znaki[0], 0Ah		; kod nowego wiersza
		cmp ebp, 0
		ja wstaw_plus
		
			wstaw_minus:
				mov byte PTR znaki[edi], 2Dh		; -
				jmp kontynuuj_wyswietlanie
		
			wstaw_plus:
				mov byte PTR znaki[edi], 2Bh		; +
		mov byte PTR znaki[11], 0Ah

		kontynuuj_wyswietlanie:
		; wyœwietlenie cyfr na ekranie
		push dword PTR 12		; liczba wyœwietlanych znaków
		push dword PTR OFFSET znaki
		push dword PTR 1		; ekran
		call __write
		add esp, 12

	popa
	ret
wyswietl_EAX_U2_b14 ENDP

wczytaj_EAX_U2_b14 PROC
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp

	; rezerwacja 12 bajtów na stosie przeznaczonych na temp. przech. cyft szesnastkowych wyœwietlanej liczby
	sub esp, 12
	mov esi, esp

	push dword PTR 10	; max il znaków wyœwietlanej liczby
	push esi
	push dword PTR 0	; klawiatura
	call __read
	add esp, 12			; usuniêcie param. ze stosu

	mov eax, 0			; dotychczas uzyskany wynik

	mov edx, 0			; aby móc dodawaæ edx w ca³oœci...

	pocz_konw:
		mov dl, [esi]

		; sprawdzenie czy ujemna
		cmp dl, 2Dh
		jne kon_pocz_konw
			ujemna:
			mov czy_ujemna, 1

		kon_pocz_konw:
		inc esi
		cmp dl, 10		; czy Enter?
		je gotowe

		; sprawdzenie czy znak jest cyfr¹ 0, 1, ..., 9
		cmp dl, '0'
		jb pocz_konw	; ignorowanie innych znaków
		cmp dl, '9'
		ja sprawdzaj_dalej
		sub dl, '0'		; zamiana ASCII na wartoœæ cyfry

		dopisz:
			push ebx
			push edx
				mov ebx, 14
				mul ebx
			pop edx
			pop ebx

			add eax, edx
			jmp pocz_konw

		; sprawdzenie czy wprowadzony znak jest cyfr¹ A, B, C, D
		sprawdzaj_dalej:
			cmp dl, 'A'
			jb pocz_konw
			cmp dl, 'D'
			ja sprawdzaj_dalej2
			sub dl, 'A' - 10	; wyznaczenie kodu bin
			jmp dopisz

		; sprawdzenie czy wprowadzony znak jest cyfr¹ a, b, c, d
		sprawdzaj_dalej2:
			cmp dl, 'a'
			jb pocz_konw
			cmp dl, 'd'
			ja pocz_konw
			sub dl, 'a' - 19
			jmp dopisz

		gotowe:
			add esp, 12			; zwolnienie zarezerwowanego obszaru pam.

	; je¿eli ujemna... to zamieñ
	cmp czy_ujemna, 1
	jne wyjdz

	neg eax ; konwersja na U2

	wyjdz:
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	ret
wczytaj_EAX_U2_b14 ENDP

_main PROC
	call wczytaj_EAX_U2_b14
	sub eax, 10
	call wyswietl_EAX_U2_b14
	push 0
	call _ExitProcess@4 
_main ENDP

END