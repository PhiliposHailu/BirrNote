import re

file_path = "lib/core/utils/app_translations.dart"
with open(file_path, "r") as f:
    content = f.read()

new_keys = {
    'manual_entry': "Manual Entry",
    'amount_etb': "Amount (ETB)",
    'category_label': "Category",
    'quantity_label': "Quantity:",
    'note_optional': "Note (Optional)",
    'eg_lunch': "e.g. Lunch with friends",
    'save_expense': "Save Expense",
    'manage_categories_desc': "Add, delete, or reorder categories",
    'eg_coffee': "e.g. Coffee 50...",
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
print("Translations updated successfully (pass 2).")
