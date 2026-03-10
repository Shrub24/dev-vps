#!/usr/bin/env python3

import argparse
import os
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

    _load_env_file(Path.home() / ".config" / "repo-sync.env")
    _load_env_file(Path.cwd() / ".env")


load_repo_sync_env()

OWNER = os.environ.get("REPO_SYNC_GH_USERNAME", "").strip()
STATE_REPO_URL = os.environ.get("REPO_SYNC_STATE_REPO_URL", "").strip()
WORKSPACES_DIR = _env_path("REPO_SYNC_WORKSPACES_DIR", "~/workspaces/github")
STATE_DIR = _env_path("REPO_SYNC_STATE_DIR", "~/project-state")
STATE_CONFIG_PATH = STATE_DIR / "config" / "repos.yaml"
STATE_REPOS_ROOT = STATE_DIR / "repos" / "github"
GH_TOKEN_PATH = _env_path("REPO_SYNC_GH_TOKEN_PATH", "/run/secrets/github.token")

DESCRIPTION = "Sync selected GitHub repos and per-repo private state"
EPILOG = """Examples:
  export REPO_SYNC_GH_USERNAME=<github-username>
  export REPO_SYNC_STATE_REPO_URL=https://github.com/<owner>/project-state.git
  repo-sync init
  repo-sync bootstrap
  repo-sync add <owner>/<repo>
  repo-sync add <owner>/<repo> --ignore-path '.direnv'
  repo-sync add <owner>/<repo> --push
  repo-sync sync
  repo-sync scan --push
  repo-sync state commit --repo <owner>/<repo> --push
"""


def run(cmd, cwd=None, check=True):
    return subprocess.run(cmd, cwd=cwd, check=check, text=True)


def validate_required_config():
    missing = []
    if not OWNER:
        missing.append("REPO_SYNC_GH_USERNAME")
    if not STATE_REPO_URL:
        missing.append("REPO_SYNC_STATE_REPO_URL")
    if missing:
        raise RuntimeError(f"Missing required configuration: {', '.join(missing)}")


def read_cmd_output(cmd, cwd=None):
    result = subprocess.run(cmd, cwd=cwd, check=False, text=True, capture_output=True)
    if result.returncode != 0:
        return ""
    return (result.stdout or "").strip()


def get_gh_token():
    if not GH_TOKEN_PATH.exists():
        raise RuntimeError(f"Missing GitHub token secret: {GH_TOKEN_PATH}")
    token = GH_TOKEN_PATH.read_text(encoding="utf-8").strip()
    if not token:
        raise RuntimeError("GitHub token secret is empty")
    return token


def git_cmd(args, cwd=None):
    cmd = ["git", *args]
    result = subprocess.run(
        cmd,
        cwd=cwd,
        check=False,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        stderr = (result.stderr or "").strip()
        detail = stderr.splitlines()[-1] if stderr else "unknown git error"
        raise RuntimeError(f"GitHub git operation failed: {detail}")
    return result


def ensure_git_identity():
    current_name = read_cmd_output(["git", "config", "--global", "user.name"])
    current_email = read_cmd_output(["git", "config", "--global", "user.email"])

    if not current_name:
        run(["git", "config", "--global", "user.name", OWNER])
    if not current_email:
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
        [
            "git",
            "config",
            "--global",
            "credential.https://github.com.username",
            OWNER,
        ],
        check=False,
    )


def ensure_gh_auth():
    token = get_gh_token()
    status = subprocess.run(
        ["gh", "auth", "status", "-h", "github.com"],
        check=False,
        text=True,
        capture_output=True,
    )
    if status.returncode != 0:
        subprocess.run(
            ["gh", "auth", "login", "--hostname", "github.com", "--with-token"],
            input=f"{token}\n",
            text=True,
            check=True,
        )
    run(["gh", "auth", "setup-git"], check=False)


def ensure_state_repo():
    ensure_git_identity()
    ensure_gh_auth()
    STATE_DIR.parent.mkdir(parents=True, exist_ok=True)
    if not STATE_DIR.exists():
        git_cmd(["clone", STATE_REPO_URL, str(STATE_DIR)])
    else:
        if (STATE_DIR / ".git").exists():
            git_cmd(["-C", str(STATE_DIR), "fetch", "--prune"])
        else:
            if any(STATE_DIR.iterdir()):
                raise RuntimeError(
                    f"{STATE_DIR} exists but is not a git repository; move it and re-run init"
                )
            STATE_DIR.rmdir()
            git_cmd(["clone", STATE_REPO_URL, str(STATE_DIR)])


