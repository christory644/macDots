# Local AI on the M5 Max / 128 GB

What this machine can actually run, per activity, tuned properly.

**Status:** written 2026-10-19. Supersedes the "Hardware Planning" section of
`docs/local-ai-agents-guide.md`, which was written against an M4 Max guess and a
2024 model list. Nothing here has been applied — the `home/ollama.nix` change is
a *proposal* at the end.

### How to read the claims

Every factual claim is tagged:

- **[M]** — measured on this machine on 2026-10-19. The benchmark sources
  lived in a session scratchpad and are gone; each method is described inline
  so you can reproduce it.
- **[S]** — a cited source says it. URL given.
- **[E]** — my estimate, with the reasoning shown. Treat as a starting
  hypothesis, not a number to quote.

Where I could not establish something, it says so.

---

## 0. The starter stack, at a glance

One pick per activity. Everything here is permissively licensed, actively
maintained, and confirmed to run on Apple Silicon. Reasoning is in §3.

| Activity | Pick | Size | Why |
|---|---|---:|---|
| **Coding, quality** | `gpt-oss:120b` (Ollama) | 65 GB | 5.1B active, so it decodes like a small model; 256k context costs only ~9 GiB of KV |
| **Coding, fast** | `qwen3-coder:30b-a3b-q8_0` | 32 GB | q8 rather than the usual q4 — the memory is there |
| **Speech-to-text** | `parakeet-mlx` (+ `whisper.cpp` for rare languages) | ~2 GB | Beats Whisper large-v3 on WER at ~20x throughput |
| **Dictation** | Handy (MIT) or VoiceInk (GPL-3.0) | app | Fully offline; Wispr Flow cannot be |
| **Text-to-speech** | Kokoro-82M via `mlx-audio` | 312 MB | Apache-2.0, ~25–50x realtime |
| **Voice cloning** | Chatterbox | 3.2 GB | MIT for code *and* weights |
| **Music** | ACE-Step 3.5B | ~8 GB | The only permissive model that works on Metal |
| **Stem separation** | `demucs-mlx` | small | ~73x realtime; the best thing in §3.4 |
| **Images** | FLUX 3 Image Klein via mflux or Draw Things | 11 GB | Commercial-OK licence, current frontier, `-q 8` |
| **Image editing** | Qwen-Image-Edit-2511 | ~40 GB | Apache-2.0 |
| **Video** | LTX-2.5 via `ltx-2-mlx`, int8 | ~75 GB | MLX is 16x PyTorch-MPS; avoid ComfyUI entirely |
| **Video post** | Apple `VTSuperResolutionScaler` + `VTFrameRateConversion` | built in | 4x upscale at ~39 ms/frame — effectively free |
| **Vision / VLM** | Qwen3.8-27B MLX 8-bit | 29.5 GB | Apache-2.0, image + video |
| **Video understanding** | `microsoft/Mage-VL` | 5B | One of the few models `mlx-vlm` accepts `--video` for |
| **OCR** | TeleOCR 1.2B or OvisOCR2 0.8B | ~1–2 GB | Sub-1.5B models that beat Gemini 3 Pro on OmniDocBench |
| **Embeddings** | `embeddinggemma-2` | 304 MB | Replaces `nomic-embed-text`; 78.7 MTEB-Code, Ollama's MLX path |
| **Vector store** | LanceDB | — | Embedded, no server, actively maintained |
| **Agents** | Goose or opencode against Ollama | — | Built for local models; Claude Code silently loses caching and MCP tool search |

**The two most valuable actions**, and neither is a model download:

```bash
brew upgrade mlx mlx-lm   # 4x MLX prefill on this chip — §2.6
nix flake update          # ollama 0.34.2 -> 0.40.x, which runs MLX by
                          # default on Apple Silicon — §2.9
```

---

## 1. The machine (measured, not assumed)

```
sysctl -n machdep.cpu.brand_string   -> Apple M5 Max
sysctl -n hw.memsize                 -> 137438953472   (128 GiB exactly)
sysctl -n hw.ncpu                    -> 18  (6 perflevel0 + 12 perflevel1)
hw.model                             -> Mac17,6  (MacBook Pro)
sw_vers                              -> macOS 26.5.2 (25F84)
```

**The memory is 128 GiB. Not 256.** Every planning document before
`docs/migration.md` §7 said 256 GB; all of them were wrong, and that error
already produced one recommendation (`qwen3:235b-a22b` at q4, ~140 GB) that
cannot load.

