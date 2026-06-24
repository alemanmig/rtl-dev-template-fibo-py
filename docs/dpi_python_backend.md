# DPI con Backend en Python (Experimental)

**Proyecto:** `fibonacci-seq-gen`
**Estado:** experimental
**Relacionado:** `verification/common/dpi/`, `verification/directed/scripts/mk/project.mk`

---

## 1. Resumen

SystemVerilog solo define `import "DPI-C"` — no existe un mecanismo nativo "DPI-Python". Lo que se implementó aquí es un **segundo backend** para el modelo de referencia DPI, donde la lógica de la recurrencia de Fibonacci vive en un módulo Python y un *shim* en C++ embebe el intérprete de CPython para exponerla con el mismo símbolo DPI-C de siempre.

`verification/directed/tests/test.sv` **no cambia**: sigue declarando

```systemverilog
import "DPI-C" function void fibonacci_step(
  input  bit          rst_n,
  input  bit          enable,
  output int unsigned fib_out
);
```

Lo único que cambia es **qué librería `.so`** se carga en tiempo de ejecución vía `-sv_lib`.

---

## 2. Arquitectura

```
                    ┌─────────────────────────┐
  test.sv  ───DPI──▶│   fibonacci_step()       │   (mismo símbolo C, siempre)
                    └────────────┬─────────────┘
                                 │
              ┌──────────────────┴───────────────────┐
              │                                       │
     DPI_BACKEND=cpp                         DPI_BACKEND=python
              │                                       │
   ┌──────────▼──────────┐               ┌────────────▼─────────────┐
   │ fibonacci_dpi.cpp    │               │ fibonacci_dpi_py.cpp      │
   │  -> clase Fibonacci  │               │  -> embebe CPython        │
   │     (C++ puro)       │               │  -> llama fibonacci_      │
   │                      │               │     model.step()          │
   └──────────────────────┘               └────────────┬─────────────┘
              │                                       │
        libdpi.so                                fibonacci_model.py
                                              (libdpi_py.so + libpython3.x.so)
```

VCS/`simv` nunca "corre Python" directamente: carga un `.so` con ABI de C como siempre. Ese `.so` simplemente, por dentro, levanta un intérprete CPython y delega la llamada.

---

## 3. Archivos involucrados

| Archivo | Tipo | Descripción |
|---|---|---|
| `verification/common/dpi/src/fibonacci_model.py` | Nuevo | Puerto fiel a Python de `Fibonacci::step()` (reset / enable / hold / wrap-around a `2^32`). Estado a nivel de módulo, persistente durante la vida del proceso `simv`. |
| `verification/common/dpi/src/fibonacci_dpi_py.cpp` | Nuevo | Shim DPI-C. Inicializa CPython de forma diferida (lazy), importa `fibonacci_model`, y reenvía cada llamada a `step()`. |
| `verification/common/dpi/src/fibonacci_dpi.cpp` | Sin cambios | Backend original en C++ puro. |
| `verification/common/mk/dpi.mk` | Modificado | Nuevo target `build-dpi-py`, usa `python3-config --includes` / `--ldflags --embed`. |
| `verification/directed/scripts/mk/project.mk` | Modificado | Variable `DPI_BACKEND` (`cpp` por defecto / `python`), exporta `DPI_PY_SRC_DIR` y ajusta `LD_LIBRARY_PATH`. |

---

## 4. Variables de Makefile

| Variable | Default | Efecto |
|---|---|---|
| `DPI_BACKEND` | `cpp` | `cpp` → carga `libdpi.so`. `python` → carga `libdpi_py.so` y activa todo lo de abajo. |
| `PYTHON3` | `python3` | Binario de Python usado por `python3-config` (build **y** run deben usar el mismo, p. ej. el de un entorno conda). |
| `DPI_PY_SRC_DIR` | *(auto)* | Exportada automáticamente a `verification/common/dpi/src` cuando `DPI_BACKEND=python`, para que el intérprete embebido encuentre `fibonacci_model.py`. |
| `LD_LIBRARY_PATH` | *(auto)* | Se le antepone `$(python3-config --prefix)/lib` cuando `DPI_BACKEND=python`, para que `simv` resuelva `libpython3.x.so` sin depender de que la shell ya lo tenga seteado. |