def remote_has_heads():
    heads = read_cmd_output(
        ["git", "-C", str(STATE_DIR), "ls-remote", "--heads", "origin"]
    )
    return bool(heads.strip())


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
    head_lines = [line for line in heads.splitlines() if line.strip()]
    branches = [
        line.split("refs/heads/")[-1] for line in head_lines if "refs/heads/" in line
    ]
    if "main" in branches:
        return "main"
    if "master" in branches:
        return "master"
    return branches[0] if branches else "main"


def bootstrap_empty_state_repo():
    (STATE_DIR / "config").mkdir(parents=True, exist_ok=True)
    save_config({"repos": []})

    readme = STATE_DIR / "README.md"
    if not readme.exists():
        readme.write_text(
            "# project-state\n\n"
            "Private state repo for repo-sync and per-project local overlays.\n",
            encoding="utf-8",
        )

    git_cmd(["-C", str(STATE_DIR), "add", "-A"])
    commit = subprocess.run(
        ["git", "-C", str(STATE_DIR), "commit", "-m", "bootstrap project-state"],
        check=False,
        text=True,
        capture_output=True,
    )
    if commit.returncode != 0:
        msg = (commit.stderr or commit.stdout or "").strip()
        if "nothing to commit" not in msg.lower():
            raise RuntimeError(
                f"GitHub git operation failed: {msg.splitlines()[-1] if msg else 'commit failed'}"
            )

    git_cmd(["-C", str(STATE_DIR), "branch", "-M", "main"])
    git_cmd(["-C", str(STATE_DIR), "push", "-u", "origin", "main"])


def ensure_state_branch_and_pull():
    branch = get_default_branch_name()

    remote_branch_exists = (
        subprocess.run(
            [
                "git",
                "-C",
                str(STATE_DIR),
                "show-ref",
                "--verify",
                f"refs/remotes/origin/{branch}",
            ],
            check=False,
            text=True,
            capture_output=True,
        ).returncode
        == 0
    )

    current_branch = read_cmd_output(
        ["git", "-C", str(STATE_DIR), "rev-parse", "--abbrev-ref", "HEAD"]
    )
    if current_branch in ("", "HEAD") or current_branch != branch:
        if remote_branch_exists:
            git_cmd(
                ["-C", str(STATE_DIR), "checkout", "-B", branch, f"origin/{branch}"]
            )
        else:
            git_cmd(["-C", str(STATE_DIR), "checkout", "-B", branch])

    if remote_branch_exists:
        git_cmd(
            [
                "-C",
                str(STATE_DIR),
                "branch",
                "--set-upstream-to",
                f"origin/{branch}",
                branch,
            ]
        )
        git_cmd(["-C", str(STATE_DIR), "pull", "--rebase"])


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


def infer_repo_from_cwd():
    cwd = Path.cwd().resolve()
    root = WORKSPACES_DIR.resolve()
    try:
        rel = cwd.relative_to(root)
    except Exception:
        return None

    parts = rel.parts
    if len(parts) < 2:
        return None
    owner, repo = parts[0], parts[1]
    candidate = root / owner / repo
    if (candidate / ".git").exists():
        return f"{owner}/{repo}"
    return None


def resolve_repo_path(repo_name, raw_path):
    repo_root = repo_worktree(repo_name).resolve()
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


def ensure_repo_cloned(repo_name):
    owner, repo = parse_repo(repo_name)
    target = repo_worktree(repo_name)
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        git_cmd(["clone", f"https://github.com/{owner}/{repo}.git", str(target)])
    else:
        git_cmd(["-C", str(target), "fetch", "--prune"])


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


def normalize_mapping(repo_name, mapping):
    if not isinstance(mapping, dict):
        raise RuntimeError(f"Invalid mapping for {repo_name}: {mapping}")

    from_value = mapping.get("from", "")
    if not isinstance(from_value, str) or not from_value.startswith("state:"):
        raise RuntimeError(f"Invalid mapping.from for {repo_name}: {from_value}")

    state_rel = from_value[len("state:") :].lstrip("/")
    to_value = mapping.get("to")
    if to_value is None:
        to_value = f"repo:{state_rel}"

    if not isinstance(to_value, str) or not to_value.startswith("repo:"):
        raise RuntimeError(f"Invalid mapping.to for {repo_name}: {to_value}")

    mode = mapping.get("mode", "symlink")
    if mode != "symlink":
        raise RuntimeError(
            f"Unsupported mapping.mode for {repo_name}: {mode}. Only 'symlink' is supported"
        )

    return {
        "from": from_value,
        "to": to_value,
        "untracked": bool(mapping.get("untracked", True)),
        "mode": mode,
    }


