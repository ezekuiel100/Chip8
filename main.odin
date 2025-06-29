#+feature dynamic-literals
package main

import "core:fmt"
import "core:math/rand "
import "core:os"
import "core:strconv"
import "vendor:raylib"

memory: [4096]u8 = {}
screen: [64 * 32]bool
delay_timer: u8

stack: [16]u16
sp: u8 = 0
pc: u16 = 0x200 // program counter , next address

//Registers
v: [16]u8
i: u16 // store memory address
dt: u8 //delay timer 
sound_timer: u8 //sound timer

chip8_keymap := [16]raylib.KeyboardKey {
	raylib.KeyboardKey.X, // 0
	raylib.KeyboardKey.ONE, // 1
	raylib.KeyboardKey.TWO, // 2
	raylib.KeyboardKey.THREE, // 3
	raylib.KeyboardKey.Q, // 4
	raylib.KeyboardKey.W, // 5
	raylib.KeyboardKey.E, // 6
	raylib.KeyboardKey.A, // 7
	raylib.KeyboardKey.S, // 8
	raylib.KeyboardKey.D, // 9
	raylib.KeyboardKey.Z, // A
	raylib.KeyboardKey.C, // B
	raylib.KeyboardKey.FOUR, // C
	raylib.KeyboardKey.R, // D
	raylib.KeyboardKey.F, // E
	raylib.KeyboardKey.V, // F
}

keys: [16]bool


main :: proc() {
	raylib.SetTraceLogLevel(raylib.TraceLogLevel.ERROR)
	raylib.InitWindow(640, 320, "CHIP-8 em Odin")
	defer raylib.CloseWindow()

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

	for i := 0; i < len(data); i += 1 {
		memory[0x200 + i] = data[i]
	}

	for !raylib.WindowShouldClose() {
		for i in 0 ..< 16 {
			keys[i] = raylib.IsKeyDown(chip8_keymap[i])
		}

		opcode := u16(memory[pc]) << 8 | u16(memory[pc + 1])

		chip8(opcode)
		pc = pc + 2

		raylib.BeginDrawing()
		raylib.ClearBackground(raylib.RAYWHITE)
		raylib.EndDrawing()
	}
}


