package main

import "core:fmt"
import "core:os"
import "core:strings"


main :: proc() {
	position := 0
	file, file_ok := os.open("teste.exe")

	if file_ok != nil {
		fmt.println("Erro ao abrir o arquivo:", file_ok)
		return
	}

	defer os.close(file)

	info, info_ok := os.stat("teste.exe")
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

	for bytes_value in data {
		value := data[position:position + 2]
		opcode := u16(value[0]) << 8 | u16(value[1])
		chip8(opcode)
		position = position + 2
	}
}


chip8 :: proc(opcode: u16) {
	fmt.printfln("0x%04X ", opcode)
}
