#!/usr/bin/env python3

import argparse
import hashlib
import os
import re
import subprocess
import sys
from pathlib import Path

import yaml


def _load_env_file(path: Path):
    if not path.exists() or not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def _env_path(name: str, default: str) -> Path:
    raw = os.environ.get(name, default)
    return Path(os.path.expandvars(raw)).expanduser()


def load_repo_sync_env():
    explicit = os.environ.get("REPO_SYNC_ENV_FILE", "").strip()
    if explicit:
        _load_env_file(Path(explicit).expanduser())
        return
    _load_env_file(Path.home() / ".config" / "repo-sync" / "config.env")


load_repo_sync_env()

OWNER = os.environ.get("REPO_SYNC_GH_USERNAME", "").strip()
STATE_REPO_URL = os.environ.get("REPO_SYNC_STATE_REPO_URL", "").strip()
WORKSPACES_DIR = _env_path("REPO_SYNC_WORKSPACES_DIR", "~/workspaces/github")
STATE_DIR = _env_path("REPO_SYNC_STATE_DIR", "~/project-state")
GH_TOKEN_PATH = _env_path("REPO_SYNC_GH_TOKEN_PATH", "/run/secrets/github.token")
LOCAL_PATHS_PATH = _env_path("REPO_SYNC_PATHS_FILE", "~/.config/repo-sync/paths.yaml")

STATE_CONFIG_PATH = STATE_DIR / "config" / "repos.yaml"
STATE_REPOS_ROOT = STATE_DIR / "repos"

DESCRIPTION = "Sync selected code repositories with private per-repo state"
EPILOG = """Examples:
  repo-sync init
  repo-sync add Shrub24/dev-vps
  repo-sync add Shrub24/dev-vps --path ~/Projects/dev/dev-vps --existing
  repo-sync track ~/Projects/dev/dev-vps
  repo-sync track ~/Projects/dev/dev-vps Shrub24/dev-vps
  repo-sync sync
  repo-sync state add .opencode
"""


def run(cmd, cwd=None, check=True, capture_output=False, input_text=None):
    return subprocess.run(
        cmd,
        cwd=cwd,
        check=check,
        text=True,
        capture_output=capture_output,
        input=input_text,
    )


def read_cmd_output(cmd, cwd=None):
    result = run(cmd, cwd=cwd, check=False, capture_output=True)
    if result.returncode != 0:
        return ""
    return (result.stdout or "").strip()


def fail_from_result(result, default_msg="git command failed"):
    err = (result.stderr or "").strip()
    out = (result.stdout or "").strip()
    msg = err or out or default_msg
    line = msg.splitlines()[-1] if msg else default_msg
    raise RuntimeError(line)


def git_cmd(args, cwd=None):
    result = run(["git", *args], cwd=cwd, check=False, capture_output=True)
    if result.returncode != 0:
        fail_from_result(result, "git operation failed")
    return result


def validate_required_config():
    missing = []
    if not OWNER:
        missing.append("REPO_SYNC_GH_USERNAME")
    if not STATE_REPO_URL:
        missing.append("REPO_SYNC_STATE_REPO_URL")
    if missing:
        raise RuntimeError(f"Missing required configuration: {', '.join(missing)}")


def get_gh_token():
    if not GH_TOKEN_PATH.exists():
        raise RuntimeError(f"Missing GitHub token secret: {GH_TOKEN_PATH}")
    token = GH_TOKEN_PATH.read_text(encoding="utf-8").strip()
    if not token:
        raise RuntimeError("GitHub token secret is empty")
    return token


def ensure_git_identity():
    if not read_cmd_output(["git", "config", "--global", "user.name"]):
        run(["git", "config", "--global", "user.name", OWNER])
    if not read_cmd_output(["git", "config", "--global", "user.email"]):
        run(
            [
                "git",
                "config",
                "--global",
                "user.email",
                f"{OWNER}@users.noreply.github.com",
            ]
        )
    run(
        ["git", "config", "--global", "credential.https://github.com.username", OWNER],
        check=False,
    )


def ensure_gh_auth():
    status = run(
        ["gh", "auth", "status", "-h", "github.com"], check=False, capture_output=True
    )
    if status.returncode != 0:
        token = get_gh_token()
        run(
            ["gh", "auth", "login", "--hostname", "github.com", "--with-token"],
            input_text=f"{token}\n",
        )
    run(["gh", "auth", "setup-git"], check=False)


