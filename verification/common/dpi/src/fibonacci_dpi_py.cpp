//==============================================================================
// [Filename]     fibonacci_dpi_py.cpp
// [Project]      fibonacci-seq-gen
// [Language]     C++ (embeds CPython)
// [Created]      2026
// [Description]  DPI-C wrapper exposing fibonacci_step() to SystemVerilog,
//                 same as fibonacci_dpi.cpp, but forwards the call to the
//                 pure-Python reference model in fibonacci_model.py via the
//                 embedded CPython interpreter instead of the C++ Fibonacci
//                 class. The exported symbol and signature are IDENTICAL to
//                 fibonacci_dpi.cpp, so verification/directed/tests/test.sv
//                 needs zero changes to switch backends -- only the .so
//                 loaded via -sv_lib (see DPI_BACKEND in project.mk) differs.
// [Notes]         Runtime requirements:
//                   - libpython3.x.so reachable by the dynamic linker
//                     (normally already true if python3-config --embed was
//                     used at link time -- see dpi.mk's build-dpi-py target).
//                   - DPI_PY_SRC_DIR environment variable set to the
//                     directory containing fibonacci_model.py
//                     (verification/common/dpi/src), so the embedded
//                     interpreter can `import fibonacci_model`. project.mk
//                     exports this automatically when DPI_BACKEND=python.
// [Status]        experimental (DPI_BACKEND=python) 
//==============================================================================

#include "svdpi.h"
#include <Python.h>
#include <cstdio>
#include <cstdlib>

static PyObject* g_step_func = nullptr;

// Lazily initialize the embedded interpreter and resolve fibonacci_model.step
// on the first DPI call. Mirrors the lazy-init-free `static Fibonacci
// g_dut(32);` in fibonacci_dpi.cpp, except CPython needs an explicit
// Py_Initialize() before anything else can happen.
static void py_init_once() {
  if (Py_IsInitialized()) {
    return;
  }

  Py_Initialize();

  const char* extra_path = std::getenv("DPI_PY_SRC_DIR");
  if (extra_path != nullptr) {
    PyObject* sys_path = PySys_GetObject("path");  // borrowed ref
    PyObject* py_extra = PyUnicode_FromString(extra_path);
    PyList_Append(sys_path, py_extra);
    Py_DECREF(py_extra);
  } else {
    fprintf(stderr,
        "[fibonacci_dpi_py] WARNING: DPI_PY_SRC_DIR not set; relying on "
        "default sys.path to find fibonacci_model.py.\n");
  }

  PyObject* module = PyImport_ImportModule("fibonacci_model");
  if (module == nullptr) {
    PyErr_Print();
    fprintf(stderr,
        "[fibonacci_dpi_py] ERROR: could not import 'fibonacci_model'. "
        "Set DPI_PY_SRC_DIR to verification/common/dpi/src.\n");
    exit(1);
  }

  g_step_func = PyObject_GetAttrString(module, "step");
  Py_DECREF(module);

  if (g_step_func == nullptr || PyCallable_Check(g_step_func) == 0) {
    PyErr_Print();
    fprintf(stderr,
        "[fibonacci_dpi_py] ERROR: fibonacci_model.step() not found or not "
        "callable.\n");
    exit(1);
  }
}

extern "C" void fibonacci_step(
    svBit rst_n,
    svBit enable,
    unsigned int* fib_out
) {
  py_init_once();

  PyObject* result = PyObject_CallFunction(
      g_step_func, "(ii)", static_cast<int>(rst_n), static_cast<int>(enable));

  if (result == nullptr) {
    PyErr_Print();
    fprintf(stderr, "[fibonacci_dpi_py] ERROR: fibonacci_model.step() call failed.\n");
    exit(1);
  }

  *fib_out = static_cast<unsigned int>(PyLong_AsUnsignedLong(result));
  Py_DECREF(result);
}
