#!/usr/bin/env python3
"""
Script to generate a README with all available status badges.
This can be run manually or as part of the badge generation workflow.
"""

import json
import urllib.parse
import os
import sys
from pathlib import Path

def generate_badge_readme(badges_dir="badges", output_file="BADGE_STATUS.md"):
    """Generate a README file with all available badges."""
    
    badges_path = Path(badges_dir)
    if not badges_path.exists():
        print(f"Badges directory '{badges_dir}' not found")
        return False
    
    # Collect all badge files
    badge_files = list(badges_path.glob("*.json"))
    badge_files = [f for f in badge_files if f.name != "all_badges.json"]
    
    if not badge_files:
        print("No badge files found")
        return False
    
    badges = []
    for badge_file in badge_files:
        try:
            with open(badge_file, 'r') as f:
                badge_data = json.load(f)
                badges.append(badge_data)
        except Exception as e:
            print(f"Error reading {badge_file}: {e}")
            continue
    
    if not badges:
        print("No valid badge data found")
        return False
    
    # Sort badges by status and name
    badges.sort(key=lambda x: (x['status'] != 'passing', x['dataset']))
    
    # Generate README content
    content = []
    content.append("# Dataset Processing Status Badges")
    content.append("")
    content.append(f"Last updated: {os.popen('date').read().strip()}")
    content.append("")
    content.append("## Overview")
    content.append("")
    content.append("This page shows the current status of CLI processing for each dataset in the OpenNeuroDatasets-JSONLD organization.")
    content.append("Each badge represents the result of processing an individual dataset using a matrix job strategy.")
    content.append("")
    
    # Status summary
    status_counts = {}
    for badge in badges:
        status = badge['status']
        status_counts[status] = status_counts.get(status, 0) + 1
    
    content.append("### Status Summary")
    content.append("")
    for status, count in status_counts.items():
        color_map = {
            'passing': 'brightgreen',
            'failing': 'red',
            'running': 'blue',
            'cancelled': 'yellow',
            'unknown': 'lightgrey'
        }
        color = color_map.get(status, 'lightgrey')
        status_badge = f"https://img.shields.io/badge/count-{count}-{color}"
        content.append(f"- ![{status}]({status_badge}) **{status.title()}**: {count} datasets")
    
    content.append("")
    content.append("## Individual Dataset Badges")
    content.append("")
    
    # Group by status for better organization
    status_groups = {}
    for badge in badges:
        status = badge['status']
        if status not in status_groups:
            status_groups[status] = []
        status_groups[status].append(badge)
    
    # Show status groups in order of priority
    status_order = ['passing', 'failing', 'running', 'cancelled', 'unknown']
    
    for status in status_order:
        if status not in status_groups:
            continue
            
        group_badges = status_groups[status]
        if not group_badges:
            continue
            
        content.append(f"### {status.title()} ({len(group_badges)})")
        content.append("")
        
        for i, badge in enumerate(group_badges):
            dataset = badge['dataset']
            badge_status = badge['status']
            color = badge['color']
            badge_url = f"https://img.shields.io/badge/{urllib.parse.quote(dataset)}-{urllib.parse.quote(badge_status)}-{color}"
            content.append(f"[![{dataset}]({badge_url})]({badge_url}) ")
            
            # Add line break every 5 badges
            if (i + 1) % 5 == 0:
                content.append("")
        
        content.append("")
        content.append("")
    
    content.append("## Usage Examples")
    content.append("")
    content.append("### Markdown")
    content.append("```markdown")
    for badge in badges[:3]:  # Show first 3 as examples
        dataset = badge['dataset']
        status = badge['status']
        color = badge['color']
        badge_url = f"https://img.shields.io/badge/{urllib.parse.quote(dataset)}-{urllib.parse.quote(status)}-{color}"
        content.append(f"![{dataset}]({badge_url})")
    content.append("```")
    content.append("")
    
    content.append("### HTML")
    content.append("```html")
    for badge in badges[:3]:
        dataset = badge['dataset']
        status = badge['status']
        color = badge['color']
        badge_url = f"https://img.shields.io/badge/{urllib.parse.quote(dataset)}-{urllib.parse.quote(status)}-{color}"
        content.append(f'<img src="{badge_url}" alt="{dataset} status">')
    content.append("```")
    content.append("")
    
    content.append("## Workflow Links")
    content.append("")
    content.append("- [CLI Processing Workflow](../../actions/workflows/run_cli_on_repo_list.yml)")
    content.append("- [Badge Generation Workflow](../../actions/workflows/generate_status_badges.yml)")
    content.append("")
    content.append("---")
    content.append("*This file is automatically generated. Do not edit manually.*")
    
    # Write to file
    try:
        with open(output_file, 'w') as f:
            f.write('\n'.join(content))
        print(f"Generated badge README: {output_file}")
        return True
    except Exception as e:
        print(f"Error writing to {output_file}: {e}")
        return False

def main():
    """Main function."""
    badges_dir = sys.argv[1] if len(sys.argv) > 1 else "badges"
    output_file = sys.argv[2] if len(sys.argv) > 2 else "BADGE_STATUS.md"
    
    success = generate_badge_readme(badges_dir, output_file)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()