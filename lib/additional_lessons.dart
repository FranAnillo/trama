part of 'catalog_source.dart';

const additionalLessons = [
  Lesson(
    "fp.sum",
    "Fundamentos de Programación",
    "Sumar lo que pasa el filtro",
    "Calcula el total de los valores que cumplen una condición.",
    "Una caja registra importes [3, −1, 4]. Si sumamos solo los positivos, el total pasa de 0 a 3, se mantiene en 3 y acaba en 7. Sumar x y sumar 1 producen resultados distintos.",
    [
      Question(
        "total empieza en 0. ¿Qué instrucción añade el importe actual x?",
        ["total += 1", "total += x", "total = x"],
        1,
        [
          "Así cuentas importes, independientemente de su valor.",
          "El total anterior se conserva y se añade x.",
          "Esto pierde lo que ya llevabas.",
        ],
      ),
      Question(
        "Con [5, −2, 3], ¿cuánto suman los valores positivos?",
        ["6", "2", "8"],
        2,
        [
          "6 incluye el −2. La condición lo descarta.",
          "Hay dos positivos, pero se pide su suma.",
          "5 + 3 = 8.",
        ],
      ),
      Question(
        "¿Qué total positivo produce una lista vacía si total empezó en 0?",
        ["0", "1", "El último importe"],
        0,
        [
          "El bucle no hace ninguna suma.",
          "No se ha observado ningún importe.",
          "No existe un último elemento.",
        ],
      ),
    ],
  ),
  Lesson(
    "fp.find",
    "Fundamentos de Programación",
    "Parar en la primera coincidencia",
    "Localiza el primer índice que cumple una condición.",
    "Una alarma busca la primera temperatura mayor de 30. En [28, 32, 35] revisa el índice 0, encuentra 32 en el índice 1 y se detiene. Los índices empiezan en cero. Nuestro algoritmo devuelve −1 si no encuentra nada.",
    [
      Question(
        "Para [31, 18, 40], ¿cuál es el primer índice con temperatura mayor de 30?",
        ["0", "2", "31"],
        0,
        [
          "El primer valor, 31, ya supera el umbral.",
          "40 también lo supera, pero se visita después.",
          "31 es el valor, no su posición.",
        ],
      ),
      Question(
        "En una función que recorre la lista, ¿qué hace return i al encontrar una coincidencia?",
        [
          "Salta solo esa vuelta",
          "Devuelve i y sale de la función",
          "Ordena los valores",
        ],
        1,
        [
          "Eso describe continue.",
          "El llamador recibe el índice y la búsqueda termina.",
          "No se altera la lista.",
        ],
      ),
      Question(
        "La lista es [30, 29]. ¿Qué índice devuelve nuestra búsqueda de un valor mayor de 30?",
        ["0", "1", "−1"],
        2,
        [
          "30 es igual al límite.",
          "29 tampoco supera el límite.",
          "Ningún elemento cumple > 30.",
        ],
      ),
    ],
  ),
  Lesson(
    "fp.func",
    "Fundamentos de Programación",
    "Devolver un valor a quien llama",
    "Distingue el valor devuelto del texto que se muestra en pantalla.",
    "Imagina una función como una máquina que recibe un dato y entrega otro. En def doble(x): return 2*x, la llamada doble(4) entrega 8. Una instrucción print puede mostrar 8, pero no entrega ese entero a quien llama.",
    [
      Question(
        "Con def doble(x): return x*2, ¿qué vale doble(3) + 1?",
        ["6", "7", "8"],
        1,
        [
          "Aún falta sumar 1 al resultado.",
          "La función devuelve 6 y el llamador suma 1.",
          "El 1 se añade después de la llamada.",
        ],
      ),
      Question(
        "Una función solo ejecuta print(8) y termina sin return. ¿Qué recibe quien la llama?",
        ["8", "\"8\"", "None"],
        2,
        [
          "8 aparece en pantalla.",
          "La función tampoco devuelve una cadena.",
          "Python devuelve None cuando no hay retorno explícito.",
        ],
      ),
      Question(
        "Con def suma_uno(x): return x+1, ¿qué vale suma_uno(suma_uno(4))?",
        ["6", "5", "8"],
        0,
        [
          "Primero se obtiene 5; la llamada exterior devuelve 6.",
          "5 es el resultado intermedio.",
          "Ninguna de las llamadas duplica x.",
        ],
      ),
    ],
  ),
  Lesson(
    "rc.prefix",
    "Redes de Computadores",
    "Encontrar la red de una dirección",
    "Calcula el bloque IPv4 al que pertenece una dirección /26.",
    "Dentro de un /24, un /26 tiene 64 direcciones. Sus bloques empiezan en .0, .64, .128 y .192. Por ejemplo, .90 cae entre .64 y .127. La dirección de red conserva el inicio del bloque.",
    [
      Question(
        "¿Dónde empieza el bloque de 192.0.2.70/26?",
        ["192.0.2.0", "192.0.2.64", "192.0.2.70"],
        1,
        [
          "El bloque que empieza en .0 termina en .63.",
          "70 está en el intervalo 64–127.",
          "La dirección del equipo no es el inicio del bloque.",
        ],
      ),
      Question(
        "¿Cuál es la última dirección del bloque que empieza en 192.0.2.128/26, incluida la de difusión?",
        ["192.0.2.190", "192.0.2.192", "192.0.2.191"],
        2,
        [
          ".190 es la última asignable a un equipo en este ejemplo.",
          "Ese es el comienzo del siguiente bloque.",
          "128 + 63 = 191.",
        ],
      ),
      Question(
        "¿Qué par comparte un mismo /26 dentro de 192.0.2.0/24?",
        [".62 y .65", ".130 y .170", ".127 y .128"],
        1,
        [
          "Cruzan el límite entre .63 y .64.",
          "Ambas están entre .128 y .191.",
          "Cruzan el límite entre .127 y .128.",
        ],
      ),
    ],
  ),
  Lesson(
    "rc.port",
    "Redes de Computadores",
    "Seguir los puertos de una conexión",
    "Identifica los puertos de origen y destino en una respuesta TCP.",
    "Un cliente abre una conexión desde su puerto 51000 al 443 del servidor. En esa misma conexión, al responder, el servidor envía desde 443 hacia 51000. Usaremos extremos directos sin traducción de direcciones ni puertos.",
    [
      Question(
        "En el primer segmento del cliente, ¿qué puerto de destino identifica al servicio?",
        ["51000", "443", "Ambos"],
        1,
        [
          "51000 identifica al extremo del cliente.",
          "El servicio escucha en 443 en este ejemplo.",
          "Un segmento tiene un único puerto de destino.",
        ],
      ),
      Question(
        "¿Cuál es el puerto de destino en la respuesta de esa conexión?",
        ["443", "80", "51000"],
        2,
        [
          "Ahora 443 es el origen.",
          "Ningún extremo eligió el 80.",
          "La respuesta vuelve al puerto del cliente.",
        ],
      ),
      Question(
        "Dos clientes de distinta IP usan el mismo puerto local hacia el mismo servidor. ¿Qué permite distinguir sus conexiones TCP?",
        [
          "Solo el puerto del servidor",
          "El contenido del mensaje",
          "La combinación de IP y puerto de ambos extremos",
        ],
        2,
        [
          "Ambos usan el mismo servicio.",
          "Se puede distinguir la conexión sin inspeccionar el contenido.",
          "Las IP de los clientes distinguen las parejas de extremos.",
        ],
      ),
    ],
  ),
  Lesson(
    "rc.ttl",
    "Redes de Computadores",
    "Hasta dónde llega un paquete",
    "Predice dónde se descarta un paquete IPv4 por agotamiento de TTL.",
    "En nuestro modelo cada router resta uno al TTL al reenviar. Si quedaría a cero, descarta el paquete. Con TTL inicial 2, el primer router lo reenvía con 1 y el segundo lo descarta. El destino es un equipo situado después de ambos routers.",
    [
      Question(
        "Un paquete llega a un router con TTL 4. En este modelo, ¿con qué TTL sale?",
        ["4", "3", "0"],
        1,
        [
          "El router debe reducir el TTL.",
          "Se resta uno al reenviar.",
          "Aún quedan saltos.",
        ],
      ),
      Question(
        "Un router necesita reenviar un paquete que llega con TTL 1. ¿Qué hace?",
        ["Lo reenvía con 0", "Lo descarta", "Reinicia el TTL"],
        1,
        [
          "No se reenvía un paquete con TTL agotado.",
          "Se descarta en ese router.",
          "Restablecer el valor permitiría bucles indefinidos.",
        ],
      ),
      Question(
        "Hay dos routers entre origen y destino. ¿Qué TTL inicial mínimo permite llegar si cada uno descuenta uno?",
        ["2", "1", "3"],
        2,
        [
          "Se agotaría en el segundo router.",
          "Se agotaría en el primero.",
          "Sale del segundo router con TTL 1 y llega al destino.",
        ],
      ),
    ],
  ),
  Lesson(
    "ac.block",
    "Arquitectura de Computadores",
    "Del byte al bloque",
    "Separa número de bloque y desplazamiento en una dirección.",
    "La memoria se numera por bytes desde 0. Con bloques de 4 bytes, el bloque 0 abarca 0–3 y el bloque 1 abarca 4–7. Para la dirección 6, el cociente entero 6 ÷ 4 da bloque 1 y el resto da desplazamiento 2.",
    [
      Question(
        "Con bloques de 4 bytes, ¿a qué bloque pertenece el byte 9?",
        ["1", "2", "3"],
        1,
        [
          "El bloque 1 termina en 7.",
          "El bloque 2 contiene los bytes 8–11.",
          "El bloque 3 empieza en 12.",
        ],
      ),
      Question(
        "¿Qué desplazamiento tiene el byte 9 dentro de ese bloque?",
        ["1", "2", "9"],
        0,
        [
          "Desde el inicio, 8, avanzamos un byte.",
          "2 es el número de bloque.",
          "9 es la dirección completa.",
        ],
      ),
      Question(
        "¿Qué par pertenece al mismo bloque de 4 bytes?",
        ["7 y 8", "11 y 12", "12 y 15"],
        2,
        [
          "8 empieza un bloque nuevo.",
          "12 empieza un bloque nuevo.",
          "Ambos están entre 12 y 15.",
        ],
      ),
    ],
  ),
  Lesson(
    "ac.line",
    "Arquitectura de Computadores",
    "Dos bloques compiten por una línea",
    "Predice el reemplazo en una caché de correspondencia directa.",
    "En una caché de cuatro líneas numeradas de 0 a 3, el bloque b solo puede ir a la línea b módulo 4. Los bloques 1 y 5 compiten por la línea 1 aunque otras líneas estén libres. La etiqueta permite distinguir qué bloque ocupa la línea.",
    [
      Question(
        "¿En qué línea se aloja el bloque 6 con cuatro líneas?",
        ["0", "2", "3"],
        1,
        [
          "A la línea 0 van los múltiplos de 4.",
          "El resto de 6 ÷ 4 es 2.",
          "El resto no es 3.",
        ],
      ),
      Question(
        "Se leen los bloques 2 y 6 desde una caché vacía de cuatro líneas. ¿Cuál queda en la línea 2?",
        ["2", "Ambos", "6"],
        2,
        [
          "El bloque 6 lo reemplaza.",
          "Cada línea guarda un solo bloque.",
          "Ambos van a la línea 2; la lectura más reciente fue 6.",
        ],
      ),
      Question(
        "Tras leer 2 y 6, se lee de nuevo el 2. ¿Qué sucede?",
        ["Fallo", "Acierto", "La línea está vacía"],
        0,
        [
          "La línea 2 contiene el bloque 6.",
          "Haber leído antes el 2 no garantiza que siga allí.",
          "La línea está ocupada por un bloque diferente.",
        ],
      ),
    ],
  ),
  Lesson(
    "ac.time",
    "Arquitectura de Computadores",
    "El coste medio de un fallo",
    "Calcula el tiempo medio de acceso en un modelo con una sola caché.",
    "Todos los accesos pagan 2 ns de consulta. Un fallo añade 20 ns. Si falla uno de cada diez, el tiempo medio es 2 + 0,10 × 20 = 4 ns. La penalización es el coste adicional, además de consultar la caché.",
    [
      Question(
        "Con esos costes, ¿cuánto dura un acceso que falla?",
        ["2 ns", "20 ns", "22 ns"],
        2,
        [
          "Eso dura un acierto.",
          "La penalización se suma a la consulta inicial.",
          "2 ns de consulta + 20 ns adicionales.",
        ],
      ),
      Question(
        "Con consulta de 1 ns, penalización de 10 ns y un 20 % de fallos, ¿cuál es la media?",
        ["3 ns", "11 ns", "2 ns"],
        0,
        [
          "1 + 0,20 × 10 = 3 ns.",
          "11 ns es la duración de un fallo individual.",
          "2 ns es solo el coste medio adicional.",
        ],
      ),
      Question(
        "Si ningún acceso falla y la consulta cuesta 2 ns, ¿cuál es la media?",
        ["0 ns", "2 ns", "22 ns"],
        1,
        [
          "Cada acceso paga la consulta.",
          "La penalización media es cero, pero la consulta sigue costando 2 ns.",
          "Esta duración corresponde a un fallo.",
        ],
      ),
    ],
  ),
];
