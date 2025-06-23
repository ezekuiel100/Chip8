package main

import "core:fmt"
import "core:os"

main :: proc() {
	stack := [16]u16
	sp := 0
	
	file, file_ok := os.open("MAZE")

	if file_ok != nil {
		fmt.println("Erro ao abrir o arquivo:", file_ok)
		return
	}

	defer os.close(file)

	info, info_ok := os.stat("MAZE")
	if info_ok != nil {
		fmt.println("Erro ao obter informações do arquivo:", info_ok)
		return
	}

	size := info.size

	data := make([]u8, size)
	read, read_ok := os.read_full(file, data)

	if read_ok != nil {
		fmt.println("Erro ao ler o arquivo:", read_ok)
		return
	}

	position := 0
	for position < len(data) {
		value := data[position:position + 2]
		opcode := u16(value[0]) << 8 | u16(value[1])

		chip8(opcode, stack, &sp)
		position = position + 2
	}
}


chip8 :: proc(opcode: u16, stack: []u16 , sp: ^int) {
	switch opcode & 0xf000 {
	case 0x0000:
		switch opcode & 0x0fff{
			case 0x00e0:
				//Clear the display
				fmt.printfln("0x%04x", opcode)
			case 0x00ee:
				fmt.printfln("0x%04x", opcode)
			}
	case 0x1000:
		fmt.printfln("0x%04x", opcode)
	case 0x2000:
		fmt.printfln("0x%04x", opcode)
	case 0x3000:
		fmt.printfln("0x%04x", opcode)
	case 0x4000:
		fmt.printfln("0x%04x", opcode)
	case 0x5000:
		fmt.printfln("0x%04x", opcode)
	case 0x6000:
		fmt.printfln("0x%04x", opcode)
	case 0x7000:
		fmt.printfln("0x%04x", opcode)
	case 0x8000:
		fmt.printfln("0x%04x", opcode)
	case 0x9000:
		fmt.printfln("0x%04x", opcode)
	case 0xa000:
		fmt.printfln("0x%04x", opcode)
	case 0xb000:
		fmt.printfln("0x%04x", opcode)
	case 0xc000:
		fmt.printfln("0x%04x", opcode)
	case 0xd000:
		fmt.printfln("0x%04x", opcode)
	case 0xe000:
		fmt.printfln("0x%04x", opcode)
	case 0xf000:
		fmt.printfln("0x%04x", opcode)
	}
}
