# GlitchTip MCP Global And Server Enablement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add GlitchTip as a globally configured Codex MCP server and enable the built-in MCP endpoint on the hosted GlitchTip instance so the client config points at a live service.

**Architecture:** Use Codex's global `~/.codex/config.toml` layer for the client-side MCP entry, preserving project independence and shared access across Codex surfaces. Use the existing GlitchTip Ansible repo's environment template and host vars to turn on `GLITCHTIP_ENABLE_MCP`, extend the static test to cover the host var, then redeploy through the repo's normal `just deploy` workflow.

**Tech Stack:** Codex CLI config, TOML, Ansible, Jinja templates, pytest, Docker Compose

---

### Task 1: Add the global Codex MCP server

**Files:**
- Modify: `~/.codex/config.toml`

**Step 1: Inspect existing MCP config**

Run: `codex mcp list`
Expected: Existing servers listed, with no `glitchtip` entry yet.

**Step 2: Add the global server**

Run: `codex mcp add glitchtip --url https://glitchtip.batb.love/mcp`
Expected: Codex writes a new `mcp_servers.glitchtip` HTTP entry to `~/.codex/config.toml`.

**Step 3: Verify the new server definition**

Run: `codex mcp get glitchtip`
Expected: A streamable HTTP MCP server definition pointing at `https://glitchtip.batb.love/mcp`.

### Task 2: Cover the GlitchTip Ansible host var with a failing test

**Files:**
- Modify: `/home/mr_bowtie/self-hosting/glitchtip-ansible/tests/test_project_static.py`

**Step 1: Extend the host var test**

Add an assertion that `inventory/host_vars/files.batb.love/vars.yml` includes `glitchtip_enable_mcp: "True"`.

**Step 2: Run the targeted test to verify it fails**

Run: `python3 -m pytest tests/test_project_static.py -q`
Expected: FAIL because the host var is not yet set.

### Task 3: Enable MCP in the GlitchTip deployment config

**Files:**
- Modify: `/home/mr_bowtie/self-hosting/glitchtip-ansible/inventory/host_vars/files.batb.love/vars.yml`

**Step 1: Set the host override**

Add `glitchtip_enable_mcp: "True"` near the other GlitchTip feature flags.

**Step 2: Re-run the test suite**

Run: `python3 -m pytest tests/test_project_static.py -q`
Expected: PASS.

### Task 4: Redeploy and verify the hosted stack

**Files:**
- No file changes

**Step 1: Run the standard deploy**

Run: `just deploy`
Expected: Ansible updates `/opt/glitchtip/.env` on `files.batb.love` and restarts or reconciles the GlitchTip stack cleanly.

**Step 2: Confirm the generated env on the host**

Run: `ssh -i ~/.ssh/nextcloud_key root@files.batb.love 'grep ^GLITCHTIP_ENABLE_MCP= /opt/glitchtip/.env'`
Expected: `GLITCHTIP_ENABLE_MCP=True`

**Step 3: Confirm the public MCP endpoint responds**

Run: `curl -I https://glitchtip.batb.love/mcp`
Expected: A non-404 HTTP response from the MCP endpoint.
