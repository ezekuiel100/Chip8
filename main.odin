package main

import "core:fmt"
import "core:os"
import "core:strings"


main :: proc() {
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

	hex_output_builder: strings.Builder
	strings.builder_init(&hex_output_builder)

	for byte_value in data {
		fmt.sbprint(&hex_output_builder, fmt.aprintf("%02X ", byte_value))
	}

	hex_string := strings.to_string(hex_output_builder)

	out_file, out_err := os.open("copia_teste.txt", os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)
	if out_err != nil {
		fmt.println("Erro ao criar/abrir saída:", out_err)
		return
	}
	defer os.close(out_file)

	bytes_to_write := transmute([]u8)hex_string
	write, write_ok := os.write(out_file, bytes_to_write)


	fmt.println("Arquivo criado com a representação hexadecimal.")
}