---

## 5. Requisitos previos

Se necesitan headers de desarrollo de Python (`Python.h`) y una `libpython3.x.so` embebible. En servidores RHEL de farms de EDA, donde normalmente no hay acceso `root`, la vía recomendada es un entorno **conda** en espacio de usuario (los paquetes `python` de conda ya incluyen `python3-config`, headers y la librería compartida):

```bash
conda create -n dpi_py python=3.10 -y
conda activate dpi_py
which python3-config        # debe resolver dentro del env
python3-config --includes
python3-config --ldflags --embed
```

> Activá ese entorno en la **misma terminal** donde después se corre `make build-dpi-py` / `make compile` / `make sim`.

---

## 6. Comandos

**Backend Python:**
```bash
make build-dpi-py DPI_BACKEND=python PYTHON3=python3
make compile
make sim DPI_BACKEND=python PYTHON3=python3
```

**Volver al backend C++ original:**
```bash
make build-dpi
make sim
```

`make compile` no depende de `DPI_BACKEND` — el backend solo afecta flags de *runtime* (`-sv_lib`), no de compilación de VCS.

---

## 7. Problemas encontrados durante la prueba (y su causa)

| Síntoma | Causa | Solución |
|---|---|---|
| `Error-[SHARED-LIBRARY-ACCESS] ... libdpi.so: cannot open shared object file` después de un `build-dpi-py` exitoso | Se corrió `make sim` sin `DPI_BACKEND=python`; volvió al default `cpp`, que apunta a `libdpi.so` (nunca compilado en este flujo). | Pasar `DPI_BACKEND=python` también en `make sim`, no solo en el build. |
| `Error-[SHARED-LIBRARY-ACCESS] ... libpython3.10.so.1.0: cannot open shared object file` | `libdpi_py.so` se encontró bien (ruta absoluta de `-sv_lib`), pero su dependencia `libpython3.10.so` no estaba en el *search path* del *linker* dinámico — `conda activate` no agrega `$CONDA_PREFIX/lib` a `LD_LIBRARY_PATH` por defecto. | `project.mk` ahora calcula `$(python3-config --prefix)/lib` y lo antepone a `LD_LIBRARY_PATH` automáticamente cuando `DPI_BACKEND=python`. |

---

## 8. Validación realizada

Sin VCS disponible para validar directamente, se compiló el archivo `fibonacci_dpi_py.cpp` real (con un `svdpi.h` *stub* ABI-compatible: `svBit` es `unsigned char`, igual que en el header real de Synopsys) y se cargó el `.so` resultante con `dlopen`/`dlsym`, exactamente como lo hace `simv` vía `-sv_lib`.

Resultado: la secuencia generada coincide **bit a bit** con los valores reales observados en el log de `make sim` del usuario (corrida con VCS real), incluyendo la zona de *wrap-around* a `2^32` (`TC-OVF-02-post`: `3185141890, 2886509027, 1776683621, ...`). También se verificaron reset, hold, y reset-domina-sobre-enable.

---

## 9. Limitaciones conocidas

- **Overhead por llamada**: cada `fibonacci_step()` adquiere el GIL y hace una llamada Python — irrelevante para este test directed (pocos miles de ciclos), pero no escalaría bien a regresiones UVM masivas.
- **Sin `Py_Finalize()`**: el intérprete embebido no se cierra explícitamente al `$finish`; no afecta la corrida pero es una limpieza pendiente.
- **Solo tiene sentido como ejercicio**: para este modelo de Fibonacci tan simple, el backend Python no aporta nada funcional sobre el C++ existente. Sería útil si se quisiera reutilizar un modelo en `numpy`/`scipy`, o compartir el golden model con un script de análisis externo.
