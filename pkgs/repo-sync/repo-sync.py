#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
from pathlib import Path

import yaml


OWNER = "Shrub24"
STATE_REPO_URL = "https://github.com/Shrub24/agent-state.git"
WORKSPACES_DIR = Path.home() / "workspaces" / "github"
STATE_DIR = Path.home() / "state"
STATE_CONFIG_PATH = STATE_DIR / "config" / "repos.yaml"
STATE_REPOS_ROOT = STATE_DIR / "repos" / "github"
GH_TOKEN_PATH = Path("/run/secrets/github.token")


def run(cmd, cwd=None, check=True):
    return subprocess.run(cmd, cwd=cwd, check=check, text=True)


def get_gh_token():
    if not GH_TOKEN_PATH.exists():
        raise RuntimeError(f"Missing GitHub token secret: {GH_TOKEN_PATH}")
    token = GH_TOKEN_PATH.read_text(encoding="utf-8").strip()
    if not token:
        raise RuntimeError("GitHub token secret is empty")
    return token


def git_with_token(args, cwd=None):
    token = get_gh_token()
    cmd = [
        "git",
        "-c",
        f"http.https://github.com/.extraheader=AUTHORIZATION: bearer {token}",
        *args,
    ]
    return run(cmd, cwd=cwd)


def ensure_state_repo():
    STATE_DIR.parent.mkdir(parents=True, exist_ok=True)
    if not STATE_DIR.exists():
        git_with_token(["clone", STATE_REPO_URL, str(STATE_DIR)])
    else:
        git_with_token(["-C", str(STATE_DIR), "fetch", "--prune"])


def ensure_dirs():
    WORKSPACES_DIR.mkdir(parents=True, exist_ok=True)
    STATE_REPOS_ROOT.mkdir(parents=True, exist_ok=True)
    (STATE_DIR / "config").mkdir(parents=True, exist_ok=True)


