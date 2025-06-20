package main

import "core:os"
import "core:fmt"


main :: proc(){
   file, err := os.open("test.txt")

   if err != nil {
      fmt.println("Erro ao abrir o arquivo:", err)
        return
   }

   info, _ := os.stat("test.txt")
   size : = info.size

    data := make([]u8 , size)
    n , error := os.read_full(file, data)
    fmt.println(string(data))
   
}