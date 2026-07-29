import re

file_path = "lib/core/utils/app_translations.dart"
with open(file_path, "r") as f:
    content = f.read()

new_keys = {
    'budget_updated_success': "Budget limit updated successfully!",
    'budget_limit_settings': "Budget Limit Settings",
    'current_budget': "Current: ",
    'set_a_budget': "Set a budget limit to track your rollover spending power!",
    'budget_cycle': "Budget Cycle",
    'daily': "Daily",
    'weekly': "Weekly",
    'monthly': "Monthly",
    'quarterly': "Quarterly",
    'yearly': "Yearly",
    'remove_budget': "Remove Budget",
    'remove_budget_q': "Remove Budget?",
    'remove_budget_warning': "This will stop tracking your daily spending power. Past expenses will not be deleted.",
    'remove': "Remove",
    'database_error': "Database Error: "
}

def inject_keys(match):
    existing_keys = match.group(1)
    injected_str = ""
    for k, v in new_keys.items():
        injected_str += f"      '{k}': \"{v}\",\n"
    return existing_keys + injected_str + "    },"

content = re.sub(r"(      '[^']*': \"[^\"]*\",\n*)+    },", inject_keys, content)

with open(file_path, "w") as f:
    f.write(content)
print("Translations updated successfully (pass 3).")
