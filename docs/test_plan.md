# Plan de Pruebas: Generador de Secuencia Fibonacci

**Módulo:** `fibonacci.sv`
**Revisión:** 1.0
**Fecha:** 2026-05-22
**Referencia:** `docs/Specs.md`, `docs/verif_plan.md`

---

## 1. Convención de Identificadores

```
TC-<CATEGORÍA>-<NN>

  CATEGORÍA:
    RST  → Reset
    SEQ  → Secuencia
    HLD  → Hold / Enable
    OVF  → Overflow / Wrap-around
    PAR  → Paramétrico
```

Cada caso de prueba incluye:
- **Condición inicial:** estado de los registros antes del test.
- **Estímulo:** secuencia de señales aplicadas.
- **Resultado esperado:** valores de `fib_out` ciclo a ciclo.
- **Req. cubierto:** ID de `Specs.md`.
- **Criterio de paso:** condición verificable.

---

## 2. Casos de Prueba — Reset (TC-RST)

### TC-RST-01: Reset asíncrono desde estado arbitrario

| Campo              | Valor                                              |
|--------------------|----------------------------------------------------|
| **Req. cubierto**  | RST-001                                            |
| **W**              | 8                                                  |
| **Condición ini.** | `a=55, b=89` (estado avanzado de la secuencia)     |
| **Estímulo**       | Aserta `rst_n=0` en medio de un ciclo (asíncrono)  |
| **Resultado esp.** | `fib_out = 0` en el mismo ciclo, sin esperar flanco |
| **Criterio**       | `fib_out === 0` mientras `rst_n === 0`             |

```
Ciclo:   0    1    2
rst_n:   1    0    0
enable:  1    x    x
fib_out: 55   0    0   ← reset asíncrono, no espera flanco
```

---

### TC-RST-02: Reset asíncrono — independiente de enable

| Campo              | Valor                                              |
|--------------------|----------------------------------------------------|
| **Req. cubierto**  | RST-001                                            |
| **W**              | 8                                                  |
| **Condición ini.** | `a=13, b=21`, `enable=0`                           |
| **Estímulo**       | Aserta `rst_n=0` con `enable=0`                    |
| **Resultado esp.** | `fib_out = 0` inmediatamente                       |
| **Criterio**       | El reset debe actuar sin importar el valor de enable |

```
Ciclo:   0    1
rst_n:   1    0
enable:  0    0
fib_out: 13   0   ← reset domina sobre hold
```

---

### TC-RST-03: Secuencia correcta tras liberar reset

| Campo              | Valor                                                       |
|--------------------|-------------------------------------------------------------|
| **Req. cubierto**  | RST-002                                                     |
| **W**              | 8                                                           |
| **Condición ini.** | `rst_n=0` (reset activo)                                    |
| **Estímulo**       | Libera `rst_n=1`, activa `enable=1` y mantiene por 8 ciclos |
| **Resultado esp.** | `fib_out`: 0, 1, 1, 2, 3, 5, 8, 13                         |
| **Criterio**       | Cada valor coincide con la secuencia de Fibonacci           |

```
Ciclo:   0    1    2    3    4    5    6    7    8
rst_n:   0    1    1    1    1    1    1    1    1
enable:  x    1    1    1    1    1    1    1    1
fib_out: 0    1    1    2    3    5    8    13   21
         ↑                                       ↑
       reset                              secuencia válida
```

---

## 3. Casos de Prueba — Secuencia (TC-SEQ)

### TC-SEQ-01: Secuencia Fibonacci continua (enable siempre activo)

| Campo              | Valor                                            |
|--------------------|--------------------------------------------------|
| **Req. cubierto**  | SEQ-001                                          |
| **W**              | 8                                                |
| **Condición ini.** | Reset liberado: `a=0, b=1`                       |
| **Estímulo**       | `enable=1` durante 12 ciclos consecutivos        |
| **Resultado esp.** | 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89         |
| **Criterio**       | Scoreboard confirma cada valor vs. modelo de referencia |

```
Ciclo:   1    2    3    4    5    6    7    8    9    10   11   12
enable:  1    1    1    1    1    1    1    1    1    1    1    1
fib_out: 1    1    2    3    5    8    13   21   34   55   89   144
```

---

