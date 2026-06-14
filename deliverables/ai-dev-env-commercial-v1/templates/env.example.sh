# Example environment for a packaged AI development environment.

export YSYX_AI_ENV_HOME="${YSYX_AI_ENV_HOME:-$PWD}"
export PYTHONPATH="$YSYX_AI_ENV_HOME/scripts${PYTHONPATH:+:$PYTHONPATH}"

# Optional customer project hooks.
export CUSTOMER_PROJECT_ROOT="${CUSTOMER_PROJECT_ROOT:-}"
export CUSTOMER_E2E_PROFILE="${CUSTOMER_E2E_PROFILE:-agent-system}"