Worth saying once so the error cannot recur: **128 GB is the maximum unified
memory the M5 Max supports** — it is a package limit, not a purchasing choice
**[S]**, [Apple M5 (Wikipedia)](https://en.wikipedia.org/wiki/Apple_M5). No
configuration of this machine could ever have had 256 GB. If you want more
unified memory than this, the only Apple answer is an Ultra-class chip in a
desktop. The rest of this document is sized against 128 GiB.

| Property | Value | How |
|---|---|---|
| Chip | Apple M5 Max | **[M]** `machdep.cpu.brand_string` |
| GPU | 40 cores, Metal 4, family `applegpu_g17s` | **[M]** `system_profiler`, `mx.device_info()` |
| CPU | 18 cores (6 + 12) | **[M]** `hw.perflevel{0,1}.logicalcpu` |
| Unified memory | 137,438,953,472 B = 128 GiB | **[M]** `hw.memsize` |
| GPU-visible memory budget | 115,448,725,504 B = **107.5 GiB** | **[M]** Metal `recommendedMaxWorkingSetSize` |
| Max *single* Metal buffer | 86,586,540,032 B = **80.6 GiB** | **[M]** Metal `maxBufferLength` |
| Peak memory bandwidth (spec) | 614 GB/s | **[S]** [Wikipedia: Apple M5](https://en.wikipedia.org/wiki/Apple_M5) |
| Sustained GPU read bandwidth | **582 GB/s** (8 GiB stream kernel) = 95% of spec | **[M]** |
| Sustained GPU copy bandwidth | 550 GB/s (read+write) | **[M]** |
| fp16 dense GEMM (MPS, 8192³) | **61–63 TFLOPS** | **[M]** |
| fp32 dense GEMM (MPS, 8192³) | 14.6 TFLOPS | **[M]** |
| Effective q4 decode bandwidth | **444 GB/s** (76% of peak) | **[M]** MLX, 64-layer matvec chain |
| SSD sequential read | ≥12 GB/s | **[M]** `F_NOCACHE` read |
| Free disk | 7.1 TB of 7.3 TB | **[M]** `df` |

### The one number that explains the M5

fp16 GEMM runs at **63 TFLOPS** while fp32 GEMM runs at **14.6 TFLOPS** — a
4.2x gap **[M]**. A GPU with only vector ALUs cannot do that; 40 cores at
~1.6 GHz is roughly 16 TFLOPS fp32, which is exactly the fp32 number measured.
The fp16 number is 4x that, which means the measurement is seeing dedicated
matrix hardware — the per-GPU-core Neural Accelerators that are the headline
change in the M5 generation.

Why this matters practically: **decode (tokens out) is bandwidth-bound,
prefill (prompt in) is compute-bound.** The M5 Max improves prefill far more
than decode. For agentic coding — where every turn re-reads a large context —
prefill is most of the wall clock, so this generation is unusually good at
exactly the thing you want it for.

### Thermal behaviour

Sustained bf16 GEMM over 60 seconds **[M]**, measured **on battery at 52%**:

```
60.7  48.6  47.6  47.5  47.6  44.7  44.0  44.3  44.7  45.0  45.9   TFLOPS (5s windows)
```

It settles at ~45 TFLOPS, retaining 76% of the first-window burst. Plan long
runs around the sustained number, not the peak. **Caveat: all benchmarks in
this document were taken on battery power.** Plugged in, the sustained figure
is likely higher; I could not test that. Treat every measured throughput
number here as a *floor*.

### Allocation ceiling

Allocated 104 GiB of private Metal buffers in 4 GiB chunks with zero failures,
and the system stayed at 95% free afterwards **[M]**. I capped the test at
104 GiB deliberately; the real ceiling is the 107.5 GiB working-set budget.

So: **~100 GiB is genuinely usable for weights + KV cache**, leaving ~28 GiB
for macOS, browsers and your editor. The 80.6 GiB `maxBufferLength` is not a
practical limit because llama.cpp and MLX both allocate per-tensor, not one
slab — but it would bite anything that tries a single monolithic allocation.

---

## 2. Tuning

### 2.1 `iogpu.wired_limit_mb` — leave it alone

This is the single most-repeated piece of Apple-Silicon LLM advice and on this
machine **it is actively harmful**.

Current state **[M]**: `iogpu.wired_limit_mb = 0` (unset/automatic), and with
it unset Metal reports a budget of 110,100 MiB — **84% of physical RAM**.

The common advice is "set it to 75% of RAM". On this machine that is 98,304
MiB, which is *lower* than the 110,100 MiB you already have. Following the
popular advice would **remove ~12 GiB of GPU-usable memory**.

That advice is not merely stale, it has a traceable origin: a 2023
disassembly of `AGXAccelerator::calcMaxGPUPhysicalMemoryBytes()` found
`reservePercent = 33.333f`, dropping to `25.0f` above 32 GiB of RAM **[S]**,
[llama.cpp discussion #2182](https://github.com/ggml-org/llama.cpp/discussions/2182).
That is also where the folklore "36 GB threshold" comes from — the same 32 GiB
boundary restated in decimal GB. **macOS 26 has superseded that formula.** The
reservation now shrinks as RAM grows **[S]**:

| RAM | default budget | % of RAM |
|---|---|---|
| 48 GiB | 37.44 GiB | 78% |
| 64 GiB | 51.8 GiB | 81% |
| **128 GiB (this machine)** | **107.52 GiB** | **84%** **[M]** |
| 256 GiB | 222.72 GiB | 87% |

ggml's own macOS app says so in a source comment: *"Apple sets it around three
quarters of RAM on smaller Macs and higher on large ones (84% of 128 GB,
measured), so it can't be derived from `hw.memsize` — it has to be asked for"*
**[S]**,
[Llama-macOS/SystemMemory.swift](https://github.com/ggml-org/Llama-macOS/blob/HEAD/Llama/System/SystemMemory.swift).
Apple documents none of it; the official page for
[`recommendedMaxWorkingSetSize`](https://developer.apple.com/documentation/metal/mtldevice/recommendedmaxworkingsetsize)
says only "an approximation of how much memory this GPU device can allocate
without affecting its runtime performance".

Two corrections to what I first assumed here:

1. **The sysctl does move the budget 1:1.** On an M4 Max/128 GB,
   `iogpu.wired_limit_mb=114688` produced exactly 114,688 MiB of
   `recommendedMaxWorkingSetSize` **[S]**,
   [llama.cpp #29465](https://github.com/ggml-org/llama.cpp/issues/29465)
   (2026-09-26). I had marked this untested; it is confirmed, just not on this
   machine.
2. **It is a recommendation, not a hard cap.** Allocations past it *succeed* —
   ggml only warns. That is worse than a clean failure: macOS starts
   compressing and swapping, quantised weights are incompressible, so the VM
   compressor burns CPU and then swaps to the same SSD you are streaming the
   model from. This is the mechanism behind the "it got slow and then the
   machine died" reports, including a kernel panic in
   [#19825](https://github.com/ggml-org/llama.cpp/issues/19825).

Recommendation: **leave it at 0.** One engineered rule of thumb is
`RAM − max(15% of RAM, 8 GiB)` **[S]**,
[utensils/mold](https://github.com/utensils/mold/blob/HEAD/website/guide/metal-memory.md),
which for 128 GiB gives 108.8 GiB — the default of 107.5 GiB is *already* at
that ceiling. Raising it buys perhaps 5 GiB before you cross the conservative
line and ~16 GiB before you are in reported-instability territory. On macOS 26
the whole lever is far smaller than the 75%-era blog posts imply.

If you ever do need it (a model whose weights + KV genuinely exceed ~100 GiB):

```bash
sudo sysctl iogpu.wired_limit_mb=114688    # 112 GiB, leaves 16 GiB for macOS
```

`/etc/sysctl.conf` is **not** supported on macOS — it needs a LaunchDaemon.
There is an off-the-shelf nix-darwin module that does exactly this
(`postActivation` plus a `launchd.daemons."sysctl-wired-limit"` with
`RunAtLoad`) at
[kitten/system `modules/base/macos-vram.nix`](https://github.com/kitten/system/blob/HEAD/modules/base/macos-vram.nix),
if it is ever worth adding here. It is not, today.

### 2.1a The macOS 26 idle-unwiring stall — already handled, keep it that way

Worth knowing because it is invisible and it specifically punishes interactive
agent use. macOS 26 reintroduced aggressive unwiring of GPU memory after about
one second of idle. Measured on a 256 GiB Tahoe machine **[S]**,
[llama.cpp PR #17766](https://github.com/ggml-org/llama.cpp/pull/17766):
wired memory holds through 1.25 s, then collapses — 107 GiB at 1.5 s, 13.7 GiB
by 5 s, with **zero page-outs** (the pages stay in RAM, they just stop being
wired). The cost is a median post-commit GPU wait going from **4.71 ms to
1296 ms**. For a coding agent with pauses between turns, that is over a second
of dead time on *every* request following a pause.

ggml's fix is a residency set held alive for a configurable period.
**The installed Ollama already has it** — `strings` on
`lib/ollama/llama-server` finds `GGML_METAL_RESIDENCY_KEEP_ALIVE_S` (default
180 s), `GGML_METAL_NO_RESIDENCY`, and the log line
`creating a residency set collection (keep_alive = %d s)` **[M]**.

So nothing to do — but this is the concrete reason not to let the Ollama
package drift too far behind (§2.9), and the first thing to suspect if
single-request latency ever goes strange after an idle gap.

### 2.2 KV cache precision — `f16` is right, and here is the arithmetic

The KV cache is the part people get wrong, because it scales with context
*and* with concurrency, and on this machine it can dwarf the weights.

```
KV bytes per token = 2 (K and V) x layers x kv_heads x head_dim x bytes_per_element
```

Layer and head counts below were read from each model's `config.json` on
HuggingFace **[S]**, so the arithmetic is exact rather than estimated:

| Model | layers x kv_heads x head_dim | KiB/token (f16) | 32k | 128k | 256k |
|---|---|---:|---:|---:|---:|
| `qwen3-coder:30b-a3b` | 48 x 4 x 128 | 96 | 3.0 GiB | 12 GiB | 24 GiB |
| `gpt-oss:120b` | 36 x 8 x 64 | 72 → **36** | 1.1 GiB | **4.5 GiB** | **9.0 GiB** |
| `gpt-oss:20b` | 24 x 8 x 64 | 48 → **24** | 0.8 GiB | 3.0 GiB | 6.0 GiB |
| `qwen3:32b` (dense) | 64 x 8 x 128 | 256 | 8.0 GiB | 32 GiB | 64 GiB |
| Mistral/Devstral 24B | 40 x 8 x 128 | 160 | 5.0 GiB | 20 GiB | 40 GiB |

**The gpt-oss arrow is the interesting part.** Its `layer_types` alternate
strictly: 18 `full_attention` and 18 `sliding_attention` with
`sliding_window: 128` **[S]**. Only the 18 full layers accumulate a growing
cache; the sliding layers never hold more than 128 tokens. So gpt-oss's real
long-context KV cost is **half** the naive formula.

That makes `gpt-oss:120b` unusually well matched to this machine: at 256k
context it is ~63 GB of weights plus only ~9 GiB of KV — about 72 GB total,
comfortably inside the ~100 GiB budget. A dense 32B model asks for *more* KV at
256k (64 GiB) than a 120B MoE does. Architecture beats parameter count when
you are sizing for context.

**`q8_0` halves every number in that table**, and the quality case for it is
much stronger than the commonly-quoted 2024 numbers suggest. In April 2026
llama.cpp merged QuaRot-style **Hadamard rotation of the KV cache** — an
orthonormal Walsh–Hadamard rotation applied to Q/K/V before caching and undone
after attention, which crushes the outliers that made low-bit KV lossy
**[S]**, [PR #21038](https://github.com/ggml-org/llama.cpp/pull/21038). It is
backend-agnostic and applies automatically whenever the cache is quantised and
`n_embd_head % 64 == 0`. Perplexity on Qwen3 0.6B:

| K/V type | before | after |
|---|---:|---:|
| f16 (baseline) | 13.6711 | — |
| q8_0 | 13.9115 | **13.6713** |
| q5_1 | 61.70 | **14.15** |
| q4_1 | 212.48 | **22.28** |

q8_0 now reproduces the f16 baseline to four decimal places. A second finding
worth carrying: **K is far more sensitive than V** — quantising K to q4_0
costs ΔPPL 0.191, quantising V to q4_0 costs 0.022, nearly 9x better **[S]**.
If you ever do quantise asymmetrically, quantise V harder than K, never the
reverse. (Ollama does not expose asymmetric KV types; llama.cpp does.)
Also relevant here: [#27390](https://github.com/ggml-org/llama.cpp/pull/27390)
(2026-08-20) routes quantised KV through the existing Metal F16 flash-attention
kernels, so quantised KV on Apple Silicon is a sane path now in a way it was
not a year ago.

Verdict for this machine: **keep `f16` anyway.** Not because q8_0 is risky —
it is now demonstrably not — but because the memory it saves is memory you are
not short of, and f16 is one less variable when something behaves oddly. The
useful change is knowing that `q8_0` is now an almost-free lever when you
*do* want 256k context on a dense model.

Note that Ollama exposes only `f16`, `q8_0` and `q4_0`, not llama.cpp's full
set **[S]**.

### 2.3 Concurrency — this is the trap

**`OLLAMA_NUM_PARALLEL` multiplies the KV cache.** Not approximately —
literally. From `server/sched.go` in Ollama's source **[S]**,
[ollama/ollama](https://github.com/ollama/ollama/blob/main/server/sched.go):

```go
func effectiveLlamaServerContext(numCtx int, f *gguf.Model, numParallel int) int {
	return effectiveModelContext(numCtx, f) * max(numParallel, 1)
}
```

So four parallel slots at 128k context on `qwen3-coder:30b-a3b` is
12 GiB x 4 = **48 GiB of KV cache to serve 19 GB of weights**. At the 256k
default (§2.4) it is 96 GiB, and the model will not load as configured.

Upstream's default is `1` (`NumParallel = Uint("OLLAMA_NUM_PARALLEL", 1)` in
`envconfig/config.go` **[S]**). Setting 4 is a deliberate 4x memory multiplier,
and for a single person at a keyboard it buys nothing — requests queue in
milliseconds either way. It is only worth paying for if you genuinely fan out
concurrent agents against one model.

The current config sets `OLLAMA_NUM_PARALLEL = "4"`. For a single human at a
keyboard that buys nothing and costs a lot of memory. It is only worth it if
you are genuinely fanning out concurrent agents against the same model.

Recommendation: **2**, and pin the context length explicitly (see §2.4).

### 2.4 `OLLAMA_CONTEXT_LENGTH` — pin it

`ollama serve --help` on the installed 0.34.2 says **[M]**:

```
OLLAMA_CONTEXT_LENGTH   Context length to use unless otherwise specified
                        (default: 4k/32k/256k based on VRAM)
```

Ollama's own documentation gives the tiers **[S]**,
[docs/context-length](https://github.com/ollama/ollama/blob/main/docs/context-length.mdx):

```
< 24 GiB VRAM:   4k context
24-48 GiB VRAM:  32k context
>= 48 GiB VRAM:  256k context
```

This machine reports ~107 GiB, so it lands in the **256k** bucket. Combine
that with the four parallel slots currently configured and the server asks for
**256k x 4 = 1,048,576 tokens** of KV cache. On `qwen3-coder:30b-a3b` at
96 KiB/token that is **96 GiB of KV cache to serve a 19 GB model** — five
times the weights. Ollama will not crash (it has an auto-reduce path,
`reduceAutoNumCtxForLoadOOM`), but it will negotiate downwards at load time and
you get unpredictable context and wasted time instead of a configuration you
chose.

Pin it. **65536** is the right default, and it matches Ollama's own advice:
*"Tasks which require large context like web search, agents, and coding tools
should be set to at least 64000 tokens."* Raise per-request with `num_ctx`
when you actually need more.

### 2.5 `OLLAMA_USE_MLX=1` is a no-op — delete it

The config sets `OLLAMA_USE_MLX = "1"` with the comment "Apple MLX backend
(unified memory, no CPU/GPU copy overhead)".

**That variable does not exist.** Verified two ways on the installed binary
**[M]**:

1. `ollama serve --help` lists every environment variable it reads.
   `OLLAMA_USE_MLX` is not among them.
2. `strings` over the binary finds every other `OLLAMA_*` name it consumes
   (`OLLAMA_KV_CACHE_TYPE`, `OLLAMA_FLASH_ATTENTION`, `OLLAMA_CONTEXT_LENGTH`,
   `OLLAMA_GPU_OVERHEAD`, `LLAMA_ARG_FIT`, …) and does not contain
   `OLLAMA_USE_MLX`.

On 0.34.2, Ollama runs llama.cpp's Metal backend. It is not MLX, and no
environment variable changes that. The line is harmless but it encodes a false
belief about what the stack is doing, which is worse than nothing.

The twist is that the belief was merely premature. **Ollama 0.40.0 runs MLX by
default on Apple Silicon** (§2.9) — so the way to get what this line was
reaching for is `nix flake update`, not an env var. Until then, `mlx_lm.server`
runs alongside (§2.8).

Undocumented-but-real variables the same check *did* find, which are worth
knowing: `OLLAMA_GPU_OVERHEAD` (reserve bytes), `OLLAMA_MAX_QUEUE`,
`OLLAMA_NO_CLOUD` (disables 0.34's cloud inference and web search —
relevant if "local" is meant strictly), `LLAMA_ARG_FIT` / `LLAMA_ARG_FIT_TARGET`
(llama.cpp's automatic memory fitting, on by default).

**`OLLAMA_FLASH_ATTENTION=1` is also redundant now.** Ollama moved to a
tri-state `auto` default, and in the installed v0.34.2 source
`FlashAttentionSupported()` returns true for `Metal` unconditionally **[S]**,
[ml/device.go @ v0.34.2](https://github.com/ollama/ollama/blob/v0.34.2/ml/device.go):

```go
supportsFA := gpu.Library == "cpu" ||
    gpu.Name == "Metal" || gpu.Library == "Metal" || ...
```

So flash attention is already on for every model here, and forcing it means
Ollama can no longer turn it *off* for the models that need that — llama-server
carries the string `flash_attn is not compatible with Grok - forcing off`
**[M]**, so there is at least one. Harmless in practice, but it is a setting
that now only removes a decision Ollama makes better than you do.

### 2.6 The most important change on this machine is not in ollama.nix

**The installed MLX is 4x slower at prefill than the version Homebrew is
already offering.**

Measured, same benchmark, same machine, minutes apart **[M]**:

| | fp16 GEMM 8192³ | q4 GEMM, batch 512 (prefill-shaped) | q4 matvec chain (decode-shaped) |
|---|---:|---:|---:|
| **mlx 0.32.1** (installed) | **15.5 TFLOPS** | 13.4 TFLOPS | 444 GB/s |
| **mlx 0.32.4** (current) | **61.2 TFLOPS** | 48.4 TFLOPS | 444 GB/s |

0.32.1 does not use the M5's matrix units; 0.32.4 does. Decode is unchanged,
exactly as theory predicts — decode is bandwidth-bound and no amount of matmul
throughput helps it. **Prefill gets ~4x.**

This machine is pinned to the slow version because `hosts/macbook/homebrew.nix`
sets `onActivation.upgrade = false` (deliberately, and for a good reason — a
flaky formula upgrade aborting the whole `darwin-rebuild` is worse). So the fix
is manual and you have to actually run it:

```bash
brew upgrade mlx mlx-lm
```

`brew outdated` currently shows `mlx` (0.32.1 → 0.32.4) and `mlx-lm`
(0.31.3 → 0.32.2) **[M]**.

Not applied. This document proposes; it changes nothing.

### 2.7 Does Ollama use the M5's matrix units? Yes — verified in the binary

This is the question that decides whether GGUF is a second-class citizen on
this chip, and it is answerable without downloading anything.

First, the legacy path. `simdgroup_matrix` (`simdgroup_float8x8` +
`simdgroup_multiply_accumulate`) is what Metal 3-era GEMM kernels use. Peak
instruction throughput on this machine, register-resident with no memory
traffic — so an *upper bound*, a real GEMM would be lower **[M]**:

```
simdgroup_float8x8   16.3 TFLOPS
simdgroup_half8x8    11.0 TFLOPS
```

That is ~4x below the 63 TFLOPS that MPS and MLX 0.32.4 reach. So a runtime
stuck on `simdgroup_matrix` would lose 4x of prefill on an M5.

Ollama is **not** stuck on it. Dumping strings from the installed
`lib/ollama/llama-server` **[M]** finds Apple's Metal 4 Tensor API — the
`mpp::` namespace is Metal Performance Primitives — compiled into the embedded
shader source:

```
mpp::tensor_ops::matmul2d<
    mpp::tensor_ops::matmul2d_descriptor(
        NRB, NRA, static_cast<int>(dynamic_extent), false, true, true,
        mpp::tensor_ops::matmul2d_descriptor::mode::multiply_accumulate),
    execution_simdgroups<N_MM_SIMD_GROUP_X * N_MM_SIMD_GROUP_Y>> mm;
```

…guarded by `GGML_METAL_HAS_TENSOR`, with runtime capability detection (it
JIT-compiles a `dummy_kernel` at startup to probe for f16 and bf16 tensor
support) and this log string:

```
%s: tensor API disabled for pre-M5 and pre-A19 devices
```

**Pre-M5.** This machine is an M5. The fast path is on.

Corroborating upstream history **[S]** — `ggml-org/llama.cpp` commits:
`metal: enable Metal 4.0 tensor API on M5+/A19+` (#27461, 2026-09-01),
`metal : optimize Metal Tensor API usage for GGML_OP_MUL_MAT` (#20962),
`metal : add tensor API flash attention kernel for F16 KV` (#29570, 2026-10-02),
BF16 variant (#30491, 2026-10-15). Ollama 0.34.2 was published 2026-09-15,
after the enabling commit, and the vendored shader source confirms it made the
cut.

And the probe passes. I extracted ggml's `dummy_kernel` verbatim from the
binary and compiled it against this machine's Metal **[M]**:

```
device: Apple M5 Max
supportsFamily(MTLGPUFamilyApple9):  1
supportsFamily(MTLGPUFamilyApple10): 1
RESULT: ggml f16 tensor-API probe COMPILES -> tensor API would be ENABLED
```

That is not an inference from version numbers — it is ggml's own capability
check, run on this hardware, passing. **Ollama is using the Neural
Accelerators on this machine.**

**But not well, and this is the correction that matters.** Someone with the
same machine — M5 Max, 128 GB — measured ggml's Metal backend prefilling at
**roughly 60% of MLX**, concluding "the M5 NAX matrix units are mostly unused
by the current ggml-metal kernels" **[S]**,
[llama.cpp #30287](https://github.com/ggml-org/llama.cpp/issues/30287)
(2026-10-10). Their six Metal-only changes measured:

| | before | after | delta |
|---|---:|---:|---:|
| prefill, 8k context | 633 t/s | 1064 t/s | **+68%** |
| prefill, 32k context | 528 t/s | 884 t/s | **+67%** |
| decode | unchanged | unchanged | — |

**That issue was closed `not_planned`, three days later, with zero comments.**

So the honest position is narrower than "same hardware path": ggml *enables*
the tensor API on M5 and gets real benefit from it, but its kernels are not
tuned for this chip and leave something like 40–68% of prefill on the table
relative to MLX. Decode is identical either way, exactly as physics requires.

This is the strongest argument in the document for **MLX being the faster
runtime on this specific machine** — and, as §2.9 explains, for upgrading
Ollama, because recent Ollama runs MLX itself.

Two **undocumented** env vars fall out of the same dump and are worth knowing:
`GGML_METAL_TENSOR_DISABLE` and `GGML_METAL_TENSOR_ENABLE` (plus
`GGML_METAL_BF16_DISABLE`). Neither appears in `ollama serve --help`. They are
your A/B switch: run the same prompt with and without
`GGML_METAL_TENSOR_DISABLE=1` and you can measure the Neural Accelerators'
contribution on your own workload in about two minutes.

To confirm it is active at runtime, start the server with `OLLAMA_DEBUG=1` and
look for the tensor-API line at model load.

**Conclusion: both runtimes reach the Neural Accelerators, but MLX uses them
better.** Decode is bandwidth-bound for both and neither can beat ~444 GB/s
effective. On prefill, expect MLX to lead by a meaningful margin on this chip
until ggml's Metal kernels are tuned for it — and note that the person who
tuned them was turned away.

### 2.8 MLX vs GGUF — choosing on ergonomics

| | MLX (`mlx_lm`) | GGUF (Ollama / llama.cpp) |
|---|---|---|
| Install | already present (brew) | already present, launchd agent |
| Model availability | `mlx-community/*` on HF; good but narrower | widest; Ollama registry is one command |
| Serving | `mlx_lm.server`, OpenAI-compatible | OpenAI-compatible, plus model management |
| Fine-tuning | **LoRA/QLoRA built in** (`mlx_lm.lora`) | not really |
| Quant formats | 4/6/8-bit, DWQ/AWQ, GPTQ | Q4_K_M, IQ4_XS, MXFP4 |
| Metal 4 tensor path | yes, **once on 0.32.4** (§2.6) | yes, already (§2.7) |
| Speculative decoding | **yes** — `--draft-model` | not exposed |

The `--draft-model` row matters more than it looks. Decode is bandwidth-bound
at ~444 GB/s and *nothing* in your control makes memory faster — except not
reading the weights as often. Speculative decoding is the one technique that
sidesteps the wall: a small draft model proposes several tokens, the big model
verifies them in one pass. `mlx_lm.server` supports it directly
(`--draft-model`, `--num-draft-tokens`) **[M]**, verified from `--help` on the
installed build. Pairing `gpt-oss:120b` with `gpt-oss:20b` as the draft is the
obvious experiment, and it is the only lever in this document that can improve
*decode* rather than prefill.

Other `mlx_lm` entry points worth knowing, all present already **[M]**:
`mlx_lm.lora` (LoRA/DoRA/full fine-tuning), `mlx_lm.awq` / `.dwq` / `.gptq` /
`.dynamic_quant` (make your own quants), `mlx_lm.benchmark`,
`mlx_lm.perplexity`, `mlx_lm.evaluate` — so you can measure quantisation
quality loss on your own code rather than trusting a table.

Practical answer: **Ollama for the daily driver** (model management and the
launchd agent are worth real money in convenience), **MLX when you want
speculative decoding, custom quantisation, or any fine-tuning at all.**
They coexist fine — just do not keep big models hot in both at once.

### 2.9 Version currency — everything here is behind

Measured against upstream on 2026-10-19 **[M]**:

| Component | Installed | Current | Gap |
|---|---|---|---|
| `ollama` (nixpkgs) | 0.34.2 (2026-09-15) | 0.40.6 (2026-10-16) | 6 minor versions, ~1 month |
| `mlx` (brew) | 0.32.1 | 0.32.4 | **4x prefill, see §2.6** |
| `mlx-lm` (brew) | 0.31.3 | 0.32.2 | |
| nixpkgs pin | rev `00455b0a36`, 2026-09-23 | — | nixpkgs master has ollama 0.40.4 |

**The Ollama gap is not cosmetic. v0.40.0 (2026-09-25) made MLX the default
runtime on Apple Silicon** — verbatim from the release notes **[S]**:

> **Models run on MLX on Apple Silicon by default.** In this release, on Apple
> Silicon devices, model architectures supported by the MLX runtime will
> automatically run on MLX.

Supported there: `qwen3.8`, `qwen3.6`, `qwen3.5`, `gemma4`, the decision
models, and `embeddinggemma-2` on the embedding side.

Put that beside §2.7 and the picture resolves: Ollama's llama.cpp backend
under-uses the M5's matrix units by 40–68% on prefill, and Ollama's own answer
was to stop using llama.cpp for the models it can. **Upgrading Ollama is how
you get MLX on this machine** — which is, with some irony, exactly what the
removed `OLLAMA_USE_MLX = "1"` line was reaching for. The env var never
existed; the capability arrived six minor versions later, automatically, and
this machine is one version short of it.

```bash
nix flake update    # nixpkgs master has ollama 0.40.4
```

Ollama ships roughly a release every other day, so some lag is healthy. Six
minor versions across *this* particular boundary is not.

### 2.10 How many models can be loaded at once

The budget is ~100 GiB of weights + KV. `OLLAMA_MAX_LOADED_MODELS = 3` is a
cap, not a reservation, so it is not wrong — but the number that binds is
bytes, not count. Workable combinations **[E]**, derived from the sizes in §3
plus the KV table in §2.2:

- `gpt-oss:120b` (65 GB) + `qwen3-coder:30b-a3b` q4 (19 GB) + an embedding
  model (~1 GB) = 85 GB of weights, ~15 GiB left for KV. Fine at 64k.
- `gpt-oss:120b` (65 GB) + `qwen3-coder:30b-a3b` **q8_0** (32 GB) = 97 GB.
  Fits, but leaves almost nothing for KV — drop one before raising context.
- Three 30B-class models at q4 = ~57 GB. Very comfortable.
- Two 120B-class models: **no.** Not at any useful quantisation.

`ollama ps` reports the real resident size and the chosen context per model —
check it rather than trusting this list.


### 2.11 What to avoid

- **Setting `iogpu.wired_limit_mb` to "75% of RAM."** On this machine that is
  a 12 GiB downgrade. See §2.1.
- **`OLLAMA_USE_MLX`.** Not a variable. See §2.5.
- **High `OLLAMA_NUM_PARALLEL` with an unpinned context.** The single most
  expensive mistake available here — it multiplies KV cache by 4 against a
  256k default. See §2.3 and §2.4.
- **`q4_0` KV cache.** `q8_0` is nearly free; `q4_0` costs more. You have
  128 GiB — do not trade accuracy for memory you are not short of.
- **`nomic-embed-text`.** Superseded, unmaintained since early 2025, and
  silently capped at 2k tokens by Ollama. See §3.7.
- **A small reranker on code.** It makes retrieval *worse*. 4B-class or none.
  See §3.7.
- **More than ~15 tools on a local model.** It does not degrade, it fails.
  See §3.8.
- **Two 120B-class models loaded at once.** Does not fit. See §2.10.
- **`faster-whisper` / `WhisperX` for speech.** CTranslate2 ships no GPU
  support on macOS; you would run a 40-core GPU machine's transcription on the
  CPU. See §3.2.
- **ComfyUI on MPS for video.** Not "slow" — *silently wrong*. M5 is named in
  the corruption issue and an M5 Max reporter logged 19 of 26 all-black runs.
  See §3.6.
- **`draw-things-cli` from Homebrew.** Mis-compiles Neural Accelerator kernels
  on M5 specifically. Use the GUI app. See §3.5.
- **CUDA-first video models** (HunyuanVideo, Mochi, CogVideoX, FramePack) and
  archived Mac runtimes (DiffusionKit, Fooocus, DiffusionBee, Core ML Stable
  Diffusion). See §3.5 and §3.6.
- **Assuming a permissive licence from a GitHub badge.** F5-TTS is MIT code
  with non-commercial weights; Qwen-Image-2.1 revoked Apache 2.0; XTTS-v2's
  commercial licence can no longer be bought. See §3.3 and §3.5.
- **Benchmarking on battery.** Everything in §1 was measured on battery and is
  therefore a floor.

---

## 3. By activity

Nothing in this section has been installed or downloaded. Sizes and speeds are
tagged as elsewhere. The recurring caveat: **no published benchmark exists for
the M5 Max for any of these models yet** — it shipped 2026-03-03 and the
community numbers are all M2/M3/M4-class. Where a speed is quoted from an
older chip, expect this machine to be faster, mostly on prefill (§1).

### 3.1 Coding assistants and agents

#### How to size and predict any model, from the measured numbers

You do not need a benchmark for every model. Two formulas and the §1
measurements cover it:

```
decode tok/s  ~=  444 GB/s  /  (bytes of weights touched per token)
prefill tok/s ~=  45 TFLOPS /  (2 x active parameters)
```

Decode is bandwidth-bound: a dense model touches *all* its weights per token,
an MoE touches only its active experts. Prefill is compute-bound and uses the
sustained matmul figure. Both are ceilings — real systems land at 50–75% of
them because of attention, MoE gather overhead and sampling. **[E]**, but the
inputs are measured.

The practical consequence: **MoE models are enormously favoured on this
machine.** `gpt-oss:120b` has 5.1B active parameters out of 117B, so it decodes
roughly as fast as a 5B dense model while reasoning like something far larger,
and the 128 GiB is what lets the other 112B sit in memory.

#### What actually fits

Sizes are the real Ollama download sizes, read from the library **[S]**:

| Model | Quant | Size | Fits? | Note |
|---|---|---:|---|---|
| `gpt-oss:20b` | MXFP4 | 14 GB | yes, trivially | 24 layers, 3.6B active |
| `qwen3-coder:30b-a3b` | Q4_K_M | **19 GB** | yes | the daily driver |
| `qwen3-coder:30b-a3b` | **Q8_0** | **32 GB** | **yes, easily** | see below |
| `qwen3-coder:30b-a3b` | **FP16** | **61 GB** | **yes** | see below |
| `devstral` 24B | Q4 / Q8 / FP16 | 14 / 25 / 47 GB | yes | agentic-coding tuned |
| `gpt-oss:120b` | MXFP4 | **65 GB** | **yes, with room** | best quality that fits |
| `qwen3:32b` dense | Q4 | 20 GB | yes | but 256 KiB/token KV |
| `qwen3-vl:32b` | Q4 | 34 GB | yes | vision, §3.6 |
| `qwen3:235b-a22b` | Q4 | 142 GB | **no** | the original error |
| `qwen3-coder:480b-a35b` | Q4 | **290 GB** | **no** | not at any quant |
| `deepseek-v3.1` | Q4 | 404 GB | **no** | |

**The thing 128 GB actually buys you is precision, not size.** Everyone reaches
for a bigger model; the more interesting move here is a *better-quantised* one.
`qwen3-coder:30b-a3b-q8_0` is 32 GB — a third of your budget — and q8 is
effectively indistinguishable from fp16 in output quality, where q4 is
measurably not. Even full `fp16` at 61 GB fits.

The trade is decode speed, and the arithmetic is unforgiving because decode is
bandwidth-bound **[E]**: at ~3.3B active parameters, q4 touches ~1.7 GB/token,
q8 ~3.3 GB, fp16 ~6.6 GB. So **q8 decodes about half as fast as q4, and fp16
about a quarter.** Sweet spot for interactive work: **q8_0**. Use fp16 only for
generating evaluation data where you want the model's honest best.

#### How fast — and a check that the formulas work

Before using them, here is the formulas validated against the only published
real M5 Max llama.cpp numbers I could find **[S]**, from the
[Apple Silicon benchmark thread](https://github.com/ggml-org/llama.cpp/discussions/4167)
(7B dense, Q4_0):

| | formula predicts | **M5 Max measured** | error |
|---|---:|---:|---:|
| prefill (pp512) | 3214 tok/s | **3220 tok/s** | 0.2% |
| decode (tg128) | 113 tok/s | **119.9 tok/s** | 6% |

That is close enough to trust. Two things follow. First, the §1 measurements
(45 TFLOPS sustained, ~444 GB/s effective) really do describe what llama.cpp
achieves in practice — **dense prefill hits essentially the full sustained GEMM
rate**, with no derating needed. Second, for scale: the same thread has M4 Max
at 885.7 tok/s prefill and 83.1 decode, so **this chip is 3.6x the prefill and
1.4x the decode of last year's**. That asymmetry is the whole M5 story, and
Apple's own research reports the same shape — 3.3–4.1x time-to-first-token but
only 19–27% faster generation **[S]**,
[Apple ML Research, 2025-11-19](https://machinelearning.apple.com/research/exploring-llms-mlx-m5).

Applying it. The decode column uses ~470 GB/s effective; **[E]**, and the MoE
rows carry a derating because expert gather has poor arithmetic intensity:

| Model | Active | Decode ceiling | Realistic decode | Prefill |
|---|---:|---:|---:|---:|
| `qwen3-coder:30b-a3b` q4 | 3.3B | ~200 tok/s | **100–140 tok/s** | ~3000–5000 tok/s |
| `qwen3-coder:30b-a3b` q8 | 3.3B | ~110 tok/s | **55–80 tok/s** | ~3000–5000 tok/s |
| `gpt-oss:120b` MXFP4 | 5.1B | ~160 tok/s | **80–110 tok/s** | ~2000–3500 tok/s |
| `devstral` 24B dense q4 | 24B | ~33 tok/s | **~30 tok/s** | ~940 tok/s |
| `qwen3:32b` dense q4 | 32B | ~24 tok/s | **~22 tok/s** | ~700 tok/s |

**The prefill column is why this machine matters.** Re-reading a 64k context
costs about 90 seconds on the dense 32B and **under 20 seconds on the MoEs** —
and that is the operation an agent performs on every single turn. Local agentic
coding stops being theatre at roughly these numbers, and it is new with the
M5's matrix units (§2.7).

#### Recommended starter stack

```bash
ollama pull gpt-oss:120b                     # 65 GB — the quality tier
ollama pull qwen3-coder:30b-a3b-q8_0         # 32 GB — the fast tier, q8 not q4
ollama pull embeddinggemma-2                 # 304 MB — see §3.7
```

~98 GB on disk, and any two of the three co-resident inside the budget.
`gpt-oss:120b` at full 256k context costs only ~9 GiB of KV thanks to its
sliding-window layers (§2.2), so 65 + 9 = 74 GB leaves room for the 30B
alongside it.

**One caveat to this recommendation, stated honestly.** `gpt-oss` weights date
from August 2025, and Ollama's library now carries the 2026 generation —
`qwen3.8` (18 / 30 / 56 GB), `qwen3.6` (up to 72 GB) and `gemma4` (up to
64 GB), all of which are on Ollama 0.40's MLX path **[M]**, i.e. the fast path
on this chip (§2.9). They are very likely the better answer.

I am not making one of them the headline pick because I could not verify
their architecture or benchmark them, and one widely-quoted figure — 74 tok/s
for `qwen3.8:27b` at q8 on an *M5 Pro* — **fails a physics check**: a dense
27B at q8 is ~30 GB per token, which at the M5 Pro's 307 GB/s ceiling cannot
exceed ~10 tok/s. Either the model is not dense, or that number involves
speculative decoding or batching. Both are plausible; neither is established.

**So: pull `qwen3.8:27b-q8_0` as well and compare the three on your own
code.** `mlx_lm.benchmark` and `ollama run --verbose` will tell you more in
ten minutes than this document can.

### 3.2 Speech-to-text — Parakeet, not Whisper

The headline: **Whisper is no longer the accuracy leader**, and the thing that
replaced it is also ~20x faster.

Open ASR Leaderboard, snapshot 2026-05-06 **[S]**,
[benchmarklist.com](https://benchmarklist.com/benchmarks/open_asr_leaderboard/):

| Model | Avg WER |
|---|---|
| IBM Granite Speech 4.1 2B | 5.33% |
| NVIDIA Canary-Qwen 2.5B | 5.63% |
| **Parakeet TDT 0.6B v2** | 6.05% |
| **Parakeet TDT 0.6B v3** | 6.32% |
| Kyutai STT 2.6B EN | 6.40% |
| Whisper large-v3 | 7.44% |
| Whisper large-v3-turbo | 7.83% |

Caveat worth stating: the top ~15 entries sit inside one WER point of each
other, so the rank order is close to noise. What actually decides the choice is
architecture, license, and whether it runs on Metal.

**The one hard "do not": `faster-whisper` and anything built on it (notably
WhisperX).** CTranslate2 ships GPU wheels for Linux and Windows only; the macOS
wheel is Accelerate/CPU **[S]**,
[CTranslate2 install docs](https://opennmt.net/CTranslate2/installation.html)
(the Metal backend, [PR #2077](https://github.com/OpenNMT/CTranslate2/pull/2077),
is still open). On this machine that means running transcription on the CPU
while a 40-core GPU idles.

Recommended:

| Use | Pick | Why |
|---|---|---|
| Bulk / batch transcription | **`parakeet-mlx`** (Apache-2.0 code, CC-BY-4.0 weights) | Beats Whisper large-v3 on WER at ~20x throughput, ~2 GB. 25 European languages + Japanese |
| Multilingual fallback | **`whisper.cpp`** large-v3-turbo | 99 languages; nixpkgs builds it with `GGML_METAL`, `WHISPER_COREML` and `WHISPER_SDL2` (so `whisper-stream` works) |
| Live dictation | **Handy** (MIT, free) or **VoiceInk** (GPL-3.0) | Both fully offline, both already run Parakeet |
| Diarization | **FluidAudio** (Apache-2.0) | Swift/CoreML; ASR + diarization + VAD + TTS in one package |
| True streaming | **Kyutai STT** via `moshi_mlx` | 0.5 s delay (1B) / 2.5 s (2.6B), semantic VAD |

**FluidAudio** ([github](https://github.com/FluidInference/FluidAudio),
Apache-2.0, ~3.1k stars, pushed 2026-10-16) is the one to look at first: it is
the backend inside VoiceInk and many other shipping Mac apps, and it bundles
Parakeet TDT v3 + diarization + Silero VAD + Kokoro TTS behind one Swift API
and a CLI.

**On Wispr Flow:** it is cloud-only at every tier, with audio going to Wispr's
US cloud. It cannot be made local. Handy or VoiceInk are the offline
replacements, and both are a one-line cask addition consistent with the
"GUI casks only" convention in `hosts/macbook/homebrew.nix`.

**On Apple's own SpeechAnalyzer** (new in macOS 26, reachable from the CLI via
`brew install yap`): the sources conflict and the popular story oversells it.
9to5Mac measured Apple at 5.3–10.3% WER vs Whisper large-v3-turbo at 1.5% or
better **[S]**; Argmax measured it as roughly matching WhisperKit `small.en`
**[S]**. Reconciled **[E]**: Whisper-small-class accuracy at 2x+ the speed,
free and zero-install, no diarization, ~30 locales. Fine for "search my
meeting recordings", not for a transcript you will publish.

### 3.3 Text-to-speech — Kokoro, plus Chatterbox if you need cloning

Two picks cover the space with no licensing risk:

- **Kokoro-82M** via `mlx-audio` — Apache-2.0, 82M params, ~312 MB, 54 voices
  across 8 languages, ~25–50x realtime on M4-class silicon **[S]**. By a wide
  margin the most-used open TTS (10.5M HF downloads/30d). Preset voices only,
  no cloning.
- **Chatterbox** (Resemble AI) — **MIT for code *and* weights**, which is rare
  among cloning models. Zero-shot cloning from a short reference, an
  `exaggeration` emotion control, ~3.2 GB, MPS officially supported.

`mlx-audio` (MIT, ~8k stars, actively developed) is the hub worth installing:
20+ TTS models plus Whisper/Parakeet/Granite/Canary on the STT side.

**Licensing traps that catch people** — verified against the HF/GitHub APIs
**[S]**, and several contradict what the project READMEs imply:

- **F5-TTS**: code MIT, **weights CC-BY-NC-4.0**. The MIT badge misleads. Use
  OpenF5-TTS-Base (Apache-2.0) if you need commercial.
- **XTTS-v2**: CPML, non-commercial — and Coqui is defunct, so you can no
  longer buy a commercial licence. Still 6.3M downloads/month from people who
  have not noticed.
- **Piper**: `rhasspy/piper` is archived; active work is `OHF-Voice/piper1-gpl`
  under **GPL-3.0**.
- **Fish Speech / OpenAudio S1**: CC-BY-NC-SA-4.0.
- Genuinely permissive: Kokoro, Chatterbox, Orpheus, Dia, CSM, KittenTTS,
  VibeVoice.

Also abandoned despite 2025 hype: Sesame CSM (last push 2025-05), Dia
(2025-11), Orpheus (2025-12).

Finally, macOS `say` / AVSpeechSynthesizer is free and fine for utility
narration. **Personal Voice cannot be driven from the CLI** — it is scoped to
Live Speech and an accessibility allow-list.

### 3.4 Audio and music generation — the weakest area

This is where Apple Silicon is genuinely badly served. Most leading music
models are CUDA-first *and* non-commercially licensed.

| Model | Mac? | Speed | License | Commercial |
|---|---|---|---|---|
| **ACE-Step 3.5B** | Yes (`--bf16 false`) | **2.27x realtime on M2 Max** **[S]** | Apache-2.0 | Yes |
| Stable Audio Open (1.2B) | Yes, diffusers/MPS | not benchmarked on Mac | Stability Community | Under $1M revenue |
| Stable Audio Open Small | Yes, has an MLX port | 11 s audio in <8 s **on CPU** | Stability Community | Same cap |
| YuE / YuE2 | **No official Mac path** | — | CC-BY-NC-4.0 | **No** |
| MusicGen / AudioCraft | **MPS broken** | — | CC-BY-NC-4.0 | **No** |

**ACE-Step is the only music model that is simultaneously permissive,
confirmed working on Apple Silicon with a real benchmark, and near-current.**
One caveat I could not resolve: my research surfaced conflicting claims about
its version, star count and licence (one source said MIT/v1.5 with an official
macOS launcher; the GitHub API said Apache-2.0, last push 2026-02-15, no macOS
script). **Verify the licence yourself before any commercial use.**

Expect clearly-below-Suno quality, especially on vocals, whatever the
marketing says.

- **Sound effects / foley: AudioLDM 2** — MIT, documented MPS support
  (`audioldm2 --device mps`), ~20 GB RAM which is nothing here. Avoid MMAudio
  (Ubuntu-only, NC checkpoints) and Tango 2 (CC-BY-NC-SA).
- **Stem separation is the one genuinely excellent thing in this section.**
  `demucs-mlx` is a pure MLX/Metal rewrite at **~73x realtime** (a 3:15 track
  in 2.7 s, vs 6.9 s on PyTorch-MPS) **[S]**. For best quality instead of best
  speed, `audio-separator` (MIT) defaults to BS-RoFormer and uses MPS + the
  CoreML execution provider. If you have Logic Pro, its Stem Splitter is
  on-device and needs no setup at all.

### 3.5 Image generation — the one area with real M5 Max benchmarks

Diffusion is compute-bound, which is exactly what the M5 improved, so this is
the activity where the new hardware shows up most clearly.

**Runtime: Draw Things (GUI) for interactive work, `mflux` for anything
scripted.** Both ship their own Metal stacks rather than going through PyTorch
MPS, and both are actively developed (mflux v0.23.0, 2026-10-16; Draw Things
ships roughly weekly) **[S]**.

⚠️ **Use the Draw Things GUI app, not the Homebrew `draw-things-cli`.** Its
issue #132 (2026-09-25) reports the CLI mis-compiling Neural Accelerator
kernels **specifically on M5**, because the binary links against SDK 13.0
**[S]**.

**Models**, with the licensing landscape as it actually is in late 2026 — this
has shifted and the shifts are traps:

| Model | Size (bf16) | Licence | Commercial? |
|---|---:|---|---|
| **FLUX 3 Image Klein** (2026-10-15) | **11.1 GB** | FLUX Kommunity v1.0 | **yes, under $5M revenue** |
| **Z-Image Turbo** (6B, 9 steps) | ~12 GB | **Apache 2.0** | **yes** |
| **Qwen-Image-Edit-2511** (20B) | ~40 GB | **Apache 2.0** | **yes** |
| Qwen-Image-2.1 (7B) — *best open model* | 14 GB | Qwen Research | **NO** |
| FLUX.2 [dev] (32B) | 64 GB | FLUX NC v2.0 | **no** (outputs yes) |
| FLUX.1 [dev] | 24 GB | FLUX NC v1.1.1 | **no** (outputs yes) |

Two traps worth stating plainly **[S]**:

- **The best open image model is not commercially usable.** Qwen-Image-2.1
  tops Artificial Analysis's open-weights board (1042 Elo), and Qwen *walked
  back* Apache 2.0 for it: the licence says "You shall not use the Materials
  for any commercial purpose without obtaining a separate commercial license".
  Qwen-Image-**Edit-2511** and Qwen-Image-2512 remain Apache 2.0.
- **FLUX.1 [dev] weights are still non-commercial**, unchanged in 2026, but
  its *outputs* are explicitly cleared for commercial use. FLUX 3 Klein is the
  first BFL open release that permits commercial use of the model itself.

**Measured on an M5 Max** by mflux's maintainers **[S]** (PRs #864, #834,
#842, Oct 2026):

| Workload | Time | Peak memory |
|---|---:|---:|
| Krea 2 Turbo + depth ControlNet, 1024², 8 steps, **bf16** | 107 s | 41.5 GB |
| same, **q8** | **62 s** | 29.5 GB |
| same, q4 | 50 s | 23 GB |
| Z-Image, 640×368, 9 steps, q8 | **4.2 s** | — |
| Qwen-Image-2.1 + ControlNet, 992×608, 20 steps, q8 | 49 s | 30 GB |

**Default to `-q 8`.** On this chip q8 is *both* 1.7x faster than bf16 *and*
29% lighter — which reverses the M4 behaviour, where quantisation bought
memory and no speed. The mechanism is macOS 26.4 exposing int8 tensors to the
Neural Accelerators **[S]** (Apple Developer Tech Talk 111432: 26.1 added
bfloat16 tensors, 26.3 cooperative tensors, 26.4 int4 and int8). You are on
26.5.2, so the quantised path is live.

**Do not generalise that to LLMs.** I measured MLX's own quantised matmul on
this machine and it goes the other way **[M]**: at prefill shape, 4-bit is
39.7 TFLOPS and 8-bit 37.6, against **61.0 TFLOPS for dense bf16**. Diffusion
runtimes with hand-written int8 kernels get the speedup; MLX's dequantise-then-
multiply path does not. For LLMs, quantisation still buys memory and decode
speed, not prefill.

**Dead ends — do not install [S]:** DiffusionKit (archived by Argmax,
2026-03-21), Fooocus (no FLUX, ever), Core ML Stable Diffusion (no feature
work since mid-2025), SwiftDiffusion, DiffusionBee, and every ComfyUI-MLX
bridge (`ComfyUI-MLX` 404s; `Mflux-ComfyUI` last pushed 2025-03). Stability AI
has shipped no image model since SD 3.5 in October 2024 — there is no SD4.

### 3.6 Video generation and understanding

#### Generation — possible, slow, and full of silent failure modes

**Pick: LTX-2.5 through MLX** (`dgrauet/ltx-2-mlx`, or `mrbizarro/Phosphene`
for a GUI). On identical LTX work, MLX measured **53 s against PyTorch-MPS's
853 s — 16x** **[S]**. Memory: LTX-2.5 is ~120 GB at bf16, ~75 GB at int8,
~47 GB at int4, so **int8 is the right target here** — bf16 technically fits
and leaves nothing.

**Before anything else, set the watchdog variable.** Without
`AGX_RELAX_CDM_CTXSTORE_TIMEOUT`, macOS 26's GPU watchdog inflates per-step
cost on long video kernels by **25–130x** **[S]**. This applies to 26.5.2. If
you ever see absurd per-step times, check this first.

**Realistic expectation [E]:** 5 seconds at 480–720p in **roughly 2–4
minutes**, extrapolated from M3/M4 Max MLX measurements scaled by Draw Things'
measured 3.3x M5-over-M4. There is **no published M5 Max video benchmark from
anyone** — the chip is newer than the public data.

⚠️ **Do not use ComfyUI on MPS for video.** The failure mode is silent
corruption, not an error **[S]**:

- ComfyUI #15793 — Wan 2.1/2.2 silent progressive output corruption on MPS,
  with **M5 explicitly listed as affected** (M3 Pro clean, M4 Pro and M5 bad).
- ComfyUI #15804 — reported *from an M5 Max on macOS 26*: **19 of 26 LTX-2.5
  text-to-video runs produced all-black output; 8 of 8 image-to-video**. Root
  cause identified precisely: MPS does not honour `beta=0` in
  `torch.baddbmm`, so uninitialised NaNs poison the attention scores.
- fp8 does not exist on MPS at all (`Undefined type Float8_e4m3fn`), and
  Conv3D has been unsupported on MPS since 2023.

If you use it anyway, `--use-split-cross-attention` is the workaround, and
inspect every output.

**No Mac path, do not spend time:** HunyuanVideo and 1.5, Mochi, CogVideoX,
Open-Sora, FramePack — CUDA-only, several dormant for a year **[S]**. Also
note Wan's open line stopped at 2.2: 2.5 through 3.0 are API-only.

#### Post-processing is free, and Apple ships it

Verified on this machine **[M]** — all of macOS 26's VideoToolbox frame
processors report supported:

```
VTFrameRateConversion   isSupported: true
VTOpticalFlow           isSupported: true
VTMotionBlur            isSupported: true
VTSuperResolutionScaler isSupported: true
VTTemporalNoiseFilter   isSupported: true
```

Throughput measured on this hardware **[M]**: frame interpolation runs
15.5 ms/frame at 832×480 and 20.9 ms at 720p; 4x super-resolution runs
39 ms/frame for 480×270→1080p and 68 ms for 540p→4K.

In practice: a 5-second 480p clip (120 frames) upscales 4x to 1080p in **~4.7
seconds** and interpolates 24→48 fps in **~1.9 seconds**. Both are rounding
errors against the minutes the generation itself takes. **Generate small and
short, then upscale and interpolate with Apple's own hardware path** — it is
the cheapest quality in this entire document. (MetalFX is the wrong tool here:
its temporal modes need motion vectors and depth from a game renderer.)

#### Understanding — strong, with one specific gap

| Use | Pick | Size | Licence |
|---|---|---:|---|
| Daily driver VLM | **Qwen3.8-27B** MLX 8-bit | 29.5 GB | Apache 2.0 |
| **Video** understanding | **`microsoft/Mage-VL`** | 5B | Apache 2.0 |
| Documents / OCR | **TeleOCR** 1.2B or **OvisOCR2** 0.8B | ~1–2 GB | Apache 2.0 |

The gap: **model support for video is ahead of runtime support for video.**
Qwen3-VL, Qwen3.8 and MiniCPM-V 4.7 all handle video as models, but `mlx-vlm`
only exposes `--video` for a short list (Qwen2-VL, Qwen2.5-VL, Idefics3,
LLaVA, LLaVA-OneVision, MiniMax M3, **Mage-VL**), and **Ollama has no video
input path at all** — its vision docs cover an `images` array only **[S]**.

That makes **Mage-VL the standout pick** and it is not on anyone's radar: 5B,
Apache 2.0, purpose-built for video, codec-native (it keeps only the predicted-
frame patches where the codec spent bits, cutting visual tokens by 75%+ for up
to 3.5x faster inference), and explicitly supported for `--video` in mlx-vlm.
It beats Qwen3-VL-4B by +22.5 on QVHighlight temporal grounding **[S]**.

On OCR, the headline is that **three sub-1.5B specialists beat every general
VLM and both frontier closed models** on OmniDocBench v1.6 **[S]**: TeleOCR
1.2B scores 96.91 and OvisOCR2 0.8B 96.47, against Gemini 3 Pro's 92.91 and
GPT-5.2's 86.59. All three have MLX quantisations and load in seconds. Do not
reach for a 30B VLM to read a PDF.

**Does Qwen3-VL-235B fit? No.** The mlx-community 4-bit is **132.4 GB** —
larger than the whole machine — and the 3-bit is 104 GB, which would need the
wired limit raised to ~115 GB and leave ~13 GB for macOS with nothing for KV
cache **[S]**. The existence of a 3-bit conversion is itself the community's
verdict on 128 GB machines. Do not build on it.

### 3.7 Embeddings and RAG — replace `nomic-embed-text`

The migration plan lists `nomic-embed-text` as the embedding model. **It is
superseded.** That is v1 from February 2024: 137M parameters, 768 dimensions,
8k context. The 2026 equivalent is smaller trouble and better in every
dimension that matters.

| Model | Dims | Max context | MTEB eng-v2 | **MTEB Code** | Size |
|---|---:|---:|---:|---:|---:|
| `nomic-embed-text` (v1.5, 2024) | 768 | **2k in Ollama** | — (62.3 on MTEB *v1*) | none published | 274 MB |
| **`embeddinggemma-2`** (270M core) | 768 (MRL 512/256/128) | 8k | 68.46 | **78.68** | **304 MB** |
| `embeddinggemma` (300m, v1) | 768 (MRL) | 2k | 69.67 | 68.76 | 622 MB |
| `qwen3-embedding:0.6b` | 1024 | **32k** | **70.70** | 75.41 | 639 MB |
| `qwen3-embedding:4b` | 2560 | 32k | 74.60 | 80.06 | 2.5 GB |
| `qwen3-embedding:8b` | 4096 | 32k | 75.22 | **80.68** | 4.7 GB |
| `bge-m3` (Jan 2024) | 1024 | 8k | ~59 legacy | — | 1.2 GB |

Scores **[S]** from the
[Qwen3-Embedding](https://huggingface.co/Qwen/Qwen3-Embedding-0.6B) and
[EmbeddingGemma 2](https://huggingface.co/google/embeddinggemma-2) model
cards; sizes **[S]** from the Ollama library. Note the nomic and Qwen3 English
scores are on different MTEB generations and are not cleanly comparable — the
Code column is.

Worth knowing who is still in this field at all **[S]**: Google, Jina,
Microsoft and NVIDIA shipped embedding models in 2026. **BAAI (BGE), Snowflake
(Arctic), mixedbread and Nomic shipped none** — Nomic's last text embedder was
February 2025 and there is no v3. The "BGE / Arctic / nomic" defaults in most
tutorials are two years stale.

And `nomic-embed-text` is worse here than its spec suggests: **Ollama caps it
at 2,048 tokens, not 8,192** — every tag in the library is listed at 2K, and
`/api/embed` defaults `truncate: true`, so the overflow is dropped **silently,
with HTTP 200** **[S]**, [ollama#11214](https://github.com/ollama/ollama/issues/11214)
(open since 2025-06).

**Pick `embeddinggemma-2`** (304 MB at q8, Apache-2.0, 768d with Matryoshka
truncation, 8k context). Two reasons beyond the MTEB table:

1. **Code retrieval, which is what you actually want it for.** It scores
   **78.68 on MTEB(Code)** against Qwen3-Embedding-0.6B's 75.41 — from a 270M
   text backbone, within 2 points of Qwen's 8B **[S]**. Google's own framing
   is that v2 is "v1 plus code, multimodal and 4x context" with general text
   quality flat; for a code corpus that is exactly the right trade.
2. **It is the only embedder on Ollama's MLX path** **[S]** (§2.9) — and §2.7
   says that is where the performance is on this chip.

Caveat: that MLX path needs Ollama 0.40+. On the installed 0.34.2 you get the
llama.cpp path, which still works.

`qwen3-embedding:0.6b` remains a fine second choice, and its real 32k context
beats EmbeddingGemma's 8k if you embed whole long documents rather than chunks.

#### Three footguns that will silently corrupt your index

These are specific to Ollama on Apple Silicon and none of them produces an
error **[S]**:

1. **All-zero vectors under load** —
   [ollama#17878](https://github.com/ollama/ollama/issues/17878) (open,
   filed on macOS Apple Silicon). A single request of ~4,700+ tokens poisons
   the endpoint: that request returns a valid vector, then **every subsequent
   request returns all zeros, with HTTP 200, correct dimensionality and no log
   line.** Reproduced 21/21. Fix is a restart.
   **Mitigation: assert `‖v‖ ≈ 1.0` on every vector before you store it.**
   Without that check you can poison an entire index and never know.
2. **Task prefixes are your job.** Every modern embedder expects asymmetric
   prefixes — EmbeddingGemma wants `task: code retrieval | query: …` on
   queries and `title: … | text: …` on documents; Qwen3 wants
   `Instruct: …\nQuery:…` on queries only. **Ollama applies none of them**
   ([#16076](https://github.com/ollama/ollama/issues/16076), open). Getting
   this wrong costs more than the gap between any two models in the table
   above, and most Ollama RAG tutorials omit it entirely.
3. **Ollama's advertised context is wrong.** It reports 256K for
   `embeddinggemma-2` (real limit 8,192) and 40K for `qwen3-embedding`
   (real limit 32K) — `max_position_embeddings` leaking through. It will
   therefore not truncate at the real limit, and you get silently degraded
   vectors from text the model was never trained to see. **Chunk to the model
   card's number, not Ollama's.**

**And changing embedding model means re-indexing everything.** Vectors from
different models are not comparable. Decide once.

#### Reranking: worth it, but not through Ollama

**Ollama has no reranking and shows no sign of getting it** — issue #3368 has
been open since 2024, with five PRs closed unmerged **[S]**. Use
`llama-server --rerank` instead; your pinned nixpkgs `llama-cpp` already has
it.

One counter-intuitive finding worth the space, from Qwen's own table **[S]**
— reranking the top-100 from a 0.6B embedder:

| | general retrieval (MTEB-R) | **code (MTEB-Code)** |
|---|---:|---:|
| no reranker | 61.82 | **75.41** |
| + 0.6B reranker | 65.80 ✅ | **73.42** ❌ |
| + 4B reranker | 69.76 ✅ | **81.20** ✅ |

**A small reranker actively hurts code retrieval.** For code, use a 4B-class
reranker or none at all. `bge-reranker-v2-m3` — the default in most RAG
tutorials — scores 41.38 on MTEB-Code and is the trap here.

**Vector store**, for a single user on one Mac **[S]** (stars/activity checked
2026-10-19):

- **LanceDB** (11.7k, Apache-2.0, actively pushed) — embedded, no server, good
  on-disk format, handles multimodal. The default recommendation.
- **sqlite-vec** (8.2k, Apache-2.0) — the simplest possible thing if your data
  already lives in SQLite. Note its last push was 2026-05-18, so it is quiet.
- **Qdrant** (35k) / **Chroma** (29.5k) — both fine and both active, but they
  want a server process. Only worth it if you need the features.

Turnkey, if you would rather not build it: **Open WebUI** (156k stars, active)
talks to Ollama natively and does document RAG out of the box;
**AnythingLLM** (67k, MIT) is the more opinionated alternative.

### 3.8 Personal agents, tool calling, MCP and voice

#### Claude Code against a local model needs no proxy

This surprised me, so it is verified three ways. **Ollama 0.34.2 — the exact
version installed — serves the Anthropic Messages API directly.** From
`server/routes.go` at the `v0.34.2` tag **[S]**:

```go
// Inference (Anthropic compatibility)
r.POST("/v1/messages", s.withInferenceRequestLogging("/v1/messages",
    cloudPassthroughMiddleware(...), middleware.AnthropicMessagesMiddleware(),
    s.ChatHandler)...)
```

And live, against the running server on this machine **[M]**:

```console
$ curl -s localhost:11434/v1/messages -H 'content-type: application/json' \
    -d '{"model":"qwen3-coder:30b","max_tokens":16,
         "messages":[{"role":"user","content":"hi"}]}'
{"type":"error","error":{"type":"not_found_error",
 "message":"model 'qwen3-coder:30b' not found"},
 "request_id":"req_2ad51d235b117f92080be253"}
```

That is the Anthropic error envelope, `request_id` and all — not a generic 404
(a genuinely nonexistent route returns a bare 404 for contrast). The model is
missing only because nothing has been pulled yet.

So the whole ecosystem of Claude-Code-to-local-model routers —
`claude-code-router` (37.7k stars) and the long tail of smaller proxies — is
**unnecessary here**. Point Claude Code at the local server:

```bash
ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY=ollama claude
```

Newer Ollama even ships a first-party launcher for it — `ollama launch claude
--model <model>` sets the environment for you **[S]**.

#### …and you probably still should not

Having established that it works, here is the case against, because the
failure modes are silent **[S]**:

- **Anthropic explicitly disclaims it.** From the Claude Code LLM-gateway
  docs: *"Anthropic doesn't endorse, maintain, or audit third-party gateway
  products, and doesn't support routing Claude Code to non-Claude models
  through any gateway."*
- **MCP tool search is disabled behind a custom `ANTHROPIC_BASE_URL`.** It is
  an Anthropic-API feature, not an MCP one. So every MCP tool definition loads
  upfront on every request — maximum context bloat, paired with the model
  least able to absorb it. Claude Code also stops reporting failed MCP
  connections in that configuration.
- **Prompt caching fails silently** — no error, every turn bills as uncached.
  [ollama#18431](https://github.com/ollama/ollama/issues/18431) measured the
  consequence: one subagent run hit 146 turns and **6.5M uncached input
  tokens**, because Claude Code's per-turn token-reminder suffix makes the
  prefix diverge every time.
- **Tool calls come back as literal text.**
  [ollama#18346](https://github.com/ollama/ollama/issues/18346): given Claude
  Code's real `Bash` tool schema, `qwen3-coder:30b` emits
  `<function=Bash><parameter=command>` as plain text instead of a `tool_use`
  block. A simple one-parameter tool works fine; the real schema does not.

**So: use a harness built for local models instead** — **Goose** (55k stars,
now under the Linux Foundation's Agentic AI Foundation, native Ollama
provider) or **opencode** (217k stars). Neither assumes prompt caching,
server-side tool search, or an Anthropic-shaped system prompt. Keep Claude
Code for Claude.

Two more endpoints in the same route table worth knowing **[M]**:
`/v1/responses` (the OpenAI Responses API) and `/v1/audio/transcriptions`
(OpenAI-compatible Whisper, which returned 400-on-bad-input rather than 404,
so it is live). One server covers three API dialects.

#### Everything else just speaks OpenAI

Agent CLIs that already point at `http://localhost:11434/v1` with no adapter —
Aider, OpenCode, Continue, Cline/Roo, Goose, `pi` — need nothing from this
document except a model name. Several are already installed via
`hosts/macbook/homebrew.nix` (`pi-coding-agent`, `gastown`, `gascity`).

Two maintenance notes that matter for `docs/local-ai-agents-guide.md`, which
leans on both **[S]**: **Aider has not released since v0.86.0 in August 2025**
and last pushed 2026-05-22, and **Roo Code is archived.** Meanwhile Goose
(v1.55.0), opencode (v1.19.3), Cline, OpenHands, Crush and Kilo Code all
pushed within the last day. That guide's recommendations have aged.

On voice and dictation specifically, `brew install --cask handy` is about
thirty minutes from working and is genuinely offline (§3.2).

#### Tool calling

Ollama supports tool calling including parallel calls and streaming, and
accumulating `thinking`, `content` and `tool_calls` across stream chunks is the
documented pattern **[S]**,
[docs.ollama.com/capabilities/tool-calling](https://docs.ollama.com/capabilities/tool-calling).
MCP is not mentioned in Ollama's own docs — MCP lives in the *client* (Claude
Code, Goose, Cline), which then talks to Ollama as a plain model endpoint. So
"MCP with a local model" is really "an MCP-capable client pointed at Ollama",
and it works exactly as well as the model's tool-calling discipline does.

That discipline is the actual limit, and **it is the weakest link in the whole
local-agent story.** No amount of RAM fixes it.

The honest numbers, with a large caveat: the Berkeley Function-Calling
Leaderboard is the canonical benchmark and **it is frozen at March 2026** —
its model list tops out at Qwen3, Kimi K2 and GLM-4.6, with none of the 2026
generation **[S]**. What it did capture:

| Model | Overall | Multi-turn |
|---|---:|---:|
| Claude Opus 4.5 | 77.5% | 68.4% |
| **GLM-4.6** (MIT) | **72.4%** | 68.0% |
| Qwen3-235B-A22B | 52.2% | 44.6% |
| **Qwen3-30B-A3B** — the class you would actually run | **41.4%** | **30.0%** |

One open model reached frontier tool-calling. **The 30B-class MoE that fits
comfortably on this machine scored 41% overall and 30% multi-turn.** Every
flattering 2026 number you will read is vendor self-reported.

What breaks in practice, all open issues **[S]**: optional fields before
required ones get dropped (llama.cpp #30321); tool calls leak into content
*stochastically* (#30078); `tool_choice` does not work (#30369); and **a large
tools array fails outright** — llama.cpp #30056 reports ~60 tools with nested
MCP schemas returning HTTP 400 before a single token, because the GBNF grammar
is built per request.

**Practical rule: cap a local agent at roughly 5–15 tools.** Local models do
not degrade gracefully as the tool list grows; they stop working. And test on
your own schemas before trusting an unattended loop.

#### Voice

The pieces for a fully-local voice assistant all exist and are covered above:
Parakeet or `whisper.cpp` for STT (§3.2), a local model for reasoning, Kokoro
for TTS (§3.3). Latency is dominated by the LLM, and on this machine a
30B-class MoE is fast enough for conversational turn-taking.

**Cascaded beats native speech-to-speech on a Mac, and it is not close.**
Every impressive voice-latency number in circulation was measured on NVIDIA:
Moshi's 200 ms is an L4, Supertonic's 47 ms a 5090, Qwen3-TTS's 97 ms
unspecified. **Unmute will never run here** — its README says x86_64 only, no
aarch64 planned. The one native speech-to-speech measurement that exists on
Apple Silicon (Qwen3-Omni, M4 Pro, 4-bit) reports **RTF 1.18 streaming —
slower than real time** **[S]**.

The cascade's parts, by contrast, are each fast and each measured on Apple
Silicon **[S]**: Smart Turn v3 endpointing at 12.6 ms, Parakeet MLX at RTF
0.0137, TTS first-audio around 80 ms. Summing them gives roughly **650–900 ms
voice-in to voice-out, dominated by endpointing rather than compute** —
though that sum is arithmetic, not a measurement, and **nobody has published
an end-to-end local voice-loop latency on any Apple Silicon Mac**.

If you build one: **Pipecat** (v1.13, 2026-10-19) is the right framework —
it has real local services for MLX Whisper, Moonshine, Kokoro, Piper and
Ollama. LiveKit Agents has only two local plugins and you would be writing
your own STT and TTS.

The pragmatic path remains the non-duplex one: a push-to-talk dictation app
(§3.2) into a normal agent. Note that **wake words have quietly been abandoned
on the desktop** — Handy, VoiceInk, Superwhisper and MacWhisper are all
hotkey-driven, and a hotkey has a 0% false-accept rate.

---

## 4. PROPOSED diff for `home/ollama.nix` — not applied

Four substantive changes:

1. **Delete `OLLAMA_USE_MLX`** — it does nothing (§2.5).
2. **Delete `OLLAMA_FLASH_ATTENTION`** — redundant since Ollama's `auto`
   default, and forcing it removes a decision Ollama makes per-model (§2.5).
3. **`OLLAMA_NUM_PARALLEL` 4 → 2** — this value multiplies the KV cache (§2.3).
4. **Add `OLLAMA_CONTEXT_LENGTH = "65536"`** — otherwise it auto-selects 256k
   on this machine, and 256k x 4 slots is the memory trap (§2.4).

The rest is comments that record *why*, so the next person does not have to
re-derive it. Indicative, not a patch to apply blind — line numbers will have
moved.

```diff
--- a/home/ollama.nix
+++ b/home/ollama.nix
   perHost =
     if hostname == "christoryCertifyOSMacbook" then {
-      # 128GB unified memory (measured: hw.memsize, 2026-10-18 — the planning
-      # docs said 256GB and were wrong). Full-precision KV cache, real
-      # parallelism, but not unlimited: see the model table in docs/migration.md.
+      # M5 Max, 128GB unified memory (measured: hw.memsize). 128GB is the
+      # chip's maximum — 256GB was never possible. Metal reports a 107.5GiB
+      # GPU budget; ~100GiB is usable for weights + KV.
+      # Sizing arithmetic and sources: docs/local-ai-128gb.md.
       OLLAMA_KV_CACHE_TYPE = "f16";
       OLLAMA_KEEP_ALIVE = "1h";       # RAM is plentiful — keep models hot
-      OLLAMA_NUM_PARALLEL = "4";
+
+      # Ollama multiplies the KV cache by this value — literally:
+      #   effectiveLlamaServerContext() = effectiveModelContext() * numParallel
+      # (ollama/server/sched.go). Upstream default is 1. Four slots buys a
+      # single human nothing and costs 4x the KV cache. Raise it only when
+      # genuinely fanning out concurrent agents against one model.
+      OLLAMA_NUM_PARALLEL = "2";
+
+      # Pin it. Unset, Ollama picks from a VRAM tier table and anything with
+      # >=48GiB lands on 256k (docs/context-length.mdx). 256k x 4 slots on
+      # qwen3-coder:30b-a3b is ~96GiB of KV cache to serve a 19GB model.
+      # 64k matches Ollama's own advice for agents and coding tools.
+      OLLAMA_CONTEXT_LENGTH = "65536";
+
       # A cap, not a reservation; ollama evicts as it needs room. Three small
       # models co-reside comfortably, but two 65GB-class ones do not fit in
       # 128GB — the limit in practice is model size, not this number.
       OLLAMA_MAX_LOADED_MODELS = "3";
     } else {
       # M3 18GB: RAM limited.
       OLLAMA_KV_CACHE_TYPE = "q8_0";  # halves KV cache memory
       OLLAMA_KEEP_ALIVE = "10m";      # shorter keepalive to free RAM faster
       OLLAMA_NUM_PARALLEL = "1";      # single request at a time
       OLLAMA_MAX_LOADED_MODELS = "1"; # only one model loaded at a time
     };
 
-  ollamaEnv = {
-    OLLAMA_USE_MLX = "1";         # Apple MLX backend (unified memory, no CPU/GPU copy overhead)
-    OLLAMA_FLASH_ATTENTION = "1"; # faster inference on Apple Silicon
-  } // perHost;
+  # Both former globals are gone, verified against ollama 0.34.2 on 2026-10-19:
+  #
+  #   OLLAMA_USE_MLX        does not exist. `ollama serve --help` lists every
+  #                         variable the server reads and it is not among them,
+  #                         nor does the string appear in the binary. On 0.34.2
+  #                         Ollama runs llama.cpp's Metal backend and no env
+  #                         var changes that. Ollama 0.40+ DOES run MLX by
+  #                         default on Apple Silicon — so the way to get what
+  #                         this line wanted is to upgrade, not to set a flag.
+  #
+  #   OLLAMA_FLASH_ATTENTION  redundant. Ollama defaults to `auto` and
+  #                         ml.FlashAttentionSupported() returns true for Metal
+  #                         unconditionally, so FA is already on for every
+  #                         model here. Forcing it only removes Ollama's
+  #                         ability to disable FA for models that need that.
+  ollamaEnv = perHost;
```

### Why not change the other things

- **`OLLAMA_KV_CACHE_TYPE = "f16"`** — correct. You are not short of memory and
  f16 avoids a class of silent long-context degradation. §2.2.
- **`OLLAMA_MAX_LOADED_MODELS = "3"`** — correct, and the existing comment
  already says the right thing (bytes bind before count does).
- **`OLLAMA_KEEP_ALIVE = "1h"`** — correct. Reloading a 65 GB model costs
  several seconds of SSD even at 12 GB/s.
- **No `iogpu.wired_limit_mb` anywhere** — correct, and should stay that way.
  §2.1.

### Changes that are *not* in ollama.nix but matter more

```bash
brew upgrade mlx mlx-lm     # 4x MLX prefill on this chip — see §2.6
nix flake update            # ollama 0.34.2 -> 0.40.x, which runs MLX by
                            # default on Apple Silicon — see §2.9
```

**Both of these matter more than anything in the diff above.** The theme of
this document's tuning findings is that the config is fine and the *versions*
are the problem: an MLX that does not use the M5's matrix units, and an Ollama
one release short of running MLX at all.

---

## 5. Assumptions, gaps, and what I could not determine

Recorded here rather than smoothed over, because this document will be read
later as if it were settled.

**Assumptions made without asking** (the user was asleep):

- `OLLAMA_NUM_PARALLEL = 2` rather than 1. One is upstream's default and is
  right for a single interactive user; 2 is a hedge because this machine runs
  multi-agent orchestration (Gastown/Gas City) where two concurrent local
  requests are plausible. If local models never serve more than one caller at
  a time, 1 is strictly better.
- `OLLAMA_CONTEXT_LENGTH = 65536` rather than 32k or 128k. 64k is Ollama's own
  stated floor for agent and coding workloads, and it keeps KV cost sane at
  2 parallel slots. Raise per-request rather than globally.
- Nothing was installed, downloaded, upgraded or changed. `brew upgrade mlx
  mlx-lm` is recommended but was not run.

**Measured on battery, not mains.** Every throughput number in §1 was taken
with the machine discharging at ~52%. Sustained GEMM settled 24% below its
opening window. Plugged in these numbers should be better, so treat them as
floors. Re-running §1's benchmarks on mains is the single cheapest way to
improve this document.

**What I could not determine:**

- **No end-to-end tok/s for any real model on this machine.** The brief
  forbade downloads, so every per-model speed here is derived from the measured
  bandwidth and TFLOPS, not observed. Once a model is pulled,
  `mlx_lm.benchmark` and `ollama run --verbose` will settle it in minutes, and
  the two formulas in §3.1 can then be calibrated rather than trusted.
- **Almost no published M5 Max benchmark exists.** The chip shipped
  2026-03-03 and most community numbers are M2/M3/M4. The two exceptions I
  found and used are llama.cpp's benchmark thread (§3.1) and mflux's
  maintainer benchmarks (§3.5). For **video generation there is no M5 Max
  measurement from anyone**; §3.6's timing is extrapolation and says so.
- **Whether `iogpu.wired_limit_mb` behaves identically on M5.** The 1:1
  behaviour is confirmed on an M4 Max/128 GB, not here. Testing it needs sudo
  and a reboot to undo cleanly.
- **Reddit (r/LocalLLaMA) is network-blocked from this environment**, and it is
  where most Apple-Silicon LLM measurement actually gets published. That is the
  largest single coverage gap in the research behind this document.
- The web-search budget for the session was exhausted partway through, so later
  sections lean on direct API and page fetches rather than broad search.
  LMArena is also unreachable, so there are no arena numbers anywhere here.
- Unresolved contradictions flagged inline: ACE-Step's version and licence
  (§3.4), and FLUX 3 Klein's memory figure (BFL's blog says 11.2 GB, its model
  card says 31 GB peak — probably weights-versus-reference-implementation, but
  unconfirmed).
- **Tool-calling numbers are from a frozen benchmark.** BFCL stopped being
  updated in March 2026 and contains no 2026-generation model (§3.8). Every
  newer figure in circulation is vendor self-reported.
- **No end-to-end local voice-loop latency has been published for any Apple
  Silicon Mac.** The 650–900 ms in §3.8 is my arithmetic over measured parts.
- **macOS 27 appears to exist** (27.0.1, 2026-09-28) while this machine is on
  26.5.2. I did not chase what that would change; several of the newest Apple-
  native tools already target 27.

**One widely-repeated claim this document contradicts.** Several sources —
including one of my own research passes — state that macOS reserves ~25% of
unified memory from the GPU, giving "~96 GB of 128". **Measured here, the
budget is 107.5 GiB (84%).** The 75% figure is a 2023 kernel constant that
macOS 26 no longer uses (§2.1). If you see the 96 GB number repeated, it is
stale.

**Things that would change the recommendations if they turned out false:**

- That q8_0 weights really are worth the halved decode speed for your work.
  §3.1 assumes yes for a coding model; that is a taste judgement, and
  `mlx_lm.perplexity` on your own repositories would replace it with evidence.
- That `gpt-oss:120b` is actually the strongest coding model that fits. It is
  the strongest I can justify from architecture and size, but I did not run a
  coding benchmark, and the field moves monthly.
