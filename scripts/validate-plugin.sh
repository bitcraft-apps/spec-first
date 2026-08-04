#!/bin/bash

# Spec First Plugin Validation Script
# Validates all components for Claude Code compliance and functionality
# Must be run from the repository root

set -e  # Exit on any error

echo "🔍 Validating Spec First Plugin..."
echo "=========================================="

# Read version from VERSION file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../VERSION" ]; then
    PLUGIN_VERSION=$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' < "$SCRIPT_DIR/../VERSION" 2>/dev/null || echo "unknown")
elif [ -f "./VERSION" ]; then
    PLUGIN_VERSION=$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' < "./VERSION" 2>/dev/null || echo "unknown")
else
    PLUGIN_VERSION="unknown"
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ "$PLUGIN_VERSION" != "unknown" ] && [ -n "$PLUGIN_VERSION" ]; then
    echo -e "${BLUE}Plugin Version: $PLUGIN_VERSION${NC}"
else
    echo -e "${YELLOW}Plugin Version: unknown (VERSION file not found)${NC}"
fi
echo ""

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to print status
print_status() {
    if [ "$2" -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ $1${NC}"
        FAILED=$((FAILED + 1))
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Verify we're at repo root
if [ ! -f "./VERSION" ] || [ ! -d "./agents" ] || [ ! -d "./skills" ]; then
    echo -e "${RED}❌ Must be run from the repository root (needs ./VERSION, ./agents/, ./skills/)${NC}" >&2
    exit 1
fi

echo ""
echo "📁 Checking Directory Structure..."
echo "=================================="

print_status "Plugin structure detected" 0

# Check VERSION file
VERSION_PATH="./VERSION"
if [ -f "$VERSION_PATH" ]; then
    print_status "VERSION file exists" 0
    VERSION_CONTENT=$(tr -d '\n\r' < "$VERSION_PATH" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if echo "$VERSION_CONTENT" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' >/dev/null; then
        print_status "VERSION file has valid format" 0
        print_info "Plugin version: $VERSION_CONTENT"
    else
        print_status "VERSION file has valid format" 1
        print_info "VERSION content: '$VERSION_CONTENT'"
    fi
else
    print_status "VERSION file exists" 1
fi

# Check plugin.json version matches VERSION file
if [ -n "$VERSION_CONTENT" ] && [ -f "./.claude-plugin/plugin.json" ] && command -v jq &>/dev/null; then
    MANIFEST_VERSION=$(jq -r '.version // empty' "./.claude-plugin/plugin.json" 2>/dev/null || true)
    if [ -n "$MANIFEST_VERSION" ]; then
        if [ "$MANIFEST_VERSION" = "$VERSION_CONTENT" ]; then
            print_status "plugin.json version matches VERSION file ($MANIFEST_VERSION)" 0
        else
            print_status "plugin.json version matches VERSION file (got $MANIFEST_VERSION, expected $VERSION_CONTENT)" 1
        fi
    fi
fi

# Check marketplace.json version matches VERSION file
if [ -n "$VERSION_CONTENT" ] && [ -f "./.claude-plugin/marketplace.json" ] && command -v jq &>/dev/null; then
    MARKETPLACE_VERSION=$(jq -r '.plugins[0].version // empty' "./.claude-plugin/marketplace.json" 2>/dev/null || true)
    if [ -n "$MARKETPLACE_VERSION" ]; then
        if [ "$MARKETPLACE_VERSION" = "$VERSION_CONTENT" ]; then
            print_status "marketplace.json version matches VERSION file ($MARKETPLACE_VERSION)" 0
        else
            print_status "marketplace.json version matches VERSION file (got $MARKETPLACE_VERSION, expected $VERSION_CONTENT)" 1
        fi
    fi
fi

# Check agents directory
AGENTS_DIR="./agents"
if [ -d "$AGENTS_DIR" ]; then
    print_status "agents/ directory exists" 0
    AGENT_COUNT=$(find "$AGENTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    print_info "Found $AGENT_COUNT agent files"
else
    print_status "agents/ directory exists" 1
    AGENT_COUNT=0
fi

# Check skills directory
SKILLS_DIR="./skills"
if [ -d "$SKILLS_DIR" ]; then
    print_status "skills/ directory exists" 0
    SKILL_COUNT=$(find "$SKILLS_DIR" -name "SKILL.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    print_info "Found $SKILL_COUNT skill files"
else
    print_status "skills/ directory exists" 1
    SKILL_COUNT=0
fi

echo ""
echo "🤖 Validating Sub-Agents..."
echo "=========================="

# Auto-discover agents and skills from directory structure
REQUIRED_AGENTS=()
while IFS= read -r agent_file; do
    REQUIRED_AGENTS+=("$(basename "$agent_file" .md)")
done < <(find "./agents" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort)
REQUIRED_SKILLS=()
for skill_dir in ./skills/*/; do
    [ -f "$skill_dir/SKILL.md" ] && REQUIRED_SKILLS+=("$(basename "$skill_dir")")
done
print_info "Discovered ${#REQUIRED_AGENTS[@]} agents and ${#REQUIRED_SKILLS[@]} skills"
# shellcheck disable=SC2034 # Used by validation checks below
VALID_TOOLS=("Read" "Write" "Edit" "Bash" "Grep" "Glob" "LSP")
VALID_MODELS=("haiku")

# Function to build agent pattern dynamically from REQUIRED_AGENTS array
build_agent_pattern() {
    local pattern=""
    local first=true
    for agent in "${REQUIRED_AGENTS[@]}"; do
        if [ "$first" = true ]; then
            pattern="$agent"
            first=false
        else
            pattern="$pattern\|$agent"
        fi
    done
    echo "$pattern"
}

# Build agent pattern for grep searches (used in multiple places)
AGENT_PATTERN=$(build_agent_pattern)

for agent in "${REQUIRED_AGENTS[@]}"; do
    AGENT_FILE="./agents/${agent}.md"

    if [ -f "$AGENT_FILE" ]; then
        print_status "$agent.md exists" 0

        # Check YAML frontmatter
        if head -1 "$AGENT_FILE" | grep -q "^---$"; then
            print_status "$agent has YAML frontmatter" 0
        else
            print_status "$agent has YAML frontmatter" 1
        fi

        # Check required fields
        if grep -q "^name: $agent$" "$AGENT_FILE"; then
            print_status "$agent has correct name field" 0
        else
            print_status "$agent has correct name field" 1
        fi

        if grep -q "^description:" "$AGENT_FILE"; then
            print_status "$agent has description field" 0
        else
            print_status "$agent has description field" 1
        fi

        # Check tools field format
        if grep -q "^tools:" "$AGENT_FILE"; then
            TOOLS_LINE=$(grep "^tools:" "$AGENT_FILE")
            print_info "$agent tools: $TOOLS_LINE"
        else
            print_warning "$agent missing tools field (optional but recommended)"
        fi

        # Check model field (optional, but must be valid if present)
        if grep -q "^model:" "$AGENT_FILE"; then
            MODEL_VALUE=$(grep "^model:" "$AGENT_FILE" | head -1 | sed 's/^model:[[:space:]]*//')
            MODEL_VALID=false
            for valid_model in "${VALID_MODELS[@]}"; do
                if [ "$MODEL_VALUE" = "$valid_model" ]; then
                    MODEL_VALID=true
                    break
                fi
            done
            if [ "$MODEL_VALID" = true ]; then
                print_status "$agent has valid model field ($MODEL_VALUE)" 0
            else
                print_status "$agent has invalid model field (got '$MODEL_VALUE', expected one of: ${VALID_MODELS[*]})" 1
            fi
        fi

        # Check content structure
        if grep -q "^# " "$AGENT_FILE"; then
            print_status "$agent has proper content structure" 0
        else
            print_status "$agent has proper content structure" 1
        fi

    else
        print_status "$agent.md exists" 1
    fi
done

echo ""
echo "📋 Validating Skills..."
echo "========================"

for skill in "${REQUIRED_SKILLS[@]}"; do
    SKILL_FILE="./skills/${skill}/SKILL.md"

    if [ -f "$SKILL_FILE" ]; then
        print_status "$skill skill exists" 0

        # Check YAML frontmatter
        if head -1 "$SKILL_FILE" | grep -q "^---$"; then
            print_status "$skill has YAML frontmatter" 0
        else
            print_status "$skill has YAML frontmatter" 1
        fi

        # Check description field
        if grep -q "^description:" "$SKILL_FILE"; then
            print_status "$skill has description field" 0
        else
            print_status "$skill has description field" 1
        fi

        # Check for $ARGUMENTS usage
        # shellcheck disable=SC2016 # Intentionally matching literal $ARGUMENTS
        if grep -q '\$ARGUMENTS' "$SKILL_FILE"; then
            print_status "$skill uses \$ARGUMENTS placeholder" 0
        else
            print_warning "$skill doesn't use \$ARGUMENTS (may be intentional)"
        fi

        # Check for agent delegation
        AGENT_MENTIONS=$(grep -c "$AGENT_PATTERN" "$SKILL_FILE" || true)
        if [ "$AGENT_MENTIONS" -gt 0 ]; then
            print_status "$skill delegates to agents ($AGENT_MENTIONS mentions)" 0
        else
            print_warning "$skill doesn't delegate to agents"
        fi

    else
        print_status "$skill skill exists" 1
    fi
done

echo ""
echo "📖 Validating AGENTS.md..."
echo "=========================="

AGENTS_MD_PATH="./AGENTS.md"

if [ -f "$AGENTS_MD_PATH" ]; then
    print_status "AGENTS.md exists at repository root" 0

    if grep -q "Spec First" "$AGENTS_MD_PATH"; then
        print_status "AGENTS.md contains spec-first framework" 0
    else
        print_status "AGENTS.md contains spec-first framework" 1
    fi

    if grep -q "## Core Philosophy" "$AGENTS_MD_PATH"; then
        print_status "AGENTS.md has core philosophy section" 0
    else
        print_status "AGENTS.md has core philosophy section" 1
    fi

    if grep -q "## Principles" "$AGENTS_MD_PATH"; then
        print_status "AGENTS.md has principles section" 0
    else
        print_status "AGENTS.md has principles section" 1
    fi
else
    print_status "AGENTS.md exists at repository root" 1
fi

echo ""
echo "📚 Checking Documentation..."
echo "============================"

README_PATH="./README.md"
if [ -f "$README_PATH" ]; then
    print_status "README.md exists" 0

    if grep -q "Quick Start" "$README_PATH"; then
        print_status "README.md has quick start guide" 0
    else
        print_status "README.md has quick start guide" 1
    fi

    if grep -q "Command Reference" "$README_PATH"; then
        print_status "README.md has command reference" 0
    else
        print_status "README.md has command reference" 1
    fi
else
    print_status "README.md exists" 1
fi

if [ -d "./examples" ]; then
    print_status "examples/ directory exists" 0
    EXAMPLE_COUNT=$(find "./examples" -name "*.md" -type f | wc -l | tr -d ' ')
    print_info "Found $EXAMPLE_COUNT example files"
else
    print_warning "examples/ directory missing (recommended)"
fi

echo ""
echo "🔧 Integration Checks..."
echo "======================="

# Check for consistency between agents and skills
SKILL_AGENT_REFS=0
if [ -d "./skills" ]; then
    SKILL_AGENT_REFS=$(grep -rh "$AGENT_PATTERN" ./skills/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
    print_info "Found $SKILL_AGENT_REFS agent references in skills"
else
    print_warning "skills/ directory missing"
fi

if [ "$SKILL_AGENT_REFS" -gt 0 ]; then
    print_status "Skills integrate with agents" 0
else
    print_status "Skills integrate with agents" 1
fi

# Documentation consistency validation
echo ""
echo "📋 Documentation Consistency..."
echo "=============================="

# Check workflow completeness (using centralized skill list)
WORKFLOW_COMPLETE=true

for skill in "${REQUIRED_SKILLS[@]}"; do
    SKILL_PATH="./skills/${skill}/SKILL.md"
    if [ ! -f "$SKILL_PATH" ]; then
        WORKFLOW_COMPLETE=false
        break
    fi
done

if [ "$WORKFLOW_COMPLETE" = true ]; then
    print_status "Complete workflow chain available" 0
else
    print_status "Complete workflow chain available" 1
fi

echo ""
echo "📊 Validation Summary"
echo "===================="
echo -e "Passed:   ${GREEN}$PASSED${NC}"
echo -e "Failed:   ${RED}$FAILED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

# Final assessment
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Plugin validation PASSED!${NC}"
    echo -e "${GREEN}The Spec First plugin is properly configured and ready for use.${NC}"

    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Note: $WARNINGS warnings found. Consider addressing them for optimal performance.${NC}"
    fi

    echo ""
    echo "🚀 Next Steps:"
    echo "- Create spec: /sf:spec sample feature"
    echo "- Implement code: /sf:implement spec-file-or-requirements"
    echo "- Generate docs: /sf:document spec-and-code-paths"

    exit 0
else
    echo -e "${RED}❌ Plugin validation FAILED!${NC}"
    echo -e "${RED}$FAILED critical issues must be resolved.${NC}"

    echo ""
    echo "🔧 Recommended Actions:"
    echo "- Fix missing files and directories"
    echo "- Correct YAML frontmatter syntax"
    echo "- Ensure all required fields are present"
    echo "- Restart Claude Code after fixes"

    exit 1
fi
