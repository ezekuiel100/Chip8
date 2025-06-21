package main

import "core:fmt"
import "core:os"


main :: proc() {
	file, file_ok := os.open("test.txt")

	if file_ok != nil {
		fmt.println("Erro ao abrir o arquivo:", file_ok)
		return
	}

	info, info_ok := os.stat("test.txt")
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

	fmt.println("Bytes lidos:", read)
	fmt.println(string(data))
}
