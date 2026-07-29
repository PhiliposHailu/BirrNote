import re

file_path = "lib/core/utils/app_translations.dart"
with open(file_path, "r") as f:
    content = f.read()

new_keys = {
    'this_week': "This Week",
    'this_month': "This Month",
    'last_3_months': "Last 3 Months",
    'error_prefix': "Error: ",
    'no_trend_data': "No trend data available yet.",
    'no_spending_logged_today_start': "No spending logged today! Start typing below.",
    'waiting_for_ai': "Waiting for AI... • ",
    'note_prefix': "Note: \\\"",
    'qty_prefix': "\\\" • Qty: ",
    'retrying_ai_sync': "Retrying AI Sync...",
    'error_loading_categories': "Error loading categories: ",
    'new_category_name': "New Category Name",
    'eg_gym_pets': "e.g., Gym, Pets...",
    'default_fallback_category': "Default fallback category",
    'delete': "Delete ",
    'delete_category_q': "Delete \\\"",
    'past_expenses_warning': "Past expenses under this category will not be deleted, but you won't be able to select it for future ones.",
    'reset_to_default_categories': "Reset to Default Categories",
    'reset_categories_q': "Reset Categories?",
    'reset_warning': "This will delete all custom categories and restore the default 5. Past expenses will not be deleted. Continue?",
    'reset': "Reset",
    'key_active_secured': "Key Active & Secured",
    'add_key_for_ai': "Add key for AI note parsing",
    'when_disabled_notes': "When disabled, notes are logged directly as drafts",
    'birr_note_footer': "BirrNote v1.0.0 • Local First",
    'budget_tour_title': "Today's Spending Power 📊",
    'budget_tour_desc': "This card displays exactly how much you can spend today. It automatically rolls over your savings or overspends every week!",
    'log_tour_title': "Your Daily Log 📝",
    'log_tour_desc': "This is your daily spending feed. If you make a mistake, tap the red trash can icon to delete any item safely with an Undo option.",
    'chat_tour_title': "Effortless Tracking 💬",
    'chat_tour_desc': "Type your transactions naturally here (e.g. 'taxi 50' or 'macchiato 40') and Gemini AI will instantly categorize it, or tap the '+' icon to log it manually!",
    'skip': "SKIP",
    'deleted': "Deleted ",
}

def inject_keys(match):
    existing_keys = match.group(1)
    # Inject our new keys at the end of each language block
    injected_str = ""
    for k, v in new_keys.items():
        injected_str += f"      '{k}': \"{v}\",\n"
    return existing_keys + injected_str + "    },"

content = re.sub(r"(      '[^']*': \"[^\"]*\",\n*)+    },", inject_keys, content)

with open(file_path, "w") as f:
    f.write(content)
print("Translations updated successfully.")