def resolve_mapping_paths(repo_name, mapping):
    normalized = normalize_mapping(repo_name, mapping)
    from_value = normalized["from"]
    to_value = normalized["to"]

    state_rel = from_value[len("state:") :].lstrip("/")
    repo_rel = to_value[len("repo:") :].lstrip("/")

    state_path = repo_state_dir(repo_name) / state_rel
    repo_path = repo_worktree(repo_name) / repo_rel

    return state_rel, repo_rel, state_path, repo_path


def apply_mapping(repo_name, mapping):
    normalized = normalize_mapping(repo_name, mapping)
    _, repo_rel, state_path, repo_path = resolve_mapping_paths(repo_name, normalized)

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

    if normalized.get("untracked", True):
        ensure_exclude(repo_worktree(repo_name), repo_rel)


def apply_default_root_mappings(repo_name, repo_entry, explicit_repo_targets):
    state_root = repo_state_dir(repo_name)
    ignore_paths = repo_entry.get("ignorePaths", [])
    if not isinstance(ignore_paths, list):
        ignore_paths = []
    ignore = {p for p in ignore_paths if isinstance(p, str)}
    ignore.add(".git")

    if not state_root.exists():
        return

    for item in sorted(state_root.iterdir(), key=lambda p: p.name):
        name = item.name
        if name in ignore:
            continue
        if name in explicit_repo_targets:
            continue

        apply_mapping(
            repo_name,
            {
                "from": f"state:{name}",
                "to": f"repo:{name}",
                "untracked": True,
                "mode": "symlink",
            },
        )


def apply_repo(repo_entry):
    repo_name = repo_entry.get("name")
    if not isinstance(repo_name, str):
        return

    ensure_repo_cloned(repo_name)
    ensure_state_subdir(repo_name)

    mappings = repo_entry.get("mappings", [])
    if not isinstance(mappings, list):
        mappings = []

    explicit_repo_targets = set()

    for mapping in mappings:
        if isinstance(mapping, dict):
            normalized = normalize_mapping(repo_name, mapping)
            repo_rel = normalized["to"][len("repo:") :].lstrip("/")
            explicit_repo_targets.add(repo_rel)
            apply_mapping(repo_name, normalized)

    apply_default_root_mappings(repo_name, repo_entry, explicit_repo_targets)

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
        git_cmd(["-C", str(STATE_DIR), "push"])


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
        "mappings": [],
        "ignorePaths": [],
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


def cmd_init(args):
    ensure_state_repo()
    ensure_dirs()
    git_cmd(["-C", str(STATE_DIR), "fetch", "--prune", "origin"])

    if not remote_has_heads():
        bootstrap_empty_state_repo()
    else:
        ensure_state_branch_and_pull()

    save_config(load_config())
    if args.push:
        commit_state(reason="init", push=True)


def cmd_add(args):
    ensure_state_repo()
    ensure_dirs()
    config = load_config()
    entry = ensure_repo_entry(config, args.repo)
    if args.ignore_path:
        ignore = entry.get("ignorePaths", [])
        if not isinstance(ignore, list):
            ignore = []
        for path in args.ignore_path:
            if path and path not in ignore:
                ignore.append(path)
        entry["ignorePaths"] = ignore
    save_config(config)
    apply_repo(
        {
            "name": args.repo,
            "mappings": entry.get("mappings", []),
            "ignorePaths": entry.get("ignorePaths", []),
        }
    )
    commit_state(repo_name=args.repo, reason="add", push=args.push)


def cmd_sync(args):
    ensure_state_repo()
    ensure_dirs()
    git_cmd(["-C", str(STATE_DIR), "pull", "--rebase"])
    config = load_config()
    for entry in config.get("repos", []):
        if isinstance(entry, dict):
            apply_repo(entry)
            repo_name = entry.get("name")
            if isinstance(repo_name, str):
                commit_state(repo_name=repo_name, reason="sync")
    if args.push:
        git_cmd(["-C", str(STATE_DIR), "push"])


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
    git_cmd(["-C", str(STATE_DIR), "pull", "--rebase"])


def cmd_state_commit(args):
    ensure_state_repo()
    ensure_dirs()
    commit_state(
        repo_name=args.repo, code_sha=args.code_sha, push=args.push, reason="manual"
    )


def cmd_state_push(_args):
    ensure_state_repo()
    git_cmd(["-C", str(STATE_DIR), "push"])