### TC-SEQ-02: Verificación de la relación F(n) = F(n-1) + F(n-2)

| Campo              | Valor                                              |
|--------------------|----------------------------------------------------|
| **Req. cubierto**  | SEQ-002                                            |
| **W**              | 16                                                 |
| **Condición ini.** | Reset liberado                                     |
| **Estímulo**       | `enable=1` durante 20 ciclos                       |
| **Resultado esp.** | Para todo n≥2: `fib_out[n] == fib_out[n-1] + fib_out[n-2]` |
| **Criterio**       | Assertion `AST_SEQ` no falla en ningún ciclo       |

> Este test valida la propiedad matemática fundamental más que los valores exactos. El scoreboard registra las últimas dos salidas y verifica la relación en cada ciclo con enable activo.

---

### TC-SEQ-03: Pulso de enable de un solo ciclo

| Campo              | Valor                                              |
|--------------------|----------------------------------------------------|
| **Req. cubierto**  | SEQ-001, HLD-001                                   |
| **W**              | 8                                                  |
| **Condición ini.** | Reset liberado: `a=0, b=1`                         |
| **Estímulo**       | Alterna `enable` un ciclo sí, un ciclo no          |
| **Resultado esp.** | Avanza solo en los ciclos con enable=1             |

```
Ciclo:   1    2    3    4    5    6    7    8
enable:  1    0    1    0    1    0    1    0
fib_out: 1    1    1    2    2    3    3    5
              ↑         ↑         ↑         ↑
            hold      hold      hold      hold
```

---

## 4. Casos de Prueba — Hold / Enable (TC-HLD)

### TC-HLD-01: Hold prolongado — enable=0 por múltiples ciclos

| Campo              | Valor                                              |
|--------------------|----------------------------------------------------|
| **Req. cubierto**  | HLD-001                                            |
| **W**              | 8                                                  |
| **Condición ini.** | `fib_out=5` (`a=5, b=8`)                           |
| **Estímulo**       | `enable=0` durante 10 ciclos consecutivos          |
| **Resultado esp.** | `fib_out=5` en todos los 10 ciclos                 |
| **Criterio**       | `$stable(fib_out)` durante toda la ventana         |

```
Ciclo:   0    1..10
enable:  1    0 (×10)
fib_out: 5    5 5 5 5 5 5 5 5 5 5   ← sin cambio
```

---

### TC-HLD-02: Reanuda desde valor retenido

| Campo              | Valor                                                   |
|--------------------|---------------------------------------------------------|
| **Req. cubierto**  | HLD-002                                                 |
| **W**              | 8                                                       |
| **Condición ini.** | `a=5, b=8` (hold durante 5 ciclos)                      |
| **Estímulo**       | Reactiva `enable=1` tras 5 ciclos de hold               |
| **Resultado esp.** | Continúa: `8, 13, 21, ...` (no reinicia desde 0)        |
| **Criterio**       | El primer valor tras reactivar es el sucesor del retenido |

```
Ciclo:   0    1    2    3    4    5    6    7    8
enable:  1    0    0    0    0    0    1    1    1
fib_out: 5    5    5    5    5    5    8    13   21
                                       ↑
                                  reanuda correctamente
```

---

### TC-HLD-03: Reset durante hold

| Campo              | Valor                                              |
|--------------------|----------------------------------------------------|
| **Req. cubierto**  | RST-001, HLD-001                                   |
| **W**              | 8                                                  |
| **Condición ini.** | `enable=0`, `a=13, b=21`                           |
| **Estímulo**       | Aserta `rst_n=0` mientras `enable=0`               |
| **Resultado esp.** | `fib_out=0` inmediatamente (reset domina sobre hold) |
| **Criterio**       | `fib_out === 0` al activar reset                   |

---

## 5. Casos de Prueba — Overflow / Wrap-around (TC-OVF)

### TC-OVF-01: Wrap-around natural con W=8

| Campo              | Valor                                               |
|--------------------|-----------------------------------------------------|
| **Req. cubierto**  | OVF-001                                             |
| **W**              | 8 (máximo sin signo: 255)                           |
| **Condición ini.** | Reset liberado                                      |
| **Estímulo**       | `enable=1` hasta que ocurra overflow                |
| **Resultado esp.** | Wrap-around aritmético (módulo 2^8). El modelo de referencia predice el mismo resultado |
| **Criterio**       | DUT y modelo de referencia coinciden tras overflow  |

