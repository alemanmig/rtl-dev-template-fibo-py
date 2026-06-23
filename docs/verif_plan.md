# Plan de Verificación: Generador de Secuencia Fibonacci

**Módulo:** `fibonacci.sv`
**Revisión:** 1.0
**Fecha:** 2026-05-22
**Referencia:** `docs/Specs.md`

---

## 1. Objetivo

Verificar que el módulo `fibonacci` cumple con todos los requisitos funcionales descritos en `Specs.md`, garantizando correctitud de la secuencia, comportamiento del reset asíncrono, retención de estado (hold) y funcionalidad con distintos anchos de parámetro `W`.

---

## 2. Alcance

| Incluido en verificación                          | Excluido                              |
|---------------------------------------------------|---------------------------------------|
| Lógica secuencial (`a`, `b` registers)            | Síntesis y timing post-layout         |
| Reset asíncrono activo en bajo                    | Verificación formal exhaustiva        |
| Habilitación (`enable`) y hold                    | Verificación a nivel de sistema       |
| Parámetro `W` (8, 16, 32 bits)                    | Protocolos de bus externos            |
| Wrap-around aritmético (overflow natural)         |                                       |

---

## 3. Metodología

La verificación se divide en dos etapas progresivas:

### Etapa 1 — Verificación Directa del RTL (Direct RTL Verification)
Testbench en SystemVerilog con:
- **Modelo de referencia** implementado en SystemVerilog (golden model).
- **Assertions** (`assert property`) para propiedades temporales críticas.
- **Functional Coverage** (`covergroup` / `coverpoint`) para medir exhaustividad.
- Comparación ciclo a ciclo entre DUT y modelo de referencia (scoreboard).

### Etapa 2 — UVM (Universal Verification Methodology)
- Generación del template base con `uvcgen`.
- Agente UVM con driver, monitor y scoreboard.
- Secuencias aleatorias y dirigidas.
- Reutilización del modelo de referencia de la Etapa 1.

> Este documento cubre la **Etapa 1**. El plan UVM se detallará en un documento separado.

---

## 4. Entorno de Verificación (Etapa 1)

```
┌──────────────────────────────────────────────────────────────┐
│                        Testbench Top                         │
│                                                              │
│  ┌───────────────┐       ┌──────────────────────────────┐   │
│  │   Stimulus    │──────▶│         DUT                  │   │
│  │  Generator    │       │     fibonacci.sv             │   │
│  └───────────────┘       └──────────────┬───────────────┘   │
│                                         │ fib_out            │
│  ┌───────────────┐                      │                    │
│  │   Reference   │──────────────────────▼                    │
│  │    Model      │       ┌──────────────────────────────┐   │
│  │  (SV golden)  │──────▶│        Scoreboard            │   │
│  └───────────────┘       │  (comparación ciclo a ciclo) │   │
│                          └──────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  SVA Checker  (assertions + cover properties)       │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Functional Coverage (covergroup fib_cg)            │    │
│  └─────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

### 4.1 Modelo de Referencia (Reference Model)

Implementado en SystemVerilog puro. Replica la lógica del DUT sin sintetizarse:

```systemverilog
// Pseudocódigo del modelo de referencia
class fibonacci_ref_model #(int W = 8);
    logic [W-1:0] a, b;

    function void reset();
        a = 0; b = 1;
    endfunction

    function logic [W-1:0] next(input logic enable);
        logic [W-1:0] tmp;
        if (enable) begin
            tmp = a + b;
            a   = b;
            b   = tmp;
        end
        return a;
    endfunction