def cmd_state_add(args):
    ensure_state_repo()
    ensure_dirs()

    repo_name = args.repo or infer_repo_from_cwd()
    if not repo_name:
        raise RuntimeError(
            "Unable to determine repo. Use --repo owner/repo or run inside ~/workspaces/github/<owner>/<repo>"
        )

    rel_path = resolve_repo_path(repo_name, args.path)

    config = load_config()
    entry = ensure_repo_entry(config, repo_name)
    mappings = entry.get("mappings", [])
    if not isinstance(mappings, list):
        mappings = []

    desired = {
        "from": f"state:{rel_path}",
        "to": f"repo:{rel_path}",
        "untracked": True,
        "mode": "symlink",
    }

    exists = False
    for m in mappings:
        if (
            isinstance(m, dict)
            and m.get("from") == desired["from"]
            and m.get("to") == desired["to"]
        ):
            if "untracked" not in m:
                m["untracked"] = True
            if "mode" not in m:
                m["mode"] = "symlink"
            exists = True
            break
    if not exists:
        mappings.append(desired)
    entry["mappings"] = mappings
    save_config(config)

    state_target = repo_state_dir(repo_name) / rel_path
    repo_target = repo_worktree(repo_name) / rel_path
    state_target.parent.mkdir(parents=True, exist_ok=True)

    if (
        repo_target.exists()
        and not repo_target.is_symlink()
        and not state_target.exists()
    ):
        repo_target.rename(state_target)

    apply_mapping(repo_name, desired)
    commit_state(repo_name=repo_name, reason="state-add", push=args.push)


def iter_repo_candidates(prefix=""):
    candidates = set()

    try:
        config = load_config()
        for entry in config.get("repos", []):
            if isinstance(entry, dict):
                name = entry.get("name")
                if isinstance(name, str) and "/" in name:
                    candidates.add(name)
    except Exception:
        pass

    if WORKSPACES_DIR.exists():
        for owner_dir in WORKSPACES_DIR.iterdir():
            if not owner_dir.is_dir():
                continue
            for repo_dir in owner_dir.iterdir():
                if (repo_dir / ".git").exists():
                    candidates.add(f"{owner_dir.name}/{repo_dir.name}")

    result = sorted(c for c in candidates if c.startswith(prefix))
    return result


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
        "init", help="Initialize or clone project-state repo and config files"
    )
    p_init.add_argument("--push", action="store_true", help="Push state commit")
    p_init.set_defaults(func=cmd_init)

    p_add = sub.add_parser("add", help="Add and manage a repository")
    p_add.add_argument("repo", help="Repository in owner/repo format")
    p_add.add_argument("--push", action="store_true", help="Push state commit")
    p_add.add_argument(
        "--ignore-path",
        action="append",
        default=[],
        help="Ignore a state path from default root mapping (repeatable)",
    )
    p_add.set_defaults(func=cmd_add)

    p_sync = sub.add_parser("sync", help="Sync all repositories from config")
    p_sync.add_argument("--push", action="store_true", help="Push state commits")
    p_sync.set_defaults(func=cmd_sync)

    p_scan = sub.add_parser("scan", help="Discover local repos into config")
    p_scan.add_argument("--push", action="store_true", help="Push state commit")
    p_scan.set_defaults(func=cmd_scan)

    p_state = sub.add_parser("state", help="State repository operations")
    state_sub = p_state.add_subparsers(dest="state_cmd", required=True)

    p_state_pull = state_sub.add_parser("pull", help="Pull latest state repo")
    p_state_pull.set_defaults(func=cmd_state_pull)

    p_state_commit = state_sub.add_parser("commit", help="Commit state changes locally")
    p_state_commit.add_argument("--repo", help="Repository in owner/repo format")
    p_state_commit.add_argument("--code-sha", help="Code commit SHA for message")
    p_state_commit.add_argument("--push", action="store_true", help="Push after commit")
    p_state_commit.set_defaults(func=cmd_state_commit)

    p_state_push = state_sub.add_parser("push", help="Push state repo")
    p_state_push.set_defaults(func=cmd_state_push)

    p_state_add = state_sub.add_parser(
        "add",
        help="Add a repo path to state mappings and move content into project-state",
    )
    p_state_add.add_argument(
        "path", help="File or directory path inside the target repository"
    )
    p_state_add.add_argument("--repo", help="Repository in owner/repo format")
    p_state_add.add_argument("--push", action="store_true", help="Push after commit")
    p_state_add.set_defaults(func=cmd_state_add)

    return parser


def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "__complete-repo":
        prefix = sys.argv[2] if len(sys.argv) >= 3 else ""
        cmd_complete_repo(argparse.Namespace(prefix=prefix))
        return 0

    if "-h" not in sys.argv and "--help" not in sys.argv:
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