def ensure_state_repo():
    ensure_git_identity()
    ensure_gh_auth()
    STATE_DIR.parent.mkdir(parents=True, exist_ok=True)

    if not STATE_DIR.exists():
        git_cmd(["clone", STATE_REPO_URL, str(STATE_DIR)])
        return

    if (STATE_DIR / ".git").exists():
        git_cmd(["-C", str(STATE_DIR), "fetch", "--prune", "origin"])
        return

    if any(STATE_DIR.iterdir()):
        raise RuntimeError(
            f"{STATE_DIR} exists but is not a git repository; move it and re-run"
        )
    STATE_DIR.rmdir()
    git_cmd(["clone", STATE_REPO_URL, str(STATE_DIR)])


def ensure_dirs():
    WORKSPACES_DIR.mkdir(parents=True, exist_ok=True)
    (STATE_DIR / "config").mkdir(parents=True, exist_ok=True)
    STATE_REPOS_ROOT.mkdir(parents=True, exist_ok=True)
    LOCAL_PATHS_PATH.parent.mkdir(parents=True, exist_ok=True)


def load_shared_config():
    if not STATE_CONFIG_PATH.exists():
        return {"repos": []}
    data = yaml.safe_load(STATE_CONFIG_PATH.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        return {"repos": []}
    if not isinstance(data.get("repos"), list):
        data["repos"] = []
    return data


def save_shared_config(cfg):
    STATE_CONFIG_PATH.write_text(
        yaml.safe_dump(cfg, sort_keys=False, default_flow_style=False), encoding="utf-8"
    )


def load_local_paths():
    if not LOCAL_PATHS_PATH.exists():
        return {"paths": []}
    data = yaml.safe_load(LOCAL_PATHS_PATH.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        return {"paths": []}
    if not isinstance(data.get("paths"), list):
        data["paths"] = []
    return data


def save_local_paths(data):
    LOCAL_PATHS_PATH.write_text(
        yaml.safe_dump(data, sort_keys=False, default_flow_style=False),
        encoding="utf-8",
    )


def parse_remote(remote):
    if "/" not in remote:
        raise RuntimeError(f"Invalid remote format '{remote}', expected owner/repo")
    owner, repo = remote.split("/", 1)
    if not owner or not repo:
        raise RuntimeError(f"Invalid remote format '{remote}', expected owner/repo")
    return owner, repo


def key_from_remote(remote):
    return f"github:{remote}"


def sanitize_key(key):
    if key.startswith("github:"):
        return key.replace(":", "/", 1)
    safe = re.sub(r"[^a-zA-Z0-9._-]+", "-", key).strip("-") or "repo"
    digest = hashlib.sha1(key.encode("utf-8")).hexdigest()[:8]
    return f"local/{safe}-{digest}"


def state_dir_from_key(key):
    return STATE_REPOS_ROOT / sanitize_key(key)


def repo_root_from_path(path_str):
    p = Path(path_str).expanduser()
    if not p.is_absolute():
        p = (Path.cwd() / p).resolve()
    return p


def get_repo_root_from_cwd():
    root = read_cmd_output(["git", "rev-parse", "--show-toplevel"])
    return Path(root).resolve() if root else None


def infer_remote_from_path(repo_path: Path):
    url = read_cmd_output(
        ["git", "-C", str(repo_path), "config", "--get", "remote.origin.url"]
    )
    if not url:
        return None

    m = re.search(r"github\.com[:/]([^/]+)/([^/.]+)(?:\.git)?$", url)
    if not m:
        return None
    return f"{m.group(1)}/{m.group(2)}"


def find_shared_entry(shared_cfg, key):
    for entry in shared_cfg.get("repos", []):
        if isinstance(entry, dict) and entry.get("key") == key:
            return entry
    return None


def ensure_shared_entry(shared_cfg, key, remote=None):
    entry = find_shared_entry(shared_cfg, key)
    if entry:
        if remote and not entry.get("remote"):
            entry["remote"] = remote
        if not isinstance(entry.get("mappings"), list):
            entry["mappings"] = []
        if not isinstance(entry.get("ignorePaths"), list):
            entry["ignorePaths"] = []
        return entry

    entry = {"key": key, "remote": remote, "mappings": [], "ignorePaths": []}
    shared_cfg.setdefault("repos", []).append(entry)
    return entry


def set_local_path(local_cfg, key, path: Path):
    path = path.expanduser().resolve()
    entries = local_cfg.setdefault("paths", [])
    for item in entries:
        if isinstance(item, dict) and item.get("key") == key:
            item["path"] = str(path)
            return
    entries.append({"key": key, "path": str(path)})


def get_local_path(local_cfg, key):
    for item in local_cfg.get("paths", []):
        if (
            isinstance(item, dict)
            and item.get("key") == key
            and isinstance(item.get("path"), str)
        ):
            return Path(item["path"]).expanduser().resolve()
    return None


def ensure_exclude(repo_path: Path, rel_path: str):
    exclude = repo_path / ".git" / "info" / "exclude"
    exclude.parent.mkdir(parents=True, exist_ok=True)
    current = exclude.read_text(encoding="utf-8") if exclude.exists() else ""
    if rel_path not in current.splitlines():
        with exclude.open("a", encoding="utf-8") as f:
            f.write(f"{rel_path}\n")


def normalize_mapping(entry_key, mapping):
    if not isinstance(mapping, dict):
        raise RuntimeError(f"Invalid mapping for {entry_key}: {mapping}")
    from_value = mapping.get("from", "")
    if not isinstance(from_value, str) or not from_value.startswith("state:"):
        raise RuntimeError(f"Invalid mapping.from for {entry_key}: {from_value}")
    state_rel = from_value[len("state:") :].lstrip("/")
    to_value = mapping.get("to")
    if to_value is None:
        to_value = f"repo:{state_rel}"
    if not isinstance(to_value, str) or not to_value.startswith("repo:"):
        raise RuntimeError(f"Invalid mapping.to for {entry_key}: {to_value}")
    mode = mapping.get("mode", "symlink")
    if mode != "symlink":
        raise RuntimeError(
            f"Unsupported mapping.mode for {entry_key}: {mode}; only symlink is supported"
        )
    return {
        "from": from_value,
        "to": to_value,
        "untracked": bool(mapping.get("untracked", True)),
        "mode": mode,
    }


def resolve_mapping_paths(entry_key, repo_root: Path, mapping):
    normalized = normalize_mapping(entry_key, mapping)
    state_rel = normalized["from"][len("state:") :].lstrip("/")
    repo_rel = normalized["to"][len("repo:") :].lstrip("/")
    state_path = state_dir_from_key(entry_key) / state_rel
    repo_path = repo_root / repo_rel
    return normalized, state_rel, repo_rel, state_path, repo_path


def apply_mapping(entry_key, repo_root: Path, mapping):
    normalized, _, repo_rel, state_path, repo_path = resolve_mapping_paths(
        entry_key, repo_root, mapping
    )

    state_path.parent.mkdir(parents=True, exist_ok=True)

    repo_path.parent.mkdir(parents=True, exist_ok=True)
    if repo_path.is_symlink():
        if repo_path.resolve() != state_path.resolve():
            repo_path.unlink()
            repo_path.symlink_to(state_path)
    elif repo_path.exists():
        return
    else:
        repo_path.symlink_to(state_path)

    if normalized.get("untracked", True):
        ensure_exclude(repo_root, repo_rel)


def apply_default_root_mappings(entry_key, entry, repo_root: Path, explicit_targets):
    state_root = state_dir_from_key(entry_key)
    ignore = {p for p in entry.get("ignorePaths", []) if isinstance(p, str)}
    ignore.add(".git")
    if not state_root.exists():
        return
    for item in sorted(state_root.iterdir(), key=lambda p: p.name):
        name = item.name
        if name in ignore or name in explicit_targets:
            continue
        apply_mapping(
            entry_key,
            repo_root,
            {
                "from": f"state:{name}",
                "to": f"repo:{name}",
                "untracked": True,
                "mode": "symlink",
            },
        )


def install_hook(repo_root: Path, key: str):
    hook = repo_root / ".git" / "hooks" / "post-commit"
    hook.parent.mkdir(parents=True, exist_ok=True)
    content = f"""#!/usr/bin/env bash
set -euo pipefail
if command -v repo-sync >/dev/null 2>&1; then
  code_sha=$(git rev-parse HEAD)
  repo-sync state commit --repo-key {key} --code-sha "$code_sha" || true
fi
"""
    hook.write_text(content, encoding="utf-8")
    hook.chmod(0o755)


def apply_repo_entry(entry, local_cfg):
    key = entry.get("key")
    if not isinstance(key, str) or not key:
        return
    repo_root = get_local_path(local_cfg, key)
    if repo_root is None:
        return
    if not (repo_root / ".git").exists():
        return

    state_dir_from_key(key).mkdir(parents=True, exist_ok=True)

    mappings = entry.get("mappings", [])
    if not isinstance(mappings, list):
        mappings = []

    explicit_targets = set()
    for mapping in mappings:
        if not isinstance(mapping, dict):
            continue
        normalized = normalize_mapping(key, mapping)
        target = normalized["to"][len("repo:") :].lstrip("/")
        explicit_targets.add(target)
        apply_mapping(key, repo_root, normalized)

    apply_default_root_mappings(key, entry, repo_root, explicit_targets)
    install_hook(repo_root, key)


def state_commit_message(key=None, code_sha=None, reason="sync"):
    if key and code_sha:
        return f"state({key}): update after {code_sha}"
    if key:
        return f"state({key}): update"
    return f"state: {reason}"


def commit_state(key=None, code_sha=None, push=False, reason="sync"):
    if not STATE_DIR.exists():
        return

    if key:
        target = state_dir_from_key(key)
        target.mkdir(parents=True, exist_ok=True)
        run(["git", "add", "."], cwd=target)
        run(
            ["git", "add", str(STATE_CONFIG_PATH.relative_to(STATE_DIR))],
            cwd=STATE_DIR,
            check=False,
        )
    else:
        run(["git", "add", "."], cwd=STATE_DIR)

    status = run(
        ["git", "diff", "--cached", "--name-only"],
        cwd=STATE_DIR,
        check=False,
        capture_output=True,
    )
    if not (status.stdout or "").strip():
        return

    run(
        [
            "git",
            "commit",
            "-m",
            state_commit_message(key=key, code_sha=code_sha, reason=reason),
        ],
        cwd=STATE_DIR,
        check=False,
    )
    if push:
        git_cmd(["-C", str(STATE_DIR), "push"])


def cmd_bootstrap(args):
    ensure_state_repo()
    ensure_dirs()
    save_shared_config(load_shared_config())
    save_local_paths(load_local_paths())
    if args.push:
        commit_state(reason="bootstrap", push=True)


def remote_has_heads():
    return bool(
        read_cmd_output(
            ["git", "-C", str(STATE_DIR), "ls-remote", "--heads", "origin"]
        ).strip()
    )


def get_default_branch_name():
    origin_head = read_cmd_output(
        [
            "git",
            "-C",
            str(STATE_DIR),
            "symbolic-ref",
            "-q",
            "--short",
            "refs/remotes/origin/HEAD",
        ]
    )
    if origin_head.startswith("origin/"):
        return origin_head.split("/", 1)[1]
    heads = read_cmd_output(
        ["git", "-C", str(STATE_DIR), "ls-remote", "--heads", "origin"]
    )
    branches = [
        line.split("refs/heads/")[-1]
        for line in heads.splitlines()
        if "refs/heads/" in line
    ]
    if "main" in branches:
        return "main"
    if "master" in branches:
        return "master"
    return branches[0] if branches else "main"


def bootstrap_empty_state_repo():
    (STATE_DIR / "config").mkdir(parents=True, exist_ok=True)
    save_shared_config({"repos": []})
    readme = STATE_DIR / "README.md"
    if not readme.exists():
        readme.write_text(
            "# project-state\n\nPrivate state repo for repo-sync.\n", encoding="utf-8"
        )
    git_cmd(["-C", str(STATE_DIR), "add", "-A"])
    run(
        ["git", "-C", str(STATE_DIR), "commit", "-m", "bootstrap project-state"],
        check=False,
    )
    git_cmd(["-C", str(STATE_DIR), "branch", "-M", "main"])
    git_cmd(["-C", str(STATE_DIR), "push", "-u", "origin", "main"])


def ensure_state_branch_and_pull():
    branch = get_default_branch_name()
    git_cmd(["-C", str(STATE_DIR), "checkout", "-B", branch, f"origin/{branch}"])
    run(
        [
            "git",
            "-C",
            str(STATE_DIR),
            "branch",
            "--set-upstream-to",
            f"origin/{branch}",
            branch,
        ],
        check=False,
    )
    git_cmd(["-C", str(STATE_DIR), "pull", "--rebase"])


def cmd_init(args):
    ensure_state_repo()
    ensure_dirs()
    git_cmd(["-C", str(STATE_DIR), "fetch", "--prune", "origin"])
    if not remote_has_heads():
        bootstrap_empty_state_repo()
    else:
        ensure_state_branch_and_pull()
    save_shared_config(load_shared_config())
    save_local_paths(load_local_paths())
    if args.push:
        commit_state(reason="init", push=True)


def ensure_local_git_repo(path: Path, existing: bool):
    if existing:
        if not (path / ".git").exists():
            raise RuntimeError(f"--existing set but no git repository at {path}")
        return
    if path.exists():
        if (path / ".git").exists():
            git_cmd(["-C", str(path), "fetch", "--prune"])
            return
        raise RuntimeError(f"Path exists and is not a git repository: {path}")


def cmd_add(args):
    ensure_state_repo()
    ensure_dirs()

    shared = load_shared_config()
    local = load_local_paths()

    remote = args.repo
    path = repo_root_from_path(args.path) if args.path else None

    if remote:
        parse_remote(remote)
    if path is None and remote:
        owner, repo = parse_remote(remote)
        path = WORKSPACES_DIR / owner / repo
    if path is None:
        raise RuntimeError("Path is required when repo remote is not provided")
    if remote is None and not path.exists():
        raise RuntimeError(
            "Path does not exist and no remote was provided; use --existing with a local repo, or pass owner/repo"
        )

    if remote is None and (path / ".git").exists():
        remote = infer_remote_from_path(path)

    if remote:
        key = key_from_remote(remote)
    elif args.key:
        key = args.key
    else:
        raise RuntimeError("Unable to infer remote. Provide owner/repo or --key")

    ensure_local_git_repo(path, args.existing)
    if not args.existing and remote and not path.exists():
        git_cmd(["clone", f"https://github.com/{remote}.git", str(path)])

    entry = ensure_shared_entry(shared, key, remote=remote)
    if args.ignore_path:
        ignore = entry.get("ignorePaths", [])
        if not isinstance(ignore, list):
            ignore = []
        for p in args.ignore_path:
            if p and p not in ignore:
                ignore.append(p)
        entry["ignorePaths"] = ignore

    save_shared_config(shared)
    set_local_path(local, key, path)
    save_local_paths(local)

    apply_repo_entry(entry, local)
    commit_state(key=key, reason="add", push=args.push)


def cmd_track(args):
    args.existing = True
    return cmd_add(args)


def cmd_sync(args):
    ensure_state_repo()
    ensure_dirs()
    git_cmd(["-C", str(STATE_DIR), "pull", "--rebase"])

    shared = load_shared_config()
    local = load_local_paths()
    for entry in shared.get("repos", []):
        if not isinstance(entry, dict):
            continue
        key = entry.get("key")
        if isinstance(key, str):
            apply_repo_entry(entry, local)
            commit_state(key=key, reason="sync")
    if args.push:
        git_cmd(["-C", str(STATE_DIR), "push"])


def cmd_scan(args):
    ensure_state_repo()
    ensure_dirs()

    shared = load_shared_config()
    local = load_local_paths()

    for owner_dir in WORKSPACES_DIR.iterdir() if WORKSPACES_DIR.exists() else []:
        if not owner_dir.is_dir():
            continue
        for repo_dir in owner_dir.iterdir():
            if not (repo_dir / ".git").exists():
                continue
            remote = infer_remote_from_path(repo_dir)
            if not remote:
                continue
            key = key_from_remote(remote)
            ensure_shared_entry(shared, key, remote=remote)
            set_local_path(local, key, repo_dir)

    save_shared_config(shared)
    save_local_paths(local)
    commit_state(reason="scan", push=args.push)


def resolve_entry_from_args_or_cwd(shared, local, repo=None, repo_key=None):
    if repo_key:
        entry = find_shared_entry(shared, repo_key)
        if not entry:
            raise RuntimeError(f"Unknown repo key: {repo_key}")
        return entry

    if repo:
        key = (
            key_from_remote(repo)
            if "/" in repo and not repo.startswith("github:")
            else repo
        )
        entry = find_shared_entry(shared, key)
        if entry:
            return entry
        if key.startswith("github:"):
            remote = key.split(":", 1)[1]
            entry = ensure_shared_entry(shared, key, remote=remote)
            return entry
        raise RuntimeError(f"Unknown repository: {repo}")

    root = get_repo_root_from_cwd()
    if not root:
        raise RuntimeError("Not inside a git repository. Use --repo or --repo-key")

    for item in local.get("paths", []):
        if not isinstance(item, dict):
            continue
        key = item.get("key")
        p = item.get("path")
        if (
            isinstance(key, str)
            and isinstance(p, str)
            and Path(p).expanduser().resolve() == root
        ):
            entry = find_shared_entry(shared, key)
            if entry:
                return entry
    raise RuntimeError(
        "Current repository is not tracked. Use repo-sync add/track first"
    )


def cmd_state_pull(_args):
    ensure_state_repo()
    git_cmd(["-C", str(STATE_DIR), "pull", "--rebase"])


def cmd_state_commit(args):
    ensure_state_repo()
    ensure_dirs()
    shared = load_shared_config()
    local = load_local_paths()
    entry = resolve_entry_from_args_or_cwd(
        shared, local, repo=args.repo, repo_key=args.repo_key
    )
    key = entry.get("key") if isinstance(entry, dict) else None
    commit_state(key=key, code_sha=args.code_sha, push=args.push, reason="manual")


def cmd_state_push(_args):
    ensure_state_repo()
    git_cmd(["-C", str(STATE_DIR), "push"])


def cmd_state_add(args):
    ensure_state_repo()
    ensure_dirs()
    shared = load_shared_config()
    local = load_local_paths()
    entry = resolve_entry_from_args_or_cwd(
        shared, local, repo=args.repo, repo_key=args.repo_key
    )
    key = entry["key"]
    repo_root = get_local_path(local, key)
    if repo_root is None:
        raise RuntimeError(f"No local path mapping found for {key}")

    rel_path = resolve_repo_relative_path(repo_root, args.path)
    mappings = entry.get("mappings", [])
    if not isinstance(mappings, list):
        mappings = []

    desired = {
        "from": f"state:{rel_path}",
        "to": f"repo:{rel_path}",
        "untracked": True,
        "mode": "symlink",
    }
    exists = any(
        isinstance(m, dict)
        and m.get("from") == desired["from"]
        and m.get("to") == desired["to"]
        for m in mappings
    )
    if not exists:
        mappings.append(desired)
    entry["mappings"] = mappings
    save_shared_config(shared)

    state_target = state_dir_from_key(key) / rel_path
    repo_target = repo_root / rel_path
    state_target.parent.mkdir(parents=True, exist_ok=True)
    if (
        repo_target.exists()
        and not repo_target.is_symlink()
        and not state_target.exists()
    ):
        repo_target.rename(state_target)
    apply_mapping(key, repo_root, desired)
    commit_state(key=key, reason="state-add", push=args.push)


def resolve_repo_relative_path(repo_root: Path, raw_path: str):
    p = Path(raw_path).expanduser()
    if not p.is_absolute():
        p = (Path.cwd() / p).resolve()
    try:
        rel = p.relative_to(repo_root)
    except Exception:
        raise RuntimeError(f"Path must be inside repo {repo_root}: {raw_path}")
    rel_str = str(rel)
    if rel_str in ("", "."):
        raise RuntimeError("Path must not be repository root")
    return rel_str


def iter_repo_candidates(prefix=""):
    candidates = set()
    try:
        shared = load_shared_config()
        for entry in shared.get("repos", []):
            if not isinstance(entry, dict):
                continue
            key = entry.get("key")
            remote = entry.get("remote")
            if isinstance(remote, str) and remote:
                candidates.add(remote)
            if isinstance(key, str) and key:
                candidates.add(key)
    except Exception:
        pass
    return sorted(c for c in candidates if c.startswith(prefix))


def cmd_complete_repo(args):
    for item in iter_repo_candidates(prefix=args.prefix or ""):
        print(item)


def build_parser():
    parser = argparse.ArgumentParser(
        prog="repo-sync",
        description=DESCRIPTION,
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_bootstrap = sub.add_parser(
        "bootstrap", help="Initialize state repo and config files"
    )
    p_bootstrap.add_argument("--push", action="store_true", help="Push state commit")
    p_bootstrap.set_defaults(func=cmd_bootstrap)

    p_init = sub.add_parser(
        "init", help="Clone/init project-state and bootstrap if remote is empty"
    )
    p_init.add_argument("--push", action="store_true", help="Push state commit")
    p_init.set_defaults(func=cmd_init)

    p_add = sub.add_parser(
        "add", help="Add a repository (clone new or register existing)"
    )
    p_add.add_argument("repo", nargs="?", help="Repository in owner/repo format")
    p_add.add_argument("--path", help="Local repository path")
    p_add.add_argument(
        "--existing",
        action="store_true",
        help="Path already exists as git repo; do not clone",
    )
    p_add.add_argument("--key", help="Custom key for non-GitHub repositories")
    p_add.add_argument("--push", action="store_true", help="Push state commit")
    p_add.add_argument(
        "--ignore-path",
        action="append",
        default=[],
        help="Ignore state top-level path from default root mapping (repeatable)",
    )
    p_add.set_defaults(func=cmd_add)

    p_track = sub.add_parser("track", help="Alias for add --path <path> --existing")
    p_track.add_argument("path", help="Existing local repository path")
    p_track.add_argument("repo", nargs="?", help="Repository in owner/repo format")
    p_track.add_argument("--key", help="Custom key for non-GitHub repositories")
    p_track.add_argument("--push", action="store_true", help="Push state commit")
    p_track.add_argument(
        "--ignore-path",
        action="append",
        default=[],
        help="Ignore state top-level path from default root mapping (repeatable)",
    )
    p_track.set_defaults(func=cmd_track)

    p_sync = sub.add_parser("sync", help="Sync all tracked repositories")
    p_sync.add_argument("--push", action="store_true", help="Push state commits")
    p_sync.set_defaults(func=cmd_sync)

    p_scan = sub.add_parser(
        "scan", help="Scan default workspace and register GitHub repos"
    )
    p_scan.add_argument("--push", action="store_true", help="Push state commit")
    p_scan.set_defaults(func=cmd_scan)

    p_state = sub.add_parser("state", help="State repository operations")
    state_sub = p_state.add_subparsers(dest="state_cmd", required=True)

    p_state_pull = state_sub.add_parser("pull", help="Pull latest state repo")
    p_state_pull.set_defaults(func=cmd_state_pull)

    p_state_add = state_sub.add_parser(
        "add", help="Move a repo path into state and map it as symlink"
    )
    p_state_add.add_argument(
        "path", help="File or directory path inside target repository"
    )
    p_state_add.add_argument("--repo", help="Repository remote (owner/repo) or key")
    p_state_add.add_argument("--repo-key", help="Repository key")
    p_state_add.add_argument("--push", action="store_true", help="Push after commit")
    p_state_add.set_defaults(func=cmd_state_add)

    p_state_commit = state_sub.add_parser("commit", help="Commit state changes locally")
    p_state_commit.add_argument("--repo", help="Repository remote (owner/repo) or key")
    p_state_commit.add_argument("--repo-key", help="Repository key")
    p_state_commit.add_argument("--code-sha", help="Code commit SHA for message")
    p_state_commit.add_argument("--push", action="store_true", help="Push after commit")
    p_state_commit.set_defaults(func=cmd_state_commit)

    p_state_push = state_sub.add_parser("push", help="Push state repo")
    p_state_push.set_defaults(func=cmd_state_push)

    return parser


def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "__complete-repo":
        prefix = sys.argv[2] if len(sys.argv) >= 3 else ""
        cmd_complete_repo(argparse.Namespace(prefix=prefix))
        return 0

    if (
        "-h" not in sys.argv
        and "--help" not in sys.argv
        and "__complete-repo" not in sys.argv
    ):
        validate_required_config()

    parser = build_parser()
    args = parser.parse_args()
    try:
        args.func(args)
    except Exception as exc:
        print(f"repo-sync: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
