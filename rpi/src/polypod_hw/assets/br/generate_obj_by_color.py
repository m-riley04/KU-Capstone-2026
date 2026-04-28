"""Generate per-team basketball assets from a color-template PNG.

This script fetches teams from ESPN men's college basketball APIs,
preferring the all-teams endpoint and falling back to scoreboard data,
then replaces template colors in a base image:
  - 901C18 -> team primary color
  - FFFFFF -> team secondary color

Outputs are written to ./mcb as <teamname>.png.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, Iterable, Tuple
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from PIL import Image


SCOREBOARD_URL = (
	"https://site.api.espn.com/apis/site/v2/sports/basketball/"
	"mens-college-basketball/scoreboard"
)
ALL_TEAMS_URL = (
	"https://site.api.espn.com/apis/site/v2/sports/basketball/"
	"mens-college-basketball/teams?limit=500"
)

# Template colors to replace.
SOURCE_PRIMARY_HEX = "901C18"
SOURCE_SECONDARY_HEX = "FFFFFF"


def parse_hex_color(value: str) -> Tuple[int, int, int]:
	"""Convert a 6-char hex string into an RGB tuple."""
	cleaned = value.strip().lstrip("#")
	if not re.fullmatch(r"[0-9A-Fa-f]{6}", cleaned):
		raise ValueError(f"Invalid color hex '{value}'. Expected 6 hex chars.")
	return tuple(int(cleaned[i : i + 2], 16) for i in range(0, 6, 2))


def slugify_team_name(name: str) -> str:
	"""Create a filesystem-safe, predictable filename stem from a team name."""
	lowered = name.lower().strip()
	lowered = lowered.replace("&", " and ")
	slug = re.sub(r"[^a-z0-9]+", "_", lowered).strip("_")
	return slug or "unknown_team"


def fetch_json(url: str) -> dict:
	"""Fetch JSON payload from an ESPN endpoint."""
	req = Request(
		url,
		headers={
			"User-Agent": "KU-Capstone-Asset-Generator/1.0",
			"Accept": "application/json",
		},
	)
	with urlopen(req, timeout=20) as response:
		payload = response.read().decode("utf-8")
	return json.loads(payload)


def extract_teams_from_scoreboard(scoreboard_payload: dict) -> Iterable[Dict[str, str]]:
	"""Yield unique teams with primary/secondary colors from scoreboard data."""
	teams_by_id: Dict[str, Dict[str, str]] = {}

	for event in scoreboard_payload.get("events", []):
		for competition in event.get("competitions", []):
			for competitor in competition.get("competitors", []):
				team = competitor.get("team", {})
				team_id = str(team.get("id", "")).strip()
				if not team_id:
					continue

				team_name = team.get("displayName") or team.get("shortDisplayName")
				if not team_name:
					continue

				primary = (team.get("color") or SOURCE_PRIMARY_HEX).upper()
				secondary = (team.get("alternateColor") or SOURCE_SECONDARY_HEX).upper()

				# Keep the latest full team record if duplicates appear in events.
				teams_by_id[team_id] = {
					"id": team_id,
					"name": team_name,
					"primary": primary,
					"secondary": secondary,
				}

	return teams_by_id.values()


def extract_teams_from_all_teams(all_teams_payload: dict) -> Iterable[Dict[str, str]]:
	"""Yield unique teams with primary/secondary colors from all-teams data."""
	teams_by_id: Dict[str, Dict[str, str]] = {}

	for sport in all_teams_payload.get("sports", []):
		for league in sport.get("leagues", []):
			for team_wrapper in league.get("teams", []):
				team = team_wrapper.get("team", {})
				team_id = str(team.get("id", "")).strip()
				if not team_id:
					continue

				team_name = team.get("displayName") or team.get("shortDisplayName")
				if not team_name:
					continue

				primary = (team.get("color") or SOURCE_PRIMARY_HEX).upper()
				secondary = (team.get("alternateColor") or SOURCE_SECONDARY_HEX).upper()

				teams_by_id[team_id] = {
					"id": team_id,
					"name": team_name,
					"primary": primary,
					"secondary": secondary,
				}

	return teams_by_id.values()


def fetch_teams() -> Iterable[Dict[str, str]]:
	"""Fetch teams, preferring all-teams endpoint and falling back to scoreboard."""
	try:
		all_teams_payload = fetch_json(ALL_TEAMS_URL)
		teams = list(extract_teams_from_all_teams(all_teams_payload))
		if teams:
			return teams
	except (HTTPError, URLError, TimeoutError, json.JSONDecodeError):
		pass

	scoreboard_payload = fetch_json(SCOREBOARD_URL)
	return list(extract_teams_from_scoreboard(scoreboard_payload))


def recolor_template(
	template_image: Image.Image,
	source_primary: Tuple[int, int, int],
	source_secondary: Tuple[int, int, int],
	target_primary: Tuple[int, int, int],
	target_secondary: Tuple[int, int, int],
) -> Image.Image:
	"""Return a recolored copy of template_image."""
	img = template_image.convert("RGBA")
	pixels = list(img.getdata())
	recolored = []

	for r, g, b, a in pixels:
		rgb = (r, g, b)
		if rgb == source_primary:
			recolored.append((*target_primary, a))
		elif rgb == source_secondary:
			recolored.append((*target_secondary, a))
		else:
			recolored.append((r, g, b, a))

	img.putdata(recolored)
	return img


def generate_images(base_image_path: Path, output_dir: Path) -> int:
	"""Generate one PNG per ESPN team and return file count."""
	source_primary = parse_hex_color(SOURCE_PRIMARY_HEX)
	source_secondary = parse_hex_color(SOURCE_SECONDARY_HEX)

	teams = list(fetch_teams())

	output_dir.mkdir(parents=True, exist_ok=True)

	generated_count = 0
	used_filenames = set()

	with Image.open(base_image_path) as base_img:
		for team in teams:
			try:
				target_primary = parse_hex_color(team["primary"])
				target_secondary = parse_hex_color(team["secondary"])
			except ValueError:
				# Skip malformed team color records from upstream data.
				continue

			stem = slugify_team_name(team["name"])
			candidate = stem
			suffix = 2
			while candidate in used_filenames:
				candidate = f"{stem}_{suffix}"
				suffix += 1
			used_filenames.add(candidate)

			out_path = output_dir / f"{candidate}.png"
			out_img = recolor_template(
				base_img,
				source_primary,
				source_secondary,
				target_primary,
				target_secondary,
			)
			out_img.save(out_path, format="PNG")
			generated_count += 1

	return generated_count


def build_parser() -> argparse.ArgumentParser:
	parser = argparse.ArgumentParser(
		description=(
			"Generate team-themed images from bb_base.png using ESPN men\'s "
			"college basketball team colors."
		)
	)
	parser.add_argument(
		"--base-image",
		default="bb_base.png",
		help="Path to template image (default: bb_base.png)",
	)
	parser.add_argument(
		"--output-dir",
		default="mcb",
		help="Output directory for generated images (default: mcb)",
	)
	return parser


def main() -> int:
	parser = build_parser()
	args = parser.parse_args()

	script_dir = Path(__file__).resolve().parent
	base_image_path = (script_dir / args.base_image).resolve()
	output_dir = (script_dir / args.output_dir).resolve()

	if not base_image_path.exists():
		print(f"Base image not found: {base_image_path}", file=sys.stderr)
		return 1

	try:
		count = generate_images(base_image_path, output_dir)
	except (HTTPError, URLError, TimeoutError) as exc:
		print(f"Failed to fetch ESPN team data: {exc}", file=sys.stderr)
		return 1
	except json.JSONDecodeError as exc:
		print(f"Failed to parse ESPN team data: {exc}", file=sys.stderr)
		return 1
	except OSError as exc:
		print(f"File/image processing error: {exc}", file=sys.stderr)
		return 1

	print(f"Generated {count} image(s) in: {output_dir}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
