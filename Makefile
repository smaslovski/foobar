EXE = fractal.tap
LST = fractal.lst
SRC = fractal.asm

ASM = pasmo



all: $(EXE) size

$(EXE): $(SRC)
	$(ASM) -d --tapbas --alocal $(SRC) $(EXE) >$(LST)

run: $(EXE) size
	fuse $(EXE)

size: $(EXE)
	tapls/tapls -l $(EXE)


clean:
	rm $(EXE) $(LST)


