"""Generate per-team hockey assets from a color-template PNG.

This script fetches teams from ESPN NHL API,
then replaces template colors in a base image:
  - 1F2346 -> team secondary color
  - FFFFFF -> team tertiary/third color (if available)

Outputs are written to ./nhl as <teamname>.png.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, Iterable, Optional, Tuple
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from PIL import Image


NHL_TEAMS_URL = (
    "https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/teams?limit=500"
)

# Template colors to replace.
SOURCE_SECONDARY_HEX = "1F2346"
SOURCE_TERTIARY_HEX = "FFFFFF"

# Hardcoded tertiary colors for NHL teams (based on official branding).
# Map team ID -> tertiary color hex.
NHL_TERTIARY_COLORS: Dict[str, str] = {
    "25": "C1272D",  # Arizona Coyotes - burgundy
    "1": "041E42",   # Atlanta Thrashers (historical) / New Jersey Devils
    "2": "FCB827",   # Boston Bruins - gold
    "3": "CE1126",   # Buffalo Sabres - red
    "4": "D32F27",   # Calgary Flames - red
    "5": "EC1C24",   # Carolina Hurricanes - red
    "6": "009CDE",   # Chicago Blackhawks - blue
    "7": "002B5C",   # Colorado Avalanche - navy
    "8": "00205B",   # Columbus Blue Jackets - navy
    "9": "C41E3A",   # Dallas Stars - red
    "10": "C41E3A",  # Detroit Red Wings - red
    "11": "0038A8",  # Edmonton Oilers - blue
    "12": "B0B7BC",  # Florida Panthers - gray
    "13": "CE1126",  # Los Angeles Kings - red
    "14": "A6192E",  # Minnesota Wild - red/burgundy
    "15": "00205B",  # Montreal Canadiens - navy
    "16": "041E42",  # Nashville Predators - navy
    "17": "041E42",  # New York Islanders - navy
    "18": "041E42",  # New York Rangers - navy
    "19": "D28E00",  # Ottawa Senators - gold/bronze
    "20": "FCAF17",  # Philadelphia Flyers - orange/gold
    "21": "0A3161",  # Pittsburgh Penguins - navy
    "22": "041E42",  # San Jose Sharks - navy
    "23": "00205B",  # Seattle Kraken - blue
    "24": "A2AAAD",  # St. Louis Blues - gray
    "25": "C1272D",  # Tampa Bay Lightning - red
    "26": "00205B",  # Toronto Maple Leafs - navy
    "27": "CE1126",  # Vancouver Canucks - red
    "28": "041E42",  # Vegas Golden Knights - navy
    "29": "041E42",  # Washington Capitals - navy
    "30": "041E42",  # Winnipeg Jets - navy
    "31": "C41E3A",  # Anaheim Ducks - red
    "32": "009CDE",  # Los Angeles Kings alternative
}


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


def extract_teams(all_teams_payload: dict) -> Iterable[Dict[str, str | None]]:
    """Yield unique teams with secondary colors and (if available) tertiary colors."""
    teams_by_id: Dict[str, Dict[str, str | None]] = {}

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

                # For NHL, alternateColor is the secondary color.
                secondary = (team.get("alternateColor") or SOURCE_SECONDARY_HEX).upper()

                # Look up tertiary color from hardcoded map or None.
                tertiary: Optional[str] = NHL_TERTIARY_COLORS.get(team_id)

                teams_by_id[team_id] = {
                    "id": team_id,
                    "name": team_name,
                    "secondary": secondary,
                    "tertiary": tertiary,
                }

    return teams_by_id.values()


def recolor_template(
    template_image: Image.Image,
    source_secondary: Tuple[int, int, int],
    source_tertiary: Tuple[int, int, int],
    target_secondary: Tuple[int, int, int],
    target_tertiary: Optional[Tuple[int, int, int]],
) -> Image.Image:
    """Return a recolored copy of template_image."""
    img = template_image.convert("RGBA")
    pixels = list(img.getdata())
    recolored = []

    for r, g, b, a in pixels:
        rgb = (r, g, b)
        if rgb == source_secondary:
            recolored.append((*target_secondary, a))
        elif target_tertiary and rgb == source_tertiary:
            recolored.append((*target_tertiary, a))
        else:
            recolored.append((r, g, b, a))

    img.putdata(recolored)
    return img


def generate_images(base_image_path: Path, output_dir: Path) -> int:
    """Generate one PNG per NHL team and return file count."""
    source_secondary = parse_hex_color(SOURCE_SECONDARY_HEX)
    source_tertiary = parse_hex_color(SOURCE_TERTIARY_HEX)

    payload = fetch_json(NHL_TEAMS_URL)
    teams = list(extract_teams(payload))

    output_dir.mkdir(parents=True, exist_ok=True)

    generated_count = 0
    used_filenames = set()

    with Image.open(base_image_path) as base_img:
        for team in teams:
            try:
                target_secondary = parse_hex_color(team["secondary"])
            except ValueError:
                # Skip malformed team color records from upstream data.
                continue

            target_tertiary: Optional[Tuple[int, int, int]] = None
            if team["tertiary"]:
                try:
                    target_tertiary = parse_hex_color(team["tertiary"])
                except ValueError:
                    pass

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
                source_secondary,
                source_tertiary,
                target_secondary,
                target_tertiary,
            )
            out_img.save(out_path, format="PNG")
            generated_count += 1

    return generated_count


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Generate team-themed images from hockey_base.png using ESPN NHL "
            "team colors."
        )
    )
    parser.add_argument(
        "--base-image",
        default="hockey_base.png",
        help="Path to template image (default: hockey_base.png)",
    )
    parser.add_argument(
        "--output-dir",
        default="nhl",
        help="Output directory for generated images (default: nhl)",
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
        print(f"Failed to fetch ESPN NHL data: {exc}", file=sys.stderr)
        return 1
    except json.JSONDecodeError as exc:
        print(f"Failed to parse ESPN NHL data: {exc}", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"File/image processing error: {exc}", file=sys.stderr)
        return 1

    print(f"Generated {count} image(s) in: {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
