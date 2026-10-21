Travel Lah! V1.2 — Travel Expense RC

Local-first travel console with a date- and category-based expense ledger and optional Forest Studio Cloud sync.

Travel expenses
- Record each expense by date, category, local currency and amount.
- Supported currencies: THB, MYR, SGD and USD.
- Foreign-currency expenses ask for the MYR equivalent shown by the user's bank or payment app; budget totals use that MYR amount and do not assume an exchange rate.
- Review category totals, daily totals, edit entries, or delete them.
- Existing expense entries remain readable and continue contributing their saved RM amounts to the budget.

Cloud model
- Uses the existing forest-studio-desk-lah Supabase project.
- Sign in with the same Supabase Auth account on iPhone, iPad and Windows.
- Local data is always saved first.
- Cloud sync runs when online.
- Revision checks prevent silent last-write-wins overwrites.
- Conflicts present two explicit choices: use cloud copy or use this device copy.
- Anonymous users have no SELECT/INSERT access to travel_lah_sync.
- RLS restricts rows to auth.uid() = user_id.

Important
- The Supabase publishable key is intentionally present in frontend code; it is not a secret and is protected by RLS.
- Never place a service-role/secret key in this repository or frontend.
- Keep Export Trip Backup as a second recovery path.