chip8 :: proc(opcode: u16) {
	switch opcode & 0xf000 {
	case 0x0000:
		switch opcode & 0x0fff {
		case 0x00e0:
			//Clear the display
			fmt.printfln("0x%04x", opcode)
		case 0x00ee:
			//RET
			sp = sp - 1
			ret_addr := stack[sp]
			pc = ret_addr
		}
	case 0x1000:
		//Jump to location nnn.
		location := opcode & 0x0fff
		pc = location
	case 0x2000:
		//Call subroutine at nnn.
		location := opcode & 0x0fff
		stack[sp] = pc
		sp = sp + 1
		pc = location
	case 0x3000:
		// Skip next instruction if Vx = kk.
		x := (opcode & 0x0f00) >> 8
		kk := opcode & 0x00ff
		if v[x] == u8(kk) {
			pc = pc + 4
		}
	case 0x4000:
		//Skip next instruction if Vx != kk.
		x := (opcode & 0x0f00) >> 8
		kk := opcode & 0x00ff
		if v[x] != u8(kk) {
			pc = pc + 4
		}

		pc = pc + 2
	case 0x5000:
		//Skip next instruction if Vx = Vy.
		x := (opcode & 0x0f00) >> 8
		y := (opcode & 0x00f0) >> 4
		if v[x] == v[y] {
			pc = pc + 4
		}
	case 0x6000:
		//Set Vx = kk. Puts the value kk into register Vx.
		x := (opcode & 0x0f00) >> 8
		kk := opcode & 0x00ff

		v[x] = u8(kk)
	case 0x7000:
		//Set Vx = Vx + kk.
		x := (opcode & 0x0f00) >> 8
		kk := opcode & 0x00ff

		v[x] = v[x] + u8(kk)
	case 0x8000:
		switch opcode & 0x000f {
		case 0x0000:
			//Set Vx = Vy.
			x := (opcode & 0x0f00) >> 8
			y := (opcode & 0x00f0) >> 4

			v[x] = v[y]
		case 0x0001:
			//Set Vx = Vx OR Vy.
			x := (opcode & 0x0f00) >> 8
			y := (opcode & 0x00f0) >> 4

			v[x] = v[x] | v[y]
		case 0x0002:
			//Set Vx = Vx AND Vy.
			x := (opcode & 0x0f00) >> 8
			y := (opcode & 0x00f0) >> 4

			v[x] = v[x] & v[y]
		case 0x0003:
			//Set Vx = Vx XOR Vy.
			x := (opcode & 0x0f00) >> 8
			y := (opcode & 0x00f0) >> 4

			v[x] = v[x] ~ v[y]
		case 0x0004:
			//Set Vx = Vx + Vy, set VF = carry. 
			x := (opcode & 0x0f00) >> 8
			y := (opcode & 0x00f0) >> 4

			sum := u16(v[x]) + u16(v[y])

			if sum > 255 {
				v[15] = 1
			} else {
				v[15] = 0
			}
			v[x] = u8(sum)
		case 0x0005:
			//Set Vx = Vx - Vy, set VF = NOT borrow.  
			x := (opcode & 0x0f00) >> 8
			y := (opcode & 0x00f0) >> 4

			if v[x] >= v[y] {
				v[15] = 1
			} else {
				v[15] = 0
			}

			v[x] = u8(v[x] - v[y])
		case 0x0006:
			//Set Vx = Vx SHR 1. 
			x := (opcode & 0x0f00) >> 8

			if v[x] & 0x1 == 1 {
				v[15] = 1
			} else {
				v[15] = 0
			}

			v[x] = v[x] >> 1
		case 0x0007:
			//Set Vx = Vy - Vx, set VF = NOT borrow. 
			x := (opcode & 0x0f00) >> 8
			y := (opcode & 0x00F0) >> 4

			if v[y] > v[x] {
				v[15] = 1
			} else {
				v[15] = 0
			}

			v[x] = u8(v[y] - v[x])

		case 0x000e:
			//Set Vx = Vx SHL 1.
			x := (opcode & 0x0f00) >> 8

			if (v[x] & 0x80) != 0 {
				v[15] = 1
			} else {
				v[15] = 0
			}

			v[x] = v[x] << 1
		}
	case 0x9000:
		//Skip next instruction if Vx != Vy.
		x := (opcode & 0x0f00) >> 8
		y := (opcode & 0x00F0) >> 4

		if v[x] != v[y] {
			pc = pc + 4
		}
	case 0xa000:
		//Set I = nnn
		nnn := opcode & 0x0fff
		i = nnn
	case 0xb000:
		//Bnnn - JP V0, addr
		nnn := opcode & 0x0fff
		pc = nnn + u16(v[0])
	case 0xc000:
		//Set Vx = random byte AND kk. 
		x := (opcode & 0x0f00) >> 8
		kk := opcode & 0x00ff
		random := u8(rand.uint32() % 256)

		v[x] = random & u8(kk)
	case 0xd000:
		//Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.
		x := (opcode & 0x0F00) >> 8
		y := (opcode & 0x00F0) >> 4
		n := opcode & 0x000F

		vx := v[x] % 64 // 64 é a largura da tela
		vy := v[y] % 32 // 32 é a altura da tela

		collision := false // Inicializa a colisão
		for row: u16 = 0; row < n; row += 1 {
			sprite_byte := memory[i + u16(row)]

			for bit: u8 = 0; bit < 8; bit += 1 {
				// Calcula a posição do pixel na tela
				screen_x := (vx + bit) % 64
				screen_y := (u16(vy) + row) % 32

				// Pega o valor do bit do sprite (0 ou 1)
				sprite_bit: bool = ((sprite_byte >> (7 - bit)) & 0x1) == 1

				// Pega o valor do pixel da tela
				screen_index := u32(screen_x) + u32(screen_y) * 64
				screen_pixel := screen[screen_index]

				// Verifica se vai ter colisão
				if sprite_bit && screen_pixel {
					collision = true
				}

				// Faz o XOR
				new_pixel := sprite_bit ~ screen_pixel

				// Atualiza a tela
				screen[screen_index] = new_pixel
			}
		}

		if collision {
			v[15] = 1
		} else {
			v[15] = 0
		}


	case 0xe000:
		switch opcode & 0x00ff {
		case 0x009e:
			x := (opcode & 0x0f00) >> 8
			vx := v[x]

			if keys[vx] {
				pc += 2
			}

		case 0x00a1:
			x := (opcode & 0x0f00) >> 8
			vx := v[x]

			if !keys[vx] {
				pc += 2
			}
		}

	case 0xf000:
		switch opcode & 0x00FF {
		case 0x0007:
			// Fx07 - LD Vx, DT Set Vx = delay timer value.
			x := (opcode & 0x0f00) >> 8
			v[x] = delay_timer
		case 0x000A:
			// Fx0A - LD Vx, K
			x := (opcode & 0x0f00) >> 8

			key_pressed := false
			for i in 0 ..< 16 {
				if keys[i] {
					v[x] = u8(i)
					key_pressed = true
					break
				}
			}

			if !key_pressed {
				return
			}
		case 0x0015:
			// Fx15 - LD DT, Vx
			x := (opcode & 0x0f00) >> 8
			delay_timer = v[x]
		case 0x0018:
			//Fx18 - LD ST, Vx
			x := (opcode & 0x0f00) >> 8
			sound_timer = v[x]
		case 0x001E:
			// Fx1E - ADD I, Vx . Set I = I + Vx.
			x := (opcode & 0x0f00) >> 8
			i = u16(v[x]) + i
		case 0x0029:
			// Fx29 - LD F, Vx
			x := (opcode & 0x0f00) >> 8
			i = u16(v[x]) * 5
		case 0x0033:
			// Fx33 - LD B, Vx
			x := (opcode & 0x0f00) >> 8
			value := v[x]
			memory[i] = value / 100
			memory[i + 1] = (value / 10) % 10
			memory[i + 2] = value % 10
		case 0x0055:
			// Fx55 - LD [I], Vx
			x := (opcode & 0x0f00) >> 8
			for a in 0 ..= x {
				memory[i + u16(a)] = v[a]
			}
		case 0x0065: // Fx65 - LD Vx, [I]
		}
	}

}
