"use strict";

function _typeof(obj) {
  "@babel/helpers - typeof";
  return (
    (_typeof =
      "function" == typeof Symbol && "symbol" == typeof Symbol.iterator
        ? function (obj) {
            return typeof obj;
          }
        : function (obj) {
            return obj &&
              "function" == typeof Symbol &&
              obj.constructor === Symbol &&
              obj !== Symbol.prototype
              ? "symbol"
              : typeof obj;
          }),
    _typeof(obj)
  );
}

var _BLS12381 = (function () {
  var _scriptDir =
    typeof document !== "undefined" && document.currentScript
      ? document.currentScript.src
      : undefined;

  if (typeof __filename !== "undefined") _scriptDir = _scriptDir || __filename;
  return (function (_BLS12381) {
    _BLS12381 = _BLS12381 || {};
    var Module = typeof _BLS12381 != "undefined" ? _BLS12381 : {};
    var readyPromiseResolve, readyPromiseReject;
    Module["ready"] = new Promise(function (resolve, reject) {
      readyPromiseResolve = resolve;
      readyPromiseReject = reject;
    });
    var moduleOverrides = Object.assign({}, Module);
    var arguments_ = [];
    var thisProgram = "./this.program";

    var quit_ = function quit_(status, toThrow) {
      throw toThrow;
    };

    var ENVIRONMENT_IS_WEB =
      (typeof window === "undefined" ? "undefined" : _typeof(window)) ==
      "object";
    var ENVIRONMENT_IS_WORKER = typeof importScripts == "function";
    var ENVIRONMENT_IS_NODE =
      (typeof process === "undefined" ? "undefined" : _typeof(process)) ==
        "object" &&
      _typeof(process.versions) == "object" &&
      typeof process.versions.node == "string";
    var scriptDirectory = "";

    function locateFile(path) {
      if (Module["locateFile"]) {
        return Module["locateFile"](path, scriptDirectory);
      }

      return scriptDirectory + path;
    }

    var read_, readAsync, readBinary, setWindowTitle;

    function logExceptionOnExit(e) {
      if (e instanceof ExitStatus) return;
      var toLog = e;
      err("exiting due to exception: " + toLog);
    }

    var fs;
    var nodePath;
    var requireNodeFS;

    if (ENVIRONMENT_IS_NODE) {
      if (ENVIRONMENT_IS_WORKER) {
        scriptDirectory = require("path").dirname(scriptDirectory) + "/";
      } else {
        scriptDirectory = __dirname + "/";
      }

      requireNodeFS = function requireNodeFS() {
        if (!nodePath) {
          fs = require("fs");
          nodePath = require("path");
        }
      };

      read_ = function shell_read(filename, binary) {
        requireNodeFS();
        filename = nodePath["normalize"](filename);
        return fs.readFileSync(filename, binary ? undefined : "utf8");
      };

      readBinary = function readBinary(filename) {
        var ret = read_(filename, true);

        if (!ret.buffer) {
          ret = new Uint8Array(ret);
        }

        return ret;
      };

      readAsync = function readAsync(filename, onload, onerror) {
        requireNodeFS();
        filename = nodePath["normalize"](filename);
        fs.readFile(filename, function (err, data) {
          if (err) onerror(err);
          else onload(data.buffer);
        });
      };

      if (process["argv"].length > 1) {
        thisProgram = process["argv"][1].replace(/\\/g, "/");
      }

      arguments_ = process["argv"].slice(2);
      process["on"]("uncaughtException", function (ex) {
        if (!(ex instanceof ExitStatus)) {
          throw ex;
        }
      });
      process["on"]("unhandledRejection", function (reason) {
        throw reason;
      });

      quit_ = function quit_(status, toThrow) {
        if (keepRuntimeAlive()) {
          process["exitCode"] = status;
          throw toThrow;
        }

        logExceptionOnExit(toThrow);
        process["exit"](status);
      };

      Module["inspect"] = function () {
        return "[Emscripten Module object]";
      };
    } else if (ENVIRONMENT_IS_WEB || ENVIRONMENT_IS_WORKER) {
      if (ENVIRONMENT_IS_WORKER) {
        scriptDirectory = self.location.href;
      } else if (typeof document != "undefined" && document.currentScript) {
        scriptDirectory = document.currentScript.src;
      }

      if (_scriptDir) {
        scriptDirectory = _scriptDir;
      }

      if (scriptDirectory.indexOf("blob:") !== 0) {
        scriptDirectory = scriptDirectory.substr(
          0,
          scriptDirectory.replace(/[?#].*/, "").lastIndexOf("/") + 1
        );
      } else {
        scriptDirectory = "";
      }

      {
        read_ = function read_(url) {
          var xhr = new XMLHttpRequest();
          xhr.open("GET", url, false);
          xhr.send(null);
          return xhr.responseText;
        };

        if (ENVIRONMENT_IS_WORKER) {
          readBinary = function readBinary(url) {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", url, false);
            xhr.responseType = "arraybuffer";
            xhr.send(null);
            return new Uint8Array(xhr.response);
          };
        }

        readAsync = function readAsync(url, onload, onerror) {
          var xhr = new XMLHttpRequest();
          xhr.open("GET", url, true);
          xhr.responseType = "arraybuffer";

          xhr.onload = function () {
            if (xhr.status == 200 || (xhr.status == 0 && xhr.response)) {
              onload(xhr.response);
              return;
            }

            onerror();
          };

          xhr.onerror = onerror;
          xhr.send(null);
        };
      }

      setWindowTitle = function setWindowTitle(title) {
        return (document.title = title);
      };
    } else {
    }

    var out = Module["print"] || console.log.bind(console);
    var err = Module["printErr"] || console.warn.bind(console);
    Object.assign(Module, moduleOverrides);
    moduleOverrides = null;
    if (Module["arguments"]) arguments_ = Module["arguments"];
    if (Module["thisProgram"]) thisProgram = Module["thisProgram"];
    if (Module["quit"]) quit_ = Module["quit"];
    var wasmBinary;
    if (Module["wasmBinary"]) wasmBinary = Module["wasmBinary"];
    var noExitRuntime = Module["noExitRuntime"] || true;

    if (
      (typeof WebAssembly === "undefined"
        ? "undefined"
        : _typeof(WebAssembly)) != "object"
    ) {
      abort("no native wasm support detected");
    }

    var wasmMemory;
    var ABORT = false;
    var EXITSTATUS;

    function alignUp(x, multiple) {
      if (x % multiple > 0) {
        x += multiple - (x % multiple);
      }

      return x;
    }

    var buffer,
      HEAP8,
      HEAPU8,
      HEAP16,
      HEAPU16,
      HEAP32,
      HEAPU32,
      HEAPF32,
      HEAPF64;

    function updateGlobalBufferAndViews(buf) {
      buffer = buf;
      Module["HEAP8"] = HEAP8 = new Int8Array(buf);
      Module["HEAP16"] = HEAP16 = new Int16Array(buf);
      Module["HEAP32"] = HEAP32 = new Int32Array(buf);
      Module["HEAPU8"] = HEAPU8 = new Uint8Array(buf);
      Module["HEAPU16"] = HEAPU16 = new Uint16Array(buf);
      Module["HEAPU32"] = HEAPU32 = new Uint32Array(buf);
      Module["HEAPF32"] = HEAPF32 = new Float32Array(buf);
      Module["HEAPF64"] = HEAPF64 = new Float64Array(buf);
    }

    var INITIAL_MEMORY = Module["INITIAL_MEMORY"] || 16777216;
    var wasmTable;
    var __ATPRERUN__ = [];
    var __ATINIT__ = [];
    var __ATPOSTRUN__ = [];
    var runtimeInitialized = false;
    var runtimeKeepaliveCounter = 0;

    function keepRuntimeAlive() {
      return noExitRuntime || runtimeKeepaliveCounter > 0;
    }

    function preRun() {
      if (Module["preRun"]) {
        if (typeof Module["preRun"] == "function")
          Module["preRun"] = [Module["preRun"]];

        while (Module["preRun"].length) {
          addOnPreRun(Module["preRun"].shift());
        }
      }

      callRuntimeCallbacks(__ATPRERUN__);
    }

    function initRuntime() {
      runtimeInitialized = true;
      callRuntimeCallbacks(__ATINIT__);
    }

    function postRun() {
      if (Module["postRun"]) {
        if (typeof Module["postRun"] == "function")
          Module["postRun"] = [Module["postRun"]];

        while (Module["postRun"].length) {
          addOnPostRun(Module["postRun"].shift());
        }
      }

      callRuntimeCallbacks(__ATPOSTRUN__);
    }

    function addOnPreRun(cb) {
      __ATPRERUN__.unshift(cb);
    }

    function addOnInit(cb) {
      __ATINIT__.unshift(cb);
    }

    function addOnPostRun(cb) {
      __ATPOSTRUN__.unshift(cb);
    }

    var runDependencies = 0;
    var runDependencyWatcher = null;
    var dependenciesFulfilled = null;

    function addRunDependency(id) {
      runDependencies++;

      if (Module["monitorRunDependencies"]) {
        Module["monitorRunDependencies"](runDependencies);
      }
    }

    function removeRunDependency(id) {
      runDependencies--;

      if (Module["monitorRunDependencies"]) {
        Module["monitorRunDependencies"](runDependencies);
      }

      if (runDependencies == 0) {
        if (runDependencyWatcher !== null) {
          clearInterval(runDependencyWatcher);
          runDependencyWatcher = null;
        }

        if (dependenciesFulfilled) {
          var callback = dependenciesFulfilled;
          dependenciesFulfilled = null;
          callback();
        }
      }
    }

    Module["preloadedImages"] = {};
    Module["preloadedAudios"] = {};

    function abort(what) {
      {
        if (Module["onAbort"]) {
          Module["onAbort"](what);
        }
      }
      what = "Aborted(" + what + ")";
      err(what);
      ABORT = true;
      EXITSTATUS = 1;
      what += ". Build with -s ASSERTIONS=1 for more info.";
      var e = new WebAssembly.RuntimeError(what);
      readyPromiseReject(e);
      throw e;
    }

    var dataURIPrefix = "data:application/octet-stream;base64,";

    function isDataURI(filename) {
      return filename.startsWith(dataURIPrefix);
    }

    function isFileURI(filename) {
      return filename.startsWith("file://");
    }

    var wasmBinaryFile;
    wasmBinaryFile = "blst.wasm";

    if (!isDataURI(wasmBinaryFile)) {
      wasmBinaryFile = locateFile(wasmBinaryFile);
    }

    function getBinary(file) {
      try {
        if (file == wasmBinaryFile && wasmBinary) {
          return new Uint8Array(wasmBinary);
        }

        if (readBinary) {
          return readBinary(file);
        } else {
          throw "both async and sync fetching of the wasm failed";
        }
      } catch (err) {
        abort(err);
      }
    }

    function getBinaryPromise() {
      if (!wasmBinary && (ENVIRONMENT_IS_WEB || ENVIRONMENT_IS_WORKER)) {
        if (typeof fetch == "function" && !isFileURI(wasmBinaryFile)) {
          return fetch(wasmBinaryFile, {
            credentials: "same-origin",
          })
            .then(function (response) {
              if (!response["ok"]) {
                throw (
                  "failed to load wasm binary file at '" + wasmBinaryFile + "'"
                );
              }

              return response["arrayBuffer"]();
            })
            ["catch"](function () {
              return getBinary(wasmBinaryFile);
            });
        } else {
          if (readAsync) {
            return new Promise(function (resolve, reject) {
              readAsync(
                wasmBinaryFile,
                function (response) {
                  resolve(new Uint8Array(response));
                },
                reject
              );
            });
          }
        }
      }

      return Promise.resolve().then(function () {
        return getBinary(wasmBinaryFile);
      });
    }

    function createWasm() {
      var info = {
        a: asmLibraryArg,
      };

      function receiveInstance(instance, module) {
        var exports = instance.exports;
        Module["asm"] = exports;
        wasmMemory = Module["asm"]["c"];
        updateGlobalBufferAndViews(wasmMemory.buffer);
        wasmTable = Module["asm"]["ta"];
        addOnInit(Module["asm"]["d"]);
        removeRunDependency("wasm-instantiate");
      }

      addRunDependency("wasm-instantiate");

      function receiveInstantiationResult(result) {
        receiveInstance(result["instance"]);
      }

      function instantiateArrayBuffer(receiver) {
        return getBinaryPromise()
          .then(function (binary) {
            return WebAssembly.instantiate(binary, info);
          })
          .then(function (instance) {
            return instance;
          })
          .then(receiver, function (reason) {
            err("failed to asynchronously prepare wasm: " + reason);
            abort(reason);
          });
      }

      function instantiateAsync() {
        if (
          !wasmBinary &&
          typeof WebAssembly.instantiateStreaming == "function" &&
          !isDataURI(wasmBinaryFile) &&
          !isFileURI(wasmBinaryFile) &&
          typeof fetch == "function"
        ) {
          return fetch(wasmBinaryFile, {
            credentials: "same-origin",
          }).then(function (response) {
            var result = WebAssembly.instantiateStreaming(response, info);
            return result.then(receiveInstantiationResult, function (reason) {
              err("wasm streaming compile failed: " + reason);
              err("falling back to ArrayBuffer instantiation");
              return instantiateArrayBuffer(receiveInstantiationResult);
            });
          });
        } else {
          return instantiateArrayBuffer(receiveInstantiationResult);
        }
      }

      if (Module["instantiateWasm"]) {
        try {
          var exports = Module["instantiateWasm"](info, receiveInstance);
          return exports;
        } catch (e) {
          err("Module.instantiateWasm callback failed with error: " + e);
          return false;
        }
      }

      instantiateAsync()["catch"](readyPromiseReject);
      return {};
    }

    function callRuntimeCallbacks(callbacks) {
      while (callbacks.length > 0) {
        var callback = callbacks.shift();

        if (typeof callback == "function") {
          callback(Module);
          continue;
        }

        var func = callback.func;

        if (typeof func == "number") {
          if (callback.arg === undefined) {
            getWasmTableEntry(func)();
          } else {
            getWasmTableEntry(func)(callback.arg);
          }
        } else {
          func(callback.arg === undefined ? null : callback.arg);
        }
      }
    }

    function getWasmTableEntry(funcPtr) {
      return wasmTable.get(funcPtr);
    }

    function _emscripten_memcpy_big(dest, src, num) {
      HEAPU8.copyWithin(dest, src, src + num);
    }

    function _emscripten_get_heap_max() {
      return 2147483648;
    }

    function emscripten_realloc_buffer(size) {
      try {
        wasmMemory.grow((size - buffer.byteLength + 65535) >>> 16);
        updateGlobalBufferAndViews(wasmMemory.buffer);
        return 1;
      } catch (e) {}
    }

    function _emscripten_resize_heap(requestedSize) {
      var oldSize = HEAPU8.length;
      requestedSize = requestedSize >>> 0;

      var maxHeapSize = _emscripten_get_heap_max();

      if (requestedSize > maxHeapSize) {
        return false;
      }

      for (var cutDown = 1; cutDown <= 4; cutDown *= 2) {
        var overGrownHeapSize = oldSize * (1 + 0.2 / cutDown);
        overGrownHeapSize = Math.min(
          overGrownHeapSize,
          requestedSize + 100663296
        );
        var newSize = Math.min(
          maxHeapSize,
          alignUp(Math.max(requestedSize, overGrownHeapSize), 65536)
        );
        var replacement = emscripten_realloc_buffer(newSize);

        if (replacement) {
          return true;
        }
      }

      return false;
    }

    var asmLibraryArg = {
      b: _emscripten_memcpy_big,
      a: _emscripten_resize_heap,
    };
    var asm = createWasm();

    var ___wasm_call_ctors = (Module["___wasm_call_ctors"] = function () {
      return (___wasm_call_ctors = Module["___wasm_call_ctors"] =
        Module["asm"]["d"]).apply(null, arguments);
    });

    var _blst_p1_cneg = (Module["_blst_p1_cneg"] = function () {
      return (_blst_p1_cneg = Module["_blst_p1_cneg"] =
        Module["asm"]["e"]).apply(null, arguments);
    });

    var _blst_p1_to_affine = (Module["_blst_p1_to_affine"] = function () {
      return (_blst_p1_to_affine = Module["_blst_p1_to_affine"] =
        Module["asm"]["f"]).apply(null, arguments);
    });

    var _blst_p1_from_affine = (Module["_blst_p1_from_affine"] = function () {
      return (_blst_p1_from_affine = Module["_blst_p1_from_affine"] =
        Module["asm"]["g"]).apply(null, arguments);
    });

    var _blst_p1_serialize = (Module["_blst_p1_serialize"] = function () {
      return (_blst_p1_serialize = Module["_blst_p1_serialize"] =
        Module["asm"]["h"]).apply(null, arguments);
    });

    var _blst_p1_compress = (Module["_blst_p1_compress"] = function () {
      return (_blst_p1_compress = Module["_blst_p1_compress"] =
        Module["asm"]["i"]).apply(null, arguments);
    });

    var _blst_p1_double = (Module["_blst_p1_double"] = function () {
      return (_blst_p1_double = Module["_blst_p1_double"] =
        Module["asm"]["j"]).apply(null, arguments);
    });

    var _blst_p1_is_equal = (Module["_blst_p1_is_equal"] = function () {
      return (_blst_p1_is_equal = Module["_blst_p1_is_equal"] =
        Module["asm"]["k"]).apply(null, arguments);
    });

    var _blst_p1_is_inf = (Module["_blst_p1_is_inf"] = function () {
      return (_blst_p1_is_inf = Module["_blst_p1_is_inf"] =
        Module["asm"]["l"]).apply(null, arguments);
    });

    var _blst_p1_in_g1 = (Module["_blst_p1_in_g1"] = function () {
      return (_blst_p1_in_g1 = Module["_blst_p1_in_g1"] =
        Module["asm"]["m"]).apply(null, arguments);
    });

    var _blst_p2_cneg = (Module["_blst_p2_cneg"] = function () {
      return (_blst_p2_cneg = Module["_blst_p2_cneg"] =
        Module["asm"]["n"]).apply(null, arguments);
    });

    var _blst_p2_to_affine = (Module["_blst_p2_to_affine"] = function () {
      return (_blst_p2_to_affine = Module["_blst_p2_to_affine"] =
        Module["asm"]["o"]).apply(null, arguments);
    });

    var _blst_p2_from_affine = (Module["_blst_p2_from_affine"] = function () {
      return (_blst_p2_from_affine = Module["_blst_p2_from_affine"] =
        Module["asm"]["p"]).apply(null, arguments);
    });

    var _blst_p2_serialize = (Module["_blst_p2_serialize"] = function () {
      return (_blst_p2_serialize = Module["_blst_p2_serialize"] =
        Module["asm"]["q"]).apply(null, arguments);
    });

    var _blst_p2_compress = (Module["_blst_p2_compress"] = function () {
      return (_blst_p2_compress = Module["_blst_p2_compress"] =
        Module["asm"]["r"]).apply(null, arguments);
    });

    var _blst_p2_double = (Module["_blst_p2_double"] = function () {
      return (_blst_p2_double = Module["_blst_p2_double"] =
        Module["asm"]["s"]).apply(null, arguments);
    });

    var _blst_p2_is_equal = (Module["_blst_p2_is_equal"] = function () {
      return (_blst_p2_is_equal = Module["_blst_p2_is_equal"] =
        Module["asm"]["t"]).apply(null, arguments);
    });

    var _blst_p2_is_inf = (Module["_blst_p2_is_inf"] = function () {
      return (_blst_p2_is_inf = Module["_blst_p2_is_inf"] =
        Module["asm"]["u"]).apply(null, arguments);
    });

    var _blst_p2_in_g2 = (Module["_blst_p2_in_g2"] = function () {
      return (_blst_p2_in_g2 = Module["_blst_p2_in_g2"] =
        Module["asm"]["v"]).apply(null, arguments);
    });

    var _blst_fp12_sqr = (Module["_blst_fp12_sqr"] = function () {
      return (_blst_fp12_sqr = Module["_blst_fp12_sqr"] =
        Module["asm"]["w"]).apply(null, arguments);
    });

    var _blst_fp12_inverse = (Module["_blst_fp12_inverse"] = function () {
      return (_blst_fp12_inverse = Module["_blst_fp12_inverse"] =
        Module["asm"]["x"]).apply(null, arguments);
    });

    var _blst_fp12_is_equal = (Module["_blst_fp12_is_equal"] = function () {
      return (_blst_fp12_is_equal = Module["_blst_fp12_is_equal"] =
        Module["asm"]["y"]).apply(null, arguments);
    });

    var _blst_fp12_is_one = (Module["_blst_fp12_is_one"] = function () {
      return (_blst_fp12_is_one = Module["_blst_fp12_is_one"] =
        Module["asm"]["z"]).apply(null, arguments);
    });

    var _blst_final_exp = (Module["_blst_final_exp"] = function () {
      return (_blst_final_exp = Module["_blst_final_exp"] =
        Module["asm"]["A"]).apply(null, arguments);
    });

    var _blst_pairing_sizeof = (Module["_blst_pairing_sizeof"] = function () {
      return (_blst_pairing_sizeof = Module["_blst_pairing_sizeof"] =
        Module["asm"]["B"]).apply(null, arguments);
    });

    var _blst_pairing_commit = (Module["_blst_pairing_commit"] = function () {
      return (_blst_pairing_commit = Module["_blst_pairing_commit"] =
        Module["asm"]["C"]).apply(null, arguments);
    });

    var _blst_fp_sqrt = (Module["_blst_fp_sqrt"] = function () {
      return (_blst_fp_sqrt = Module["_blst_fp_sqrt"] =
        Module["asm"]["D"]).apply(null, arguments);
    });

    var _blst_fp2_sqrt = (Module["_blst_fp2_sqrt"] = function () {
      return (_blst_fp2_sqrt = Module["_blst_fp2_sqrt"] =
        Module["asm"]["E"]).apply(null, arguments);
    });

    var _blst_fr_eucl_inverse = (Module["_blst_fr_eucl_inverse"] = function () {
      return (_blst_fr_eucl_inverse = Module["_blst_fr_eucl_inverse"] =
        Module["asm"]["F"]).apply(null, arguments);
    });

    var _blst_p2s_mult_pippenger_scratch_sizeof = (Module[
      "_blst_p2s_mult_pippenger_scratch_sizeof"
    ] = function () {
      return (_blst_p2s_mult_pippenger_scratch_sizeof = Module[
        "_blst_p2s_mult_pippenger_scratch_sizeof"
      ] =
        Module["asm"]["G"]).apply(null, arguments);
    });

    var _blst_fr_add = (Module["_blst_fr_add"] = function () {
      return (_blst_fr_add = Module["_blst_fr_add"] = Module["asm"]["H"]).apply(
        null,
        arguments
      );
    });

    var _blst_fr_sub = (Module["_blst_fr_sub"] = function () {
      return (_blst_fr_sub = Module["_blst_fr_sub"] = Module["asm"]["I"]).apply(
        null,
        arguments
      );
    });

    var _blst_fr_mul = (Module["_blst_fr_mul"] = function () {
      return (_blst_fr_mul = Module["_blst_fr_mul"] = Module["asm"]["J"]).apply(
        null,
        arguments
      );
    });

    var _blst_fr_sqr = (Module["_blst_fr_sqr"] = function () {
      return (_blst_fr_sqr = Module["_blst_fr_sqr"] = Module["asm"]["K"]).apply(
        null,
        arguments
      );
    });

    var _blst_fr_from_scalar = (Module["_blst_fr_from_scalar"] = function () {
      return (_blst_fr_from_scalar = Module["_blst_fr_from_scalar"] =
        Module["asm"]["L"]).apply(null, arguments);
    });

    var _blst_scalar_from_fr = (Module["_blst_scalar_from_fr"] = function () {
      return (_blst_scalar_from_fr = Module["_blst_scalar_from_fr"] =
        Module["asm"]["M"]).apply(null, arguments);
    });

    var _blst_scalar_fr_check = (Module["_blst_scalar_fr_check"] = function () {
      return (_blst_scalar_fr_check = Module["_blst_scalar_fr_check"] =
        Module["asm"]["N"]).apply(null, arguments);
    });

    var _blst_fp_add = (Module["_blst_fp_add"] = function () {
      return (_blst_fp_add = Module["_blst_fp_add"] = Module["asm"]["O"]).apply(
        null,
        arguments
      );
    });

    var _blst_fp_mul = (Module["_blst_fp_mul"] = function () {
      return (_blst_fp_mul = Module["_blst_fp_mul"] = Module["asm"]["P"]).apply(
        null,
        arguments
      );
    });

    var _blst_fp_cneg = (Module["_blst_fp_cneg"] = function () {
      return (_blst_fp_cneg = Module["_blst_fp_cneg"] =
        Module["asm"]["Q"]).apply(null, arguments);
    });

    var _blst_fp_from_lendian = (Module["_blst_fp_from_lendian"] = function () {
      return (_blst_fp_from_lendian = Module["_blst_fp_from_lendian"] =
        Module["asm"]["R"]).apply(null, arguments);
    });

    var _blst_lendian_from_fp = (Module["_blst_lendian_from_fp"] = function () {
      return (_blst_lendian_from_fp = Module["_blst_lendian_from_fp"] =
        Module["asm"]["S"]).apply(null, arguments);
    });

    var _blst_fp2_cneg = (Module["_blst_fp2_cneg"] = function () {
      return (_blst_fp2_cneg = Module["_blst_fp2_cneg"] =
        Module["asm"]["T"]).apply(null, arguments);
    });

    var _blst_scalar_from_lendian = (Module["_blst_scalar_from_lendian"] =
      function () {
        return (_blst_scalar_from_lendian = Module[
          "_blst_scalar_from_lendian"
        ] =
          Module["asm"]["U"]).apply(null, arguments);
      });

    var _blst_lendian_from_scalar = (Module["_blst_lendian_from_scalar"] =
      function () {
        return (_blst_lendian_from_scalar = Module[
          "_blst_lendian_from_scalar"
        ] =
          Module["asm"]["V"]).apply(null, arguments);
      });

    var _blst_scalar_sizeof = (Module["_blst_scalar_sizeof"] = function () {
      return (_blst_scalar_sizeof = Module["_blst_scalar_sizeof"] =
        Module["asm"]["W"]).apply(null, arguments);
    });

    var _blst_fr_sizeof = (Module["_blst_fr_sizeof"] = function () {
      return (_blst_fr_sizeof = Module["_blst_fr_sizeof"] =
        Module["asm"]["X"]).apply(null, arguments);
    });

    var _blst_fr_compare = (Module["_blst_fr_compare"] = function () {
      return (_blst_fr_compare = Module["_blst_fr_compare"] =
        Module["asm"]["Y"]).apply(null, arguments);
    });

    var _blst_fr_is_equal = (Module["_blst_fr_is_equal"] = function () {
      return (_blst_fr_is_equal = Module["_blst_fr_is_equal"] =
        Module["asm"]["Z"]).apply(null, arguments);
    });

    var _blst_fr_is_zero = (Module["_blst_fr_is_zero"] = function () {
      return (_blst_fr_is_zero = Module["_blst_fr_is_zero"] =
        Module["asm"]["_"]).apply(null, arguments);
    });

    var _blst_fr_is_one = (Module["_blst_fr_is_one"] = function () {
      return (_blst_fr_is_one = Module["_blst_fr_is_one"] =
        Module["asm"]["$"]).apply(null, arguments);
    });

    var _blst_fr_from_lendian = (Module["_blst_fr_from_lendian"] = function () {
      return (_blst_fr_from_lendian = Module["_blst_fr_from_lendian"] =
        Module["asm"]["aa"]).apply(null, arguments);
    });

    var _blst_lendian_from_fr = (Module["_blst_lendian_from_fr"] = function () {
      return (_blst_lendian_from_fr = Module["_blst_lendian_from_fr"] =
        Module["asm"]["ba"]).apply(null, arguments);
    });

    var _blst_fp_sizeof = (Module["_blst_fp_sizeof"] = function () {
      return (_blst_fp_sizeof = Module["_blst_fp_sizeof"] =
        Module["asm"]["ca"]).apply(null, arguments);
    });

    var _blst_fp2_sizeof = (Module["_blst_fp2_sizeof"] = function () {
      return (_blst_fp2_sizeof = Module["_blst_fp2_sizeof"] =
        Module["asm"]["da"]).apply(null, arguments);
    });

    var _blst_fp2_assign = (Module["_blst_fp2_assign"] = function () {
      return (_blst_fp2_assign = Module["_blst_fp2_assign"] =
        Module["asm"]["ea"]).apply(null, arguments);
    });

    var _blst_fp2_zero = (Module["_blst_fp2_zero"] = function () {
      return (_blst_fp2_zero = Module["_blst_fp2_zero"] =
        Module["asm"]["fa"]).apply(null, arguments);
    });

    var _blst_fp2_set_one = (Module["_blst_fp2_set_one"] = function () {
      return (_blst_fp2_set_one = Module["_blst_fp2_set_one"] =
        Module["asm"]["ga"]).apply(null, arguments);
    });

    var _blst_fp2_of_bytes_components = (Module[
      "_blst_fp2_of_bytes_components"
    ] = function () {
      return (_blst_fp2_of_bytes_components = Module[
        "_blst_fp2_of_bytes_components"
      ] =
        Module["asm"]["ha"]).apply(null, arguments);
    });

    var _blst_fp2_to_bytes = (Module["_blst_fp2_to_bytes"] = function () {
      return (_blst_fp2_to_bytes = Module["_blst_fp2_to_bytes"] =
        Module["asm"]["ia"]).apply(null, arguments);
    });

    var _blst_fp12_sizeof = (Module["_blst_fp12_sizeof"] = function () {
      return (_blst_fp12_sizeof = Module["_blst_fp12_sizeof"] =
        Module["asm"]["ja"]).apply(null, arguments);
    });

    var _blst_fp12_set_one = (Module["_blst_fp12_set_one"] = function () {
      return (_blst_fp12_set_one = Module["_blst_fp12_set_one"] =
        Module["asm"]["ka"]).apply(null, arguments);
    });

    var _blst_fp12_to_bytes = (Module["_blst_fp12_to_bytes"] = function () {
      return (_blst_fp12_to_bytes = Module["_blst_fp12_to_bytes"] =
        Module["asm"]["la"]).apply(null, arguments);
    });

    var _blst_fp12_of_bytes = (Module["_blst_fp12_of_bytes"] = function () {
      return (_blst_fp12_of_bytes = Module["_blst_fp12_of_bytes"] =
        Module["asm"]["ma"]).apply(null, arguments);
    });

    var _blst_p1_sizeof = (Module["_blst_p1_sizeof"] = function () {
      return (_blst_p1_sizeof = Module["_blst_p1_sizeof"] =
        Module["asm"]["na"]).apply(null, arguments);
    });

    var _blst_p1_affine_sizeof = (Module["_blst_p1_affine_sizeof"] =
      function () {
        return (_blst_p1_affine_sizeof = Module["_blst_p1_affine_sizeof"] =
          Module["asm"]["oa"]).apply(null, arguments);
      });

    var _blst_p1_set_coordinates = (Module["_blst_p1_set_coordinates"] =
      function () {
        return (_blst_p1_set_coordinates = Module["_blst_p1_set_coordinates"] =
          Module["asm"]["pa"]).apply(null, arguments);
      });

    var _blst_p2_sizeof = (Module["_blst_p2_sizeof"] = function () {
      return (_blst_p2_sizeof = Module["_blst_p2_sizeof"] =
        Module["asm"]["qa"]).apply(null, arguments);
    });

    var _blst_p2_affine_sizeof = (Module["_blst_p2_affine_sizeof"] =
      function () {
        return (_blst_p2_affine_sizeof = Module["_blst_p2_affine_sizeof"] =
          Module["asm"]["ra"]).apply(null, arguments);
      });

    var _blst_p2_set_coordinates = (Module["_blst_p2_set_coordinates"] =
      function () {
        return (_blst_p2_set_coordinates = Module["_blst_p2_set_coordinates"] =
          Module["asm"]["sa"]).apply(null, arguments);
      });

    var calledRun;

    function ExitStatus(status) {
      this.name = "ExitStatus";
      this.message = "Program terminated with exit(" + status + ")";
      this.status = status;
    }

    dependenciesFulfilled = function runCaller() {
      if (!calledRun) run();
      if (!calledRun) dependenciesFulfilled = runCaller;
    };

    function run(args) {
      args = args || arguments_;

      if (runDependencies > 0) {
        return;
      }

      preRun();

      if (runDependencies > 0) {
        return;
      }

      function doRun() {
        if (calledRun) return;
        calledRun = true;
        Module["calledRun"] = true;
        if (ABORT) return;
        initRuntime();
        readyPromiseResolve(Module);
        if (Module["onRuntimeInitialized"]) Module["onRuntimeInitialized"]();
        postRun();
      }

      if (Module["setStatus"]) {
        Module["setStatus"]("Running...");
        setTimeout(function () {
          setTimeout(function () {
            Module["setStatus"]("");
          }, 1);
          doRun();
        }, 1);
      } else {
        doRun();
      }
    }

    Module["run"] = run;

    if (Module["preInit"]) {
      if (typeof Module["preInit"] == "function")
        Module["preInit"] = [Module["preInit"]];

      while (Module["preInit"].length > 0) {
        Module["preInit"].pop()();
      }
    }

    run();
    return _BLS12381.ready;
  })();
})();

if (
  (typeof exports === "undefined" ? "undefined" : _typeof(exports)) ===
    "object" &&
  (typeof module === "undefined" ? "undefined" : _typeof(module)) === "object"
)
  module.exports = _BLS12381;
else if (typeof define === "function" && define["amd"])
  define([], function () {
    return _BLS12381;
  });
else if (
  (typeof exports === "undefined" ? "undefined" : _typeof(exports)) === "object"
)
  exports["_BLS12381"] = _BLS12381;