> La secuencia con W=8 desborda en `F(13)=233` y `F(14)=377 → 377 mod 256 = 121`.

```
Ciclo (aprox):  ...  12   13   14
fib_out:        ...  144  233  121   ← 377 mod 256 = 121 (wrap)
ref_model:      ...  144  233  121   ← coincide
```

---

### TC-OVF-02: Comportamiento post-overflow — continúa sin reset

| Campo              | Valor                                            |
|--------------------|--------------------------------------------------|
| **Req. cubierto**  | OVF-001                                          |
| **W**              | 8                                                |
| **Estímulo**       | `enable=1` durante 20 ciclos (cruza overflow)    |
| **Resultado esp.** | DUT sigue al modelo de referencia en todos los ciclos, incluso post-overflow |
| **Criterio**       | 0 errores de scoreboard en los 20 ciclos         |

---

## 6. Casos de Prueba — Paramétrico (TC-PAR)

### TC-PAR-01: Instancia con W=8

| Campo              | Valor                                           |
|--------------------|-------------------------------------------------|
| **Req. cubierto**  | PAR-001                                         |
| **W**              | 8                                               |
| **Estímulo**       | Secuencia completa: reset + 15 ciclos enable=1  |
| **Criterio**       | Compilación sin errores, secuencia correcta     |

---

### TC-PAR-02: Instancia con W=16

| Campo              | Valor                                           |
|--------------------|-------------------------------------------------|
| **Req. cubierto**  | PAR-001                                         |
| **W**              | 16 (máximo sin signo: 65535)                    |
| **Estímulo**       | Reset + 24 ciclos enable=1                      |
| **Resultado esp.** | Secuencia válida hasta `F(23) = 28657` sin overflow |
| **Criterio**       | Scoreboard con modelo de referencia W=16        |

---

### TC-PAR-03: Instancia con W=32

| Campo              | Valor                                           |
|--------------------|-------------------------------------------------|
| **Req. cubierto**  | PAR-001                                         |
| **W**              | 32                                              |
| **Estímulo**       | Reset + 48 ciclos enable=1                      |
| **Resultado esp.** | Secuencia válida hasta `F(47) = 2971215073` sin overflow |
| **Criterio**       | Scoreboard con modelo de referencia W=32        |

---

## 7. Resumen de Cobertura de Requisitos

| Req. ID  | TC-RST | TC-SEQ | TC-HLD | TC-OVF | TC-PAR |
|----------|--------|--------|--------|--------|--------|
| RST-001  | 01, 02 | —      | 03     | —      | —      |
| RST-002  | 03     | —      | —      | —      | —      |
| SEQ-001  | 03     | 01, 03 | —      | —      | 01..03 |
| SEQ-002  | —      | 02     | —      | —      | —      |
| HLD-001  | —      | 03     | 01     | —      | —      |
| HLD-002  | —      | —      | 02     | —      | —      |
| OVF-001  | —      | —      | —      | 01, 02 | —      |
| PAR-001  | —      | —      | —      | —      | 01..03 |

---

## 8. Orden de Ejecución Sugerido

```
1. TC-RST-01   → Valida reset básico (prerrequisito de todos)
2. TC-RST-02   → Reset independiente de enable
3. TC-RST-03   → Secuencia inicial correcta
4. TC-SEQ-01   → Secuencia continua (smoke test principal)
5. TC-SEQ-02   → Propiedad matemática F(n)=F(n-1)+F(n-2)
6. TC-HLD-01   → Hold básico
7. TC-HLD-02   → Reanuda desde hold
8. TC-SEQ-03   → Enable pulsado
9. TC-HLD-03   → Reset durante hold
10. TC-OVF-01  → Overflow con W=8
11. TC-OVF-02  → Post-overflow continúa
12. TC-PAR-01  → W=8  (ya cubierto, verificación de compilación)
13. TC-PAR-02  → W=16
14. TC-PAR-03  → W=32
```

---

*Los casos de prueba de esta tabla serán implementados en `verification/tests/`. Ver `verif_plan.md` para la arquitectura del entorno.*