endclass
```

### 4.2 Assertions (SVA)

| ID Assertion | Propiedad verificada                                          | Tipo        |
|--------------|---------------------------------------------------------------|-------------|
| `AST_RST`    | `rst_n==0 |=> fib_out==0`                                    | `assert`    |
| `AST_SEQ`    | Secuencia válida: `fib_out == prev_a + prev_b` tras enable   | `assert`    |
| `AST_HLD`    | `!enable |=> $stable(fib_out)`                               | `assert`    |
| `AST_HOLD_B` | `!enable |=> $stable(b_internal)` *(si accesible)*           | `assert`    |
| `COV_EN`     | `enable` toggleado durante la simulación                     | `cover`     |
| `COV_RST`    | Reset asertado y liberado al menos una vez                   | `cover`     |

### 4.3 Functional Coverage

```systemverilog
covergroup fib_cg @(posedge clk);

    cp_enable: coverpoint enable {
        bins enabled  = {1};
        bins disabled = {0};
    }

    cp_rst: coverpoint rst_n {
        bins active   = {0};
        bins inactive = {1};
    }

    cp_enable_rst: cross cp_enable, cp_rst;

    cp_fib_out: coverpoint fib_out {
        bins zero       = {0};
        bins small      = {[1:15]};
        bins medium     = {[16:127]};
        bins large      = {[128:$]};
        bins overflow   = default;   // Solo relevante para W pequeños
    }

    cp_transitions: coverpoint enable {
        bins en_to_dis  = (1 => 0);
        bins dis_to_en  = (0 => 1);
    }

endgroup
```

---

## 5. Métricas de Cierre (Exit Criteria)

| Métrica                            | Objetivo  |
|------------------------------------|-----------|
| Cobertura funcional total          | ≥ 95 %    |
| Cobertura de código (línea)        | ≥ 90 %    |
| Cobertura de código (rama/toggle)  | ≥ 85 %    |
| Assertions fallidas                | 0         |
| Casos de prueba dirigidos pasando  | 100 %     |
| Simulación con W=8, W=16, W=32     | Completa  |

---

## 6. Requisitos Cubiertos por la Verificación

| Req. ID  | Descripción breve                          | Assertion     | Test Case(s)           | Coverage Point   |
|----------|--------------------------------------------|---------------|------------------------|------------------|
| RST-001  | `fib_out=0` al reset                       | `AST_RST`     | TC-RST-01, TC-RST-02   | `cp_rst`         |
| RST-002  | Secuencia correcta tras reset              | `AST_SEQ`     | TC-RST-03              | `cp_fib_out`     |
| SEQ-001  | Secuencia Fibonacci con enable continuo    | `AST_SEQ`     | TC-SEQ-01              | `cp_enable`      |
| SEQ-002  | F(n) = F(n-1) + F(n-2)                    | `AST_SEQ`     | TC-SEQ-02              | `cp_fib_out`     |
| HLD-001  | Hold cuando enable=0                       | `AST_HLD`     | TC-HLD-01              | `cp_transitions` |
| HLD-002  | Reanuda desde valor retenido               | —             | TC-HLD-02              | `cp_transitions` |
| OVF-001  | Wrap-around natural para W bits            | —             | TC-OVF-01              | `cp_fib_out`     |
| PAR-001  | Instanciable con distintos W               | —             | TC-PAR-01..03          | —                |

---

## 7. Herramientas y Simulador

| Herramienta         | Propósito                              |
|---------------------|----------------------------------------|
| Icarus Verilog / VCS / Questa | Simulación RTL                 |
| `$dumpfile` / GTKWave       | Visualización de waveforms     |
| SystemVerilog Assertions    | Chequeo de propiedades         |
| `$coverage_save`            | Reporte de cobertura funcional |

---

## 8. Estructura de Archivos de Verificación

```
fibonacci-seq-gen/
└── verification/
    ├── tb_fibonacci.sv         ← Testbench top
    ├── fibonacci_ref_model.sv  ← Modelo de referencia
    ├── fibonacci_sva.sv        ← SVA checker (assertions + cover)
    ├── fibonacci_cov.sv        ← Covergroups de cobertura funcional
    └── tests/
        ├── tc_rst.sv           ← Tests de reset
        ├── tc_seq.sv           ← Tests de secuencia
        ├── tc_hld.sv           ← Tests de hold
        ├── tc_ovf.sv           ← Tests de overflow
        └── tc_par.sv           ← Tests paramétricos
```

---

*Documento sujeto a actualización al avanzar hacia la Etapa 2 (UVM).*
