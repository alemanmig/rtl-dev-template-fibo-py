# Especificaciones de Diseño: Generador de Secuencia Fibonacci con Enable

**Proyecto:** `fibonacci-seq-gen`
**Archivo RTL objetivo:** `rtl/fibonacci.sv`
**Revisión:** 1.0
**Fecha:** 2026-05-22

---

## 1. Descripción General

Diseñar e implementar un generador de secuencia de Fibonacci parametrizable en SystemVerilog. El módulo avanza en la secuencia únicamente cuando la señal de habilitación (`enable`) está activa. Cuando `enable` está desactivada, el módulo retiene el valor de salida actual sin modificar el estado interno.

La secuencia de Fibonacci se define como:

```
F(0) = 0
F(1) = 1
F(n) = F(n-1) + F(n-2)   para n >= 2

Secuencia esperada: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, ...
```

---

## 2. Parámetros

| Parámetro | Tipo    | Valor por defecto | Descripción                                             |
|-----------|---------|-------------------|---------------------------------------------------------|
| `W`       | integer | `8`               | Ancho en bits de la salida y registros internos (`fib_out`, `a`, `b`) |

> **Nota:** El diseñador debe ser consciente de que para valores de `W` pequeños, la secuencia puede desbordarse (overflow). El comportamiento en desbordamiento es por definición el comportamiento natural de aritmética sin signo en ese ancho de bits (wrap-around). El plan de verificación debe contemplar este caso.

---

## 3. Puertos de Entrada / Salida

| Señal     | Ancho    | Dirección | Descripción                                         |
|-----------|----------|-----------|-----------------------------------------------------|
| `clk`     | 1        | Input     | Reloj del sistema. Activo en flanco de subida.      |
| `rst_n`   | 1        | Input     | Reset asíncrono activo en bajo.                     |
| `enable`  | 1        | Input     | Habilitación del generador. Activo en alto.         |
| `fib_out` | `[W-1:0]`| Output    | Salida del valor actual de la secuencia Fibonacci.  |

---

## 4. Descripción Funcional

### 4.1 Estado Interno

El módulo mantiene dos registros internos de `W` bits:

- **`a`**: Almacena el valor del elemento actual de la secuencia (F(n)).
- **`b`**: Almacena el valor del siguiente elemento de la secuencia (F(n+1)).

La salida `fib_out` refleja el valor de `a` en cada ciclo.

### 4.2 Lógica de Transición de Estado

En cada flanco de subida del reloj:

```
if (!rst_n):
    a <= 0
    b <= 1

else if (enable):
    a <= b
    b <= a + b

else:
    a <= a    // Hold
    b <= b    // Hold
```

### 4.3 Reset (RST-001)

- El reset es **asíncrono** y **activo en bajo** (`rst_n = 0`).
- Al activarse el reset, los registros se inicializan a:
  - `a = 0`
  - `b = 1`
- Esto garantiza que al liberar el reset y activar `enable`, la secuencia de salida comience en `0, 1, 1, 2, 3, 5, ...`
- `fib_out` deberá mostrar `0` en el primer ciclo después del reset.

### 4.4 Avance de la Secuencia — Enable Activo (SEQ-001)

- Cuando `enable = 1`, en cada flanco de subida del reloj:
  - `a` toma el valor previo de `b`.
  - `b` toma el valor de `a + b` (calculado con los valores previos).
  - `fib_out` presenta el nuevo valor de `a`.

### 4.5 Retención de Valor — Enable Inactivo (HLD-001)

- Cuando `enable = 0`, el estado interno (`a`, `b`) y la salida (`fib_out`) permanecen sin cambios.
- El generador puede reanudar la secuencia desde donde se detuvo al volver a activar `enable`.

---

## 5. Diagrama de Estados

```
         rst_n = 0 (asíncrono)
              │
              ▼
        ┌─────────────┐
        │  RESET      │  a=0, b=1, fib_out=0
        └──────┬──────┘
               │ rst_n = 1
               ▼
        ┌─────────────────────────────────┐
        │  IDLE / HOLD                    │
        │  enable = 0                     │  fib_out = a (sin cambio)
        │  a <= a,  b <= b                │
        └──────┬──────────────────────────┘
               │ enable = 1
               ▼
        ┌─────────────────────────────────┐
        │  ADVANCE                        │
        │  a <= b                         │  fib_out = b (nuevo a)
        │  b <= a + b                     │
        └─────────────────────────────────┘
               │ enable = 0  →  regresa a IDLE/HOLD
               │ enable = 1  →  permanece en ADVANCE
```

---

## 6. Comportamiento Esperado — Tabla de Verdad / Simulación

| Ciclo | `rst_n` | `enable` | `a` (interno) | `b` (interno) | `fib_out` |
|-------|---------|----------|---------------|---------------|-----------|
| 0     | 0       | x        | 0             | 1             | 0         |
| 1     | 1       | 1        | 1             | 1             | 1         |
| 2     | 1       | 1        | 1             | 2             | 1         |
| 3     | 1       | 1        | 2             | 3             | 2         |
| 4     | 1       | 0        | 2             | 3             | 2         | ← Hold
| 5     | 1       | 0        | 2             | 3             | 2         | ← Hold
| 6     | 1       | 1        | 3             | 5             | 3         |
| 7     | 1       | 1        | 5             | 8             | 5         |

---

## 7. Requisitos Verificables

| ID       | Categoría  | Descripción                                                                                   |
|----------|------------|-----------------------------------------------------------------------------------------------|
| RST-001  | Reset      | Al activar `rst_n=0`, `fib_out` debe ser `0` independientemente del estado anterior.         |
| RST-002  | Reset      | Tras liberar el reset con `enable=1`, la secuencia debe comenzar: `0 → 1 → 1 → 2 → 3 → 5`. |
| SEQ-001  | Secuencia  | Con `enable=1` continuo, la salida debe seguir la secuencia de Fibonacci válida.             |
| SEQ-002  | Secuencia  | `F(n) = F(n-1) + F(n-2)` debe cumplirse en cada paso de avance.                             |
| HLD-001  | Hold       | Con `enable=0`, `fib_out` no debe cambiar en ningún flanco de reloj.                         |
| HLD-002  | Hold       | Al reactivar `enable=1` tras hold, la secuencia continúa desde el valor retenido.            |
| OVF-001  | Overflow   | El módulo debe manejar wrap-around natural para el ancho `W` configurado.                    |
| PAR-001  | Parámetro  | El módulo debe ser instanciable con distintos valores de `W` (ej. 8, 16, 32 bits).           |

---

## 8. Consideraciones de Implementación RTL

- Usar `always_ff` para los registros secuenciales.
- Usar `always_comb` o asignación continua para la lógica combinacional de suma (`next_b = a + b`).
- Declarar el módulo con el parámetro `W` usando la sintaxis de parámetros de SystemVerilog:
  ```systemverilog
  module fibonacci #(parameter int W = 8) ( ... );
  ```
- La salida `fib_out` debe ser asignación directa del registro `a` (sin lógica adicional).
- No se requiere lógica de detección de overflow; el comportamiento de wrap-around es aceptable.

---

## 9. Archivos del Proyecto

```
fibonacci-seq-gen/
├── docs/
│   ├── Specs.md          ← Este archivo
│   ├── test_plan.md
│   └── verif_plan.md
├── rtl/
│   └── fibonacci.sv      ← Archivo RTL a implementar
└── verification/
```

---

*Especificaciones sujetas a revisión conforme avance el proyecto.*