def load_config():
    if not STATE_CONFIG_PATH.exists():
        return {"repos": []}
    data = yaml.safe_load(STATE_CONFIG_PATH.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        return {"repos": []}
    repos = data.get("repos")
    if not isinstance(repos, list):
        data["repos"] = []
    return data


def save_config(config):
    STATE_CONFIG_PATH.write_text(
        yaml.safe_dump(config, sort_keys=False, default_flow_style=False),
        encoding="utf-8",
    )


def parse_repo(repo_name):
    if "/" not in repo_name:
        raise RuntimeError(f"Invalid repo format '{repo_name}', expected owner/repo")
    owner, repo = repo_name.split("/", 1)
    if not owner or not repo:
        raise RuntimeError(f"Invalid repo format '{repo_name}', expected owner/repo")
    return owner, repo


def repo_worktree(repo_name):
    owner, repo = parse_repo(repo_name)
    return WORKSPACES_DIR / owner / repo


def repo_state_dir(repo_name):
    owner, repo = parse_repo(repo_name)
    return STATE_REPOS_ROOT / owner / repo


def ensure_repo_cloned(repo_name):
    owner, repo = parse_repo(repo_name)
    target = repo_worktree(repo_name)
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        git_with_token(["clone", f"https://github.com/{owner}/{repo}.git", str(target)])
    else:
        git_with_token(["-C", str(target), "fetch", "--prune"])


def ensure_state_subdir(repo_name):
    d = repo_state_dir(repo_name)
    d.mkdir(parents=True, exist_ok=True)
    return d


def ensure_exclude(repo_path, rel_path):
    exclude_path = repo_path / ".git" / "info" / "exclude"
    exclude_path.parent.mkdir(parents=True, exist_ok=True)
    current = ""
    if exclude_path.exists():
        current = exclude_path.read_text(encoding="utf-8")
    line = rel_path
    if line not in current.splitlines():
        with exclude_path.open("a", encoding="utf-8") as f:
            f.write(f"{line}\n")


def resolve_mapping_paths(repo_name, mapping):
    from_value = mapping.get("from", "")
    to_value = mapping.get("to", "")
    if not isinstance(from_value, str) or not from_value.startswith("state:"):
        raise RuntimeError(f"Invalid mapping.from for {repo_name}: {from_value}")
    if not isinstance(to_value, str) or not to_value.startswith("repo:"):
        raise RuntimeError(f"Invalid mapping.to for {repo_name}: {to_value}")

    state_rel = from_value[len("state:") :].lstrip("/")
    repo_rel = to_value[len("repo:") :].lstrip("/")

    state_path = repo_state_dir(repo_name) / state_rel
    repo_path = repo_worktree(repo_name) / repo_rel

    return state_rel, repo_rel, state_path, repo_path


def apply_mapping(repo_name, mapping):
    _, repo_rel, state_path, repo_path = resolve_mapping_paths(repo_name, mapping)

    state_path.parent.mkdir(parents=True, exist_ok=True)
    if not state_path.exists():
        if repo_rel.endswith("/"):
            state_path.mkdir(parents=True, exist_ok=True)
        else:
            if "." in state_path.name:
                state_path.parent.mkdir(parents=True, exist_ok=True)
                state_path.touch(exist_ok=True)
            else:
                state_path.mkdir(parents=True, exist_ok=True)

    repo_path.parent.mkdir(parents=True, exist_ok=True)

    if repo_path.is_symlink():
        if repo_path.resolve() == state_path.resolve():
            pass
        else:
            repo_path.unlink()
            repo_path.symlink_to(state_path)
    elif repo_path.exists():
        return
    else:
        repo_path.symlink_to(state_path)

    if mapping.get("untracked", False):
        ensure_exclude(repo_worktree(repo_name), repo_rel)


def apply_repo(repo_entry):
    repo_name = repo_entry.get("name")
    if not isinstance(repo_name, str):
        return

    ensure_repo_cloned(repo_name)
    ensure_state_subdir(repo_name)

    mappings = repo_entry.get("mappings", [])
    if not isinstance(mappings, list):
        mappings = []

    for mapping in mappings:
        if isinstance(mapping, dict):
            apply_mapping(repo_name, mapping)

    install_hook(repo_name)


def state_commit_message(repo_name=None, code_sha=None, reason="sync"):
    if repo_name and code_sha:
        return f"state({repo_name}): update after {code_sha}"
    if repo_name:
        return f"state({repo_name}): update"
    return f"state: {reason}"


def commit_state(repo_name=None, code_sha=None, push=False, reason="sync"):
    if not STATE_DIR.exists():
        return

    if repo_name:
        target = repo_state_dir(repo_name)
        rel = target.relative_to(STATE_DIR)
        run(["git", "add", "."], cwd=target)
        run(
            ["git", "add", str(STATE_CONFIG_PATH.relative_to(STATE_DIR))],
            cwd=STATE_DIR,
            check=False,
        )
        status = subprocess.run(
            ["git", "diff", "--cached", "--name-only"],
            cwd=STATE_DIR,
            text=True,
            capture_output=True,
            check=False,
        )
        changed = [line.strip() for line in status.stdout.splitlines() if line.strip()]
        if not changed:
            return
    else:
        run(["git", "add", "."], cwd=STATE_DIR)
        status = subprocess.run(
            ["git", "diff", "--cached", "--name-only"],
            cwd=STATE_DIR,
            text=True,
            capture_output=True,
            check=False,
        )
        if not status.stdout.strip():
            return

    msg = state_commit_message(repo_name=repo_name, code_sha=code_sha, reason=reason)
    run(["git", "commit", "-m", msg], cwd=STATE_DIR, check=False)
    if push:
        git_with_token(["-C", str(STATE_DIR), "push"])


def install_hook(repo_name):
    repo = repo_worktree(repo_name)
    hook = repo / ".git" / "hooks" / "post-commit"
    hook.parent.mkdir(parents=True, exist_ok=True)
    content = f"""#!/usr/bin/env bash
set -euo pipefail
if command -v repo-sync >/dev/null 2>&1; then
  code_sha=$(git rev-parse HEAD)
  repo-sync state commit --repo {repo_name} --code-sha "$code_sha" || true
fi
"""
    hook.write_text(content, encoding="utf-8")
    hook.chmod(0o755)


def ensure_repo_entry(config, repo_name):
    repos = config.setdefault("repos", [])
    for entry in repos:
        if isinstance(entry, dict) and entry.get("name") == repo_name:
            return entry

    entry = {
        "name": repo_name,
        "mappings": [
            {
                "from": "state:.opencode",
                "to": "repo:.opencode",
                "untracked": True,
            }
        ],
    }
    repos.append(entry)
    return entry


def cmd_bootstrap(args):
    ensure_state_repo()
    ensure_dirs()
    config = load_config()
    save_config(config)
    if args.push:
        commit_state(reason="bootstrap", push=True)


def cmd_add(args):
    ensure_state_repo()
    ensure_dirs()
    config = load_config()
    ensure_repo_entry(config, args.repo)
    save_config(config)
    apply_repo(
        {
            "name": args.repo,
            "mappings": ensure_repo_entry(config, args.repo).get("mappings", []),
        }
    )
    commit_state(repo_name=args.repo, reason="add", push=args.push)


def cmd_sync(args):
    ensure_state_repo()
    ensure_dirs()
    git_with_token(["-C", str(STATE_DIR), "pull", "--rebase"], cwd=None)
    config = load_config()
    for entry in config.get("repos", []):
        if isinstance(entry, dict):
            apply_repo(entry)
            repo_name = entry.get("name")
            if isinstance(repo_name, str):
                commit_state(repo_name=repo_name, reason="sync")
    if args.push:
        git_with_token(["-C", str(STATE_DIR), "push"])


def cmd_scan(args):
    ensure_state_repo()
    ensure_dirs()
    config = load_config()
    repos = config.setdefault("repos", [])
    known = {
        entry.get("name")
        for entry in repos
        if isinstance(entry, dict) and isinstance(entry.get("name"), str)
    }

    for owner_dir in WORKSPACES_DIR.iterdir() if WORKSPACES_DIR.exists() else []:
        if not owner_dir.is_dir():
            continue
        for repo_dir in owner_dir.iterdir():
            if (repo_dir / ".git").exists():
                repo_name = f"{owner_dir.name}/{repo_dir.name}"
                if repo_name not in known:
                    ensure_repo_entry(config, repo_name)
                    known.add(repo_name)

    save_config(config)
    commit_state(reason="scan", push=args.push)


def cmd_state_pull(_args):
    ensure_state_repo()
    git_with_token(["-C", str(STATE_DIR), "pull", "--rebase"])


def cmd_state_commit(args):
    ensure_state_repo()
    ensure_dirs()
    commit_state(
        repo_name=args.repo, code_sha=args.code_sha, push=args.push, reason="manual"
    )


def cmd_state_push(_args):
    ensure_state_repo()
    git_with_token(["-C", str(STATE_DIR), "push"])


def build_parser():
    parser = argparse.ArgumentParser(prog="repo-sync")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_bootstrap = sub.add_parser("bootstrap")
    p_bootstrap.add_argument("--push", action="store_true")
    p_bootstrap.set_defaults(func=cmd_bootstrap)

    p_add = sub.add_parser("add")
    p_add.add_argument("repo")
    p_add.add_argument("--push", action="store_true")
    p_add.set_defaults(func=cmd_add)

    p_sync = sub.add_parser("sync")
    p_sync.add_argument("--push", action="store_true")
    p_sync.set_defaults(func=cmd_sync)

    p_scan = sub.add_parser("scan")
    p_scan.add_argument("--push", action="store_true")
    p_scan.set_defaults(func=cmd_scan)

    p_state = sub.add_parser("state")
    state_sub = p_state.add_subparsers(dest="state_cmd", required=True)

    p_state_pull = state_sub.add_parser("pull")
    p_state_pull.set_defaults(func=cmd_state_pull)

    p_state_commit = state_sub.add_parser("commit")
    p_state_commit.add_argument("--repo")
    p_state_commit.add_argument("--code-sha")
    p_state_commit.add_argument("--push", action="store_true")
    p_state_commit.set_defaults(func=cmd_state_commit)

    p_state_push = state_sub.add_parser("push")
    p_state_push.set_defaults(func=cmd_state_push)

    return parser


def main():
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
