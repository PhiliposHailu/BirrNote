import re

file_path = "lib/core/utils/app_translations.dart"
with open(file_path, "r") as f:
    content = f.read()

new_keys = {
    'notes': "Notes",
    'dashboard': "Dashboard",
    'advisor': "Advisor",
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
print("Translations updated successfully (pass 4).")
