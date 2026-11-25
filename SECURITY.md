# Security Policy

This is a set of MATLAB functions and a MATLAB dashboard that run on the user's own
machine with that user's permissions. It contains no server, network client or
authentication of its own. The `mcp_*` functions are meant to be called by a MATLAB MCP
server that you run separately, so whoever can call that server can call these functions.

## Supported versions

| Version | Supported |
|---|---|
| 0.1.x | ✅ Current |

Single maintainer; only the latest release receives fixes.

## Reporting a vulnerability

**Please do not open a public issue for a security problem.** Report it privately:
**[Report a vulnerability](https://github.com/sergiudanstan/satellite-mcp-matlab/security/advisories/new)**
(Security → Advisories → Report a vulnerability).

| Stage | Target |
|---|---|
| Acknowledgement | within 3 business days |
| Triage | within 10 business days |
| Fix, or a documented decision not to fix | within 90 days |

These are best-effort targets from a single unpaid maintainer, not a contractual SLA.
There is no bug bounty; credit is offered in the advisory and changelog.

## Scope

In scope: - The satellite name passed to `mcp_load_satellite` / `Satellite(name)` is used to build a
  function name and a file path, and the matching `<name>_sat_params.m` is executed
  (`feval` and `run` in `src/core/Satellite.m`, `feval` in `src/mcp_tools/satellite_mcp_tools.m`).
  A crafted name that makes MATLAB run a file other than the shipped parameter files is a
  vulnerability; we have not audited or exploited this, so treat the function as trusting its
  caller.
- Image and file paths that the localization and super-resolution tools read with `imread`,
  and output written by the dashboard (`saveas`, `VideoWriter`), where a path chosen by an
  untrusted caller reaches outside `data/` or `results/`.
- Anything in this repository's workflows that could publish a release not built from `main`.

Out of scope: vulnerabilities in MATLAB, its toolboxes or the MATLAB MCP server you use to expose these
functions (report upstream), and the accuracy of the orbit, localization or
super-resolution results. The propagator is unperturbed Keplerian motion and the
localization is not a trained model; wrong numbers are a correctness bug, file them as a
normal issue.

## Supply chain

CI runs the MATLAB test suite (base MATLAB, no toolbox) on every push, `pip-audit` on the
hash-pinned CI toolchain, CodeQL on the workflow files (CodeQL does not analyse MATLAB, so
the MATLAB source itself has no static security analysis), and `zizmor` on the workflows. Actions are pinned to full commit SHAs and kept current by Dependabot. Releases attach a
source archive with Sigstore build provenance:

```
gh attestation verify satellite-mcp-matlab-v0.1.0.tar.gz --repo sergiudanstan/satellite-mcp-matlab
```
