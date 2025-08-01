#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function snooze() {
    echo -e "${YELLOW}😴 Snooze...${NC}"
    sleep "$1"
}

deno fmt
gleam format
gleam update
gleam build

set +e
gleam test
gleam run -m birdie 
set -e

echo -e "${GREEN}==> erlang${NC}"
./scripts/target_test.sh erlang

echo -e "${GREEN}==> nodejs${NC}"
./scripts/target_test.sh javascript nodejs

echo -e "${GREEN}==> deno${NC}"
./scripts/target_test.sh javascript deno

echo -e "${GREEN}==> bun${NC}"
./scripts/target_test.sh javascript bun
